package app.sora.client

import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.util.Properties
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.put

class LinuxGateway : SoraPlatformGateway, AutoCloseable {
    private val mutableConnection = MutableStateFlow(PlatformConnectionState())
    private val native by lazy { loadNative() }
    private val proxy = LinuxSystemProxy()
    override val connectionState = mutableConnection.asStateFlow()
    override val supportsTun: Boolean = isLinux() && effectiveUserId() == 0

    init { proxy.restoreAfterUncleanExit() }

    override suspend fun invokeLibXray(requestJson: String): String = withContext(Dispatchers.IO) { native.invoke(requestJson) }

    override suspend fun createPingConfig(xrayJson: String): String = withContext(Dispatchers.IO) {
        val directory = xdgDirectory("XDG_CACHE_HOME", ".cache").resolve("sora/ping")
        Files.createDirectories(directory)
        Files.createTempFile(directory, "config-", ".json").also { path ->
            Files.writeString(path, xrayJson, Charsets.UTF_8, StandardOpenOption.TRUNCATE_EXISTING)
            runCatching { Files.setPosixFilePermissions(path, setOf(java.nio.file.attribute.PosixFilePermission.OWNER_READ, java.nio.file.attribute.PosixFilePermission.OWNER_WRITE)) }
        }.toAbsolutePath().toString()
    }

    override suspend fun deletePingConfig(path: String) { withContext(Dispatchers.IO) { Files.deleteIfExists(Path.of(path)) } }

    override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) = withContext(Dispatchers.IO) {
        require(isLinux()) { "Linux-клиент запускается только в Linux" }
        require(mode != ConnectionMode.Tun || supportsTun) { "Для TUN запустите Sora с правами root" }
        mutableConnection.value = PlatformConnectionState(ConnectionPhase.Connecting, "Запускаем ядро")
        runCatching {
            stopCore()
            val runtime = LibXrayProtocol(this@LinuxGateway).runtimeConfig(xrayJson, outboundTag, mode, linuxSystemRoutes = mode == ConnectionMode.Tun)
            invokeMethod("runXray", runtime)
            if (mode == ConnectionMode.Proxy) proxy.enable()
        }.onSuccess {
            mutableConnection.value = PlatformConnectionState(ConnectionPhase.Connected, if (mode == ConnectionMode.Tun) "Весь трафик защищён" else proxy.statusMessage)
        }.onFailure { failure ->
            runCatching { proxy.restore() }
            mutableConnection.value = PlatformConnectionState(ConnectionPhase.Failed, failure.message?.take(160) ?: "Ошибка подключения")
        }.getOrThrow()
        Unit
    }

    override suspend fun disconnect() = withContext(Dispatchers.IO) {
        mutableConnection.value = PlatformConnectionState(ConnectionPhase.Disconnecting)
        runCatching { stopCore() }
        runCatching { proxy.restore() }
        mutableConnection.value = PlatformConnectionState()
    }

    override fun close() {
        runCatching { stopCore() }
        runCatching { proxy.restore() }
    }

    private fun stopCore() { if (isLinux()) invokeMethod("stopXray") }

    private fun invokeMethod(method: String, xrayJson: String? = null) {
        val request = buildJsonObject {
            put("apiVersion", 2)
            put("method", method)
            put("payload", buildJsonObject { if (xrayJson != null) put("xrayJson", xrayJson) })
        }
        val raw = native.invoke(request.toString())
        val response = Json.parseToJsonElement(raw).jsonObject
        check(response["success"]?.jsonPrimitive?.booleanOrNull == true) { "Ядро не выполнило $method" }
    }

    private fun loadNative(): LibXrayNative {
        check(isLinux()) { "Нативное ядро собрано для Linux x64" }
        val cache = xdgDirectory("XDG_CACHE_HOME", ".cache").resolve("sora/libXray-v26.7.28.so")
        if (!Files.exists(cache)) {
            Files.createDirectories(cache.parent)
            val resource = checkNotNull(javaClass.getResourceAsStream("/native/linux-x64/libXray.so")) { "libXray.so не найден" }
            resource.use { Files.copy(it, cache, StandardCopyOption.REPLACE_EXISTING) }
            cache.toFile().setExecutable(true, true)
        }
        return Native.load(cache.toAbsolutePath().toString(), LibXrayNative::class.java)
    }

    private fun effectiveUserId(): Int = runCatching {
        ProcessBuilder("id", "-u").start().inputStream.bufferedReader().use { it.readText().trim().toInt() }
    }.getOrDefault(-1)

    private fun isLinux(): Boolean = System.getProperty("os.name").contains("linux", true)
}

private interface LibXrayNative : Library {
    fun CGoInvoke(requestJSON: String): Pointer?
    fun CGoFree(value: Pointer)

    fun invoke(request: String): String {
        val pointer = checkNotNull(CGoInvoke(request)) { "libXray вернул пустой ответ" }
        return try { pointer.getString(0, Charsets.UTF_8.name()) } finally { CGoFree(pointer) }
    }
}

private class LinuxSystemProxy {
    private val backupFile = xdgDirectory("XDG_STATE_HOME", ".local/state").resolve("sora/proxy.properties")
    var statusMessage: String = "Локально: SOCKS 10808, HTTP 10809"
        private set

    fun enable() {
        val desktop = System.getenv("XDG_CURRENT_DESKTOP").orEmpty().lowercase()
        when {
            desktop.contains("gnome") || desktop.contains("unity") || desktop.contains("cinnamon") -> enableGnome()
            commandExists("kwriteconfig6") || commandExists("kwriteconfig5") -> enableKde()
            else -> statusMessage = "Локально: SOCKS 10808, HTTP 10809 — системный прокси не поддержан средой"
        }
    }

    fun restoreAfterUncleanExit() {
        if (Files.exists(backupFile)) runCatching { restore() }
    }

    fun restore() {
        if (!Files.exists(backupFile)) return
        val values = Properties().also { properties -> Files.newInputStream(backupFile).use(properties::load) }
        when (values.getProperty("desktop")) {
            "gnome" -> values.stringPropertyNames().filterNot { it == "desktop" }.forEach { key ->
                val (schema, property) = key.split('|', limit = 2)
                run(schema, property, values.getProperty(key))
            }
            "kde" -> {
                val writer = if (commandExists("kwriteconfig6")) "kwriteconfig6" else "kwriteconfig5"
                writeKde(writer, "ProxyType", values.getProperty("ProxyType", "0"))
                writeKde(writer, "httpProxy", values.getProperty("httpProxy", ""))
                writeKde(writer, "httpsProxy", values.getProperty("httpsProxy", ""))
                writeKde(writer, "socksProxy", values.getProperty("socksProxy", ""))
                reloadKde()
            }
        }
        Files.deleteIfExists(backupFile)
        statusMessage = "Локально: SOCKS 10808, HTTP 10809"
    }

    private fun enableGnome() {
        val keys = listOf(
            "org.gnome.system.proxy|mode",
            "org.gnome.system.proxy.http|host", "org.gnome.system.proxy.http|port",
            "org.gnome.system.proxy.https|host", "org.gnome.system.proxy.https|port",
            "org.gnome.system.proxy.socks|host", "org.gnome.system.proxy.socks|port",
        )
        val values = Properties().apply {
            setProperty("desktop", "gnome")
            keys.forEach { key -> val (schema, property) = key.split('|', limit = 2); setProperty(key, read(schema, property)) }
        }
        save(values)
        run("org.gnome.system.proxy.http", "host", "'127.0.0.1'")
        run("org.gnome.system.proxy.http", "port", "10809")
        run("org.gnome.system.proxy.https", "host", "'127.0.0.1'")
        run("org.gnome.system.proxy.https", "port", "10809")
        run("org.gnome.system.proxy.socks", "host", "'127.0.0.1'")
        run("org.gnome.system.proxy.socks", "port", "10808")
        run("org.gnome.system.proxy", "mode", "'manual'")
        statusMessage = "Системный прокси включён"
    }

    private fun enableKde() {
        val writer = if (commandExists("kwriteconfig6")) "kwriteconfig6" else "kwriteconfig5"
        val config = Path.of(System.getProperty("user.home"), ".config", "kioslaverc")
        val values = Properties().apply {
            setProperty("desktop", "kde")
            setProperty("ProxyType", readKde(config, "ProxyType"))
            setProperty("httpProxy", readKde(config, "httpProxy"))
            setProperty("httpsProxy", readKde(config, "httpsProxy"))
            setProperty("socksProxy", readKde(config, "socksProxy"))
        }
        save(values)
        writeKde(writer, "ProxyType", "1")
        writeKde(writer, "httpProxy", "http://127.0.0.1 10809")
        writeKde(writer, "httpsProxy", "http://127.0.0.1 10809")
        writeKde(writer, "socksProxy", "socks://127.0.0.1 10808")
        reloadKde()
        statusMessage = "Системный прокси включён"
    }

    private fun save(values: Properties) {
        Files.createDirectories(backupFile.parent)
        Files.newOutputStream(backupFile, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING).use { values.store(it, "Sora proxy backup") }
    }

    private fun read(schema: String, key: String): String = process("gsettings", "get", schema, key).trim()
    private fun run(schema: String, key: String, value: String) { process("gsettings", "set", schema, key, value) }
    private fun commandExists(name: String): Boolean = runCatching { ProcessBuilder("sh", "-lc", "command -v $name").start().waitFor() == 0 }.getOrDefault(false)
    private fun readKde(config: Path, key: String): String = if (Files.exists(config)) Files.readAllLines(config).firstOrNull { it.startsWith("$key=") }?.substringAfter('=') ?: "" else ""
    private fun writeKde(writer: String, key: String, value: String) { process(writer, "--file", "kioslaverc", "--group", "Proxy Settings", "--key", key, value) }
    private fun reloadKde() { runCatching { process("qdbus6", "org.kde.KIO.Scheduler", "/KIO/Scheduler", "reparseSlaveConfiguration", "") }.recoverCatching { process("qdbus", "org.kde.KIO.Scheduler", "/KIO/Scheduler", "reparseSlaveConfiguration", "") } }

    private fun process(vararg command: String): String {
        val process = ProcessBuilder(*command).redirectErrorStream(true).start()
        val output = process.inputStream.bufferedReader().use { it.readText() }
        check(process.waitFor() == 0) { output.trim().ifBlank { "Команда ${command.first()} завершилась с ошибкой" } }
        return output
    }
}
