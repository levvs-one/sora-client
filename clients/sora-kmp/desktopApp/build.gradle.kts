import java.net.URI
import java.security.MessageDigest
import java.util.zip.ZipFile
import org.jetbrains.compose.desktop.application.dsl.TargetFormat

plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
}

val nativeArchive = layout.buildDirectory.file("downloads/libxray-linux-x64-v26.7.28.zip")
val nativeLibrary = layout.buildDirectory.file("generated/resources/native/linux-x64/libXray.so")
val prepareLibXray = tasks.register("prepareLibXray") {
    notCompatibleWithConfigurationCache("Сетевая загрузка и распаковка закреплённого release asset")
    inputs.property("url", "https://github.com/XTLS/libXray/releases/download/v26.7.28/libxray-linux-x64.zip")
    outputs.file(nativeLibrary)
    doLast {
        val archive = nativeArchive.get().asFile
        archive.parentFile.mkdirs()
        if (!archive.exists()) URI(inputs.properties["url"].toString()).toURL().openStream().use { input -> archive.outputStream().use(input::copyTo) }
        val digest = MessageDigest.getInstance("SHA-256").digest(archive.readBytes()).joinToString("") { "%02X".format(it) }
        check(digest == "26D27073DEE7FC5E88FA7390B4F7EC9E863C310DB4359D87E744AF496595141F") { "Неверная контрольная сумма libXray Linux" }
        val target = nativeLibrary.get().asFile
        target.parentFile.mkdirs()
        ZipFile(archive).use { zip ->
            val entry = zip.entries().asSequence().first { it.name.endsWith("/libXray.so") }
            zip.getInputStream(entry).use { input -> target.outputStream().use(input::copyTo) }
        }
    }
}

sourceSets.main { resources.srcDir(layout.buildDirectory.dir("generated/resources")) }
tasks.processResources { dependsOn(prepareLibXray) }

dependencies {
    implementation(projects.shared)
    implementation(compose.desktop.currentOs)
    implementation(libs.compose.uiToolingPreview)
    implementation(libs.kotlinx.coroutines.swing)
    implementation(libs.ktor.client.cio)
    implementation(libs.jna)
    implementation(libs.kotlinx.serialization.json)
}

compose.desktop {
    application {
        mainClass = "app.sora.client.MainKt"
        nativeDistributions {
            targetFormats(TargetFormat.Deb)
            packageName = "sora-client"
            packageVersion = "0.3.0"
            description = "Sora subscription client for Linux"
            vendor = "Sora community"
            linux {
                shortcut = true
                menuGroup = "Network"
            }
        }
    }
}
