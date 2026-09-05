package app.sora.client

import kotlinx.serialization.Serializable

@Serializable
enum class ConnectionMode {
    Proxy,
    Tun,
}

@Serializable
enum class SoraLanguage(val localeTag: String, val code: String, val flag: String, val nativeName: String) {
    Russian("ru", "RU", "🇷🇺", "Русский"),
    English("en", "EN", "🇬🇧", "English"),
    ChineseSimplified("zh-CN", "简", "🇨🇳", "简体中文"),
    ChineseTraditional("zh-TW", "繁", "🇹🇼", "繁體中文"),
    RussianPreReform("chu", "Ѣ", "🇷🇺", "Русскій дореформенный"),
}

@Serializable
data class SoraSubscription(
    val id: String,
    val url: String,
    val title: String,
    val xrayJson: String,
    val description: String = "",
    val usage: SubscriptionUsage = SubscriptionUsage(),
    val enabled: Boolean = true,
    val expanded: Boolean = true,
    val updateIntervalMinutes: Int = 720,
    val lastUpdatedEpochMillis: Long,
    val lastError: String = "",
)

@Serializable
data class SubscriptionUsage(
    val uploadBytes: Long? = null,
    val downloadBytes: Long? = null,
    val totalBytes: Long? = null,
    val expiresAtEpochSeconds: Long? = null,
)

@Serializable
data class SoraStoredState(
    val subscriptions: List<SoraSubscription> = emptyList(),
    val selectedNodeKey: String = "",
    val mode: ConnectionMode = ConnectionMode.Proxy,
    val language: SoraLanguage = SoraLanguage.Russian,
)

data class SoraNode(
    val key: String,
    val subscriptionId: String,
    val outboundTag: String,
    val name: String,
    val protocol: String,
    val detail: String,
    val flag: String,
)

enum class ConnectionPhase {
    Disconnected,
    Connecting,
    Connected,
    Disconnecting,
    Failed,
}

data class PlatformConnectionState(
    val phase: ConnectionPhase = ConnectionPhase.Disconnected,
    val message: String = "",
)

data class SoraLogEntry(
    val epochMillis: Long,
    val source: String,
    val message: String,
)

data class SoraUiState(
    val subscriptions: List<SoraSubscription> = emptyList(),
    val nodes: List<SoraNode> = emptyList(),
    val selectedNodeKey: String = "",
    val mode: ConnectionMode = ConnectionMode.Proxy,
    val language: SoraLanguage = SoraLanguage.Russian,
    val tunSupported: Boolean = false,
    val connection: PlatformConnectionState = PlatformConnectionState(),
    val latencies: Map<String, Long> = emptyMap(),
    val pendingLatencyKeys: Set<String> = emptySet(),
    val logs: List<SoraLogEntry> = emptyList(),
    val currentEpochMillis: Long = 0,
    val loading: Boolean = true,
    val operation: String = "",
    val error: String = "",
)

sealed interface ImportResult {
    data class Added(val subscriptionId: String) : ImportResult
    data class Duplicate(val subscriptionId: String) : ImportResult
}

interface SoraStateStore {
    suspend fun read(): String?
    suspend fun write(value: String)
}

interface SoraPlatformGateway {
    val connectionState: kotlinx.coroutines.flow.StateFlow<PlatformConnectionState>
    val supportsTun: Boolean
    suspend fun invokeLibXray(requestJson: String): String
    suspend fun createPingConfig(xrayJson: String): String
    suspend fun deletePingConfig(path: String)
    suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode)
    suspend fun disconnect()
}
