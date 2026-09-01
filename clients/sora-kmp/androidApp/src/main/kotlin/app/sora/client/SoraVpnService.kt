package app.sora.client

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import androidx.core.app.NotificationCompat
import java.util.concurrent.atomic.AtomicBoolean
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import libXray.DialerController
import libXray.LibXray

object SoraServiceBridge {
    private val mutableState = MutableStateFlow(PlatformConnectionState())
    val state = mutableState.asStateFlow()
    fun update(value: PlatformConnectionState) { mutableState.value = value }
}

class SoraVpnService : VpnService() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var tunnel: ParcelFileDescriptor? = null
    private val stopping = AtomicBoolean(false)

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_DISCONNECT) {
            scope.launch { stopConnection() }
            return START_NOT_STICKY
        }
        val preferences = getSharedPreferences("sora-service", MODE_PRIVATE)
        val source = intent?.getStringExtra(EXTRA_CONFIG) ?: preferences.getString(EXTRA_CONFIG, null)
        val outbound = intent?.getStringExtra(EXTRA_OUTBOUND) ?: preferences.getString(EXTRA_OUTBOUND, null)
        val modeName = intent?.getStringExtra(EXTRA_MODE) ?: preferences.getString(EXTRA_MODE, null)
        if (source.isNullOrBlank() || outbound.isNullOrBlank() || modeName.isNullOrBlank()) {
            stopSelf()
            return START_NOT_STICKY
        }
        val mode = runCatching { ConnectionMode.valueOf(modeName) }.getOrDefault(ConnectionMode.Tun)
        preferences.edit().putString(EXTRA_CONFIG, source).putString(EXTRA_OUTBOUND, outbound).putString(EXTRA_MODE, mode.name).apply()
        startForeground(NOTIFICATION_ID, notification("Подключаемся", mode))
        scope.launch { startConnection(source, outbound, mode) }
        return START_STICKY
    }

    override fun onRevoke() {
        scope.launch { stopConnection() }
        super.onRevoke()
    }

    override fun onDestroy() {
        scope.cancel()
        tunnel?.close()
        super.onDestroy()
    }

    private suspend fun startConnection(source: String, outbound: String, mode: ConnectionMode) {
        stopping.set(false)
        SoraServiceBridge.update(PlatformConnectionState(ConnectionPhase.Connecting, "Запускаем ядро"))
        runCatching {
            invoke("stopXray")
            val dialer = DialerController { fileDescriptor -> protect(fileDescriptor.toInt()) }
            LibXray.registerDialerController(dialer)
            val fileDescriptor = if (mode == ConnectionMode.Tun) establishTunnel().fd else null
            if (mode == ConnectionMode.Tun) runCatching { LibXray.setDNS(dialer, "1.1.1.1:53") }
            val runtime = LibXrayProtocol(ServiceLibXrayGateway()).runtimeConfig(source, outbound, mode, fileDescriptor)
            invoke("runXray", runtime)
        }.onSuccess {
            SoraServiceBridge.update(PlatformConnectionState(ConnectionPhase.Connected, if (mode == ConnectionMode.Tun) "Весь трафик защищён" else "Локально: SOCKS 10808, HTTP 10809"))
            getSystemService(NotificationManager::class.java).notify(NOTIFICATION_ID, notification("Подключено", mode))
        }.onFailure { failure ->
            tunnel?.close(); tunnel = null
            SoraServiceBridge.update(PlatformConnectionState(ConnectionPhase.Failed, failure.message?.take(160) ?: "Ошибка подключения"))
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
        }
    }

    private fun establishTunnel(): ParcelFileDescriptor {
        tunnel?.close()
        return Builder()
            .setSession("Sora")
            .setMtu(1500)
            .addAddress("172.19.0.1", 30)
            .addRoute("0.0.0.0", 0)
            .addDnsServer("1.1.1.1")
            .addDnsServer("8.8.8.8")
            .establish()
            ?.also { tunnel = it }
            ?: throw IllegalStateException("Android не создал VPN-интерфейс")
    }

    private suspend fun stopConnection() {
        if (!stopping.compareAndSet(false, true)) return
        SoraServiceBridge.update(PlatformConnectionState(ConnectionPhase.Disconnecting))
        withContext(Dispatchers.IO) { runCatching { invoke("stopXray") }; runCatching { LibXray.resetDNS() } }
        tunnel?.close(); tunnel = null
        SoraServiceBridge.update(PlatformConnectionState())
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun invoke(method: String, xrayJson: String? = null): String {
        val request = buildJsonObject {
            put("apiVersion", 2)
            put("method", method)
            put("payload", buildJsonObject { if (xrayJson != null) put("xrayJson", xrayJson) })
        }
        val response = LibXray.invoke(request.toString())
        if (!response.contains("\"success\":true")) throw IllegalStateException("Ядро не выполнило $method")
        return response
    }

    private fun notification(status: String, mode: ConnectionMode): android.app.Notification {
        val disconnect = Intent(this, SoraVpnService::class.java).setAction(ACTION_DISCONNECT)
        val pending = PendingIntent.getService(this, 1, disconnect, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle("Sora — $status")
            .setContentText(if (mode == ConnectionMode.Tun) "Режим TUN" else "Локальный прокси")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .addAction(0, "Отключить", pending)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(CHANNEL_ID, "Подключение Sora", NotificationManager.IMPORTANCE_LOW)
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }

    private class ServiceLibXrayGateway : SoraPlatformGateway {
        override val connectionState = MutableStateFlow(PlatformConnectionState())
        override val supportsTun = true
        override suspend fun invokeLibXray(requestJson: String): String = LibXray.invoke(requestJson)
        override suspend fun createPingConfig(xrayJson: String): String = error("Служба не измеряет задержку")
        override suspend fun deletePingConfig(path: String) = Unit
        override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) = Unit
        override suspend fun disconnect() = Unit
    }

    companion object {
        const val ACTION_CONNECT = "app.sora.client.CONNECT"
        const val ACTION_DISCONNECT = "app.sora.client.DISCONNECT"
        const val EXTRA_CONFIG = "xray_config"
        const val EXTRA_OUTBOUND = "outbound_tag"
        const val EXTRA_MODE = "connection_mode"
        private const val CHANNEL_ID = "sora_connection"
        private const val NOTIFICATION_ID = 3107
    }
}
