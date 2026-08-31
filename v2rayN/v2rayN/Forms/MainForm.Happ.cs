using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Windows.Forms;
using Newtonsoft.Json.Linq;
using v2rayN.Handler;
using v2rayN.Mode;
using v2rayN.Tool;

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
        private static readonly Color HappMuted = Color.FromArgb(214, 214, 218);
        private static readonly Color HappLine = Color.FromArgb(128, 128, 132);
        private static readonly Color HappControlBorder = Color.FromArgb(76, 76, 81);
        private static readonly Color HappListBorder = Color.FromArgb(45, 45, 49);
        private static readonly Color HappDivider = Color.FromArgb(49, 49, 53);
        private static readonly Color HappServerSurface = Color.FromArgb(29, 29, 32);

        private Panel _happPageHost;
        private Control _happServerPage;
        private HappConnectionControl _happConnection;
        private List<Button> _happSelectableNavButtons;
        private readonly DateTime _happStartedAt = DateTime.Now;
        private long _happUploadRate;
        private long _happDownloadRate;
        private Label _soraSubscriptionTitle;
        private Label _soraSubscriptionDetail;
        private Button _soraSubscriptionRefresh;
        private Button _soraSubscriptionPing;
        private Panel _soraSubscriptionQuotaTrack;
        private Panel _soraSubscriptionQuotaFill;
        private Label _soraSubscriptionQuota;
        private Label _soraSubscriptionSchedule;
        private SoraMarkdownView _soraSubscriptionAnnouncement;
        private Timer _soraSubscriptionSummaryTimer;
        private Label _soraTrafficSummary;
        private Timer _soraTrafficTimer;
        private bool _happUseTun;
        private Button _happModeButton;
        private bool _happReportShortcutWired;
        private int _happHoveredServerIndex = -1;
        private HappListScrollRail _happServerScroll;
        private bool _happHidingServerScrollbars;
        private Timer _soraPingAnimationTimer;
        private int _soraPingAnimationFrame;
        private readonly Dictionary<string, SoraProtocolDisplay> _soraProtocolDisplayCache = new Dictionary<string, SoraProtocolDisplay>(StringComparer.OrdinalIgnoreCase);
        private readonly Dictionary<string, Image> _soraCountryFlagCache = new Dictionary<string, Image>(StringComparer.OrdinalIgnoreCase);
        private Image _soraDefaultCountryIcon;

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
            NormalizeSoraVisibleConfiguration();
            KeyPreview = true;
            KeyDown += HandleHappShortcut;
            FormClosed += DisposeSoraCountryImages;

            tsMain.Visible = false;
            panel1.Visible = false;
            gbServers.Visible = false;
            scBig.Visible = false;

            var root = new TableLayoutPanel { Dock = DockStyle.Fill, Margin = Padding.Empty, Padding = Padding.Empty, ColumnCount = 1, RowCount = 2, BackColor = HappCanvas };
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F));
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
            SoraText.Apply(root);
            ResumeLayout(true);

            Shown += (sender, args) =>
            {
                NormalizeSoraVisibleConfiguration();
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
                RefreshSoraSubscriptionCard();
                StartSoraSubscriptionScheduler();
            };
        }

        private Control BuildHappTitleBar()
        {
            var bar = new Panel { Dock = DockStyle.Fill, BackColor = HappTitle, Margin = Padding.Empty };
            var brand = new Panel { Dock = DockStyle.Left, Width = 164, BackColor = HappTitle };
            var logo = new PictureBox { Location = new Point(8, 6), Size = new Size(16, 16), Image = HappIconLoader.LoadSoraLogo(), SizeMode = PictureBoxSizeMode.Zoom, BackColor = HappTitle };
            var title = new Label { Location = new Point(28, 0), Size = new Size(132, 28), Text = "Sora " + SoraVersion, ForeColor = Color.White, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 8.25F) };
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
            Image source = HappIconLoader.Load(icon, Color.White);
            Image compactIcon = new Bitmap(source, new Size(14, 14));
            source.Dispose();
            var button = new Button { Dock = DockStyle.Right, Width = 32, FlatStyle = FlatStyle.Flat, BackColor = HappTitle, Image = compactIcon, Cursor = Cursors.Hand, TabStop = false, AccessibleName = accessibleName, AccessibleRole = AccessibleRole.PushButton };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(45, 45, 48);
            button.Click += (sender, args) => action();
            return button;
        }

        private Control BuildHappNavigation()
        {
            var nav = new Panel { Dock = DockStyle.Fill, BackColor = HappNav };
            var primary = new FlowLayoutPanel { Dock = DockStyle.Top, Height = 298, BackColor = HappNav, FlowDirection = FlowDirection.TopDown, WrapContents = false, Padding = new Padding(8, 10, 8, 0) };
            _happSelectableNavButtons = new List<Button>();
            primary.Controls.Add(CreateHappNavButton("plus-square", ShowHappAddConfiguration, false, false));
            primary.Controls.Add(CreateHappNavButton("globe", () => ShowHappPage(_happServerPage), true));
            primary.Controls.Add(CreateHappNavButton("gear", () => ShowHappPage(BuildHappSettingsPage())));
            primary.Controls.Add(CreateHappNavButton("chart-line-up", () => ShowHappPage(BuildHappStatisticsPage())));
            primary.Controls.Add(CreateHappNavButton("terminal-window", () => ShowHappPage(BuildHappLogsPage())));

            var infoHost = new Panel { Dock = DockStyle.Bottom, Height = 60, BackColor = HappNav, Padding = new Padding(8) };
            var info = CreateHappNavButton("info", ShowCommunityAbout, false, false);
            info.Dock = DockStyle.Left;
            info.Margin = Padding.Empty;
            infoHost.Controls.Add(info);

            nav.Controls.Add(primary);
            nav.Controls.Add(infoHost);
            return nav;
        }

        private Button CreateHappNavButton(string icon, Action action, bool selected = false, bool selectable = true)
        {
            string accessibleName = icon == "plus-square" ? "Добавить конфигурацию"
                : icon == "globe" ? "Серверы"
                : icon == "gear" ? "Настройки"
                : icon == "chart-line-up" ? "Статистика"
                : icon == "terminal-window" ? "Логи"
                : icon == "info" ? "О программе"
                : "Раздел";
            var button = new Button { Size = new Size(48, 44), Margin = new Padding(0, 0, 0, 4), FlatStyle = FlatStyle.Flat, BackColor = selected ? Color.Black : HappNav, Image = HappIconLoader.Load(icon, Color.FromArgb(225, 225, 229)), Cursor = Cursors.Hand, TabStop = true, AccessibleName = accessibleName, AccessibleRole = AccessibleRole.PushButton, UseVisualStyleBackColor = false };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(45, 45, 48);
            button.FlatAppearance.MouseDownBackColor = Color.FromArgb(58, 58, 62);
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
                ActiveControl = null;
                action();
                if (selectable)
                {
                    foreach (Button item in _happSelectableNavButtons)
                    {
                        item.BackColor = item == button ? Color.Black : HappNav;
                        item.Invalidate();
                    }
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
            var pane = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappPane, ColumnCount = 1, RowCount = 4, Padding = new Padding(28, 16, 18, 18) };
            pane.RowStyles.Add(new RowStyle(SizeType.Absolute, 38F));
            pane.RowStyles.Add(new RowStyle(SizeType.Absolute, 58F));
            pane.RowStyles.Add(new RowStyle(SizeType.Absolute, 166F));
            pane.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            pane.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Серверы", Font = new Font("Segoe UI Semibold", 15F), ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft }, 0, 0);

            var searchRow = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappPane, ColumnCount = 3, RowCount = 1, Margin = new Padding(0, 0, 0, 14) };
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 38F));
            searchRow.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 38F));
            searchRow.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            var searchBox = new Panel { Dock = DockStyle.Fill, BackColor = HappControlBorder, Margin = new Padding(0, 2, 8, 4), Padding = new Padding(1) };
            ApplyRoundedCorners(searchBox, 6);
            var searchContent = new Panel { Dock = DockStyle.Fill, BackColor = HappNav, Margin = Padding.Empty, Padding = Padding.Empty };
            ApplyRoundedCorners(searchContent, 5);
            _communitySearch = new TextBox { BorderStyle = BorderStyle.None, BackColor = HappNav, ForeColor = HappMuted, Font = new Font("Segoe UI", 9F), Text = SoraText.Translate("Введите текст для поиска"), TabStop = true, AccessibleName = "Поиск серверов" };
            _communitySearch.ContextMenuStrip = CreateSoraTextContextMenu(_communitySearch);
            WireHappSearch();
            var searchButton = CreateHappSmallButton("magnifying-glass", () =>
            {
                _communitySearch.Focus();
                _communitySearch.SelectAll();
            });
            searchButton.Dock = DockStyle.Right;
            searchButton.Width = 42;
            searchButton.Margin = Padding.Empty;
            searchButton.BackColor = HappNav;
            searchButton.UseVisualStyleBackColor = false;
            searchButton.TabStop = false;
            searchContent.Controls.Add(_communitySearch);
            searchContent.Controls.Add(searchButton);
            Action positionSearch = () =>
            {
                int textHeight = _communitySearch.PreferredHeight;
                int textTop = Math.Max(0, (searchContent.ClientSize.Height - textHeight) / 2);
                _communitySearch.SetBounds(12, textTop, Math.Max(80, searchContent.ClientSize.Width - searchButton.Width - 20), textHeight);
            };
            searchContent.Resize += (sender, args) => positionSearch();
            _communitySearch.Enter += (sender, args) => searchBox.BackColor = Color.FromArgb(112, 112, 118);
            _communitySearch.Leave += (sender, args) => searchBox.BackColor = HappControlBorder;
            searchBox.Controls.Add(searchContent);
            positionSearch();
            searchButton.BringToFront();
            searchRow.Controls.Add(searchBox, 0, 0);
            searchRow.Controls.Add(CreateHappSmallButton("gauge", TestAllCommunityServers), 1, 0);
            searchRow.Controls.Add(CreateHappSmallButton("dots-three", ShowHappServerMenu), 2, 0);
            pane.Controls.Add(searchRow, 0, 1);

            pane.Controls.Add(BuildSoraInlineSubscriptionCard(), 0, 2);

            var listHost = new Panel { Dock = DockStyle.Fill, BackColor = HappListBorder, Margin = Padding.Empty, Padding = new Padding(1) };
            ApplyRoundedCorners(listHost, 6);
            var listSurface = new Panel { Dock = DockStyle.Fill, BackColor = HappServerSurface, Margin = Padding.Empty };
            ApplyRoundedCorners(listSurface, 5);
            listHost.Controls.Add(listSurface);
            lvServers.Parent = listSurface;
            lvServers.Dock = DockStyle.Fill;
            lvServers.BorderStyle = BorderStyle.None;
            lvServers.BackColor = HappServerSurface;
            lvServers.ForeColor = HappText;
            lvServers.Font = new Font("Segoe UI", 9F);
            lvServers.HeaderStyle = ColumnHeaderStyle.None;
            lvServers.GridLines = false;
            lvServers.OwnerDraw = true;
            lvServers.DrawSubItem += DrawHappServerSubItem;
            lvServers.ContextMenuStrip = null;
            lvServers.MouseUp += SoraServersMouseUp;
            lvServers.MouseMove += SoraServersMouseMove;
            lvServers.MouseLeave += SoraServersMouseLeave;
            lvServers.HandleCreated += (sender, args) => HideSoraServerScrollbars();
            lvServers.Layout += (sender, args) => HideSoraServerScrollbars();
            lvServers.DoubleClick -= lvServers_DoubleClick;
            lvServers.DoubleClick += SoraServersDoubleClick;
            lvServers.KeyDown -= lvServers_KeyDown;
            lvServers.KeyDown += SoraServersKeyDown;
            lvServers.Resize += (sender, args) => ConfigureSoraServerList();
            _communityRowHeight = new ImageList(components) { ImageSize = new Size(1, 58), ColorDepth = ColorDepth.Depth32Bit };
            lvServers.SmallImageList = _communityRowHeight;
            _happServerScroll = new HappListScrollRail(lvServers, HappServerSurface, Color.FromArgb(124, 124, 130))
            {
                Anchor = AnchorStyles.Top | AnchorStyles.Right | AnchorStyles.Bottom,
                Width = 18
            };
            listSurface.Controls.Add(_happServerScroll);
            Action positionServerScroll = () => _happServerScroll.SetBounds(Math.Max(0, listSurface.ClientSize.Width - 18), 0, 18, listSurface.ClientSize.Height);
            listSurface.Resize += (sender, args) => positionServerScroll();
            positionServerScroll();
            _happServerScroll.BringToFront();
            _communityEmptyState = BuildHappEmptyState();
            _communityEmptyState.BackColor = HappServerSurface;
            listSurface.Controls.Add(_communityEmptyState);
            _communityEmptyState.BringToFront();
            pane.Controls.Add(listHost, 0, 3);
            return pane;
        }

        private Control BuildSoraInlineSubscriptionCard()
        {
            Color cardBackground = Color.FromArgb(35, 35, 38);
            var card = new Panel { Dock = DockStyle.Fill, Margin = new Padding(0, 0, 0, 8), BackColor = cardBackground, AccessibleName = "Подписка" };
            ApplyRoundedCorners(card, 7);
            _soraSubscriptionTitle = new Label { Location = new Point(16, 7), Size = new Size(280, 22), ForeColor = HappText, Font = new Font("Segoe UI Semibold", 10.5F), TextAlign = ContentAlignment.MiddleLeft, AutoEllipsis = true, BackColor = cardBackground, Cursor = Cursors.Hand };
            _soraSubscriptionDetail = new Label { Location = new Point(16, 31), Size = new Size(390, 18), ForeColor = HappMuted, Font = new Font("Segoe UI", 9F), TextAlign = ContentAlignment.MiddleLeft, AutoEllipsis = true, BackColor = cardBackground, Cursor = Cursors.Hand };
            _soraSubscriptionSchedule = new Label { Location = new Point(16, 50), Size = new Size(390, 18), ForeColor = Color.FromArgb(202, 202, 208), Font = new Font("Segoe UI", 8.75F), TextAlign = ContentAlignment.MiddleLeft, AutoEllipsis = true, BackColor = cardBackground, Cursor = Cursors.Hand };
            _soraSubscriptionQuotaTrack = new Panel { Location = new Point(16, 72), Size = new Size(390, 3), BackColor = Color.FromArgb(78, 78, 84) };
            _soraSubscriptionQuotaFill = new Panel { Location = Point.Empty, Size = new Size(0, 3), BackColor = Color.FromArgb(232, 232, 235) };
            _soraSubscriptionQuotaTrack.Controls.Add(_soraSubscriptionQuotaFill);
            _soraSubscriptionQuota = new Label { Location = new Point(16, 78), Size = new Size(390, 18), ForeColor = Color.FromArgb(202, 202, 208), Font = new Font("Segoe UI", 8.75F), BackColor = cardBackground, TextAlign = ContentAlignment.MiddleLeft, AutoEllipsis = true };
            _soraSubscriptionAnnouncement = new SoraMarkdownView { Location = new Point(12, 99), Size = new Size(398, 52), BackColor = cardBackground, Compact = true, ScrollBars = RichTextBoxScrollBars.None, TabStop = false, AccessibleName = "Описание подписки" };
            _soraSubscriptionRefresh = CreateHappSmallButton("arrows-clockwise", UpdateSoraPrimarySubscription);
            _soraSubscriptionPing = CreateHappSmallButton("gauge", TestSoraPrimarySubscriptionServers);
            Button actions = CreateHappSmallButton("dots-three", ShowSoraSubscriptionCardMenu);
            Button[] buttons = { _soraSubscriptionRefresh, _soraSubscriptionPing, actions };
            for (int index = 0; index < buttons.Length; index++)
            {
                buttons[index].Dock = DockStyle.None;
                buttons[index].Size = new Size(28, 28);
                buttons[index].Location = new Point(card.Width - 100 + index * 30, 7);
                buttons[index].BackColor = cardBackground;
                buttons[index].UseVisualStyleBackColor = false;
                buttons[index].FlatAppearance.MouseOverBackColor = Color.FromArgb(55, 55, 60);
                buttons[index].FlatAppearance.MouseDownBackColor = Color.FromArgb(70, 70, 76);
                ApplyRoundedCorners(buttons[index], 5);
                card.Controls.Add(buttons[index]);
            }
            Action open = OpenSoraPrimarySubscription;
            _soraSubscriptionTitle.Click += (sender, args) => open();
            _soraSubscriptionDetail.Click += (sender, args) => open();
            _soraSubscriptionSchedule.Click += (sender, args) => open();
            _soraSubscriptionAnnouncement.DoubleClick += (sender, args) => ShowSoraPrimarySubscriptionAnnouncement();
            card.Resize += (sender, args) =>
            {
                _soraSubscriptionTitle.Width = Math.Max(120, card.ClientSize.Width - 116);
                for (int index = 0; index < buttons.Length; index++) buttons[index].Left = card.ClientSize.Width - 100 + index * 30;
                _soraSubscriptionQuotaTrack.Width = Math.Max(80, card.ClientSize.Width - 32);
                _soraSubscriptionDetail.Width = _soraSubscriptionQuotaTrack.Width;
                _soraSubscriptionQuota.Width = _soraSubscriptionQuotaTrack.Width;
                _soraSubscriptionSchedule.Width = _soraSubscriptionQuotaTrack.Width;
                _soraSubscriptionAnnouncement.Width = Math.Max(80, card.ClientSize.Width - 24);
                _soraSubscriptionAnnouncement.Height = Math.Max(44, card.ClientSize.Height - 106);
                RefreshSoraSubscriptionCard();
            };
            card.Controls.Add(_soraSubscriptionAnnouncement);
            card.Controls.Add(_soraSubscriptionQuota);
            card.Controls.Add(_soraSubscriptionQuotaTrack);
            card.Controls.Add(_soraSubscriptionSchedule);
            card.Controls.Add(_soraSubscriptionDetail);
            card.Controls.Add(_soraSubscriptionTitle);
            StartSoraSubscriptionSummary();
            return card;
        }

        private void HideSoraServerScrollbars()
        {
            if (!lvServers.IsHandleCreated || _happHidingServerScrollbars)
            {
                return;
            }
            _happHidingServerScrollbars = true;
            try
            {
                ShowScrollBar(lvServers.Handle, 3, false);
            }
            finally
            {
                _happHidingServerScrollbars = false;
            }
            _happServerScroll?.RefreshState();
        }

        private void SoraServersMouseMove(object sender, MouseEventArgs args)
        {
            ListViewItem item = lvServers.GetItemAt(args.X, args.Y);
            int hovered = item?.Index ?? -1;
            if (_happHoveredServerIndex == hovered)
            {
                return;
            }
            _happHoveredServerIndex = hovered;
            lvServers.Invalidate();
        }

        private void SoraServersMouseLeave(object sender, EventArgs args)
        {
            if (_happHoveredServerIndex < 0)
            {
                return;
            }
            _happHoveredServerIndex = -1;
            lvServers.Invalidate();
        }

        private void WireHappSearch()
        {
            string placeholder = SoraText.Translate("Введите текст для поиска");
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
            _happModeButton = CreateHappButton("Прокси", ShowHappModeMenu, false);
            _happModeButton.Image = modeIcon;
            _happModeButton.ImageAlign = ContentAlignment.MiddleRight;
            _happModeButton.TextAlign = ContentAlignment.MiddleLeft;
            _happModeButton.Padding = new Padding(10, 0, 8, 0);
            _happModeButton.Name = "happMode";
            _happModeButton.AccessibleName = "Режим подключения: Прокси";
            _happModeButton.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            _happModeButton.Size = new Size(120, 32);
            _happModeButton.Location = new Point(410, 18);
            pane.Resize += (sender, args) => _happModeButton.Left = pane.ClientSize.Width - _happModeButton.Width - 20;
            _happConnection = new HappConnectionControl { Anchor = AnchorStyles.None, Location = new Point(150, 72) };
            _happConnection.PowerClick += async (sender, args) =>
            {
                bool active = (config != null && config.sysProxyType == ESysProxyType.ForcedChange && v2rayHandler != null && v2rayHandler.IsRunning)
                    || (_tunModeController != null && _tunModeController.IsRunning);
                if (active)
                {
                    _happConnection.State = SoraConnectionState.Disconnecting;
                    DisconnectCommunity();
                }
                else if (_happUseTun)
                {
                    _happConnection.State = SoraConnectionState.Connecting;
                    await StartCommunityTunAsync();
                }
                else if (config == null || config.GetVmessItem(config.indexId) == null)
                {
                    UI.ShowWarning("Сначала добавьте и выберите сервер.");
                }
                else
                {
                    _happConnection.State = SoraConnectionState.Connecting;
                    SetListenerType(ESysProxyType.ForcedChange);
                }
            };
            pane.Resize += (sender, args) => { _happConnection.Left = (pane.ClientSize.Width - _happConnection.Width) / 2; _happConnection.Top = 72; };
            _communityActiveServer = new Label { Anchor = AnchorStyles.Bottom, AutoEllipsis = true, Size = new Size(320, 24), Location = new Point(125, 500), Text = "Сервер не выбран", ForeColor = HappText, TextAlign = ContentAlignment.MiddleCenter, Font = new Font("Segoe UI", 10F) };
            _soraTrafficSummary = new Label { Anchor = AnchorStyles.Top, Location = new Point(126, 300), Size = new Size(320, 42), BackColor = Color.Transparent, ForeColor = HappMuted, Font = new Font("Segoe UI", 8.5F), Text = "↓ 0 B/s     ↑ 0 B/s\r\nСегодня 0 B", TextAlign = ContentAlignment.TopCenter, AccessibleName = "Счётчик трафика" };
            StartSoraTrafficCounter();
            var ping = CreateHappButton("Проверить задержку", TestAllCommunityServers, true);
            ping.Anchor = AnchorStyles.Bottom; ping.Size = new Size(192, 34); ping.Location = new Point(190, 548);
            pane.Resize += (sender, args) => { _soraTrafficSummary.Left = (pane.ClientSize.Width - _soraTrafficSummary.Width) / 2; _communityActiveServer.Left = (pane.ClientSize.Width - _communityActiveServer.Width) / 2; _communityActiveServer.Top = pane.ClientSize.Height - 90; ping.Left = (pane.ClientSize.Width - ping.Width) / 2; ping.Top = pane.ClientSize.Height - 54; };
            pane.Controls.Add(_happModeButton); pane.Controls.Add(_happConnection); pane.Controls.Add(_soraTrafficSummary); pane.Controls.Add(_communityActiveServer); pane.Controls.Add(ping);
            _soraTrafficSummary.BringToFront();
            return pane;
        }

        private void StartSoraTrafficCounter()
        {
            if (_soraTrafficTimer != null) return;
            _soraTrafficTimer = new Timer(components) { Interval = 500 };
            _soraTrafficTimer.Tick += (sender, args) =>
            {
                if (_soraTrafficSummary == null) return;
                ulong down = (ulong)Math.Max(0L, System.Threading.Interlocked.Read(ref _happDownloadRate));
                ulong up = (ulong)Math.Max(0L, System.Threading.Interlocked.Read(ref _happUploadRate));
                ulong today = 0;
                try
                {
                    if (statistics != null && statistics.Enable)
                    {
                        foreach (ServerStatItem item in statistics.Statistic.ToArray()) today += item.todayDown + item.todayUp;
                    }
                }
                catch (InvalidOperationException)
                {
                    today = 0;
                }
                _soraTrafficSummary.Text = "↓ " + Utils.HumanFy(down) + "/s     ↑ " + Utils.HumanFy(up) + "/s\r\n" + SoraText.Translate("Сегодня") + " " + Utils.HumanFy(today);
            };
            _soraTrafficTimer.Start();
        }

        private void StartSoraSubscriptionSummary()
        {
            if (_soraSubscriptionSummaryTimer != null) return;
            _soraSubscriptionSummaryTimer = new Timer(components) { Interval = 500 };
            _soraSubscriptionSummaryTimer.Tick += (sender, args) => RefreshSoraSubscriptionCard();
            _soraSubscriptionSummaryTimer.Start();
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
            string accessibleName = icon == "gauge" ? "Проверить задержку серверов подписки" : icon == "arrows-clockwise" ? "Обновить подписку" : icon == "dots-three" ? "Действия с подпиской" : icon == "magnifying-glass" ? "Поиск серверов" : "Действие";
            var button = new Button { Dock = DockStyle.Fill, Margin = new Padding(2, 3, 2, 5), FlatStyle = FlatStyle.Flat, BackColor = HappPane, Image = HappIconLoader.Load(icon, HappMuted), Cursor = Cursors.Hand, TabStop = true, AccessibleName = accessibleName, AccessibleRole = AccessibleRole.PushButton };
            button.FlatAppearance.BorderSize = 0; button.FlatAppearance.MouseOverBackColor = HappSurface; button.Click += (sender, args) => action(); return button;
        }

        private Button CreateHappButton(string text, Action action, bool accent)
        {
            var button = new Button { Text = text, FlatStyle = FlatStyle.Flat, BackColor = accent ? HappAccent : HappSurface, ForeColor = accent ? HappTitle : HappText, Font = new Font("Segoe UI", 9F), Cursor = Cursors.Hand, UseVisualStyleBackColor = false, TabStop = true, AccessibleName = text, AccessibleRole = AccessibleRole.PushButton };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = accent ? Color.FromArgb(218, 218, 221) : Color.FromArgb(70, 70, 74);
            if (action != null) button.Click += (sender, args) => action();
            ApplyRoundedCorners(button, 5);
            return button;
        }

        private void DrawHappServerSubItem(object sender, DrawListViewSubItemEventArgs args)
        {
            bool selected = args.Item.Selected;
            bool hovered = args.ItemIndex == _happHoveredServerIndex;
            Color background = selected ? Color.FromArgb(52, 52, 56) : hovered ? Color.FromArgb(37, 37, 41) : HappServerSurface;
            using (var fill = new SolidBrush(background)) args.Graphics.FillRectangle(fill, args.Bounds);
            VmessItem item = args.ItemIndex >= 0 && args.ItemIndex < lstVmess.Count ? lstVmess[args.ItemIndex] : null;
            if (args.ColumnIndex == 0)
            {
                if (item != null && config.IsActiveNode(item))
                {
                    Rectangle markerBounds = new Rectangle(args.Bounds.Left, args.Bounds.Top + 12, 3, args.Bounds.Height - 24);
                    SmoothingMode previous = args.Graphics.SmoothingMode;
                    args.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                    using (GraphicsPath markerPath = CreateRoundedPath(markerBounds, 2))
                    using (var marker = new SolidBrush(Color.FromArgb(108, 108, 114)))
                    {
                        args.Graphics.FillPath(marker, markerPath);
                    }
                    args.Graphics.SmoothingMode = previous;
                }
                DrawSoraCountryMark(args.Graphics, new Rectangle(args.Bounds.Left + 7, args.Bounds.Top + 20, 22, 17), item?.remarks);
            }
            else if (args.ColumnIndex == (int)EServerColName.remarks && item != null)
            {
                string name = GetSoraDisplayName(item.remarks);
                string[] protocols = GetSoraProtocolDisplay(item);
                using (var titleFont = new Font("Segoe UI Semibold", 10F))
                using (var protocolFont = new Font("Segoe UI Semibold", 8.25F))
                using (var detailFont = new Font("Segoe UI", 8.25F))
                {
                    TextRenderer.DrawText(args.Graphics, name, titleFont, new Rectangle(args.Bounds.X + 10, args.Bounds.Y + 7, Math.Max(0, args.Bounds.Width - 18), 22), HappText, TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
                    DrawSoraProtocolLine(args.Graphics, new Rectangle(args.Bounds.X + 10, args.Bounds.Y + 32, Math.Max(0, args.Bounds.Width - 18), 16), protocols, protocolFont, detailFont);
                }
            }
            else if (args.ColumnIndex == (int)EServerColName.testResult)
            {
                string result = string.IsNullOrWhiteSpace(args.SubItem.Text) ? string.Empty : args.SubItem.Text;
                if (string.Equals(result, "Проверка…", StringComparison.Ordinal))
                {
                    EnsureSoraPingAnimation();
                    DrawSoraPingAnimation(args.Graphics, args.Bounds);
                }
                else
                {
                    bool measured = result.Any(char.IsDigit);
                    Color resultColor = measured || selected ? HappText : HappMuted;
                    using (var resultFont = new Font("Segoe UI Semibold", 8.5F))
                    {
                        TextRenderer.DrawText(args.Graphics, result, resultFont, new Rectangle(args.Bounds.X, args.Bounds.Y, Math.Max(0, args.Bounds.Width - 10), args.Bounds.Height), resultColor, TextFormatFlags.Right | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine);
                    }
                }
            }
            using (var line = new Pen(HappDivider)) args.Graphics.DrawLine(line, args.Bounds.Left, args.Bounds.Bottom - 1, args.Bounds.Right, args.Bounds.Bottom - 1);
        }

        private void EnsureSoraPingAnimation()
        {
            if (_soraPingAnimationTimer == null)
            {
                _soraPingAnimationTimer = new Timer(components) { Interval = 120 };
                _soraPingAnimationTimer.Tick += (sender, args) =>
                {
                    if (lstVmess == null || !lstVmess.Any(item => string.Equals(item.testResult, "Проверка…", StringComparison.Ordinal)))
                    {
                        _soraPingAnimationTimer.Stop();
                        _soraPingAnimationFrame = 0;
                        return;
                    }
                    _soraPingAnimationFrame = (_soraPingAnimationFrame + 1) % 6;
                    lvServers.Invalidate();
                };
            }
            if (!_soraPingAnimationTimer.Enabled)
            {
                _soraPingAnimationTimer.Start();
            }
        }

        private void DrawSoraPingAnimation(Graphics graphics, Rectangle bounds)
        {
            const int diameter = 4;
            const int spacing = 7;
            int left = bounds.Left + (bounds.Width - diameter * 3 - spacing * 2) / 2;
            int baseline = bounds.Top + bounds.Height / 2;
            int activeDot = _soraPingAnimationFrame / 2;
            int lift = _soraPingAnimationFrame % 2 == 0 ? 3 : 2;
            SmoothingMode previous = graphics.SmoothingMode;
            graphics.SmoothingMode = SmoothingMode.AntiAlias;
            for (int index = 0; index < 3; index++)
            {
                int y = baseline - diameter / 2 - (index == activeDot ? lift : 0);
                using (var brush = new SolidBrush(index == activeDot ? HappText : HappMuted))
                {
                    graphics.FillEllipse(brush, left + index * (diameter + spacing), y, diameter, diameter);
                }
            }
            graphics.SmoothingMode = previous;
        }

        private static string GetSoraDisplayName(string remarks)
        {
            string name = string.IsNullOrWhiteSpace(remarks) ? "Сервер без названия" : remarks.Trim();
            return Regex.Replace(name, @"^[\uD83C][\uDDE6-\uDDFF][\uD83C][\uDDE6-\uDDFF]\s*", string.Empty);
        }

        private void DrawSoraCountryMark(Graphics graphics, Rectangle bounds, string remarks)
        {
            string countryCode = GetSoraVisualCountryCode(remarks);
            Image flag = LoadSoraCountryFlag(countryCode);
            if (flag == null)
            {
                if (_soraDefaultCountryIcon == null)
                {
                    _soraDefaultCountryIcon = HappIconLoader.Load("globe", HappMuted);
                }
                graphics.DrawImage(_soraDefaultCountryIcon, new Rectangle(bounds.Left + 2, bounds.Top, 17, 17));
                return;
            }

            InterpolationMode previousInterpolation = graphics.InterpolationMode;
            PixelOffsetMode previousPixelOffset = graphics.PixelOffsetMode;
            graphics.InterpolationMode = InterpolationMode.HighQualityBicubic;
            graphics.PixelOffsetMode = PixelOffsetMode.HighQuality;
            graphics.DrawImage(flag, new Rectangle(bounds.Left, bounds.Top + 1, bounds.Width, bounds.Height - 2));
            graphics.InterpolationMode = previousInterpolation;
            graphics.PixelOffsetMode = previousPixelOffset;
            using (var border = new Pen(Color.FromArgb(92, 92, 97)))
            {
                graphics.DrawRectangle(border, bounds.Left, bounds.Top + 1, bounds.Width - 1, bounds.Height - 3);
            }
        }

        private Image LoadSoraCountryFlag(string countryCode)
        {
            if (string.IsNullOrWhiteSpace(countryCode))
            {
                return null;
            }
            if (_soraCountryFlagCache.TryGetValue(countryCode, out Image cached))
            {
                return cached;
            }

            Image flag = null;
            string path = Path.Combine(Application.StartupPath, "Assets", "Flags", "png100px", countryCode.ToLowerInvariant() + ".png");
            if (File.Exists(path))
            {
                try
                {
                    using (Image source = Image.FromFile(path))
                    {
                        flag = new Bitmap(source);
                    }
                }
                catch (Exception exception)
                {
                    Utils.SaveLog("Не удалось загрузить изображение флага " + countryCode + ".", exception);
                }
            }
            _soraCountryFlagCache[countryCode] = flag;
            return flag;
        }

        private static string GetSoraVisualCountryCode(string remarks)
        {
            Match flag = Regex.Match(remarks ?? string.Empty, @"^\s*\uD83C(?<first>[\uDDE6-\uDDFF])\uD83C(?<second>[\uDDE6-\uDDFF])");
            if (flag.Success)
            {
                char first = (char)('A' + flag.Groups["first"].Value[0] - '\uDDE6');
                char second = (char)('A' + flag.Groups["second"].Value[0] - '\uDDE6');
                return new string(new[] { first, second });
            }
            return GetSoraCountryCode(remarks);
        }

        private void DisposeSoraCountryImages(object sender, FormClosedEventArgs args)
        {
            foreach (Image flag in _soraCountryFlagCache.Values.Where(value => value != null))
            {
                flag.Dispose();
            }
            _soraCountryFlagCache.Clear();
            _soraDefaultCountryIcon?.Dispose();
            _soraDefaultCountryIcon = null;
        }

        private string[] GetSoraProtocolDisplay(VmessItem item)
        {
            if (item.configType != EConfigType.Custom)
            {
                return BuildSoraProtocolDisplay(GetSoraProtocolName(item), item.network, item.streamSecurity);
            }

            string path = File.Exists(item.address) ? item.address : Utils.GetConfigPath(item.address);
            long stamp = File.Exists(path) ? File.GetLastWriteTimeUtc(path).Ticks : 0L;
            if (_soraProtocolDisplayCache.TryGetValue(path, out SoraProtocolDisplay cached) && cached.Stamp == stamp)
            {
                return cached.Values;
            }

            string[] values = new[] { "XRAY", "JSON" };
            try
            {
                JObject document = JObject.Parse(File.ReadAllText(path));
                JObject outbound = (document["outbounds"] as JArray)?.OfType<JObject>().FirstOrDefault(candidate =>
                {
                    string protocol = (string)candidate["protocol"];
                    return !string.Equals(protocol, "freedom", StringComparison.OrdinalIgnoreCase)
                        && !string.Equals(protocol, "blackhole", StringComparison.OrdinalIgnoreCase)
                        && !string.Equals(protocol, "dns", StringComparison.OrdinalIgnoreCase);
                });
                JObject stream = outbound?["streamSettings"] as JObject;
                values = BuildSoraProtocolDisplay((string)outbound?["protocol"], (string)stream?["network"], (string)stream?["security"], "JSON");
            }
            catch (Exception exception)
            {
                Utils.SaveLog("Не удалось прочитать протокол импортированной конфигурации.", exception);
            }
            _soraProtocolDisplayCache[path] = new SoraProtocolDisplay { Stamp = stamp, Values = values };
            return values;
        }

        private static string[] BuildSoraProtocolDisplay(params string[] values)
        {
            return values
                .Where(value => !string.IsNullOrWhiteSpace(value))
                .Select(value => value.Trim().ToUpperInvariant())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }

        private static void DrawSoraProtocolLine(Graphics graphics, Rectangle bounds, string[] values, Font primaryFont, Font secondaryFont)
        {
            int x = bounds.Left;
            for (int index = 0; index < values.Length && x < bounds.Right; index++)
            {
                Font font = index == 0 ? primaryFont : secondaryFont;
                Color color = index == 0 ? Color.FromArgb(224, 224, 228) : HappMuted;
                Size size = TextRenderer.MeasureText(graphics, values[index], font, Size.Empty, TextFormatFlags.NoPadding | TextFormatFlags.SingleLine);
                int available = bounds.Right - x;
                TextRenderer.DrawText(graphics, values[index], font, new Rectangle(x, bounds.Top, available, bounds.Height), color, TextFormatFlags.NoPadding | TextFormatFlags.EndEllipsis | TextFormatFlags.NoPrefix | TextFormatFlags.SingleLine | TextFormatFlags.VerticalCenter);
                x += Math.Min(size.Width, available);
                if (index < values.Length - 1 && x + 14 < bounds.Right)
                {
                    TextRenderer.DrawText(graphics, "/", secondaryFont, new Rectangle(x + 4, bounds.Top, 10, bounds.Height), Color.FromArgb(174, 174, 180), TextFormatFlags.NoPadding | TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
                    x += 17;
                }
            }
        }

        private sealed class SoraProtocolDisplay
        {
            internal long Stamp { get; set; }
            internal string[] Values { get; set; }
        }

        private void ShowHappServerMenu()
        {
            var menu = BuildHappMenu();
            menu.Items.Add("Добавить", HappIconLoader.Load("plus-square", HappText), (sender, args) => ShowHappAddConfiguration());
            menu.Items.Add("Проверить все серверы", HappIconLoader.Load("gauge", HappText), (sender, args) => TestAllCommunityServers());
            if (GetLvSelectedIndex(false) >= 0)
            {
                menu.Items.Add(new ToolStripSeparator());
                menu.Items.Add("Настройки сервера", null, (sender, args) => ShowSoraServerEditor());
                menu.Items.Add("Копировать ссылку", HappIconLoader.Load("copy", HappText), (sender, args) => menuExport2ShareUrl_Click(null, null));
                menu.Items.Add("Удалить", HappIconLoader.Load("trash", HappText), (sender, args) => DeleteSelectedSoraServers());
            }
            menu.Show(Cursor.Position);
        }

        private void ShowHappModeMenu()
        {
            var menu = BuildHappMenu();
            var proxy = (ToolStripMenuItem)menu.Items.Add("Для приложений", null, (sender, args) => SetHappConnectionMode(false));
            proxy.Checked = !_happUseTun;
            var tun = (ToolStripMenuItem)menu.Items.Add("Для всей системы (TUN)", null, (sender, args) => SetHappConnectionMode(true));
            tun.Checked = _happUseTun;
            menu.Show(Cursor.Position);
        }

        private void SetHappConnectionMode(bool useTun)
        {
            _happUseTun = useTun;
            if (_happModeButton == null)
            {
                return;
            }
            _happModeButton.Text = useTun ? "TUN" : SoraText.Translate("Прокси");
            _happModeButton.AccessibleName = SoraText.Translate("Режим подключения: ") + _happModeButton.Text;
        }

        private ContextMenuStrip BuildHappMenu()
        {
            var menu = new ContextMenuStrip(components) { BackColor = Color.FromArgb(64, 64, 64), ForeColor = HappText, Font = new Font("Segoe UI", 9F), ShowImageMargin = true, Renderer = new ToolStripProfessionalRenderer(new HappMenuColors()) };
            menu.Opening += (sender, args) => SoraText.Apply(menu.Items);
            return menu;
        }

        private void ShowHappPage(Control page)
        {
            SoraText.Apply(page);
            if (page.Parent != _happPageHost) { page.Dock = DockStyle.Fill; _happPageHost.Controls.Add(page); }
            page.BringToFront(); page.Visible = true;
            foreach (Control sibling in _happPageHost.Controls) if (sibling != page) sibling.Visible = false;
            Invalidate(true);
            Update();
        }

        private void DragHappWindow(object sender, MouseEventArgs args)
        {
            if (args.Button != MouseButtons.Left) return;
            ReleaseCapture(); SendMessage(Handle, 0xA1, new IntPtr(2), IntPtr.Zero);
        }

        private void HandleHappShortcut(object sender, KeyEventArgs args)
        {
            if (_happServerPage?.Visible != true)
            {
                return;
            }
            if (args.Control && args.KeyCode == Keys.V)
            {
                ShowHappAddConfiguration();
            }
            else if (args.Control && args.KeyCode == Keys.F)
            {
                _communitySearch?.Focus();
                _communitySearch?.SelectAll();
            }
            else if (!args.Control && args.KeyCode == Keys.Delete)
            {
                DeleteSelectedSoraServers();
            }
            else
            {
                return;
            }
            args.Handled = true;
            args.SuppressKeyPress = true;
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
