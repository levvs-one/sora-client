using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace Sora.Centers
{
    internal class CenterWindow : Form
    {
        internal static readonly Color Surface = Color.FromArgb(30, 30, 32);
        internal static readonly Color Ink = Color.FromArgb(244, 244, 245);
        internal readonly Label Status;
        internal readonly FlowLayoutPanel Actions;
        internal readonly Panel Content;

        [DllImport("dwmapi.dll")]
        private static extern int DwmSetWindowAttribute(IntPtr window, int attribute, ref int value, int size);

        internal CenterWindow(string title)
        {
            Text = title;
            Font = new Font("Segoe UI", 10F);
            ForeColor = Ink;
            BackColor = Color.FromArgb(17, 17, 18);
            MinimumSize = new Size(760, 520);
            Size = new Size(1040, 700);
            StartPosition = FormStartPosition.CenterScreen;
            AutoScaleMode = AutoScaleMode.Dpi;
            DoubleBuffered = true;
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            var heading = new Label { Text = title, Font = new Font("Segoe UI Semibold", 19F), Dock = DockStyle.Top, Height = 68, Padding = new Padding(24, 18, 24, 0) };
            Actions = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 58, Padding = new Padding(24, 8, 24, 8), WrapContents = false, AutoScroll = true };
            Status = new Label { Dock = DockStyle.Bottom, Height = 54, Padding = new Padding(24, 10, 24, 8), ForeColor = Color.FromArgb(215, 215, 218), AutoEllipsis = true };
            Content = new Panel { Dock = DockStyle.Fill, Padding = new Padding(24, 8, 24, 8) };
            Controls.Add(Content);
            Controls.Add(Status);
            Controls.Add(Actions);
            Controls.Add(heading);
        }

        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            int enabled = 1;
            DwmSetWindowAttribute(Handle, 20, ref enabled, sizeof(int));
            int caption = ColorTranslator.ToWin32(BackColor);
            int ink = ColorTranslator.ToWin32(Ink);
            DwmSetWindowAttribute(Handle, 35, ref caption, sizeof(int));
            DwmSetWindowAttribute(Handle, 36, ref ink, sizeof(int));
            DwmSetWindowAttribute(Handle, 34, ref caption, sizeof(int));
        }

        internal static Button Button(string text, EventHandler action, bool primary = false)
        {
            var button = new Button { Text = text, AutoSize = true, Height = 36, MinimumSize = new Size(104, 36), Padding = new Padding(12, 0, 12, 0), Margin = new Padding(0, 0, 8, 0), FlatStyle = FlatStyle.Flat, BackColor = primary ? Ink : Surface, ForeColor = primary ? Color.FromArgb(20, 20, 22) : Ink, Cursor = Cursors.Hand };
            button.FlatAppearance.BorderSize = 0;
            button.Click += action;
            return button;
        }

        internal void Report(string text)
        {
            if (IsDisposed || Disposing) return;
            if (InvokeRequired)
            {
                try { BeginInvoke(new Action(() => Report(text))); }
                catch (InvalidOperationException) { /* The window can close while a worker finishes. */ }
                return;
            }
            Status.Text = text;
            Status.AccessibleName = text;
        }
    }
}
