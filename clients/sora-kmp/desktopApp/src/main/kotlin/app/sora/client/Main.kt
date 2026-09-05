package app.sora.client

import androidx.compose.runtime.remember
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Window
import androidx.compose.ui.window.application
import io.ktor.client.HttpClient
import io.ktor.client.engine.cio.CIO
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermissions
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob

fun main() = application {
    val client = remember { HttpClient(CIO) }
    val scope = remember { CoroutineScope(SupervisorJob() + Dispatchers.Main) }
    val gateway = remember { LinuxGateway() }
    val controller = remember {
        SoraController(scope, client, XdgStateStore(), gateway, System::currentTimeMillis)
    }
    Window(
        title = "Sora",
        onCloseRequest = {
            gateway.close()
            client.close()
            exitApplication()
        },
    ) {
        window.minimumSize = java.awt.Dimension(720, 560)
        window.setSize(1080, 720)
        SoraApp(controller)
    }
}

class XdgStateStore : SoraStateStore {
    private val stateFile = xdgDirectory("XDG_CONFIG_HOME", ".config").resolve("sora/state.json")

    override suspend fun read(): String? = runCatching { Files.readString(stateFile, StandardCharsets.UTF_8) }.getOrNull()

    override suspend fun write(value: String) {
        Files.createDirectories(stateFile.parent)
        runCatching { Files.setPosixFilePermissions(stateFile.parent, PosixFilePermissions.fromString("rwx------")) }
        val temporary = stateFile.resolveSibling("state.json.tmp")
        Files.writeString(temporary, value, StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING)
        runCatching { Files.setPosixFilePermissions(temporary, PosixFilePermissions.fromString("rw-------")) }
        runCatching { Files.move(temporary, stateFile, StandardCopyOption.ATOMIC_MOVE, StandardCopyOption.REPLACE_EXISTING) }
            .getOrElse { Files.move(temporary, stateFile, StandardCopyOption.REPLACE_EXISTING) }
        runCatching { Files.setPosixFilePermissions(stateFile, PosixFilePermissions.fromString("rw-------")) }
    }
}

internal fun xdgDirectory(variable: String, fallback: String): Path {
    val configured = System.getenv(variable)?.takeIf(String::isNotBlank)
    return Path.of(configured ?: Path.of(System.getProperty("user.home"), fallback).toString())
}
