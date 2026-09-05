package app.sora.client

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put

class LibXrayProtocolTest {
    private val gateway = FakeGateway()
    private val protocol = LibXrayProtocol(gateway)

    @Test
    fun nodesExcludeServiceOutboundsAndUsePlanetFallback() {
        val subscription = SoraSubscription("one", "https://example.com/sub", "Test", sampleConfig, lastUpdatedEpochMillis = 1)
        val nodes = protocol.nodes(subscription)
        assertEquals(2, nodes.size)
        assertEquals("🇩🇪", nodes.first().flag)
        assertEquals("◎", nodes.last().flag)
        assertEquals("VLESS", nodes.first().protocol)
    }

    @Test
    fun runtimeConfigContainsOnlySelectedOutboundAndLocalProxy() {
        val runtime = Json.parseToJsonElement(protocol.runtimeConfig(sampleConfig, "Unknown", ConnectionMode.Proxy)).jsonObject
        val outbounds = runtime.getValue("outbounds").jsonArray
        val inbounds = runtime.getValue("inbounds").jsonArray
        assertEquals(1, outbounds.size)
        assertEquals("Unknown", outbounds.first().jsonObject.getValue("tag").jsonPrimitive.content)
        assertEquals(listOf(10808, 10809), inbounds.map { it.jsonObject.getValue("port").jsonPrimitive.content.toInt() })
        assertFalse(runtime.containsKey("env"))
    }

    @Test
    fun tunConfigCarriesFileDescriptorAndRoutesOnlyWhenRequested() {
        val runtime = Json.parseToJsonElement(protocol.runtimeConfig(sampleConfig, "Germany", ConnectionMode.Tun, 42, linuxSystemRoutes = true)).jsonObject
        assertEquals("42", runtime.getValue("env").jsonObject.getValue("xray.tun.fd").jsonPrimitive.content)
        val settings = runtime.getValue("inbounds").jsonArray.first().jsonObject.getValue("settings").jsonObject
        assertTrue(settings.containsKey("autoSystemRoutingTable"))
    }

    @Test
    fun pingUsesProtectedFileAndBatchesAtFive() = runBlocking {
        val recording = RecordingGateway()
        val result = LibXrayProtocol(recording).ping(sampleConfig, (1..6).map { "node-$it" })
        assertEquals(2, recording.requests.size)
        assertEquals(5, recording.requests.first().jsonObject.getValue("payload").jsonObject.getValue("configs").jsonArray.size)
        assertEquals("/private/sora-ping.json", recording.requests.first().jsonObject.getValue("payload").jsonObject.getValue("configs").jsonArray.first().jsonObject.getValue("configPath").jsonPrimitive.content)
        assertEquals("8", recording.requests.first().jsonObject.getValue("payload").jsonObject.getValue("timeout").jsonPrimitive.content)
        assertEquals(6, result.size)
        assertTrue(recording.deleted)
    }

    private class FakeGateway : SoraPlatformGateway {
        override val connectionState = MutableStateFlow(PlatformConnectionState())
        override val supportsTun = true
        override suspend fun invokeLibXray(requestJson: String) = "{\"success\":true,\"data\":{}}"
        override suspend fun createPingConfig(xrayJson: String) = "/tmp/sora-test.json"
        override suspend fun deletePingConfig(path: String) = Unit
        override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) = Unit
        override suspend fun disconnect() = Unit
    }

    private class RecordingGateway : SoraPlatformGateway {
        override val connectionState = MutableStateFlow(PlatformConnectionState())
        override val supportsTun = true
        val requests = mutableListOf<kotlinx.serialization.json.JsonElement>()
        var deleted = false
        override suspend fun invokeLibXray(requestJson: String): String {
            val request = Json.parseToJsonElement(requestJson)
            requests += request
            val count = request.jsonObject.getValue("payload").jsonObject.getValue("configs").jsonArray.size
            return buildJsonObject {
                put("success", true)
                put("data", buildJsonObject {
                    put("results", buildJsonArray { repeat(count) { add(buildJsonObject { put("success", true); put("delay", 50 + it) }) } })
                })
            }.toString()
        }
        override suspend fun createPingConfig(xrayJson: String) = "/private/sora-ping.json"
        override suspend fun deletePingConfig(path: String) { deleted = true }
        override suspend fun connect(xrayJson: String, outboundTag: String, mode: ConnectionMode) = Unit
        override suspend fun disconnect() = Unit
    }

    companion object {
        val sampleConfig = """{
            "outbounds": [
                {"tag":"Germany","protocol":"vless","settings":{"vnext":[{"address":"de.example.com"}]},"streamSettings":{"network":"xhttp","security":"reality"}},
                {"tag":"Unknown","protocol":"trojan","settings":{"servers":[{"address":"node.example.net"}]},"streamSettings":{"network":"tcp","security":"tls"}},
                {"tag":"direct","protocol":"freedom"}
            ]
        }""".trimIndent()
    }
}
