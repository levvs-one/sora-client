package app.sora.client

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.VpnService
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.core.content.ContextCompat
import androidx.lifecycle.lifecycleScope
import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import java.util.concurrent.TimeUnit
import java.io.File
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import libXray.LibXray

class MainActivity : ComponentActivity() {
    private var permissionContinuation: kotlin.coroutines.Continuation<Boolean>? = null
    private lateinit var client: HttpClient

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        client = HttpClient(OkHttp) {
            engine {
                config {
                    connectTimeout(15, TimeUnit.SECONDS)
                    readTimeout(30, TimeUnit.SECONDS)
                    followRedirects(true)
                }
            }
        }
        val gateway = AndroidGateway(this)
        val controller = SoraController(
            scope = lifecycleScope,
            client = client,
            store = AndroidStateStore(this),
            gateway = gateway,
            now = System::currentTimeMillis,
        )
        setContent { SoraApp(controller) }
    }

    override fun onDestroy() {
        client.close()
        super.onDestroy()
    }

    @Suppress("DEPRECATION")
    suspend fun requestVpnPermission(): Boolean {
        val intent = VpnService.prepare(this) ?: return true
        return suspendCancellableCoroutine { continuation ->
            permissionContinuation = continuation
            continuation.invokeOnCancellation { permissionContinuation = null }
            startActivityForResult(intent, VPN_PERMISSION_REQUEST)
        }
    }

    @Deprecated("Android callback retained for API 24 compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == VPN_PERMISSION_REQUEST) {
            permissionContinuation?.resume(resultCode == Activity.RESULT_OK)
            permissionContinuation = null
        }
    }

    private companion object { const val VPN_PERMISSION_REQUEST = 3107 }
}

private class AndroidStateStore(context: Context) : SoraStateStore {
    private val preferences = context.getSharedPreferences("sora-state", Context.MODE_PRIVATE)
    override suspend fun read(): String? = preferences.getString("state", null)
    override suspend fun write(value: String) { preferences.edit().putString("state", value).commit() }
}

private class AndroidGateway(private val activity: MainActivity) : SoraPlatformGateway {
    override val connectionState: StateFlow<PlatformConnectionState> = SoraServiceBridge.state
    override val supportsTun: Boolean = true

    override suspend fun invokeLibXray(requestJson: String): String = withContext(Dispatchers.IO) { LibXray.invoke(requestJson) }

    override suspend fun createPingConfig(xrayJson: String): String = withContext(Dispatchers.IO) {
        File.createTempFile("sora-ping-", ".json", activity.cacheDir).apply { writeText(xrayJson); setReadable(false, false); setReadable(true, true) }.absolutePath
    }

    override suspend fun deletePingConfig(path: String) { withContext(Dispatchers.IO) { File(path).delete() } }

    override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) {
        if (mode == ConnectionMode.Tun && !activity.requestVpnPermission()) throw IllegalStateException("Разрешение VPN не выдано")
        val intent = Intent(activity, SoraVpnService::class.java).apply {
            action = SoraVpnService.ACTION_CONNECT
            putExtra(SoraVpnService.EXTRA_CONFIG, xrayJson)
            putExtra(SoraVpnService.EXTRA_OUTBOUND, outboundTag)
            putExtra(SoraVpnService.EXTRA_MODE, mode.name)
        }
        ContextCompat.startForegroundService(activity, intent)
    }

    override suspend fun disconnect() {
        val intent = Intent(activity, SoraVpnService::class.java).setAction(SoraVpnService.ACTION_DISCONNECT)
        activity.startService(intent)
    }
}
