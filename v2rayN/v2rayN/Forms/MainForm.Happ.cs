using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Linq;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using v2rayN.Handler;
using v2rayN.Mode;

namespace v2rayN.Forms
{
    public partial class MainForm
    {
        internal static readonly Color HappAccent = Color.FromArgb(244, 244, 245);
        private static readonly Color HappTitle = Color.FromArgb(11, 11, 12);
        private static readonly Color HappNav = Color.FromArgb(16, 16, 17);
        private static readonly Color HappPane = Color.FromArgb(24, 24, 25);
        private static readonly Color HappSurface = Color.FromArgb(51, 51, 54);
        private static readonly Color HappCanvas = Color.FromArgb(20, 20, 22);
        private static readonly Color HappText = Color.FromArgb(247, 247, 248);
        private static readonly Color HappMuted = Color.FromArgb(196, 196, 201);
        private static readonly Color HappLine = Color.FromArgb(128, 128, 132);

        private Panel _happPageHost;
        private Control _happServerPage;
        private HappConnectionControl _happConnection;
        private List<Button> _happSelectableNavButtons;
        private readonly DateTime _happStartedAt = DateTime.Now;
        private long _happUploadRate;
        private long _happDownloadRate;
        private bool _happUseTun;
        private bool _happReportShortcutWired;

        [DllImport("user32.dll")]
        private static extern bool ReleaseCapture();

        [DllImport("user32.dll")]
        private static extern IntPtr SendMessage(IntPtr handle, int message, IntPtr wParam, IntPtr lParam);

        [DllImport("user32.dll")]
        private static extern bool ShowScrollBar(IntPtr handle, int bar, bool show);

        private void ApplyHappLayout()
        {
            SuspendLayout();
            AutoScaleMode = AutoScaleMode.Dpi;
            Font = new Font("Segoe UI", 9F);
            ForeColor = HappText;
            BackColor = HappCanvas;
            FormBorderStyle = FormBorderStyle.None;
            MinimumSize = new Size(920, 620);
            Size = new Size(1004, 672);
            StartPosition = FormStartPosition.CenterScreen;
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            notifyMain.Icon = Icon;
            notifyMain.Text = "Sora";
            notifyMain.ContextMenuStrip = BuildSoraTrayMenu();
            ApplyRoundedCorners(this, 9);

            tsMain.Visible = false;
            panel1.Visible = false;
            gbServers.Visible = false;
            scBig.Visible = false;

            var root = new TableLayoutPanel { Dock = DockStyle.Fill, Margin = Padding.Empty, Padding = Padding.Empty, ColumnCount = 1, RowCount = 2, BackColor = HappCanvas };
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, 32F));
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            root.Controls.Add(BuildHappTitleBar(), 0, 0);

            var shell = new TableLayoutPanel { Dock = DockStyle.Fill, Margin = Padding.Empty, Padding = Padding.Empty, ColumnCount = 2, RowCount = 1, BackColor = HappCanvas };
            shell.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 64F));
            shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            shell.Controls.Add(BuildHappNavigation(), 0, 0);
            _happPageHost = new Panel { Dock = DockStyle.Fill, BackColor = HappCanvas, Margin = Padding.Empty };
            shell.Controls.Add(_happPageHost, 1, 0);
            root.Controls.Add(shell, 0, 1);

            Controls.Clear();
            Controls.Add(root);
            _happServerPage = BuildHappServerPage();
            ShowHappPage(_happServerPage);
            ResumeLayout(true);

            Shown += (sender, args) =>
            {
                if (!_startHidden)
                {
                    Size = new Size(1004, 672);
                    CenterToScreen();
                }
                lvServers.HeaderStyle = ColumnHeaderStyle.None;
                lvServers.GridLines = false;
                ConfigureSoraServerList();
                UpdateCommunityActiveServer();
                if (config != null && config.sysProxyType == ESysProxyType.ForcedChange && config.GetVmessItem(config.indexId) == null)
                {
                    SetListenerType(ESysProxyType.ForcedClear);
                }
                else
                {
                    UpdateCommunityConnectionState(config == null ? ESysProxyType.ForcedClear : config.sysProxyType);
                }
                UpdateCommunityEmptyState();
            };
        }

        private Control BuildHappTitleBar()
        {
            var bar = new Panel { Dock = DockStyle.Fill, BackColor = HappTitle, Margin = Padding.Empty };
            var brand = new Panel { Dock = DockStyle.Left, Width = 190, BackColor = HappTitle };
            var logo = new PictureBox { Location = new Point(9, 7), Size = new Size(18, 18), Image = HappIconLoader.LoadSoraLogo(), SizeMode = PictureBoxSizeMode.Zoom, BackColor = HappTitle };
            var title = new Label { Location = new Point(31, 0), Size = new Size(155, 32), Text = "Sora 0.2.0", ForeColor = Color.White, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 8.5F) };
            title.MouseDown += DragHappWindow;
            logo.MouseDown += DragHappWindow;
            brand.MouseDown += DragHappWindow;
            bar.MouseDown += DragHappWindow;
            brand.Controls.Add(logo); brand.Controls.Add(title); bar.Controls.Add(brand);
            bar.Controls.Add(CreateWindowButton("minus", () => WindowState = FormWindowState.Minimized));
            bar.Controls.Add(CreateWindowButton("square", ToggleHappMaximize));
            bar.Controls.Add(CreateWindowButton("x", () => Close()));
            return bar;
        }

        private Button CreateWindowButton(string icon, Action action)
        {
            string accessibleName = icon == "minus" ? "Свернуть" : icon == "square" ? "Развернуть или восстановить" : "Закрыть";
            var button = new Button { Dock = DockStyle.Right, Width = 42, FlatStyle = FlatStyle.Flat, BackColor = HappTitle, Image = HappIconLoader.Load(icon, Color.White), Cursor = Cursors.Hand, TabStop = false, AccessibleName = accessibleName };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(45, 45, 48);
            button.Click += (sender, args) => action();
            return button;
        }

        private Control BuildHappNavigation()
        {
            var nav = new FlowLayoutPanel { Dock = DockStyle.Fill, BackColor = HappNav, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(8, 10, 8, 8) };
            _happSelectableNavButtons = new List<Button>();
            nav.Controls.Add(CreateHappNavButton("arrow-right", () => HideForm(), false, false));
            nav.Controls.Add(CreateHappNavButton("plus-square", ShowHappAddConfiguration, false, false));
            nav.Controls.Add(CreateHappNavButton("globe", () => ShowHappPage(_happServerPage), true));
            nav.Controls.Add(CreateHappNavButton("gear", () => ShowHappPage(BuildHappSettingsPage())));
            nav.Controls.Add(CreateHappNavButton("chart-line-up", () => ShowHappPage(BuildHappStatisticsPage())));
            nav.Controls.Add(CreateHappNavButton("terminal-window", () => ShowHappPage(BuildHappLogsPage())));
            var spacer = new Panel { Width = 52, Height = 250, Margin = Padding.Empty };
            nav.Controls.Add(spacer);
            nav.Controls.Add(CreateHappNavButton("info", ShowCommunityAbout, false, false));
            return nav;
        }

        private Button CreateHappNavButton(string icon, Action action, bool selected = false, bool selectable = true)
        {
            var button = new Button { Size = new Size(52, 44), Margin = new Padding(0, 0, 0, 4), FlatStyle = FlatStyle.Flat, BackColor = selected ? Color.Black : HappNav, Image = HappIconLoader.Load(icon, Color.FromArgb(225, 225, 229)), Cursor = Cursors.Hand, TabStop = false };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(45, 45, 48);
            button.Paint += (sender, args) =>
            {
                if (button.BackColor == Color.Black)
                {
                    using (var marker = new SolidBrush(HappAccent)) args.Graphics.FillRectangle(marker, 0, 10, 2, 24);
                }
            };
            if (selectable) _happSelectableNavButtons.Add(button);
            button.Click += (sender, args) =>
            {
                action();
                if (selectable)
                {
                    foreach (Button item in _happSelectableNavButtons)
                    {
                        item.BackColor = item == button ? Color.Black : HappNav;
                        item.Invalidate();
                    }
                    ActiveControl = null;
                }
            };
            ApplyRoundedCorners(button, 5);
            return button;
        }

        private Control BuildHappServerPage()
        {
            var page = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappCanvas, ColumnCount = 2, RowCount = 1, Margin = Padding.Empty, Padding = Padding.Empty };
            page.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 470F));
            page.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            page.Controls.Add(BuildHappServerPane(), 0, 0);
            page.Controls.Add(BuildHappConnectionPane(), 1, 0);
            return page;
        }

        private Control BuildHappServerPane()
        {
            var pane = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappPane, ColumnCount = 1, RowCount = 3, Padding = new Padding(28, 20, 18, 18) };
            pane.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F));
            pane.RowStyles.Add(new RowStyle(SizeType.Absolute, 62F));
            pane.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            pane.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Серверы", Font = new Font("Segoe UI Semibold", 17F), ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft }, 0, 0);

            var searchRow = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappPane, ColumnCount = 3, RowCount = 1, Margin = new Padding(0, 0, 0, 14) };
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 38F));
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 38F));
            searchRow.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            var searchBox = new Panel { Dock = DockStyle.Fill, BackColor = HappNav, Margin = new Padding(0, 2, 8, 4), Padding = new Padding(12, 9, 42, 5) };
            ApplyRoundedSurface(searchBox, 5, Color.FromArgb(100, 100, 105));
            _communitySearch = new TextBox { Dock = DockStyle.Fill, BorderStyle = BorderStyle.None, BackColor = HappNav, ForeColor = HappMuted, Font = new Font("Segoe UI", 9F), Text = "Введите текст для поиска", TabStop = false };
            _communitySearch.ContextMenuStrip = CreateSoraTextContextMenu(_communitySearch);
            WireHappSearch();
            searchBox.Controls.Add(_communitySearch);
            var searchIcon = new PictureBox { Dock = DockStyle.Right, Width = 30, Image = HappIconLoader.Load("magnifying-glass", HappMuted), SizeMode = PictureBoxSizeMode.CenterImage, BackColor = HappNav };
            searchBox.Controls.Add(searchIcon);
            searchRow.Controls.Add(searchBox, 0, 0);
            searchRow.Controls.Add(CreateHappSmallButton("gauge", TestAllCommunityServers), 1, 0);
            searchRow.Controls.Add(CreateHappSmallButton("dots-three", ShowHappServerMenu), 2, 0);
            pane.Controls.Add(searchRow, 0, 1);

            var listHost = new Panel { Dock = DockStyle.Fill, BackColor = HappPane, Margin = Padding.Empty };
            lvServers.Parent = listHost;
            lvServers.Dock = DockStyle.Fill;
            lvServers.BorderStyle = BorderStyle.None;
            lvServers.BackColor = HappPane;
            lvServers.ForeColor = HappText;
            lvServers.Font = new Font("Segoe UI", 9F);
            lvServers.HeaderStyle = ColumnHeaderStyle.None;
            lvServers.GridLines = false;
            lvServers.OwnerDraw = true;
            lvServers.DrawSubItem += DrawHappServerSubItem;
            lvServers.ContextMenuStrip = null;
            lvServers.MouseUp += SoraServersMouseUp;
            lvServers.HandleCreated += (sender, args) => HideSoraServerScrollbars();
            lvServers.Layout += (sender, args) => HideSoraServerScrollbars();
            lvServers.DoubleClick -= lvServers_DoubleClick;
            lvServers.DoubleClick += SoraServersDoubleClick;
            lvServers.KeyDown -= lvServers_KeyDown;
            lvServers.KeyDown += SoraServersKeyDown;
            lvServers.Resize += (sender, args) => ConfigureSoraServerList();
            _communityRowHeight = new ImageList(components) { ImageSize = new Size(1, 58), ColorDepth = ColorDepth.Depth32Bit };
            lvServers.SmallImageList = _communityRowHeight;
            _communityEmptyState = BuildHappEmptyState();
            listHost.Controls.Add(_communityEmptyState);
            _communityEmptyState.BringToFront();
            pane.Controls.Add(listHost, 0, 2);
            return pane;
        }

        private void HideSoraServerScrollbars()
        {
            if (!lvServers.IsHandleCreated)
            {
                return;
            }
            ShowScrollBar(lvServers.Handle, 0, false);
        }

        private void WireHappSearch()
        {
            const string placeholder = "Введите текст для поиска";
            _communitySearch.Enter += (sender, args) => { if (_communitySearch.Text == placeholder) { _communitySearch.Clear(); _communitySearch.ForeColor = HappText; } };
            _communitySearch.Leave += (sender, args) => { if (string.IsNullOrWhiteSpace(_communitySearch.Text)) { _communitySearch.Text = placeholder; _communitySearch.ForeColor = HappMuted; } };
            _communitySearchTimer = new Timer(components) { Interval = 250 };
            _communitySearchTimer.Tick += (sender, args) => { _communitySearchTimer.Stop(); serverFilter = _communitySearch.Text == placeholder ? string.Empty : _communitySearch.Text.Trim(); RefreshServers(); };
            _communitySearch.TextChanged += (sender, args) => { _communitySearchTimer.Stop(); _communitySearchTimer.Start(); };
        }

        private Panel BuildHappEmptyState()
        {
            var panel = new Panel { Dock = DockStyle.Fill, BackColor = HappPane, Visible = false };
            var text = new Label { Dock = DockStyle.Top, Height = 74, Padding = new Padding(8, 20, 8, 0), Text = "Добавьте прокси-сервер или подписку,\r\nчтобы они появились в списке", TextAlign = ContentAlignment.TopCenter, ForeColor = HappMuted, Font = new Font("Segoe UI", 9F) };
            var add = CreateHappButton("Добавить конфигурацию", ShowHappAddConfiguration, true);
            add.Location = new Point(90, 88); add.Size = new Size(210, 38);
            panel.Controls.Add(add); panel.Controls.Add(text);
            return panel;
        }

        private Control BuildHappConnectionPane()
        {
            var pane = new Panel { Dock = DockStyle.Fill, BackColor = HappCanvas, Margin = Padding.Empty };
            pane.Paint += DrawHappConnectionBackground;
            Image modeIcon = HappIconLoader.Load("caret-right", HappText);
            modeIcon.RotateFlip(RotateFlipType.Rotate90FlipNone);
            var mode = CreateHappButton("Прокси", ShowHappModeMenu, false);
            mode.Image = modeIcon;
            mode.ImageAlign = ContentAlignment.MiddleRight;
            mode.TextAlign = ContentAlignment.MiddleLeft;
            mode.Padding = new Padding(12, 0, 10, 0);
            mode.Name = "happMode"; mode.Anchor = AnchorStyles.Top | AnchorStyles.Right; mode.Size = new Size(140, 34); mode.Location = new Point(390, 26);
            pane.Resize += (sender, args) => mode.Left = pane.ClientSize.Width - mode.Width - 24;
            _happConnection = new HappConnectionControl { Anchor = AnchorStyles.None, Location = new Point(150, 72) };
            _happConnection.PowerClick += async (sender, args) =>
            {
                bool active = (config != null && config.sysProxyType == ESysProxyType.ForcedChange) || (_tunModeController != null && _tunModeController.IsRunning);
                if (active)
                {
                    DisconnectCommunity();
                }
                else if (_happUseTun)
                {
                    await StartCommunityTunAsync();
                }
                else if (config == null || config.GetVmessItem(config.indexId) == null)
                {
                    UI.ShowWarning("Сначала добавьте и выберите сервер.");
                }
                else
                {
                    SetListenerType(ESysProxyType.ForcedChange);
                }
            };
            pane.Resize += (sender, args) => { _happConnection.Left = (pane.ClientSize.Width - _happConnection.Width) / 2; _happConnection.Top = 72; };
            _communityActiveServer = new Label { Anchor = AnchorStyles.Bottom, AutoEllipsis = true, Size = new Size(320, 24), Location = new Point(125, 500), Text = "Сервер не выбран", ForeColor = HappText, TextAlign = ContentAlignment.MiddleCenter, Font = new Font("Segoe UI", 10F) };
            var ping = CreateHappButton("Тест пинга", TestAllCommunityServers, true);
            ping.Anchor = AnchorStyles.Bottom; ping.Size = new Size(192, 34); ping.Location = new Point(190, 548);
            pane.Resize += (sender, args) => { _communityActiveServer.Left = (pane.ClientSize.Width - _communityActiveServer.Width) / 2; _communityActiveServer.Top = pane.ClientSize.Height - 90; ping.Left = (pane.ClientSize.Width - ping.Width) / 2; ping.Top = pane.ClientSize.Height - 54; };
            pane.Controls.Add(mode); pane.Controls.Add(_happConnection); pane.Controls.Add(_communityActiveServer); pane.Controls.Add(ping);
            return pane;
        }

        private void DrawHappConnectionBackground(object sender, PaintEventArgs args)
        {
            var panel = (Panel)sender;
            args.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            using (var dark = new SolidBrush(Color.FromArgb(17, 17, 18)))
            using (var ray = new SolidBrush(Color.FromArgb(24, 24, 26)))
            {
                args.Graphics.FillRectangle(dark, panel.ClientRectangle);
                args.Graphics.FillPolygon(ray, new[] { new Point(0, 0), new Point(panel.Width, 0), new Point(panel.Width, panel.Height), new Point(panel.Width / 2, panel.Height / 2) });
            }
        }

        private Button CreateHappSmallButton(string icon, Action action)
        {
            var button = new Button { Dock = DockStyle.Fill, Margin = new Padding(2, 3, 2, 5), FlatStyle = FlatStyle.Flat, BackColor = HappPane, Image = HappIconLoader.Load(icon, HappMuted), Cursor = Cursors.Hand };
            button.FlatAppearance.BorderSize = 0; button.FlatAppearance.MouseOverBackColor = HappSurface; button.Click += (sender, args) => action(); return button;
        }

        private Button CreateHappButton(string text, Action action, bool accent)
        {
            var button = new Button { Text = text, FlatStyle = FlatStyle.Flat, BackColor = accent ? HappAccent : HappSurface, ForeColor = accent ? HappTitle : HappText, Font = new Font("Segoe UI", 9F), Cursor = Cursors.Hand, UseVisualStyleBackColor = false, TabStop = false };
            button.FlatAppearance.BorderSize = 0; button.FlatAppearance.MouseOverBackColor = accent ? Color.FromArgb(218, 218, 221) : Color.FromArgb(70, 70, 74); button.Click += (sender, args) => action(); ApplyRoundedCorners(button, 5); return button;
        }

        private void DrawHappServerSubItem(object sender, DrawListViewSubItemEventArgs args)
        {
            bool selected = args.Item.Selected;
            Color background = selected ? Color.FromArgb(55, 55, 58) : args.ItemIndex % 2 == 0 ? HappPane : Color.FromArgb(29, 29, 31);
            using (var fill = new SolidBrush(background)) args.Graphics.FillRectangle(fill, args.Bounds);
            VmessItem item = args.ItemIndex >= 0 && args.ItemIndex < lstVmess.Count ? lstVmess[args.ItemIndex] : null;
            if (args.ColumnIndex == 0)
            {
                if (item != null && config.IsActiveNode(item))
                {
                    using (var marker = new SolidBrush(HappAccent)) args.Graphics.FillRectangle(marker, args.Bounds.Left, args.Bounds.Top + 10, 3, args.Bounds.Height - 20);
                }
                string country = GetSoraCountryCode(item?.remarks);
                if (!string.IsNullOrWhiteSpace(country))
                {
                    using (var badge = new SolidBrush(Color.FromArgb(61, 61, 65))) args.Graphics.FillRectangle(badge, args.Bounds.Left + 7, args.Bounds.Top + 19, 22, 18);
                    using (var badgeFont = new Font("Segoe UI Semibold", 7F)) TextRenderer.DrawText(args.Graphics, country, badgeFont, new Rectangle(args.Bounds.Left + 7, args.Bounds.Top + 19, 22, 18), HappText, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
                }
                else if (item != null && config.IsActiveNode(item))
                {
                    using (Image check = HappIconLoader.Load("check", HappText)) args.Graphics.DrawImage(check, new Rectangle(args.Bounds.Left + 8, args.Bounds.Top + 18, 18, 18));
                }
            }
            else if (args.ColumnIndex == (int)EServerColName.remarks && item != null)
            {
                string name = string.IsNullOrWhiteSpace(item.remarks) ? "Сервер без названия" : item.remarks;
                string details = GetSoraProtocolName(item);
                if (!string.IsNullOrWhiteSpace(item.network)) details += "  ·  " + item.network.ToUpperInvariant();
                if (!string.IsNullOrWhiteSpace(item.streamSecurity)) details += "  ·  " + item.streamSecurity.ToUpperInvariant();
                using (var titleFont = new Font("Segoe UI Semibold", 9.5F))
                using (var detailFont = new Font("Segoe UI", 7.5F))
                {
                    TextRenderer.DrawText(args.Graphics, name, titleFont, new Rectangle(args.Bounds.X + 10, args.Bounds.Y + 8, Math.Max(0, args.Bounds.Width - 18), 22), HappText, TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
                    TextRenderer.DrawText(args.Graphics, details, detailFont, new Rectangle(args.Bounds.X + 10, args.Bounds.Y + 31, Math.Max(0, args.Bounds.Width - 18), 17), HappMuted, TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
                }
            }
            else if (args.ColumnIndex == (int)EServerColName.testResult)
            {
                string result = string.IsNullOrWhiteSpace(args.SubItem.Text) ? "—" : args.SubItem.Text;
                TextRenderer.DrawText(args.Graphics, result, lvServers.Font, new Rectangle(args.Bounds.X, args.Bounds.Y, Math.Max(0, args.Bounds.Width - 10), args.Bounds.Height), selected ? HappText : HappMuted, TextFormatFlags.Right | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
            }
            using (var line = new Pen(Color.FromArgb(47, 47, 50))) args.Graphics.DrawLine(line, args.Bounds.Left, args.Bounds.Bottom - 1, args.Bounds.Right, args.Bounds.Bottom - 1);
        }

        private void ShowHappServerMenu()
        {
            var menu = BuildHappMenu();
            menu.Items.Add("Добавить", HappIconLoader.Load("plus-square", HappText), (sender, args) => ShowHappAddConfiguration());
            menu.Items.Add("Пинг всех", HappIconLoader.Load("gauge", HappText), (sender, args) => TestAllCommunityServers());
            if (GetLvSelectedIndex(false) >= 0)
            {
                menu.Items.Add(new ToolStripSeparator());
                menu.Items.Add("Настройки сервера", null, (sender, args) => ShowSoraServerEditor());
                menu.Items.Add("Копировать ссылку", HappIconLoader.Load("copy", HappText), (sender, args) => menuExport2ShareUrl_Click(null, null));
                menu.Items.Add("Удалить", HappIconLoader.Load("trash", Color.FromArgb(238, 178, 178)), (sender, args) => DeleteSelectedSoraServers());
            }
            menu.Show(Cursor.Position);
        }

        private void ShowHappModeMenu()
        {
            var menu = BuildHappMenu();
            menu.Items.Add("Прокси", null, (sender, args) => _happUseTun = false);
            menu.Items.Add("TUN", null).Enabled = false;
            menu.Items.Add("Sing-box", null).Enabled = false;
            menu.Items.Add("Happ TUN", null).Enabled = false;
            menu.Items.Add("Xray TUN", null).Enabled = false;
            menu.Items.Add("tun2proxy", null, (sender, args) => _happUseTun = true);
            menu.Show(Cursor.Position);
        }

        private ContextMenuStrip BuildHappMenu()
        {
            return new ContextMenuStrip(components) { BackColor = Color.FromArgb(64, 64, 64), ForeColor = HappText, Font = new Font("Segoe UI", 9F), ShowImageMargin = true, Renderer = new ToolStripProfessionalRenderer(new HappMenuColors()) };
        }

        private void ShowHappPage(Control page)
        {
            if (page.Parent != _happPageHost) { page.Dock = DockStyle.Fill; _happPageHost.Controls.Add(page); }
            page.BringToFront(); page.Visible = true;
            foreach (Control sibling in _happPageHost.Controls) if (sibling != page) sibling.Visible = false;
        }

        private void DragHappWindow(object sender, MouseEventArgs args)
        {
            if (args.Button != MouseButtons.Left) return;
            ReleaseCapture(); SendMessage(Handle, 0xA1, new IntPtr(2), IntPtr.Zero);
        }

        private void ToggleHappMaximize() => WindowState = WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized;

        protected override void WndProc(ref Message message)
        {
            const int hitTest = 0x84;
            if (message.Msg == hitTest && WindowState == FormWindowState.Normal)
            {
                Point point = PointToClient(new Point(message.LParam.ToInt32()));
                int edge = 7; int result = 0;
                if (point.X < edge && point.Y < edge) result = 13; else if (point.X > Width - edge && point.Y < edge) result = 14;
                else if (point.X < edge && point.Y > Height - edge) result = 16; else if (point.X > Width - edge && point.Y > Height - edge) result = 17;
                else if (point.X < edge) result = 10; else if (point.X > Width - edge) result = 11; else if (point.Y < edge) result = 12; else if (point.Y > Height - edge) result = 15;
                if (result != 0) { message.Result = new IntPtr(result); return; }
            }
            base.WndProc(ref message);
        }

        private sealed class HappMenuColors : ProfessionalColorTable
        {
            public override Color MenuItemSelected => Color.FromArgb(48, 48, 50);
            public override Color MenuItemBorder => HappAccent;
            public override Color ToolStripDropDownBackground => Color.FromArgb(64, 64, 64);
            public override Color ImageMarginGradientBegin => Color.FromArgb(64, 64, 64);
            public override Color ImageMarginGradientMiddle => Color.FromArgb(64, 64, 64);
            public override Color ImageMarginGradientEnd => Color.FromArgb(64, 64, 64);
        }
    }
}
