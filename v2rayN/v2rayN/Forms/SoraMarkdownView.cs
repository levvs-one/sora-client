using System;
using System.Diagnostics;
using System.Drawing;
using System.Globalization;
using System.Text;
using System.Windows.Forms;
using Markdig;
using Markdig.Extensions.EmphasisExtras;
using Markdig.Syntax;
using Markdig.Syntax.Inlines;
using v2rayN.Tool;

namespace v2rayN.Forms
{
    internal sealed class SoraMarkdownView : RichTextBox
    {
        private const int MaximumMarkdownLength = 32768;
        private static readonly MarkdownPipeline Pipeline = new MarkdownPipelineBuilder()
            .UseEmphasisExtras(EmphasisExtraOptions.Strikethrough)
            .DisableHtml()
            .Build();

        private string _markdownText = string.Empty;
        private bool _compact;

        internal SoraMarkdownView()
        {
            BorderStyle = BorderStyle.None;
            BackColor = Color.FromArgb(35, 35, 38);
            ForeColor = Color.FromArgb(243, 243, 244);
            Font = new Font("Segoe UI", 9F);
            ReadOnly = true;
            DetectUrls = false;
            ScrollBars = RichTextBoxScrollBars.None;
            ShortcutsEnabled = true;
            TabStop = true;
            LinkClicked += OpenSafeLink;
        }

        internal bool Compact
        {
            get => _compact;
            set
            {
                if (_compact == value) return;
                _compact = value;
                RenderMarkdown();
            }
        }

        internal string MarkdownText
        {
            get => _markdownText;
            set
            {
                string next = value ?? string.Empty;
                if (string.Equals(_markdownText, next, StringComparison.Ordinal)) return;
                _markdownText = next;
                RenderMarkdown();
            }
        }

        internal static string RenderToRtf(string markdown, bool compact)
        {
            string source = markdown ?? string.Empty;
            if (source.Length > MaximumMarkdownLength)
            {
                source = source.Substring(0, MaximumMarkdownLength) + "\n\n…";
            }

            MarkdownDocument document = Markdown.Parse(source, Pipeline);
            var output = new StringBuilder(Math.Max(256, source.Length * 2));
            output.Append(@"{\rtf1\ansi\deff0{\fonttbl{\f0 Segoe UI;}{\f1 Consolas;}}")
                .Append(@"{\colortbl;\red243\green243\blue244;\red185\green185\blue192;\red49\green49\blue53;\red224\green224\blue228;}")
                .Append(@"\viewkind4\uc1 ");
            foreach (Block block in document)
            {
                RenderBlock(output, block, compact, 0);
                if (compact && output.Length > 6000) break;
            }
            output.Append('}');
            return output.ToString();
        }

        private void RenderMarkdown()
        {
            try
            {
                Rtf = RenderToRtf(_markdownText, _compact);
                Select(0, 0);
            }
            catch (Exception exception)
            {
                Text = _markdownText;
                Utils.SaveLog("Не удалось отобразить Markdown-описание подписки.", exception);
            }
        }

        private static void RenderBlock(StringBuilder output, Block block, bool compact, int depth)
        {
            if (block is HeadingBlock heading)
            {
                output.Append(compact ? @"\pard\sa20\f0\fs18\cf1\b " : @"\pard\sa100\f0\fs24\cf1\b ");
                RenderInlines(output, heading.Inline);
                output.Append(@"\b0\par ");
            }
            else if (block is ParagraphBlock paragraph)
            {
                output.Append(compact ? @"\pard\sa24\sl220\slmult1\f0\fs18\cf1 " : @"\pard\sa80\sl240\slmult1\f0\fs18\cf1 ");
                RenderInlines(output, paragraph.Inline);
                output.Append(@"\par ");
            }
            else if (block is ListBlock list)
            {
                RenderList(output, list, compact, depth);
            }
            else if (block is QuoteBlock quote)
            {
                foreach (Block child in quote)
                {
                    output.Append(@"\pard\li260\sa60\f0\fs18\cf2\i ");
                    AppendText(output, "│ ");
                    if (child is LeafBlock leaf) RenderInlines(output, leaf.Inline);
                    else RenderBlock(output, child, compact, depth + 1);
                    output.Append(@"\i0\par ");
                }
            }
            else if (block is CodeBlock code)
            {
                output.Append(@"\pard\li120\ri120\sa80\f1\fs16\cf1\highlight3 ");
                if (code.CodeBlockLines != null)
                {
                    for (int index = 0; index < code.CodeBlockLines.Count; index++)
                    {
                        if (index > 0) output.Append(@"\line ");
                        AppendText(output, code.CodeBlockLines[index].ToString());
                    }
                }
                output.Append(@"\highlight0\f0\par ");
            }
            else if (block is ThematicBreakBlock)
            {
                output.Append(@"\pard\sa80\cf2 ");
                AppendText(output, "────────────────");
                output.Append(@"\par ");
            }
            else if (block is ContainerBlock container)
            {
                foreach (Block child in container) RenderBlock(output, child, compact, depth);
            }
            else if (block is LeafBlock leaf)
            {
                output.Append(@"\pard\sa60\f0\fs18\cf1 ");
                RenderInlines(output, leaf.Inline);
                output.Append(@"\par ");
            }
        }

        private static void RenderList(StringBuilder output, ListBlock list, bool compact, int depth)
        {
            int number = 1;
            int.TryParse(list.OrderedStart, NumberStyles.Integer, CultureInfo.InvariantCulture, out number);
            if (number < 1) number = 1;
            foreach (Block block in list)
            {
                if (!(block is ListItemBlock item)) continue;
                int indent = 300 + depth * 220;
                output.Append("\\pard\\li").Append(indent).Append(@"\fi-180\sa40\f0\fs18\cf1 ");
                AppendText(output, list.IsOrdered ? number++ + ". " : "• ");
                bool first = true;
                foreach (Block child in item)
                {
                    if (child is ListBlock nested)
                    {
                        output.Append(@"\par ");
                        RenderList(output, nested, compact, depth + 1);
                        continue;
                    }
                    if (!first) output.Append(@"\line ");
                    if (child is LeafBlock leaf) RenderInlines(output, leaf.Inline);
                    else RenderBlock(output, child, compact, depth + 1);
                    first = false;
                }
                output.Append(@"\par ");
            }
        }

        private static void RenderInlines(StringBuilder output, ContainerInline container)
        {
            if (container == null) return;
            for (Inline inline = container.FirstChild; inline != null; inline = inline.NextSibling)
            {
                if (inline is LiteralInline literal)
                {
                    AppendText(output, literal.Content.ToString());
                }
                else if (inline is LineBreakInline)
                {
                    output.Append(@"\line ");
                }
                else if (inline is CodeInline code)
                {
                    output.Append(@"{\f1\fs16\highlight3 ");
                    AppendText(output, code.Content);
                    output.Append(@"\highlight0}");
                }
                else if (inline is EmphasisInline emphasis)
                {
                    bool strike = emphasis.DelimiterChar == '~' && emphasis.DelimiterCount >= 2;
                    output.Append(strike ? @"{\strike " : emphasis.DelimiterCount >= 2 ? @"{\b " : @"{\i ");
                    RenderInlines(output, emphasis);
                    output.Append('}');
                }
                else if (inline is LinkInline link)
                {
                    RenderLink(output, link);
                }
                else if (inline is ContainerInline nested)
                {
                    RenderInlines(output, nested);
                }
            }
        }

        private static void RenderLink(StringBuilder output, LinkInline link)
        {
            if (link.IsImage)
            {
                output.Append(@"{\cf2 ");
                RenderInlines(output, link);
                output.Append('}');
                return;
            }

            if (!TryGetSafeUrl(link.Url, out Uri target))
            {
                RenderInlines(output, link);
                return;
            }

            output.Append(@"{\field{\*\fldinst{HYPERLINK """);
            AppendInstruction(output, target.AbsoluteUri);
            output.Append(@"""}}{\fldrslt{\ul\cf4 ");
            if (link.FirstChild == null) AppendText(output, target.AbsoluteUri);
            else RenderInlines(output, link);
            output.Append("}}}");
        }

        private static void AppendText(StringBuilder output, string value)
        {
            foreach (char character in value ?? string.Empty)
            {
                if (character == '\\' || character == '{' || character == '}') output.Append('\\').Append(character);
                else if (character == '\r') continue;
                else if (character == '\n') output.Append(@"\line ");
                else if (character <= 127) output.Append(character);
                else output.Append("\\u").Append(unchecked((short)character).ToString(CultureInfo.InvariantCulture)).Append('?');
            }
        }

        private static void AppendInstruction(StringBuilder output, string value)
        {
            foreach (char character in value)
            {
                if (character == '\\' || character == '{' || character == '}' || character == '"') output.Append('\\');
                output.Append(character);
            }
        }

        private static bool TryGetSafeUrl(string value, out Uri target)
        {
            return Uri.TryCreate(value, UriKind.Absolute, out target)
                && (target.Scheme == Uri.UriSchemeHttp || target.Scheme == Uri.UriSchemeHttps);
        }

        private static void OpenSafeLink(object sender, LinkClickedEventArgs args)
        {
            if (!TryGetSafeUrl(args.LinkText, out Uri target)) return;
            try
            {
                Process.Start(new ProcessStartInfo(target.AbsoluteUri) { UseShellExecute = true });
            }
            catch (Exception exception)
            {
                Utils.SaveLog("Не удалось открыть ссылку из описания подписки.", exception);
            }
        }
    }
}
