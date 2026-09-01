import java.net.URI
import java.security.MessageDigest
import java.util.zip.ZipFile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeCompiler)
}

val libXrayArchive = layout.buildDirectory.file("downloads/libxray-android-v26.7.28.zip")
val libXrayAar = layout.buildDirectory.file("generated/libxray/libXray.aar")
val prepareLibXray = tasks.register("prepareLibXray") {
    notCompatibleWithConfigurationCache("Сетевая загрузка и распаковка закреплённого release asset")
    inputs.property("url", "https://github.com/XTLS/libXray/releases/download/v26.7.28/libxray-android.zip")
    outputs.file(libXrayAar)
    doLast {
        val archive = libXrayArchive.get().asFile
        archive.parentFile.mkdirs()
        if (!archive.exists()) URI(inputs.properties["url"].toString()).toURL().openStream().use { input -> archive.outputStream().use(input::copyTo) }
        val digest = MessageDigest.getInstance("SHA-256").digest(archive.readBytes()).joinToString("") { "%02X".format(it) }
        check(digest == "28B7DC9D6CC8455FCCA5CBD56E387003A7BFB558128651A64899DC3A8CCFF666") { "Неверная контрольная сумма libXray Android" }
        val target = libXrayAar.get().asFile
        target.parentFile.mkdirs()
        ZipFile(archive).use { zip ->
            val entry = zip.entries().asSequence().first { it.name.endsWith("/libXray.aar") }
            zip.getInputStream(entry).use { input -> target.outputStream().use(input::copyTo) }
        }
    }
}

dependencies {
    implementation(projects.shared)
    implementation(libs.androidx.activity.compose)
    implementation(libs.compose.uiToolingPreview)
    implementation(libs.compose.foundation)
    implementation(libs.ktor.client.okhttp)
    implementation(files(libXrayAar).builtBy(prepareLibXray))
    debugImplementation(libs.compose.uiTooling)
}

android {
    namespace = "app.sora.client"
    compileSdk = libs.versions.android.compileSdk.get().toInt()
    defaultConfig {
        applicationId = "app.sora.client"
        minSdk = libs.versions.android.minSdk.get().toInt()
        targetSdk = libs.versions.android.targetSdk.get().toInt()
        versionCode = 3
        versionName = "0.3.0-dev"
    }
    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    packaging.resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
}

kotlin.compilerOptions.jvmTarget = JvmTarget.JVM_11
