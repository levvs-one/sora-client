package app.sora.client

import io.ktor.client.HttpClient
import io.ktor.client.call.body
import io.ktor.client.request.get
import io.ktor.client.statement.HttpResponse
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpHeaders
import io.ktor.http.isSuccess
import kotlin.random.Random
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class SoraController(
    private val scope: CoroutineScope,
    private val client: HttpClient,
    private val store: SoraStateStore,
    private val gateway: SoraPlatformGateway,
    private val now: () -> Long,
) {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val protocol = LibXrayProtocol(gateway)
    private val mutation = Mutex()
    private val mutableState = MutableStateFlow(SoraUiState())
    private var stored = SoraStoredState()
    private var refreshJob: Job? = null

    val state: StateFlow<SoraUiState> = mutableState.asStateFlow()

    init {
        scope.launch {
            gateway.connectionState.collectLatest { connection ->
                mutableState.value = mutableState.value.copy(connection = connection)
            }
        }
    }

    fun start() {
        if (refreshJob != null) return
        refreshJob = scope.launch {
            load()
            while (true) {
                delay(60_000)
                refreshDueSubscriptions()
            }
        }
    }

    suspend fun importSubscription(rawUrl: String, preferredTitle: String = ""): ImportResult = mutation.withLock {
        val url = rawUrl.trim()
        require(url.startsWith("https://", ignoreCase = true)) { "Подписка должна использовать HTTPS" }
        val duplicate = stored.subscriptions.firstOrNull { canonicalUrl(it.url) == canonicalUrl(url) }
        if (duplicate != null) {
            mutableState.value = mutableState.value.copy(error = "Эта подписка уже добавлена: «${safeTitle(duplicate.title)}»")
            return@withLock ImportResult.Duplicate(duplicate.id)
        }

        setOperation("Добавляем подписку")
        runCatching {
            val fetched = fetch(url)
            val xrayJson = protocol.normalize(fetched.body)
            protocol.validate(xrayJson)
            val id = randomId()
            val title = preferredTitle.trim().take(80).ifBlank {
                protocol.profileTitle(fetched.profileTitle, hostFromUrl(url))
            }
            val subscription = SoraSubscription(
                id = id,
                url = url,
                title = title,
                xrayJson = xrayJson,
                description = fetched.description,
                usage = parseUsage(fetched.userInfo),
                updateIntervalMinutes = fetched.updateIntervalMinutes ?: 720,
                lastUpdatedEpochMillis = now(),
            )
            require(protocol.nodes(subscription).isNotEmpty()) { "Подписка не содержит поддерживаемых серверов" }
            stored = stored.copy(subscriptions = stored.subscriptions + subscription)
            persist()
            log("Подписки", "Добавлена подписка «${safeTitle(title)}»")
            ImportResult.Added(id)
        }.getOrElse { failure ->
            failOperation(failure, "Не удалось добавить подписку")
            throw failure
        }.also { clearOperation() }
    }

    suspend fun updateSubscription(id: String) = mutation.withLock {
        val old = stored.subscriptions.firstOrNull { it.id == id } ?: return@withLock
        setOperation("Обновляем «${safeTitle(old.title)}»")
        val updated = runCatching {
            val fetched = fetch(old.url)
            val xrayJson = protocol.normalize(fetched.body)
            protocol.validate(xrayJson)
            old.copy(
                title = protocol.profileTitle(fetched.profileTitle, old.title),
                xrayJson = xrayJson,
                description = fetched.description.ifBlank { old.description },
                usage = parseUsage(fetched.userInfo),
                lastUpdatedEpochMillis = now(),
                lastError = "",
            ).also { require(protocol.nodes(it).isNotEmpty()) { "Подписка не содержит поддерживаемых серверов" } }
        }.getOrElse { failure ->
            old.copy(lastError = userMessage(failure))
        }
        stored = stored.copy(subscriptions = stored.subscriptions.map { if (it.id == id) updated else it })
        persist()
        if (updated.lastError.isBlank()) log("Подписки", "Обновлена «${safeTitle(updated.title)}»")
        else failOperation(IllegalStateException(updated.lastError), "Не удалось обновить подписку")
        clearOperation()
    }

    suspend fun updateAll() {
        val ids = stored.subscriptions.filter(SoraSubscription::enabled).map(SoraSubscription::id)
        ids.forEach { updateSubscription(it) }
    }

    suspend fun deleteSubscription(id: String) = mutation.withLock {
        val removed = stored.subscriptions.firstOrNull { it.id == id } ?: return@withLock
        val selectedBelongsToRemoved = mutableState.value.nodes.firstOrNull { it.key == stored.selectedNodeKey }?.subscriptionId == id
        stored = stored.copy(
            subscriptions = stored.subscriptions.filterNot { it.id == id },
            selectedNodeKey = if (selectedBelongsToRemoved) "" else stored.selectedNodeKey,
        )
        persist()
        log("Подписки", "Удалена «${safeTitle(removed.title)}»")
    }

    suspend fun renameSubscription(id: String, title: String) = updateSubscriptionRecord(id) {
        it.copy(title = title.trim().take(80).ifBlank { it.title })
    }

    suspend fun setSubscriptionEnabled(id: String, enabled: Boolean) = updateSubscriptionRecord(id) {
        it.copy(enabled = enabled)
    }

    suspend fun setSubscriptionExpanded(id: String, expanded: Boolean) = updateSubscriptionRecord(id) {
        it.copy(expanded = expanded)
    }

    suspend fun setUpdateInterval(id: String, minutes: Int) = updateSubscriptionRecord(id) {
        it.copy(updateIntervalMinutes = minutes.coerceIn(15, 43_200))
    }

    suspend fun selectNode(key: String) = mutation.withLock {
        if (mutableState.value.nodes.none { it.key == key }) return@withLock
        stored = stored.copy(selectedNodeKey = key)
        persist()
    }

    suspend fun setMode(mode: ConnectionMode) = mutation.withLock {
        require(mode != ConnectionMode.Tun || gateway.supportsTun) { "TUN недоступен на этой системе" }
        if (gateway.connectionState.value.phase == ConnectionPhase.Connected) {
            mutableState.value = mutableState.value.copy(error = "Сначала отключитесь: смена режима требует нового подключения")
            throw IllegalStateException("Сначала отключитесь: смена режима требует нового подключения")
        }
        stored = stored.copy(mode = mode)
        persist()
    }

    suspend fun pingAll() {
        val subscriptions = stored.subscriptions.filter(SoraSubscription::enabled)
        val allNodes = mutableState.value.nodes
        mutableState.value = mutableState.value.copy(pendingLatencyKeys = allNodes.map(SoraNode::key).toSet(), error = "")
        subscriptions.forEach { subscription ->
            val nodes = allNodes.filter { it.subscriptionId == subscription.id }
            val latencies = runCatching {
                protocol.ping(subscription.xrayJson, nodes.map(SoraNode::outboundTag))
            }.getOrElse { failure ->
                log("Задержка", "${safeTitle(subscription.title)}: ${userMessage(failure)}")
                emptyMap()
            }
            val keyed = nodes.mapNotNull { node -> latencies[node.outboundTag]?.let { node.key to it } }.toMap()
            mutableState.value = mutableState.value.copy(
                latencies = mutableState.value.latencies + keyed,
                pendingLatencyKeys = mutableState.value.pendingLatencyKeys - nodes.map(SoraNode::key).toSet(),
            )
        }
    }

    suspend fun connectOrDisconnect() {
        when (gateway.connectionState.value.phase) {
            ConnectionPhase.Connected, ConnectionPhase.Connecting -> gateway.disconnect()
            ConnectionPhase.Disconnected, ConnectionPhase.Failed -> runCatching { connectSelected() }.onFailure { failure ->
                mutableState.value = mutableState.value.copy(error = userMessage(failure))
            }
            ConnectionPhase.Disconnecting -> Unit
        }
    }

    fun clearError() {
        mutableState.value = mutableState.value.copy(error = "")
    }

    suspend fun exportLogs(): String = mutableState.value.logs.joinToString("\n") { entry ->
        "${entry.epochMillis}\t${entry.source}\t${entry.message}"
    }

    private suspend fun load() = mutation.withLock {
        stored = store.read()?.let { raw -> runCatching { json.decodeFromString<SoraStoredState>(raw) }.getOrNull() }
            ?: SoraStoredState()
        publish(loading = false)
    }

    private suspend fun connectSelected() {
        val node = mutableState.value.nodes.firstOrNull { it.key == stored.selectedNodeKey }
            ?: throw IllegalStateException("Выберите сервер")
        val subscription = stored.subscriptions.first { it.id == node.subscriptionId }
        gateway.connect(subscription.xrayJson, node.outboundTag, stored.mode)
        log("Подключение", "${safeTitle(node.name)}, режим ${if (stored.mode == ConnectionMode.Tun) "TUN" else "прокси"}")
    }

    private suspend fun refreshDueSubscriptions() {
        val moment = now()
        stored.subscriptions.filter { subscription ->
            subscription.enabled && moment - subscription.lastUpdatedEpochMillis >= subscription.updateIntervalMinutes * 60_000L
        }.map(SoraSubscription::id).forEach { updateSubscription(it) }
    }

    private suspend fun updateSubscriptionRecord(id: String, transform: (SoraSubscription) -> SoraSubscription) = mutation.withLock {
        stored = stored.copy(subscriptions = stored.subscriptions.map { if (it.id == id) transform(it) else it })
        persist()
    }

    private suspend fun persist() {
        store.write(json.encodeToString(stored))
        publish(loading = false)
    }

    private fun publish(loading: Boolean = mutableState.value.loading) {
        val nodes = stored.subscriptions.filter(SoraSubscription::enabled).flatMap(protocol::nodes)
        val selected = stored.selectedNodeKey.takeIf { key -> nodes.any { it.key == key } }.orEmpty()
        if (selected != stored.selectedNodeKey) stored = stored.copy(selectedNodeKey = selected)
        mutableState.value = mutableState.value.copy(
            subscriptions = stored.subscriptions,
            nodes = nodes,
            selectedNodeKey = selected,
            mode = stored.mode,
            tunSupported = gateway.supportsTun,
            currentEpochMillis = now(),
            loading = loading,
        )
    }

    private suspend fun fetch(url: String): FetchedSubscription {
        val response: HttpResponse = client.get(url) {
            headers.append(HttpHeaders.UserAgent, "Sora/0.3 (Android; Linux)")
            headers.append(HttpHeaders.Accept, "text/plain, application/json")
        }
        require(response.status.isSuccess()) { "Сервер подписки ответил ${response.status.value}" }
        val body = response.bodyAsText().trim()
        require(body.isNotBlank()) { "Сервер вернул пустую подписку" }
        return FetchedSubscription(
            body = body,
            profileTitle = response.headers["profile-title"],
            userInfo = response.headers["subscription-userinfo"],
            description = protocol.profileTitle(response.headers["announce"], ""),
            updateIntervalMinutes = response.headers["profile-update-interval"]?.trim()?.toIntOrNull()?.times(60),
        )
    }

    private fun parseUsage(header: String?): SubscriptionUsage {
        val values = header.orEmpty().split(';').mapNotNull { part ->
            val pair = part.trim().split('=', limit = 2)
            if (pair.size == 2) pair[0].lowercase() to pair[1].toLongOrNull() else null
        }.toMap()
        return SubscriptionUsage(values["upload"], values["download"], values["total"], values["expire"])
    }

    private fun setOperation(name: String) {
        mutableState.value = mutableState.value.copy(operation = name, error = "")
    }

    private fun clearOperation() {
        mutableState.value = mutableState.value.copy(operation = "")
    }

    private fun failOperation(failure: Throwable, fallback: String) {
        val message = userMessage(failure).ifBlank { fallback }
        mutableState.value = mutableState.value.copy(error = message)
        log("Ошибка", message)
    }

    private fun log(source: String, message: String) {
        val safe = message.replace(Regex("https?://\\S+"), "[ссылка скрыта]")
        val entries = mutableState.value.logs + SoraLogEntry(now(), source, safe)
        mutableState.value = mutableState.value.copy(logs = entries.takeLast(1_000))
    }

    private fun userMessage(failure: Throwable): String = failure.message?.lineSequence()?.firstOrNull()?.take(180)
        ?: "Неизвестная ошибка"

    private fun safeTitle(value: String): String = value.replace(Regex("[\\r\\n\\t]"), " ").take(80)

    private fun hostFromUrl(url: String): String = url.substringAfter("://").substringBefore('/').substringBefore('?').ifBlank { "Подписка" }

    private fun canonicalUrl(url: String): String = url.trim().trimEnd('/').lowercase()

    private fun randomId(): String = buildString {
        repeat(24) { append("0123456789abcdef"[Random.nextInt(16)]) }
    }

    private data class FetchedSubscription(
        val body: String,
        val profileTitle: String?,
        val userInfo: String?,
        val description: String,
        val updateIntervalMinutes: Int?,
    )
}
