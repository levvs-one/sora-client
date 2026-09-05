package app.sora.client

import androidx.compose.runtime.Composable
import androidx.compose.runtime.ProvidedValue
import androidx.compose.runtime.staticCompositionLocalOf
import java.util.Locale

actual object LocalAppLocale {
    private val localLocale = staticCompositionLocalOf { Locale.getDefault().toLanguageTag() }

    actual val current: String
        @Composable get() = localLocale.current

    @Composable
    actual infix fun provides(value: String): ProvidedValue<*> {
        val locale = Locale.forLanguageTag(value)
        Locale.setDefault(locale)
        return localLocale.provides(locale.toLanguageTag())
    }
}
