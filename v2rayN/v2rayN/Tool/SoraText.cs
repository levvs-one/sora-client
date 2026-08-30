using System;
using System.Globalization;
using System.Resources;
using System.Windows.Forms;

namespace v2rayN.Tool
{
    internal static class SoraText
    {
        internal const string Russian = "ru-RU";
        internal const string PreReformRussian = "ru-pre1918";
        internal const string English = "en-US";
        internal const string Chinese = "zh-Hans";

        private static readonly ResourceManager Standard = new ResourceManager("v2rayN.Resx.SoraUI", typeof(SoraText).Assembly);
        private static readonly ResourceManager PreReform = new ResourceManager("v2rayN.Resx.SoraUI_PreReform", typeof(SoraText).Assembly);

        internal static string CurrentLanguage => Normalize(Utils.RegReadValue(Global.MyRegPath, Global.MyRegKeyLanguage, Russian));

        internal static CultureInfo CurrentCulture
        {
            get
            {
                string language = CurrentLanguage;
                return new CultureInfo(language == PreReformRussian ? Russian : language);
            }
        }

        internal static string Translate(string text)
        {
            if (string.IsNullOrWhiteSpace(text) || CurrentLanguage == Russian)
            {
                return text;
            }
            ResourceManager manager = CurrentLanguage == PreReformRussian ? PreReform : Standard;
            return manager.GetString(text, CurrentCulture) ?? text;
        }

        internal static void Apply(Control root)
        {
            if (!(root is TextBoxBase) && !(root is ComboBox))
            {
                root.Text = Translate(root.Text);
            }
            if (!string.IsNullOrWhiteSpace(root.AccessibleName))
            {
                root.AccessibleName = Translate(root.AccessibleName);
            }
            foreach (Control child in root.Controls)
            {
                Apply(child);
            }
        }

        internal static void Apply(ToolStripItemCollection items)
        {
            foreach (ToolStripItem item in items)
            {
                item.Text = Translate(item.Text);
                if (item is ToolStripMenuItem menu && menu.DropDownItems.Count > 0)
                {
                    Apply(menu.DropDownItems);
                }
            }
        }

        internal static void Select(string language)
        {
            Utils.RegWriteValue(Global.MyRegPath, Global.MyRegKeyLanguage, Normalize(language));
            Application.Restart();
        }

        private static string Normalize(string language)
        {
            if (string.Equals(language, "en", StringComparison.OrdinalIgnoreCase)) return English;
            if (string.Equals(language, "ru", StringComparison.OrdinalIgnoreCase)) return Russian;
            if (string.Equals(language, "zh", StringComparison.OrdinalIgnoreCase) || string.Equals(language, "zh-CN", StringComparison.OrdinalIgnoreCase)) return Chinese;
            if (string.Equals(language, PreReformRussian, StringComparison.OrdinalIgnoreCase)) return PreReformRussian;
            if (string.Equals(language, English, StringComparison.OrdinalIgnoreCase)) return English;
            if (string.Equals(language, Chinese, StringComparison.OrdinalIgnoreCase)) return Chinese;
            return Russian;
        }
    }
}
