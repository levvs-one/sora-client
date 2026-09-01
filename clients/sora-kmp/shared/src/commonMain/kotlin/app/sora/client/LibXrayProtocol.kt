package app.sora.client

import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

class LibXrayProtocol(
    private val gateway: SoraPlatformGateway,
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun normalize(source: String): String {
        val response = invoke(
            "convertShareLinksToXrayJson",
            buildJsonObject { put("text", source) },
        )
        return response.toString()
    }

    suspend fun validate(xrayJson: String) {
        invoke("testXray", buildJsonObject { put("xrayJson", xrayJson) })
    }

    suspend fun ping(xrayJson: String, tags: List<String>, timeoutSeconds: Int = 8): Map<String, Long> {
        if (tags.isEmpty()) return emptyMap()
        val path = gateway.createPingConfig(xrayJson)
        return try {
            tags.chunked(5).flatMap { batch ->
                val payload = buildJsonObject {
                    put("configs", buildJsonArray {
                        batch.forEach { tag ->
                            add(buildJsonObject {
                                put("configPath", path)
                                put("outboundTag", tag)
                            })
                        }
                    })
                    put("timeout", timeoutSeconds)
                    put("url", "https://cp.cloudflare.com/")
                }
                val data = invoke("pingBatch", payload).jsonObject
                val results = data["results"]?.jsonArray ?: JsonArray(emptyList())
                batch.mapIndexedNotNull { index, tag ->
                    val result = results.getOrNull(index)?.jsonObject ?: return@mapIndexedNotNull null
                    if (result["success"]?.jsonPrimitive?.booleanOrNull != true) return@mapIndexedNotNull null
                    val delay = result["delay"]?.jsonPrimitive?.longOrNull ?: return@mapIndexedNotNull null
                    tag to delay
                }
            }.toMap()
        } finally {
            gateway.deletePingConfig(path)
        }
    }

    fun nodes(subscription: SoraSubscription): List<SoraNode> {
        val root = runCatching { json.parseToJsonElement(subscription.xrayJson).jsonObject }.getOrNull() ?: return emptyList()
        val outbounds = root["outbounds"]?.jsonArray ?: return emptyList()
        return outbounds.mapIndexedNotNull { index, element ->
            val outbound = element as? JsonObject ?: return@mapIndexedNotNull null
            val protocol = outbound.string("protocol").lowercase()
            if (protocol in setOf("freedom", "blackhole", "dns", "loopback")) return@mapIndexedNotNull null
            val tag = outbound.string("tag").ifBlank { "sora-$index" }
            val address = findString(outbound["settings"], "address")
                .ifBlank { findString(outbound["settings"], "server") }
            val declaredName = outbound.string("sendThrough")
            val name = when {
                declaredName.isNotBlank() && !looksLikeAddress(declaredName) -> declaredName
                tag.isNotBlank() && !tag.startsWith("sora-") -> tag
                address.isNotBlank() -> address
                else -> "Сервер ${index + 1}"
            }
            SoraNode(
                key = "${subscription.id}:$tag",
                subscriptionId = subscription.id,
                outboundTag = tag,
                name = name,
                protocol = protocol.uppercase(),
                detail = buildNodeDetail(outbound, address),
                flag = countryFlag(name),
            )
        }
    }

    fun runtimeConfig(
        sourceJson: String,
        outboundTag: String,
        mode: ConnectionMode,
        tunFileDescriptor: Int? = null,
        linuxSystemRoutes: Boolean = false,
    ): String {
        val source = json.parseToJsonElement(sourceJson).jsonObject
        val outbounds = source["outbounds"]?.jsonArray?.mapNotNull { it as? JsonObject }.orEmpty()
        val selected = outbounds.firstOrNull { it.string("tag") == outboundTag }
            ?: outbounds.firstOrNull { it.string("protocol").lowercase() !in setOf("freedom", "blackhole", "dns", "loopback") }
            ?: error("В конфигурации нет поддерживаемого сервера")
        val root = buildJsonObject {
            put("log", buildJsonObject { put("loglevel", "warning") })
            if (tunFileDescriptor != null) {
                put("env", buildJsonObject { put("xray.tun.fd", tunFileDescriptor.toString()) })
            }
            put("inbounds", if (mode == ConnectionMode.Tun) tunInbounds(linuxSystemRoutes) else proxyInbounds())
            put("outbounds", buildJsonArray { add(selected) })
        }
        return root.toString()
    }

    fun profileTitle(header: String?, fallbackHost: String): String {
        val raw = header?.trim().orEmpty()
        if (raw.isBlank()) return fallbackHost
        val decoded = decodeBase64Header(raw)
        return decoded.trim().take(80).ifBlank { fallbackHost }
    }

    private suspend fun invoke(method: String, payload: JsonObject): JsonElement {
        val request = buildJsonObject {
            put("apiVersion", 2)
            put("method", method)
            put("payload", payload)
        }
        val raw = gateway.invokeLibXray(request.toString())
        val envelope = json.parseToJsonElement(raw).jsonObject
        val success = envelope["success"]?.jsonPrimitive?.booleanOrNull == true
        if (!success) {
            throw IllegalStateException(envelope["error"]?.jsonPrimitive?.contentOrNull ?: "libXray вернул ошибку")
        }
        return envelope["data"] ?: JsonNull
    }

    private fun proxyInbounds() = buildJsonArray {
        add(buildJsonObject {
            put("listen", "127.0.0.1")
            put("port", 10808)
            put("protocol", "socks")
            put("settings", buildJsonObject { put("udp", true) })
        })
        add(buildJsonObject {
            put("listen", "127.0.0.1")
            put("port", 10809)
            put("protocol", "http")
        })
    }

    private fun tunInbounds(linuxSystemRoutes: Boolean) = buildJsonArray {
        add(buildJsonObject {
            put("port", 0)
            put("protocol", "tun")
            put("settings", buildJsonObject {
                put("name", "sora0")
                put("mtu", 1500)
                put("gateway", buildJsonArray { add(JsonPrimitive("172.19.0.1/30")) })
                put("dns", buildJsonArray { add(JsonPrimitive("1.1.1.1")); add(JsonPrimitive("8.8.8.8")) })
                if (linuxSystemRoutes) {
                    put("autoSystemRoutingTable", buildJsonArray {
                        add(JsonPrimitive("0.0.0.0/1"))
                        add(JsonPrimitive("128.0.0.0/1"))
                    })
                }
            })
        })
    }

    private fun buildNodeDetail(outbound: JsonObject, address: String): String {
        val stream = outbound["streamSettings"] as? JsonObject
        val network = stream?.string("network").orEmpty().uppercase()
        val security = stream?.string("security").orEmpty().uppercase()
        return listOf(address, network, security).filter { it.isNotBlank() }.joinToString("  /  ")
    }

    private fun findString(element: JsonElement?, key: String): String {
        return when (element) {
            is JsonObject -> (element[key] as? JsonPrimitive)?.contentOrNull
                ?: element.values.firstNotNullOfOrNull { child -> findString(child, key).ifBlank { null } }.orEmpty()
            is JsonArray -> element.firstNotNullOfOrNull { child -> findString(child, key).ifBlank { null } }.orEmpty()
            else -> ""
        }
    }

    private fun JsonObject.string(key: String): String = (this[key] as? JsonPrimitive)?.contentOrNull.orEmpty()

    private fun looksLikeAddress(value: String): Boolean = value.contains('.') || value.contains(':')

    @OptIn(ExperimentalEncodingApi::class)
    private fun decodeBase64Header(value: String): String {
        val encoded = if (value.startsWith("base64:", ignoreCase = true)) value.substringAfter(':') else return value
        return runCatching { Base64.decode(encoded).decodeToString() }.getOrDefault(value)
    }

    private fun countryFlag(name: String): String {
        val normalized = name.lowercase()
        val countries = listOf(
            listOf("россия", "russia", "москва") to "🇷🇺",
            listOf("франция", "france", "paris") to "🇫🇷",
            listOf("германия", "germany", "frankfurt") to "🇩🇪",
            listOf("нидерланды", "netherlands", "amsterdam") to "🇳🇱",
            listOf("польша", "poland", "warsaw") to "🇵🇱",
            listOf("финляндия", "finland", "helsinki") to "🇫🇮",
            listOf("швеция", "sweden", "stockholm") to "🇸🇪",
            listOf("сша", "usa", "united states", "new york") to "🇺🇸",
            listOf("великобритания", "united kingdom", "london") to "🇬🇧",
            listOf("япония", "japan", "tokyo") to "🇯🇵",
            listOf("сингапур", "singapore") to "🇸🇬",
        )
        return countries.firstOrNull { (aliases, _) -> aliases.any(normalized::contains) }?.second ?: "◎"
    }
}
