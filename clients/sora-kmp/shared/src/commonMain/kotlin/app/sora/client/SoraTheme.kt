package app.sora.client

import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import app.sora.client.resources.Res
import app.sora.client.resources.inter_variable
import org.jetbrains.compose.resources.Font

data class SoraColors(
    val canvas: Color = Color(0xFF0B0B0C),
    val navigation: Color = Color(0xFF0F0F10),
    val surface: Color = Color(0xFF18181A),
    val surfaceRaised: Color = Color(0xFF242427),
    val line: Color = Color(0xFF3C3C41),
    val text: Color = Color(0xFFF7F7F8),
    val textSecondary: Color = Color(0xFFC8C8CE),
    val textMuted: Color = Color(0xFF9A9AA2),
    val inverse: Color = Color(0xFF101012),
    val danger: Color = Color(0xFFFFB4B4),
)

data class SoraTypography(
    val title: TextStyle,
    val heading: TextStyle,
    val body: TextStyle,
    val label: TextStyle,
    val caption: TextStyle,
)

val LocalSoraColors = staticCompositionLocalOf { SoraColors() }
val LocalSoraTypography = staticCompositionLocalOf<SoraTypography> { error("SoraTheme не установлен") }

@Composable
fun SoraTheme(content: @Composable () -> Unit) {
    val inter = FontFamily(Font(Res.font.inter_variable))
    val typography = SoraTypography(
        title = TextStyle(fontFamily = inter, fontWeight = FontWeight.SemiBold, fontSize = 22.sp, lineHeight = 28.sp),
        heading = TextStyle(fontFamily = inter, fontWeight = FontWeight.SemiBold, fontSize = 16.sp, lineHeight = 22.sp),
        body = TextStyle(fontFamily = inter, fontWeight = FontWeight.Normal, fontSize = 14.sp, lineHeight = 20.sp),
        label = TextStyle(fontFamily = inter, fontWeight = FontWeight.SemiBold, fontSize = 12.sp, lineHeight = 16.sp),
        caption = TextStyle(fontFamily = inter, fontWeight = FontWeight.Normal, fontSize = 12.sp, lineHeight = 16.sp),
    )
    CompositionLocalProvider(LocalSoraColors provides SoraColors(), LocalSoraTypography provides typography, content = content)
}
