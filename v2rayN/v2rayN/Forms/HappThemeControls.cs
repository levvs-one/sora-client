using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace v2rayN.Forms
{
    internal static class HappIconLoader
    {
        internal static Image LoadSoraLogo()
        {
            string path = Path.Combine(Application.StartupPath, "Assets", "Sora", "sora-logo-white.png");
            using (var source = new Bitmap(path)) return new Bitmap(source);
        }

        internal static Image Load(string name, Color color)
        {
            string path = Path.Combine(Application.StartupPath, "Assets", "Phosphor", "png", name + "-bold.png");
            using (var source = new Bitmap(path))
            {
                var result = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb);
                using (Graphics graphics = Graphics.FromImage(result))
                using (var attributes = new ImageAttributes())
                {
                    float red = color.R / 255F;
                    float green = color.G / 255F;
                    float blue = color.B / 255F;
                    attributes.SetColorMatrix(new ColorMatrix(new[]
                    {
                        new[] { 0F, 0F, 0F, 0F, 0F },
                        new[] { 0F, 0F, 0F, 0F, 0F },
                        new[] { 0F, 0F, 0F, 0F, 0F },
                        new[] { 0F, 0F, 0F, 1F, 0F },
                        new[] { red, green, blue, 0F, 1F }
                    }));
                    graphics.DrawImage(source, new Rectangle(0, 0, source.Width, source.Height), 0, 0, source.Width, source.Height, GraphicsUnit.Pixel, attributes);
                }
                return result;
            }
        }
    }

    internal sealed class HappConnectionControl : Control
    {
        private readonly Timer _animation;
        private readonly Image _powerImage;
        private readonly Font _stateFont;
        private readonly Font _timeFont;
        private float _phase;
        private bool _connected;
        private DateTime _connectedAt;

        internal event EventHandler PowerClick;

        internal DateTime? ConnectedAt => _connected ? _connectedAt : (DateTime?)null;

        internal bool Connected
        {
            get => _connected;
            set
            {
                if (_connected == value)
                {
                    return;
                }
                _connected = value;
                if (value)
                {
                    _connectedAt = DateTime.Now;
                }
                Invalidate();
            }
        }

        internal HappConnectionControl()
        {
            SetStyle(ControlStyles.SupportsTransparentBackColor | ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint, true);
            DoubleBuffered = true;
            Cursor = Cursors.Hand;
            BackColor = Color.Transparent;
            Size = new Size(270, 270);
            _powerImage = HappIconLoader.Load("power", MainForm.HappAccent);
            _stateFont = new Font("Segoe UI", 8F);
            _timeFont = new Font("Segoe UI Semibold", 9F);
            _animation = new Timer { Interval = 33 };
            _animation.Tick += (sender, args) =>
            {
                _phase = (_phase + 0.105F) % ((float)Math.PI * 2F);
                Invalidate();
            };
            _animation.Start();
        }

        protected override void OnClick(EventArgs e)
        {
            base.OnClick(e);
            PowerClick?.Invoke(this, EventArgs.Empty);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            Color accent = MainForm.HappAccent;
            float pulse = (float)((Math.Sin(_phase) + 1D) * 0.5D);
            int diameter = 154 + (int)Math.Round(pulse * 4F);
            var button = new Rectangle((Width - diameter) / 2, Height / 2 - diameter / 2 - 17, diameter, diameter);
            using (var fill = new LinearGradientBrush(
                button,
                Color.FromArgb(74 + (int)(pulse * 14F), 82, 82, 86),
                Color.FromArgb(255, 31, 31, 34),
                LinearGradientMode.Vertical))
            using (var border = new Pen(Color.FromArgb(_connected ? 170 : 105, accent), 2F))
            {
                e.Graphics.FillEllipse(fill, button);
                e.Graphics.DrawEllipse(border, button);
            }

            e.Graphics.DrawImage(_powerImage, new Rectangle(Width / 2 - 14, Height / 2 - 49, 28, 28));

            string state = _connected ? "ПОДКЛЮЧЕНО" : "ОТКЛЮЧЕНО";
            TextRenderer.DrawText(e.Graphics, state, _stateFont, new Rectangle(0, Height / 2 - 6, Width, 18), Color.FromArgb(172, 176, 190), TextFormatFlags.HorizontalCenter);
            if (_connected)
            {
                string elapsed = (DateTime.Now - _connectedAt).ToString(@"hh\:mm\:ss");
                TextRenderer.DrawText(e.Graphics, elapsed, _timeFont, new Rectangle(0, Height / 2 + 12, Width, 20), Color.White, TextFormatFlags.HorizontalCenter);
            }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                _animation.Dispose();
                _powerImage.Dispose();
                _stateFont.Dispose();
                _timeFont.Dispose();
            }
            base.Dispose(disposing);
        }
    }

    internal sealed class HappToggle : Control
    {
        private readonly Timer _animation;
        private float _position;
        private bool _checked;

        internal event EventHandler CheckedChanged;

        internal bool Checked
        {
            get => _checked;
            set
            {
                if (_checked == value)
                {
                    return;
                }
                _checked = value;
                _animation.Start();
                CheckedChanged?.Invoke(this, EventArgs.Empty);
            }
        }

        internal HappToggle()
        {
            DoubleBuffered = true;
            Cursor = Cursors.Hand;
            Size = new Size(42, 22);
            _animation = new Timer { Interval = 16 };
            _animation.Tick += (sender, args) =>
            {
                float target = _checked ? 1F : 0F;
                _position += (target - _position) * 0.32F;
                if (Math.Abs(target - _position) < 0.02F)
                {
                    _position = target;
                    _animation.Stop();
                }
                Invalidate();
            };
        }

        protected override void OnClick(EventArgs e)
        {
            Checked = !Checked;
            base.OnClick(e);
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using (GraphicsPath track = Rounded(new Rectangle(0, 1, Width - 1, Height - 2), 10))
            using (var brush = new SolidBrush(!Enabled ? Color.FromArgb(53, 53, 57) : _checked ? MainForm.HappAccent : Color.FromArgb(78, 78, 82)))
            using (var border = new Pen(Enabled ? Color.White : Color.FromArgb(78, 78, 82)))
            {
                e.Graphics.FillPath(brush, track);
                e.Graphics.DrawPath(border, track);
            }
            float x = 3F + _position * (Width - 20F);
            using (var knob = new SolidBrush(!Enabled ? Color.FromArgb(77, 77, 82) : _checked ? Color.FromArgb(18, 18, 19) : Color.White)) e.Graphics.FillEllipse(knob, x, 4F, 14F, 14F);
        }

        private static GraphicsPath Rounded(Rectangle bounds, int radius)
        {
            int d = radius * 2;
            var path = new GraphicsPath();
            path.AddArc(bounds.Left, bounds.Top, d, d, 180, 90);
            path.AddArc(bounds.Right - d, bounds.Top, d, d, 270, 90);
            path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
            path.AddArc(bounds.Left, bounds.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    internal sealed class HappScrollPage : Panel
    {
        private const int SbVert = 1;
        private readonly HappScrollRail _rail;

        [DllImport("user32.dll")]
        private static extern bool ShowScrollBar(IntPtr handle, int bar, bool show);

        internal FlowLayoutPanel Content { get; }

        internal HappScrollPage(Color background, Color thumb)
        {
            BackColor = background;
            Content = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                BackColor = background,
                AutoScroll = true,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                Padding = new Padding(22, 14, 22, 22),
                Margin = Padding.Empty
            };
            _rail = new HappScrollRail(Content, background, thumb) { Dock = DockStyle.Right, Width = 14 };
            Controls.Add(Content);
            Controls.Add(_rail);
            _rail.BringToFront();
            Content.HandleCreated += (sender, args) => HideNativeScrollBar();
            Content.Layout += (sender, args) => HideNativeScrollBar();
            Content.Scroll += (sender, args) => { HideNativeScrollBar(); _rail.Invalidate(); };
            Content.MouseWheel += (sender, args) => _rail.Invalidate();
        }

        private void HideNativeScrollBar()
        {
            if (Content.IsHandleCreated)
            {
                ShowScrollBar(Content.Handle, SbVert, false);
            }
            bool needsScroll = _rail.CanScroll;
            if (_rail.Visible != needsScroll)
            {
                _rail.Visible = needsScroll;
            }
            if (!needsScroll && Content.AutoScrollPosition.Y != 0)
            {
                Content.AutoScrollPosition = Point.Empty;
            }
            _rail.Invalidate();
        }
    }

    internal sealed class HappScrollRail : Control
    {
        private readonly ScrollableControl _target;
        private readonly Color _thumb;
        private bool _dragging;
        private int _dragOffset;

        internal HappScrollRail(ScrollableControl target, Color background, Color thumb)
        {
            _target = target;
            _thumb = thumb;
            BackColor = background;
            Cursor = Cursors.Hand;
            SetStyle(ControlStyles.OptimizedDoubleBuffer | ControlStyles.UserPaint, true);
            _target.SizeChanged += (sender, args) => Invalidate();
            _target.ControlAdded += (sender, args) => Invalidate();
        }

        internal bool CanScroll => GetMaximumScroll() > 0;

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            Rectangle thumb = GetThumbBounds();
            if (thumb.IsEmpty)
            {
                return;
            }
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using (var path = Rounded(thumb, 3))
            using (var brush = new SolidBrush(_dragging ? Color.FromArgb(176, 176, 180) : _thumb))
            {
                e.Graphics.FillPath(brush, path);
            }
        }

        protected override void OnMouseDown(MouseEventArgs e)
        {
            base.OnMouseDown(e);
            Rectangle thumb = GetThumbBounds();
            if (thumb.IsEmpty)
            {
                return;
            }
            if (thumb.Contains(e.Location))
            {
                _dragging = true;
                _dragOffset = e.Y - thumb.Top;
                Capture = true;
            }
            else
            {
                SetScrollFromThumbTop(e.Y - thumb.Height / 2, thumb.Height);
            }
            Invalidate();
        }

        protected override void OnMouseMove(MouseEventArgs e)
        {
            base.OnMouseMove(e);
            if (_dragging)
            {
                SetScrollFromThumbTop(e.Y - _dragOffset, GetThumbBounds().Height);
            }
        }

        protected override void OnMouseUp(MouseEventArgs e)
        {
            _dragging = false;
            Capture = false;
            Invalidate();
            base.OnMouseUp(e);
        }

        private Rectangle GetThumbBounds()
        {
            int maximum = GetMaximumScroll();
            if (maximum == 0 || Height < 64)
            {
                return Rectangle.Empty;
            }
            int trackHeight = Height - 16;
            int contentHeight = _target.ClientSize.Height + maximum;
            int thumbHeight = Math.Max(48, (int)Math.Round(trackHeight * Math.Min(1D, (double)_target.ClientSize.Height / contentHeight)));
            int travel = Math.Max(1, trackHeight - thumbHeight);
            int scrollValue = Math.Max(0, -_target.AutoScrollPosition.Y);
            int top = 8 + (int)Math.Round(travel * (double)scrollValue / maximum);
            return new Rectangle(4, top, 6, thumbHeight);
        }

        private void SetScrollFromThumbTop(int top, int thumbHeight)
        {
            int maximum = GetMaximumScroll();
            int travel = Math.Max(1, Height - 16 - thumbHeight);
            int clamped = Math.Max(8, Math.Min(8 + travel, top));
            int value = (int)Math.Round(maximum * (double)(clamped - 8) / travel);
            _target.AutoScrollPosition = new Point(0, value);
            Invalidate();
        }

        private int GetMaximumScroll()
        {
            int contentBottom = _target.Padding.Top;
            int scrollOffset = -_target.AutoScrollPosition.Y;
            foreach (Control child in _target.Controls)
            {
                if (child.Visible)
                {
                    contentBottom = Math.Max(contentBottom, child.Bottom + scrollOffset + child.Margin.Bottom);
                }
            }
            int contentHeight = contentBottom + _target.Padding.Bottom;
            return Math.Max(0, contentHeight - _target.ClientSize.Height);
        }

        private static GraphicsPath Rounded(Rectangle bounds, int radius)
        {
            int diameter = radius * 2;
            var path = new GraphicsPath();
            path.AddArc(bounds.Left, bounds.Top, diameter, diameter, 180, 90);
            path.AddArc(bounds.Right - diameter, bounds.Top, diameter, diameter, 270, 90);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
            path.AddArc(bounds.Left, bounds.Bottom - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }
    }
}
