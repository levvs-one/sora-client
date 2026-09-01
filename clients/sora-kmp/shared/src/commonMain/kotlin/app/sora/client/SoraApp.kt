package app.sora.client

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.requiredSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ColorFilter
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.unit.dp
import app.sora.client.resources.Res
import app.sora.client.resources.icon_add
import app.sora.client.resources.icon_caret
import app.sora.client.resources.icon_close
import app.sora.client.resources.icon_globe
import app.sora.client.resources.icon_info
import app.sora.client.resources.icon_logs
import app.sora.client.resources.icon_more
import app.sora.client.resources.icon_power
import app.sora.client.resources.icon_refresh
import app.sora.client.resources.icon_search
import app.sora.client.resources.icon_settings
import kotlinx.coroutines.launch
import com.mikepenz.markdown.compose.Markdown
import com.mikepenz.markdown.model.DefaultMarkdownColors
import com.mikepenz.markdown.model.DefaultMarkdownTypography
import org.jetbrains.compose.resources.DrawableResource
import org.jetbrains.compose.resources.painterResource

private enum class Screen { Servers, Logs, Settings }

@Composable
fun SoraApp(controller: SoraController) {
    val state by controller.state.collectAsStateCompat()
    var screen by remember { mutableStateOf(Screen.Servers) }
    var importOpen by remember { mutableStateOf(false) }
    var subscriptionSettings by remember { mutableStateOf<String?>(null) }
    val scope = rememberCoroutineScope()

    LaunchedEffect(controller) { controller.start() }
    SoraTheme {
        val colors = LocalSoraColors.current
        BoxWithConstraints(Modifier.fillMaxSize().background(colors.canvas)) {
            val compact = maxWidth < 720.dp
            if (compact) {
                Column(Modifier.fillMaxSize()) {
                    Box(Modifier.weight(1f)) {
                        ScreenContent(screen, state, controller, onImport = { importOpen = true }, onSubscriptionSettings = { subscriptionSettings = it })
                    }
                    MobileNavigation(screen, onSelect = { screen = it })
                }
            } else {
                Row(Modifier.fillMaxSize()) {
                    SideNavigation(screen, onSelect = { screen = it })
                    Box(Modifier.weight(1f)) {
                        ScreenContent(screen, state, controller, onImport = { importOpen = true }, onSubscriptionSettings = { subscriptionSettings = it })
                    }
                }
            }
        }
        if (importOpen) {
            ImportDialog(
                busy = state.operation.isNotBlank(),
                onClose = { importOpen = false },
                onImport = { url, title ->
                    scope.launch {
                        runCatching { controller.importSubscription(url, title) }.getOrNull()?.let { result ->
                            if (result is ImportResult.Added) importOpen = false
                        }
                    }
                },
            )
        }
        subscriptionSettings?.let { id ->
            state.subscriptions.firstOrNull { it.id == id }?.let { subscription ->
                SubscriptionDialog(subscription, onClose = { subscriptionSettings = null }, controller = controller)
            }
        }
        if (state.error.isNotBlank()) {
            NoticeDialog(state.error, onClose = controller::clearError)
        }
    }
}

@Composable
private fun ScreenContent(
    screen: Screen,
    state: SoraUiState,
    controller: SoraController,
    onImport: () -> Unit,
    onSubscriptionSettings: (String) -> Unit,
) {
    when (screen) {
        Screen.Servers -> ServersScreen(state, controller, onImport, onSubscriptionSettings)
        Screen.Logs -> LogsScreen(state, controller)
        Screen.Settings -> SettingsScreen(state, controller)
    }
}

@Composable
private fun SideNavigation(selected: Screen, onSelect: (Screen) -> Unit) {
    val colors = LocalSoraColors.current
    Column(
        Modifier.width(72.dp).fillMaxHeight().background(colors.navigation).border(width = 1.dp, color = colors.surface, shape = RoundedCornerShape(0.dp)),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(18.dp))
        NavigationButton(Res.drawable.icon_add, "Добавить", false) { onSelect(Screen.Servers) }
        Spacer(Modifier.height(12.dp))
        NavigationButton(Res.drawable.icon_globe, "Серверы", selected == Screen.Servers) { onSelect(Screen.Servers) }
        Spacer(Modifier.height(12.dp))
        NavigationButton(Res.drawable.icon_logs, "Журнал", selected == Screen.Logs) { onSelect(Screen.Logs) }
        Spacer(Modifier.height(12.dp))
        NavigationButton(Res.drawable.icon_settings, "Настройки", selected == Screen.Settings) { onSelect(Screen.Settings) }
        Spacer(Modifier.weight(1f))
        NavigationButton(Res.drawable.icon_info, "О Sora", selected == Screen.Settings) { onSelect(Screen.Settings) }
        Spacer(Modifier.height(18.dp))
    }
}

@Composable
private fun MobileNavigation(selected: Screen, onSelect: (Screen) -> Unit) {
    val colors = LocalSoraColors.current
    Row(
        Modifier.fillMaxWidth().height(64.dp).background(colors.navigation).border(1.dp, colors.surface),
        horizontalArrangement = Arrangement.SpaceEvenly,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        NavigationButton(Res.drawable.icon_globe, "Серверы", selected == Screen.Servers) { onSelect(Screen.Servers) }
        NavigationButton(Res.drawable.icon_logs, "Журнал", selected == Screen.Logs) { onSelect(Screen.Logs) }
        NavigationButton(Res.drawable.icon_settings, "Настройки", selected == Screen.Settings) { onSelect(Screen.Settings) }
    }
}

@Composable
private fun NavigationButton(icon: DrawableResource, label: String, selected: Boolean, onClick: () -> Unit) {
    val colors = LocalSoraColors.current
    Box(
        Modifier.requiredSize(44.dp).clip(RoundedCornerShape(8.dp)).background(if (selected) colors.surfaceRaised else Color.Transparent).clickable(onClick = onClick),
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, label, Modifier.size(22.dp), if (selected) colors.text else colors.textSecondary)
    }
}

@Composable
private fun ServersScreen(state: SoraUiState, controller: SoraController, onImport: () -> Unit, onSubscriptionSettings: (String) -> Unit) {
    BoxWithConstraints(Modifier.fillMaxSize()) {
        if (maxWidth < 900.dp) {
            Column(Modifier.fillMaxSize().padding(horizontal = 20.dp)) {
                ServerList(Modifier.weight(1f), state, controller, onImport, onSubscriptionSettings)
                ConnectionPanel(Modifier.fillMaxWidth().height(244.dp), state, controller)
            }
        } else {
            Row(Modifier.fillMaxSize()) {
                ServerList(Modifier.width(480.dp).fillMaxHeight().padding(horizontal = 28.dp), state, controller, onImport, onSubscriptionSettings)
                ConnectionPanel(Modifier.weight(1f).fillMaxHeight(), state, controller)
            }
        }
    }
}

@Composable
private fun ServerList(
    modifier: Modifier,
    state: SoraUiState,
    controller: SoraController,
    onImport: () -> Unit,
    onSubscriptionSettings: (String) -> Unit,
) {
    var query by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()
    Column(modifier.padding(top = 28.dp, bottom = 20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            SoraText("Серверы", style = LocalSoraTypography.current.title)
            Spacer(Modifier.weight(1f))
            IconButton(Res.drawable.icon_add, "Добавить подписку", onImport)
        }
        Spacer(Modifier.height(16.dp))
        Row(verticalAlignment = Alignment.CenterVertically) {
            SearchField(query, { query = it }, Modifier.weight(1f))
            Spacer(Modifier.width(8.dp))
            IconButton(Res.drawable.icon_refresh, "Измерить задержку") { scope.launch { controller.pingAll() } }
        }
        Spacer(Modifier.height(16.dp))
        if (state.loading) {
            CenterMessage("Загружаем подписки", Modifier.weight(1f))
        } else if (state.subscriptions.isEmpty()) {
            EmptySubscriptions(Modifier.weight(1f), onImport)
        } else {
            LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                items(state.subscriptions, key = SoraSubscription::id) { subscription ->
                    val nodes = state.nodes.filter { node ->
                        node.subscriptionId == subscription.id && (query.isBlank() || node.name.contains(query, true) || node.protocol.contains(query, true))
                    }
                    SubscriptionCard(subscription, nodes, state, controller, onSubscriptionSettings)
                }
            }
        }
    }
}

@Composable
private fun SubscriptionCard(
    subscription: SoraSubscription,
    nodes: List<SoraNode>,
    state: SoraUiState,
    controller: SoraController,
    onSettings: (String) -> Unit,
) {
    val colors = LocalSoraColors.current
    val scope = rememberCoroutineScope()
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(colors.surface).border(1.dp, colors.line, RoundedCornerShape(8.dp))) {
        Row(
            Modifier.fillMaxWidth().clickable { scope.launch { controller.setSubscriptionExpanded(subscription.id, !subscription.expanded) } }.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(Res.drawable.icon_caret, if (subscription.expanded) "Свернуть" else "Развернуть", Modifier.size(18.dp).rotate(if (subscription.expanded) 90f else 0f), colors.textSecondary)
            Spacer(Modifier.width(10.dp))
            Column(Modifier.weight(1f)) {
                SoraText(subscription.title, style = LocalSoraTypography.current.heading, maxLines = 1)
                Spacer(Modifier.height(2.dp))
                SoraText("${nodes.size} ${serverWord(nodes.size)}", color = colors.textSecondary, style = LocalSoraTypography.current.caption)
            }
            IconButton(Res.drawable.icon_refresh, "Обновить") { scope.launch { controller.updateSubscription(subscription.id) } }
            Spacer(Modifier.width(2.dp))
            IconButton(Res.drawable.icon_more, "Настройки") { onSettings(subscription.id) }
        }
        UsageLine(subscription.usage, state.currentEpochMillis)
        if (subscription.description.isNotBlank()) {
            MarkdownDescription(subscription.description)
        }
        if (subscription.lastError.isNotBlank()) {
            SoraText(subscription.lastError, Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), color = colors.danger, style = LocalSoraTypography.current.caption)
        }
        AnimatedVisibility(subscription.expanded) {
            Column {
                nodes.forEach { node ->
                    NodeRow(node, selected = node.key == state.selectedNodeKey, latency = state.latencies[node.key], pending = node.key in state.pendingLatencyKeys) {
                        scope.launch { controller.selectNode(node.key) }
                    }
                }
            }
        }
    }
}

@Composable
private fun MarkdownDescription(markdown: String) {
    val colors = LocalSoraColors.current
    val typography = LocalSoraTypography.current
    val paragraph = typography.caption.copy(color = colors.textSecondary, textAlign = TextAlign.Center)
    Markdown(
        content = markdown,
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp),
        colors = DefaultMarkdownColors(
            text = colors.textSecondary,
            codeBackground = colors.canvas,
            inlineCodeBackground = colors.canvas,
            dividerColor = colors.line,
            tableBackground = colors.surfaceRaised,
        ),
        typography = DefaultMarkdownTypography(
            h1 = typography.heading.copy(textAlign = TextAlign.Center),
            h2 = typography.heading.copy(textAlign = TextAlign.Center),
            h3 = typography.body.copy(fontWeight = androidx.compose.ui.text.font.FontWeight.SemiBold, textAlign = TextAlign.Center),
            h4 = typography.body.copy(textAlign = TextAlign.Center),
            h5 = typography.label.copy(textAlign = TextAlign.Center),
            h6 = typography.label.copy(textAlign = TextAlign.Center),
            text = paragraph,
            code = typography.caption,
            inlineCode = typography.caption,
            quote = paragraph,
            paragraph = paragraph,
            ordered = paragraph,
            bullet = paragraph,
            list = paragraph,
            textLink = TextLinkStyles(style = SpanStyle(color = colors.text)),
            table = typography.caption,
        ),
    )
}

@Composable
private fun UsageLine(usage: SubscriptionUsage, currentEpochMillis: Long) {
    if (usage.totalBytes == null && usage.expiresAtEpochSeconds == null) return
    val colors = LocalSoraColors.current
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
        val used = (usage.uploadBytes ?: 0L) + (usage.downloadBytes ?: 0L)
        SoraText(if (usage.totalBytes != null) "${formatBytes(used)} из ${formatBytes(usage.totalBytes)}" else formatBytes(used), color = colors.textSecondary, style = LocalSoraTypography.current.caption)
        Spacer(Modifier.weight(1f))
        usage.expiresAtEpochSeconds?.let { SoraText(formatExpiry(it, currentEpochMillis), color = colors.textSecondary, style = LocalSoraTypography.current.caption) }
    }
}

@Composable
private fun NodeRow(node: SoraNode, selected: Boolean, latency: Long?, pending: Boolean, onClick: () -> Unit) {
    val colors = LocalSoraColors.current
    Row(
        Modifier.fillMaxWidth().background(if (selected) colors.surfaceRaised else Color.Transparent).selectable(selected, onClick = onClick).padding(horizontal = 14.dp, vertical = 11.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.size(30.dp).clip(RoundedCornerShape(8.dp)).background(colors.canvas), contentAlignment = Alignment.Center) {
            SoraText(node.flag, style = LocalSoraTypography.current.body)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            SoraText(node.name, style = LocalSoraTypography.current.body, maxLines = 1)
            if (node.detail.isNotBlank()) SoraText(listOf(node.protocol, node.detail).joinToString("  /  "), color = colors.textSecondary, style = LocalSoraTypography.current.caption, maxLines = 1)
        }
        Spacer(Modifier.width(8.dp))
        when {
            pending -> BouncingDots()
            latency != null -> SoraText("$latency мс", style = LocalSoraTypography.current.label)
        }
    }
}

@Composable
private fun ConnectionPanel(modifier: Modifier, state: SoraUiState, controller: SoraController) {
    val colors = LocalSoraColors.current
    val scope = rememberCoroutineScope()
    val selected = state.nodes.firstOrNull { it.key == state.selectedNodeKey }
    val connected = state.connection.phase == ConnectionPhase.Connected
    Column(modifier.background(colors.surface.copy(alpha = 0.35f)).padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            ModeSelector(state.mode, state.tunSupported, controller)
        }
        Spacer(Modifier.weight(1f))
        val alpha by animateFloatAsState(if (state.connection.phase == ConnectionPhase.Connecting) 0.58f else 1f, tween(160))
        Box(
            Modifier.size(150.dp).alpha(alpha).clip(CircleShape).background(if (connected) colors.text else colors.surfaceRaised).border(2.dp, if (connected) colors.text else colors.textSecondary, CircleShape).clickable(enabled = state.connection.phase != ConnectionPhase.Disconnecting) { scope.launch { runCatching { controller.connectOrDisconnect() } } },
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Icon(Res.drawable.icon_power, "Питание", Modifier.size(28.dp), if (connected) colors.inverse else colors.text)
                Spacer(Modifier.height(10.dp))
                SoraText(connectionLabel(state.connection.phase), color = if (connected) colors.inverse else colors.text, style = LocalSoraTypography.current.label)
            }
        }
        selected?.let { node ->
            val subscription = state.subscriptions.firstOrNull { it.id == node.subscriptionId }
            subscription?.usage?.takeIf { it.uploadBytes != null || it.downloadBytes != null }?.let { usage ->
                Spacer(Modifier.height(18.dp))
                Row(Modifier.clip(RoundedCornerShape(8.dp)).background(colors.surface).padding(horizontal = 16.dp, vertical = 10.dp)) {
                    SoraText("↓ ${formatBytes(usage.downloadBytes ?: 0)}", color = colors.textSecondary, style = LocalSoraTypography.current.caption)
                    Spacer(Modifier.width(18.dp))
                    SoraText("↑ ${formatBytes(usage.uploadBytes ?: 0)}", color = colors.textSecondary, style = LocalSoraTypography.current.caption)
                }
            }
        }
        Spacer(Modifier.height(24.dp))
        SoraText(selected?.name ?: "Сервер не выбран", style = LocalSoraTypography.current.heading, maxLines = 1)
        if (selected != null) {
            Spacer(Modifier.height(4.dp))
            SoraText(listOf(selected.protocol, selected.detail).filter(String::isNotBlank).joinToString("  /  "), color = colors.textSecondary, style = LocalSoraTypography.current.caption, maxLines = 1)
        }
        if (state.connection.message.isNotBlank()) {
            Spacer(Modifier.height(8.dp))
            SoraText(state.connection.message, color = if (state.connection.phase == ConnectionPhase.Failed) colors.danger else colors.textSecondary, style = LocalSoraTypography.current.caption, textAlign = TextAlign.Center)
        }
        Spacer(Modifier.weight(1f))
    }
}

@Composable
private fun ModeSelector(mode: ConnectionMode, tunSupported: Boolean, controller: SoraController) {
    val scope = rememberCoroutineScope()
    Row(Modifier.clip(RoundedCornerShape(8.dp)).border(1.dp, LocalSoraColors.current.line, RoundedCornerShape(8.dp))) {
        listOf(ConnectionMode.Proxy to "Прокси", ConnectionMode.Tun to "TUN").forEach { (value, title) ->
            val enabled = value != ConnectionMode.Tun || tunSupported
            SoraText(
                title,
                Modifier.background(if (mode == value) LocalSoraColors.current.text else Color.Transparent).clickable(enabled) { scope.launch { runCatching { controller.setMode(value) } } }.padding(horizontal = 14.dp, vertical = 9.dp),
                color = when {
                    mode == value -> LocalSoraColors.current.inverse
                    enabled -> LocalSoraColors.current.text
                    else -> LocalSoraColors.current.textMuted
                },
                style = LocalSoraTypography.current.label,
            )
        }
    }
}

@Composable
private fun LogsScreen(state: SoraUiState, controller: SoraController) {
    var query by remember { mutableStateOf("") }
    val colors = LocalSoraColors.current
    Column(Modifier.fillMaxSize().padding(28.dp)) {
        SoraText("Журнал", style = LocalSoraTypography.current.title)
        Spacer(Modifier.height(16.dp))
        SearchField(query, { query = it }, Modifier.fillMaxWidth())
        Spacer(Modifier.height(14.dp))
        val entries = state.logs.filter { query.isBlank() || it.message.contains(query, true) || it.source.contains(query, true) }
        if (entries.isEmpty()) CenterMessage("Записей пока нет", Modifier.weight(1f)) else LazyColumn(Modifier.weight(1f).fillMaxWidth().clip(RoundedCornerShape(8.dp)).background(colors.surface)) {
            items(entries.reversed()) { entry ->
                Row(Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 10.dp)) {
                    SoraText(entry.source, Modifier.width(110.dp), color = colors.textSecondary, style = LocalSoraTypography.current.caption)
                    SoraText(entry.message, Modifier.weight(1f), style = LocalSoraTypography.current.body)
                }
            }
        }
    }
}

@Composable
private fun SettingsScreen(state: SoraUiState, controller: SoraController) {
    val colors = LocalSoraColors.current
    val uriHandler = LocalUriHandler.current
    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(28.dp)) {
        SoraText("Настройки", style = LocalSoraTypography.current.title)
        Spacer(Modifier.height(24.dp))
        SectionTitle("Подключение")
        SettingsRow("Режим", if (state.mode == ConnectionMode.Proxy) "Прокси" else "TUN")
        Spacer(Modifier.height(24.dp))
        SectionTitle("О приложении")
        SettingsRow("Sora", "Клиент подписок для Android и Linux")
        SettingsRow("Исходный код", "github.com/levvs-one/sora-client") {
            uriHandler.openUri("https://github.com/levvs-one/sora-client")
        }
        SettingsRow("Telegram", "t.me/sora_client") {
            uriHandler.openUri("https://t.me/sora_client")
        }
        Spacer(Modifier.height(16.dp))
        SoraText("Sora — независимый проект с открытым исходным кодом.", color = colors.textSecondary, style = LocalSoraTypography.current.caption)
    }
}

@Composable
private fun SectionTitle(value: String) {
    SoraText(value, Modifier.padding(bottom = 8.dp), style = LocalSoraTypography.current.label)
}

@Composable
private fun SettingsRow(name: String, value: String, onClick: (() -> Unit)? = null) {
    val colors = LocalSoraColors.current
    Row(
        Modifier.fillMaxWidth().background(colors.surface).border(1.dp, colors.line).clickable(enabled = onClick != null) { onClick?.invoke() }.padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        SoraText(name, style = LocalSoraTypography.current.body)
        Spacer(Modifier.weight(1f))
        SoraText(value, color = if (onClick == null) colors.textSecondary else colors.text, style = LocalSoraTypography.current.body, textAlign = TextAlign.End)
        if (onClick != null) {
            Spacer(Modifier.width(8.dp))
            Icon(Res.drawable.icon_caret, "Открыть", Modifier.size(16.dp), colors.textSecondary)
        }
    }
}

@Composable
private fun ImportDialog(busy: Boolean, onClose: () -> Unit, onImport: (String, String) -> Unit) {
    var url by remember { mutableStateOf("") }
    var title by remember { mutableStateOf("") }
    DialogSurface(onClose) {
        SoraText("Добавить подписку", style = LocalSoraTypography.current.title)
        Spacer(Modifier.height(8.dp))
        SoraText("Вставьте HTTPS-ссылку. Название и параметры Sora подхватит автоматически.", color = LocalSoraColors.current.textSecondary, style = LocalSoraTypography.current.body)
        Spacer(Modifier.height(20.dp))
        FieldLabel("Ссылка подписки")
        SoraField(url, { url = it }, "https://…")
        Spacer(Modifier.height(14.dp))
        FieldLabel("Название — необязательно")
        SoraField(title, { title = it }, "Из заголовка подписки")
        Spacer(Modifier.height(24.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
            SecondaryButton("Отмена", onClose)
            Spacer(Modifier.width(10.dp))
            PrimaryButton(if (busy) "Добавляем" else "Добавить", enabled = url.trim().startsWith("https://") && !busy) { onImport(url, title) }
        }
    }
}

@Composable
private fun SubscriptionDialog(subscription: SoraSubscription, onClose: () -> Unit, controller: SoraController) {
    var title by remember(subscription.id) { mutableStateOf(subscription.title) }
    var interval by remember(subscription.id) { mutableStateOf(subscription.updateIntervalMinutes.toString()) }
    val scope = rememberCoroutineScope()
    DialogSurface(onClose) {
        SoraText("Настройки подписки", style = LocalSoraTypography.current.title)
        Spacer(Modifier.height(20.dp))
        FieldLabel("Название")
        SoraField(title, { title = it }, "Название")
        Spacer(Modifier.height(14.dp))
        FieldLabel("Обновлять каждые, минут")
        SoraField(interval, { interval = it.filter(Char::isDigit).take(5) }, "720")
        Spacer(Modifier.height(8.dp))
        SoraText(subscription.url.substringBefore('?'), color = LocalSoraColors.current.textMuted, style = LocalSoraTypography.current.caption, maxLines = 1)
        Spacer(Modifier.height(24.dp))
        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
            DangerButton("Удалить") { scope.launch { controller.deleteSubscription(subscription.id); onClose() } }
            Spacer(Modifier.weight(1f))
            SecondaryButton("Отмена", onClose)
            Spacer(Modifier.width(10.dp))
            PrimaryButton("Сохранить", enabled = title.isNotBlank() && (interval.toIntOrNull() ?: 0) >= 15) {
                scope.launch {
                    controller.renameSubscription(subscription.id, title)
                    controller.setUpdateInterval(subscription.id, interval.toInt())
                    onClose()
                }
            }
        }
    }
}

@Composable
private fun NoticeDialog(message: String, onClose: () -> Unit) {
    DialogSurface(onClose) {
        SoraText("Не получилось", style = LocalSoraTypography.current.title)
        Spacer(Modifier.height(12.dp))
        SoraText(message, color = LocalSoraColors.current.textSecondary, style = LocalSoraTypography.current.body)
        Spacer(Modifier.height(22.dp))
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) { PrimaryButton("Закрыть", onClick = onClose) }
    }
}

@Composable
private fun DialogSurface(onClose: () -> Unit, content: @Composable ColumnScope.() -> Unit) {
    val colors = LocalSoraColors.current
    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.72f)).clickable(indication = null, interactionSource = remember { MutableInteractionSource() }, onClick = onClose), contentAlignment = Alignment.Center) {
        Column(
            Modifier.fillMaxWidth(0.88f).width(560.dp).clip(RoundedCornerShape(12.dp)).background(colors.surfaceRaised).border(1.dp, colors.line, RoundedCornerShape(12.dp)).clickable(indication = null, interactionSource = remember { MutableInteractionSource() }) {}.padding(24.dp),
            content = content,
        )
    }
}

@Composable
private fun SearchField(value: String, onValueChange: (String) -> Unit, modifier: Modifier) {
    val colors = LocalSoraColors.current
    Row(modifier.height(42.dp).clip(RoundedCornerShape(8.dp)).background(colors.surface).border(1.dp, colors.line, RoundedCornerShape(8.dp)).padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
        BasicTextField(value, onValueChange, Modifier.weight(1f), textStyle = LocalSoraTypography.current.body.copy(color = colors.text), cursorBrush = SolidColor(colors.text), singleLine = true, decorationBox = { inner ->
            Box {
                if (value.isBlank()) SoraText("Поиск по серверам", color = colors.textMuted, style = LocalSoraTypography.current.body)
                inner()
            }
        })
        Spacer(Modifier.width(8.dp))
        Icon(Res.drawable.icon_search, "Поиск", Modifier.size(20.dp), colors.textSecondary)
    }
}

@Composable
private fun SoraField(value: String, onValueChange: (String) -> Unit, placeholder: String) {
    val colors = LocalSoraColors.current
    BasicTextField(value, onValueChange, Modifier.fillMaxWidth().height(44.dp).clip(RoundedCornerShape(8.dp)).background(colors.surface).border(1.dp, colors.line, RoundedCornerShape(8.dp)).padding(horizontal = 12.dp, vertical = 11.dp), textStyle = LocalSoraTypography.current.body.copy(color = colors.text), cursorBrush = SolidColor(colors.text), singleLine = true, decorationBox = { inner ->
        Box {
            if (value.isBlank()) SoraText(placeholder, color = colors.textMuted, style = LocalSoraTypography.current.body)
            inner()
        }
    })
}

@Composable
private fun FieldLabel(value: String) {
    SoraText(value, Modifier.padding(bottom = 6.dp), color = LocalSoraColors.current.textSecondary, style = LocalSoraTypography.current.label)
}

@Composable
private fun IconButton(icon: DrawableResource, label: String, onClick: () -> Unit) {
    Box(Modifier.size(38.dp).clip(RoundedCornerShape(8.dp)).clickable(onClick = onClick), contentAlignment = Alignment.Center) {
        Icon(icon, label, Modifier.size(20.dp), LocalSoraColors.current.textSecondary)
    }
}

@Composable
private fun Icon(resource: DrawableResource, description: String, modifier: Modifier, color: Color) {
    Image(painterResource(resource), description, modifier, contentScale = ContentScale.Fit, colorFilter = ColorFilter.tint(color))
}

@Composable
private fun SoraText(
    text: String,
    modifier: Modifier = Modifier,
    color: Color = LocalSoraColors.current.text,
    style: androidx.compose.ui.text.TextStyle = LocalSoraTypography.current.body,
    maxLines: Int = Int.MAX_VALUE,
    textAlign: TextAlign? = null,
) {
    androidx.compose.foundation.text.BasicText(text, modifier, style.copy(color = color, textAlign = textAlign ?: style.textAlign), maxLines = maxLines, overflow = TextOverflow.Ellipsis)
}

@Composable
private fun PrimaryButton(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    val colors = LocalSoraColors.current
    Box(Modifier.height(40.dp).clip(RoundedCornerShape(8.dp)).background(if (enabled) colors.text else colors.line).clickable(enabled, onClick = onClick).padding(horizontal = 18.dp), contentAlignment = Alignment.Center) {
        SoraText(text, color = if (enabled) colors.inverse else colors.textMuted, style = LocalSoraTypography.current.label)
    }
}

@Composable
private fun SecondaryButton(text: String, onClick: () -> Unit) {
    Box(Modifier.height(40.dp).clip(RoundedCornerShape(8.dp)).border(1.dp, LocalSoraColors.current.line, RoundedCornerShape(8.dp)).clickable(onClick = onClick).padding(horizontal = 18.dp), contentAlignment = Alignment.Center) {
        SoraText(text, style = LocalSoraTypography.current.label)
    }
}

@Composable
private fun DangerButton(text: String, onClick: () -> Unit) {
    Box(Modifier.height(40.dp).clip(RoundedCornerShape(8.dp)).clickable(onClick = onClick).padding(horizontal = 10.dp), contentAlignment = Alignment.Center) {
        SoraText(text, color = LocalSoraColors.current.danger, style = LocalSoraTypography.current.label)
    }
}

@Composable
private fun EmptySubscriptions(modifier: Modifier, onImport: () -> Unit) {
    Column(modifier.fillMaxWidth(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
        Icon(Res.drawable.icon_globe, "", Modifier.size(32.dp), LocalSoraColors.current.textSecondary)
        Spacer(Modifier.height(14.dp))
        SoraText("Добавьте подписку", style = LocalSoraTypography.current.heading)
        Spacer(Modifier.height(6.dp))
        SoraText("Sora распознает формат и разложит серверы по подпискам.", color = LocalSoraColors.current.textSecondary, style = LocalSoraTypography.current.body, textAlign = TextAlign.Center)
        Spacer(Modifier.height(18.dp))
        PrimaryButton("Добавить", onClick = onImport)
    }
}

@Composable
private fun CenterMessage(text: String, modifier: Modifier) {
    Box(modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { SoraText(text, color = LocalSoraColors.current.textSecondary) }
}

@Composable
private fun BouncingDots() {
    Row(horizontalArrangement = Arrangement.spacedBy(2.dp), verticalAlignment = Alignment.CenterVertically) {
        repeat(3) { Box(Modifier.size(3.dp).clip(CircleShape).background(LocalSoraColors.current.textSecondary)) }
    }
}

@Composable
private fun <T> kotlinx.coroutines.flow.StateFlow<T>.collectAsStateCompat(): androidx.compose.runtime.State<T> = collectAsState()

private fun connectionLabel(phase: ConnectionPhase): String = when (phase) {
    ConnectionPhase.Disconnected, ConnectionPhase.Failed -> "Подключиться"
    ConnectionPhase.Connecting -> "Подключаем"
    ConnectionPhase.Connected -> "Отключить"
    ConnectionPhase.Disconnecting -> "Отключаем"
}

private fun serverWord(count: Int): String = when {
    count % 10 == 1 && count % 100 != 11 -> "сервер"
    count % 10 in 2..4 && count % 100 !in 12..14 -> "сервера"
    else -> "серверов"
}

private fun formatBytes(bytes: Long): String {
    val units = listOf("Б", "КБ", "МБ", "ГБ", "ТБ")
    var value = bytes.toDouble().coerceAtLeast(0.0)
    var unit = 0
    while (value >= 1024 && unit < units.lastIndex) { value /= 1024; unit++ }
    return if (unit == 0) "${value.toLong()} ${units[unit]}" else "${(value * 10).toLong() / 10.0} ${units[unit]}"
}

private fun formatExpiry(epochSeconds: Long, currentEpochMillis: Long): String {
    val remainingDays = ((epochSeconds * 1_000 - currentEpochMillis) / 86_400_000).coerceAtLeast(0)
    return if (epochSeconds * 1_000 <= currentEpochMillis) "Срок истёк" else "Осталось $remainingDays дн."
}
