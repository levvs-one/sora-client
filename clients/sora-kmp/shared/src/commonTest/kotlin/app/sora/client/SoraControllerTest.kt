package app.sora.client

import io.ktor.client.HttpClient
import io.ktor.client.engine.mock.MockEngine
import io.ktor.client.engine.mock.respond
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpStatusCode
import io.ktor.http.headersOf
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertIs
import kotlin.test.assertTrue
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive

class SoraControllerTest {
    @Test
    fun importsProfileMetadataAndStopsDuplicateBeforeNetwork() = runBlocking {
        var requests = 0
        val engine = MockEngine {
            requests++
            respond(
                content = "vless://redacted",
                status = HttpStatusCode.OK,
                headers = headersOf(
                    HttpHeaders.ContentType to listOf("text/plain"),
                    "profile-title" to listOf("base64:U29yYSBUZXN0"),
                    "subscription-userinfo" to listOf("upload=1024; download=2048; total=4096; expire=2000000000"),
                    "profile-update-interval" to listOf("1"),
                    "announce" to listOf("base64:IyDQn9GA0LjQstC10YIgU29yYQ=="),
                ),
            )
        }
        val store = MemoryStore()
        val gateway = FakeGateway()
        val background = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val controller = SoraController(background, HttpClient(engine), store, gateway, { 1_000L })
        controller.start(); yield()

        assertIs<ImportResult.Added>(controller.importSubscription("https://example.com/sub"))
        val duplicate = controller.importSubscription("https://EXAMPLE.com/sub/")

        assertIs<ImportResult.Duplicate>(duplicate)
        assertEquals(1, requests)
        assertEquals("Sora Test", controller.state.value.subscriptions.single().title)
        assertEquals(60, controller.state.value.subscriptions.single().updateIntervalMinutes)
        assertEquals("# Привет Sora", controller.state.value.subscriptions.single().description)
        assertEquals(3_072, controller.state.value.subscriptions.single().usage.uploadBytes!! + controller.state.value.subscriptions.single().usage.downloadBytes!!)
        assertTrue(store.value!!.contains("Sora Test"))
        background.cancel()
    }

    @Test
    fun refusesInsecureSubscriptionWithoutNetwork() = runBlocking {
        val background = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val controller = SoraController(background, HttpClient(MockEngine { error("network must not be used") }), MemoryStore(), FakeGateway(), { 1L })
        controller.start(); yield()
        assertFailsWith<IllegalArgumentException> { controller.importSubscription("http://example.com/sub") }
        background.cancel()
        Unit
    }

    @Test
    fun modeCannotChangeDuringConnection() = runBlocking {
        val gateway = FakeGateway().apply { connectionState.value = PlatformConnectionState(ConnectionPhase.Connected) }
        val background = CoroutineScope(SupervisorJob() + Dispatchers.Default)
        val controller = SoraController(background, HttpClient(MockEngine { error("unused") }), MemoryStore(), gateway, { 1L })
        controller.start(); yield()
        assertFailsWith<IllegalStateException> { controller.setMode(ConnectionMode.Tun) }
        background.cancel()
        Unit
    }

    private class MemoryStore : SoraStateStore {
        var value: String? = null
        override suspend fun read() = value
        override suspend fun write(value: String) { this.value = value }
    }

    private class FakeGateway : SoraPlatformGateway {
        override val connectionState = MutableStateFlow(PlatformConnectionState())
        override val supportsTun = true
        override suspend fun invokeLibXray(requestJson: String): String {
            val method = Json.parseToJsonElement(requestJson).jsonObject.getValue("method").jsonPrimitive.content
            return when (method) {
                "convertShareLinksToXrayJson" -> "{\"success\":true,\"data\":${LibXrayProtocolTest.sampleConfig}}"
                else -> "{\"success\":true,\"data\":{}}"
            }
        }
        override suspend fun createPingConfig(xrayJson: String) = "/tmp/sora-test.json"
        override suspend fun deletePingConfig(path: String) = Unit
        override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) = Unit
        override suspend fun disconnect() = Unit
    }
}
