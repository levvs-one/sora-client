using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;
using v2rayN.Forms;

namespace v2rayN
{
    internal static class UI
    {
        public static void Show(string message)
        {
            SoraMessageBox.Show(message, MessageBoxButtons.OK, "Готово", "check");
        }

        public static void ShowWarning(string message)
        {
            SoraMessageBox.Show(message, MessageBoxButtons.OK, "Обратите внимание", "warning");
        }

        public static void ShowError(string message)
        {
            SoraMessageBox.Show(message, MessageBoxButtons.OK, "Не удалось выполнить действие", "warning");
        }

        public static DialogResult ShowYesNo(string message)
        {
            return SoraMessageBox.Show(message, MessageBoxButtons.YesNo, "Подтвердите действие", "warning");
        }
    }

    internal static class SoraMessageBox
    {
        internal static DialogResult Show(string message, MessageBoxButtons buttons, string title, string icon)
        {
            message = NormalizeSoraMessage(message);
            Form owner = Form.ActiveForm;
            if (owner == null && Application.OpenForms.Count > 0)
            {
                owner = Application.OpenForms[Application.OpenForms.Count - 1];
            }
            if (owner != null && owner.InvokeRequired)
            {
                return (DialogResult)owner.Invoke(new Func<DialogResult>(() => Show(message, buttons, title, icon)));
            }

            using (var dialog = BuildDialog(message ?? string.Empty, buttons, title, icon))
            {
                return owner == null ? dialog.ShowDialog() : dialog.ShowDialog(owner);
            }
        }

        private static string NormalizeSoraMessage(string message)
        {
            if (string.IsNullOrWhiteSpace(message))
            {
                return string.Empty;
            }
            if (message.IndexOf("加载GUI配置文件异常", StringComparison.Ordinal) >= 0)
            {
                return "Не удалось загрузить настройки Sora. Перезапустите приложение; если ошибка повторится, восстановите последнюю резервную копию.";
            }
            return message.Replace("v2rayN", "Sora");
        }

        private static Form BuildDialog(string message, MessageBoxButtons buttons, string titleText, string icon)
        {
            const int minimumWidth = 460;
            const int maximumWidth = 720;
            using (var measureFont = new Font("Segoe UI", 9.5F))
            {
                Size measured = TextRenderer.MeasureText(message, measureFont, new Size(maximumWidth - 80, 0), TextFormatFlags.WordBreak | TextFormatFlags.NoPadding);
                int width = Math.Max(minimumWidth, Math.Min(maximumWidth, measured.Width + 80));
                int textHeight = Math.Max(44, measured.Height + 8);
                int height = Math.Max(190, Math.Min(360, textHeight + 142));
                var dialog = new Form
                {
                    FormBorderStyle = FormBorderStyle.None,
                    StartPosition = FormStartPosition.CenterParent,
                    ClientSize = new Size(width, height),
                    BackColor = Color.FromArgb(37, 37, 39),
                    ForeColor = Color.FromArgb(247, 247, 248),
                    ShowInTaskbar = false,
                    MinimizeBox = false,
                    MaximizeBox = false,
                    KeyPreview = true
                };
                ApplyRoundedRegion(dialog, 10);

                var logo = new PictureBox
                {
                    Location = new Point(28, 25),
                    Size = new Size(22, 22),
                    Image = HappIconLoader.Load(icon, Color.FromArgb(247, 247, 248)),
                    SizeMode = PictureBoxSizeMode.Zoom,
                    BackColor = dialog.BackColor
                };
                var title = new Label
                {
                    Location = new Point(60, 20),
                    Size = new Size(width - 116, 34),
                    Text = titleText,
                    Font = new Font("Segoe UI Semibold", 14F),
                    ForeColor = dialog.ForeColor,
                    TextAlign = ContentAlignment.MiddleLeft
                };
                var close = new Button
                {
                    Location = new Point(width - 54, 16),
                    Size = new Size(38, 38),
                    FlatStyle = FlatStyle.Flat,
                    BackColor = dialog.BackColor,
                    Image = HappIconLoader.Load("x", Color.FromArgb(196, 196, 201)),
                    Cursor = Cursors.Hand,
                    TabStop = false,
                    DialogResult = buttons == MessageBoxButtons.YesNo ? DialogResult.No : DialogResult.OK
                };
                close.FlatAppearance.BorderSize = 0;
                close.FlatAppearance.MouseOverBackColor = Color.FromArgb(52, 52, 55);
                var body = new Label
                {
                    Location = new Point(28, 70),
                    Size = new Size(width - 56, height - 132),
                    Text = message,
                    Font = new Font("Segoe UI", 9.5F),
                    ForeColor = dialog.ForeColor,
                    TextAlign = ContentAlignment.TopLeft
                };
                dialog.Controls.AddRange(new Control[] { logo, title, close, body });

                if (buttons == MessageBoxButtons.YesNo)
                {
                    var no = CreateButton("Нет", DialogResult.No, false);
                    no.Location = new Point(width - 224, height - 54);
                    var yes = CreateButton("Да", DialogResult.Yes, true);
                    yes.Location = new Point(width - 116, height - 54);
                    dialog.Controls.AddRange(new Control[] { no, yes });
                    dialog.AcceptButton = yes;
                    dialog.CancelButton = no;
                }
                else
                {
                    var ok = CreateButton("ОК", DialogResult.OK, true);
                    ok.Location = new Point(width - 116, height - 54);
                    dialog.Controls.Add(ok);
                    dialog.AcceptButton = ok;
                    dialog.CancelButton = ok;
                }
                dialog.KeyDown += (sender, args) =>
                {
                    if (args.KeyCode == Keys.Escape)
                    {
                        dialog.DialogResult = buttons == MessageBoxButtons.YesNo ? DialogResult.No : DialogResult.OK;
                        dialog.Close();
                    }
                };
                return dialog;
            }
        }

        private static Button CreateButton(string text, DialogResult result, bool primary)
        {
            var button = new Button
            {
                Size = new Size(96, 34),
                Text = text,
                DialogResult = result,
                FlatStyle = FlatStyle.Flat,
                BackColor = primary ? Color.FromArgb(244, 244, 245) : Color.FromArgb(62, 62, 65),
                ForeColor = primary ? Color.FromArgb(11, 11, 12) : Color.FromArgb(247, 247, 248),
                Font = new Font("Segoe UI Semibold", 9F),
                Cursor = Cursors.Hand,
                UseVisualStyleBackColor = false
            };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = primary ? Color.FromArgb(218, 218, 221) : Color.FromArgb(78, 78, 82);
            ApplyRoundedRegion(button, 5);
            return button;
        }

        private static void ApplyRoundedRegion(Control control, int radius)
        {
            Action update = () =>
            {
                if (control.Width < 2 || control.Height < 2)
                {
                    return;
                }
                int diameter = radius * 2;
                using (var path = new GraphicsPath())
                {
                    path.AddArc(0, 0, diameter, diameter, 180, 90);
                    path.AddArc(control.Width - diameter, 0, diameter, diameter, 270, 90);
                    path.AddArc(control.Width - diameter, control.Height - diameter, diameter, diameter, 0, 90);
                    path.AddArc(0, control.Height - diameter, diameter, diameter, 90, 90);
                    path.CloseFigure();
                    Region previous = control.Region;
                    control.Region = new Region(path);
                    previous?.Dispose();
                }
            };
            control.SizeChanged += (sender, args) => update();
            update();
        }
    }
}
