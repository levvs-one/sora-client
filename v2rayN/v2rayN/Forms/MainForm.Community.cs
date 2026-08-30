using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Globalization;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using v2rayN.Handler;
using v2rayN.Mode;
using v2rayN.Tool;

namespace v2rayN.Forms
{
    public partial class MainForm
    {
        internal static readonly Color CommunityAccent = Color.FromArgb(244, 244, 245);
        internal static readonly Color CommunityAccentHover = Color.FromArgb(218, 218, 221);
        internal static readonly Color CommunityBackground = Color.FromArgb(20, 20, 22);
        internal static readonly Color CommunitySidebar = Color.FromArgb(16, 16, 17);
        internal static readonly Color CommunitySidebarHover = Color.FromArgb(45, 45, 48);
        internal static readonly Color CommunityText = Color.FromArgb(247, 247, 248);
        internal static readonly Color CommunityMuted = Color.FromArgb(196, 196, 201);
        internal static readonly Color CommunityBorder = Color.FromArgb(128, 128, 132);
        internal static readonly Color CommunityRowAlternate = Color.FromArgb(31, 31, 33);
        internal static readonly Color CommunitySuccess = Color.FromArgb(247, 247, 248);

        private Label _communityConnectionStatus;
        private Label _communityActiveServer;
        private Button _communityConnect;
        private Button _communityTun;
        private Button _communityDisconnect;
        private TextBox _communitySearch;
        private Timer _communitySearchTimer;
        private ImageList _communityRowHeight;
        private Panel _communityEmptyState;

        private void ApplyCommunityLayout()
        {
            SuspendLayout();

            AutoScaleMode = AutoScaleMode.Dpi;
            BackColor = CommunityBackground;
            Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
            ForeColor = CommunityText;
            MinimumSize = new Size(920, 600);
            Size = new Size(1120, 720);
            StartPosition = FormStartPosition.CenterScreen;
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            notifyMain.Icon = Icon;
            notifyMain.Text = "Sora";

            tsMain.Visible = false;
            panel1.Visible = false;
            gbServers.Controls.Remove(scServers);
            scBig.Panel1.Controls.Clear();
            scBig.Panel1.Controls.Add(scServers);
            scServers.Dock = DockStyle.Fill;
            scServers.Panel2Collapsed = true;
            scServers.SplitterWidth = 1;

            scBig.Dock = DockStyle.Fill;
            scBig.Orientation = Orientation.Horizontal;
            scBig.SplitterWidth = 1;
            scBig.BackColor = CommunityBorder;
            scBig.Panel1.BackColor = Color.White;
            scBig.Panel2.BackColor = Color.White;
            scBig.Panel2MinSize = 124;
            mainMsgControl.Dock = DockStyle.Fill;
            ApplyCommunityLogStyle(mainMsgControl);

            tabGroup.Dock = DockStyle.Fill;
            tabGroup.Font = new Font("Segoe UI Semibold", 9F, FontStyle.Regular, GraphicsUnit.Point);
            tabGroup.Appearance = TabAppearance.FlatButtons;
            tabGroup.DrawMode = TabDrawMode.OwnerDrawFixed;
            tabGroup.ItemSize = new Size(122, 30);
            tabGroup.SizeMode = TabSizeMode.Fixed;
            tabGroup.Padding = new Point(10, 4);
            tabGroup.DrawItem += DrawCommunityGroupTab;
            lvServers.BorderStyle = BorderStyle.None;
            lvServers.BackColor = Color.White;
            lvServers.ForeColor = CommunityText;
            lvServers.Font = new Font("Segoe UI", 9F, FontStyle.Regular, GraphicsUnit.Point);
            lvServers.GridLines = false;
            lvServers.HideSelection = false;

            var serverLayout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                ColumnCount = 1,
                RowCount = 2,
                Margin = Padding.Empty,
                Padding = Padding.Empty
            };
            serverLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            serverLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 38F));
            serverLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            scServers.Panel1.Controls.Clear();
            serverLayout.Controls.Add(tabGroup, 0, 0);
            var serverArea = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                Margin = Padding.Empty
            };
            serverArea.Controls.Add(lvServers);
            lvServers.Dock = DockStyle.Fill;
            serverLayout.Controls.Add(serverArea, 0, 1);
            scServers.Panel1.Controls.Add(serverLayout);

            _communityEmptyState = BuildCommunityEmptyState();
            serverArea.Controls.Add(_communityEmptyState);
            _communityEmptyState.BringToFront();

            _communityRowHeight = new ImageList(components)
            {
                ImageSize = new Size(1, 34),
                ColorDepth = ColorDepth.Depth32Bit
            };
            lvServers.SmallImageList = _communityRowHeight;

            var root = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                BackColor = CommunityBackground,
                ColumnCount = 2,
                RowCount = 2,
                Margin = Padding.Empty,
                Padding = Padding.Empty
            };
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 200F));
            root.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, 80F));
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

            var sidebar = BuildCommunitySidebar();
            root.Controls.Add(sidebar, 0, 0);
            root.SetRowSpan(sidebar, 2);
            root.Controls.Add(BuildCommunityHeader(), 1, 0);
            root.Controls.Add(BuildCommunityWorkspace(), 1, 1);

            Controls.Clear();
            Controls.Add(root);
            ResumeLayout(true);

            Shown += (sender, args) =>
            {
                if (scBig.Height > 300)
                {
                    scBig.SplitterDistance = Math.Max(260, scBig.Height - 168);
                }
                UpdateCommunityActiveServer();
                UpdateCommunityConnectionState(config == null ? ESysProxyType.ForcedClear : config.sysProxyType);
                UpdateCommunityEmptyState();
            };
        }

        private Panel BuildCommunityEmptyState()
        {
            var panel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                Visible = false
            };
            var title = new Label
            {
                AutoSize = true,
                Location = new Point(32, 38),
                Text = "Добавьте первый сервер",
                ForeColor = CommunityText,
                Font = new Font("Segoe UI Semibold", 13F, FontStyle.Bold)
            };
            var text = new Label
            {
                AutoSize = true,
                Location = new Point(33, 72),
                Text = "Скопируйте ссылку подключения и импортируйте её из буфера обмена.",
                ForeColor = CommunityMuted,
                Font = new Font("Segoe UI", 9F)
            };
            var import = CreateActionButton("Импортировать из буфера", () => menuAddServers_Click(this, EventArgs.Empty), true);
            import.Location = new Point(32, 108);
            import.AutoSize = false;
            import.Size = new Size(196, 34);
            panel.Controls.Add(title);
            panel.Controls.Add(text);
            panel.Controls.Add(import);
            return panel;
        }

        private static void ApplyCommunityLogStyle(Control root)
        {
            foreach (Control child in root.Controls.Cast<Control>().ToArray())
            {
                if (child is GroupBox group)
                {
                    TextBox log = group.Controls.OfType<TextBox>().FirstOrDefault();
                    StatusStrip status = group.Controls.OfType<StatusStrip>().FirstOrDefault();
                    if (log != null && status != null)
                    {
                        var logLayout = new TableLayoutPanel
                        {
                            Dock = DockStyle.Fill,
                            BackColor = Color.White,
                            ColumnCount = 1,
                            RowCount = 3,
                            Padding = new Padding(12, 6, 12, 6)
                        };
                        logLayout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
                        logLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 24F));
                        logLayout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
                        logLayout.RowStyles.Add(new RowStyle(SizeType.Absolute, 22F));
                        var title = new Label
                        {
                            Dock = DockStyle.Fill,
                            Text = "Журнал подключения",
                            Font = new Font("Segoe UI Semibold", 8.5F),
                            ForeColor = CommunityMuted,
                            TextAlign = ContentAlignment.MiddleLeft
                        };
                        log.Parent = logLayout;
                        log.Dock = DockStyle.Fill;
                        log.Font = new Font("Consolas", 8.5F);
                        status.Parent = logLayout;
                        status.Dock = DockStyle.Fill;
                        status.SizingGrip = false;
                        status.BackColor = Color.White;
                        logLayout.Controls.Add(title, 0, 0);
                        logLayout.Controls.Add(log, 0, 1);
                        logLayout.Controls.Add(status, 0, 2);
                        root.Controls.Add(logLayout);
                        logLayout.BringToFront();
                        group.Visible = false;
                    }
                }
                else if (child is TextBox text)
                {
                    text.Font = new Font("Consolas", 8.5F);
                }
                ApplyCommunityLogStyle(child);
            }
        }

        private Control BuildCommunitySidebar()
        {
            var sidebar = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = CommunitySidebar,
                Margin = new Padding(12),
                Padding = new Padding(12, 16, 12, 14)
            };
            ApplyRoundedCorners(sidebar, 16);

            var brand = new Label
            {
                Dock = DockStyle.Top,
                Height = 68,
                Text = "SORA",
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 14F, FontStyle.Bold, GraphicsUnit.Point),
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 0, 0)
            };
            sidebar.Controls.Add(brand);

            var footer = new Label
            {
                Dock = DockStyle.Bottom,
                Height = 38,
                Text = "Win7 x86 · GPL-3.0",
                ForeColor = Color.FromArgb(153, 167, 181),
                Font = new Font("Segoe UI", 8.5F),
                TextAlign = ContentAlignment.MiddleCenter
            };
            sidebar.Controls.Add(footer);

            var navigation = new FlowLayoutPanel
            {
                Dock = DockStyle.Fill,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                BackColor = CommunitySidebar,
                Padding = new Padding(0, 10, 0, 0)
            };

            navigation.Controls.Add(CreateNavigationButton("Подключение", () => lvServers.Focus(), true));
            navigation.Controls.Add(CreateNavigationButton("Серверы", () => lvServers.Focus()));
            navigation.Controls.Add(CreateNavigationButton("Подписки", () => tsbSubSetting_Click(this, EventArgs.Empty)));
            navigation.Controls.Add(CreateNavigationButton("Маршруты", () => tsbRoutingSetting_Click(this, EventArgs.Empty)));
            navigation.Controls.Add(CreateNavigationButton("Настройки", () => tsbOptionSetting_Click(this, EventArgs.Empty)));
            navigation.Controls.Add(CreateNavigationButton("Резервные копии", ShowCommunityBackupMenu));
            navigation.Controls.Add(CreateNavigationButton("Диагностика", ExportCommunityDiagnostics));
            navigation.Controls.Add(CreateNavigationButton("О программе", ShowCommunityAbout));
            sidebar.Controls.Add(navigation);
            navigation.BringToFront();

            return sidebar;
        }

        private void ShowCommunityBackupMenu()
        {
            var menu = BuildHappMenu();
            menu.ShowImageMargin = false;
            menu.Items.Add("Сохранить настройки…", null, (sender, args) => MainFormHandler.Instance.BackupGuiNConfig(config));
            menu.Items.Add("Восстановить настройки…", null, (sender, args) =>
            {
                if (MainFormHandler.Instance.RestoreGuiNConfig(ref config))
                {
                    RefreshServers();
                    Global.reloadV2ray = true;
                    _ = LoadV2ray();
                }
            });
            menu.Show(Cursor.Position);
        }

        private Control BuildCommunityHeader()
        {
            var header = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                Margin = new Padding(12, 12, 12, 4),
                Padding = new Padding(20, 10, 16, 8)
            };
            ApplyRoundedSurface(header, 14, CommunityBorder);

            _communityConnectionStatus = new Label
            {
                AutoSize = true,
                Location = new Point(20, 10),
                Text = "Отключено",
                ForeColor = CommunityMuted,
                Font = new Font("Segoe UI Semibold", 10F, FontStyle.Bold)
            };
            _communityActiveServer = new Label
            {
                AutoEllipsis = true,
                Location = new Point(20, 32),
                Size = new Size(470, 18),
                Text = "Сервер не выбран",
                ForeColor = CommunityMuted,
                Font = new Font("Segoe UI", 8.5F)
            };

            _communityDisconnect = CreateHeaderButton("Отключить", Color.White, CommunityText, CommunityBorder);
            _communityDisconnect.Click += (sender, args) => DisconnectCommunity();

            _communityTun = CreateHeaderButton("TUN", Color.White, CommunityText, CommunityBorder);
            _communityTun.Width = 72;
            _communityTun.Click += async (sender, args) => await StartCommunityTunAsync();

            _communityConnect = CreateHeaderButton("Подключить", CommunityAccent, Color.White, CommunityAccent);
            _communityConnect.Click += (sender, args) =>
            {
                if (config == null || config.vmess == null || config.vmess.Count == 0)
                {
                    UI.ShowWarning("Сначала добавьте сервер или подписку.");
                    return;
                }
                StopCommunityTun();
                SetListenerType(ESysProxyType.ForcedChange);
            };

            var connectionActions = new FlowLayoutPanel
            {
                Dock = DockStyle.Right,
                Width = 320,
                BackColor = Color.White,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false,
                Padding = new Padding(0, 5, 0, 0)
            };
            connectionActions.Controls.Add(_communityConnect);
            connectionActions.Controls.Add(_communityTun);
            connectionActions.Controls.Add(_communityDisconnect);

            header.Controls.Add(_communityActiveServer);
            header.Controls.Add(_communityConnectionStatus);
            header.Controls.Add(connectionActions);
            return header;
        }

        private Control BuildCommunityWorkspace()
        {
            var workspace = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = CommunityBackground,
                Margin = Padding.Empty,
                Padding = new Padding(12, 4, 12, 12)
            };

            var body = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                BackColor = Color.White,
                ColumnCount = 1,
                RowCount = 2,
                Margin = Padding.Empty,
                Padding = Padding.Empty
            };
            ApplyRoundedSurface(body, 14, CommunityBorder);
            body.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F));
            body.RowStyles.Add(new RowStyle(SizeType.Absolute, 56F));
            body.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

            var actions = new FlowLayoutPanel
            {
                Dock = DockStyle.Top,
                Height = 56,
                BackColor = Color.White,
                FlowDirection = FlowDirection.LeftToRight,
                WrapContents = false,
                Padding = new Padding(14, 12, 14, 8)
            };

            actions.Controls.Add(CreateActionButton("Импорт", () => menuAddServers_Click(this, EventArgs.Empty), true));
            actions.Controls.Add(CreateActionButton("Добавить", () => menuAddVlessServer_Click(this, EventArgs.Empty)));
            actions.Controls.Add(CreateActionButton("Обновить подписки", () => tsbSubUpdate_Click(this, EventArgs.Empty)));
            actions.Controls.Add(CreateActionButton("Проверить задержку", TestAllCommunityServers));
            actions.Controls.Add(CreateActionButton("Выбрать лучший", SelectBestMeasuredServer));

            _communitySearch = new TextBox
            {
                Dock = DockStyle.Fill,
                BorderStyle = BorderStyle.None,
                BackColor = CommunityRowAlternate,
                Font = new Font("Segoe UI", 9F),
                ForeColor = CommunityMuted,
                Text = "Поиск серверов"
            };
            _communitySearch.Enter += (sender, args) =>
            {
                if (_communitySearch.Text == "Поиск серверов")
                {
                    _communitySearch.Text = string.Empty;
                    _communitySearch.ForeColor = CommunityText;
                }
            };
            _communitySearch.Leave += (sender, args) =>
            {
                if (string.IsNullOrWhiteSpace(_communitySearch.Text))
                {
                    _communitySearch.Text = "Поиск серверов";
                    _communitySearch.ForeColor = CommunityMuted;
                }
            };
            _communitySearchTimer = new Timer(components) { Interval = 250 };
            _communitySearchTimer.Tick += (sender, args) =>
            {
                _communitySearchTimer.Stop();
                serverFilter = _communitySearch.Text == "Поиск серверов" ? string.Empty : _communitySearch.Text.Trim();
                RefreshServers();
            };
            _communitySearch.TextChanged += (sender, args) =>
            {
                _communitySearchTimer.Stop();
                _communitySearchTimer.Start();
            };
            var searchShell = new Panel
            {
                Size = new Size(188, 32),
                Margin = new Padding(8, 0, 0, 0),
                Padding = new Padding(12, 7, 10, 4),
                BackColor = CommunityRowAlternate
            };
            ApplyRoundedSurface(searchShell, 10, CommunityBorder);
            searchShell.Controls.Add(_communitySearch);
            actions.Controls.Add(searchShell);

            body.Controls.Add(actions, 0, 0);
            body.Controls.Add(scBig, 0, 1);
            workspace.Controls.Add(body);
            return workspace;
        }

        private Button CreateNavigationButton(string text, Action action, bool active = false)
        {
            var button = new Button
            {
                Width = 152,
                Height = 38,
                Margin = new Padding(0, 0, 0, 4),
                Padding = new Padding(12, 0, 0, 0),
                Text = text,
                TextAlign = ContentAlignment.MiddleLeft,
                FlatStyle = FlatStyle.Flat,
                BackColor = active ? CommunityAccent : CommunitySidebar,
                ForeColor = Color.White,
                Font = new Font("Segoe UI Semibold", 9F),
                Cursor = Cursors.Hand,
                UseVisualStyleBackColor = false
            };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = active ? CommunityAccentHover : CommunitySidebarHover;
            button.FlatAppearance.MouseDownBackColor = CommunityAccentHover;
            button.Click += (sender, args) => action();
            ApplyRoundedCorners(button, 10);
            return button;
        }

        private Button CreateActionButton(string text, Action action, bool primary = false)
        {
            var button = new Button
            {
                AutoSize = true,
                Height = 32,
                MinimumSize = new Size(82, 32),
                Margin = new Padding(0, 0, 6, 0),
                Padding = new Padding(10, 0, 10, 0),
                Text = text,
                FlatStyle = FlatStyle.Flat,
                BackColor = primary ? CommunityAccent : Color.White,
                ForeColor = primary ? Color.White : CommunityText,
                Font = new Font("Segoe UI Semibold", 8.5F),
                Cursor = Cursors.Hand,
                UseVisualStyleBackColor = false
            };
            button.FlatAppearance.BorderColor = primary ? CommunityAccent : CommunityBorder;
            button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.MouseOverBackColor = primary ? CommunityAccentHover : CommunityRowAlternate;
            button.Click += (sender, args) => action();
            ApplyRoundedCorners(button, 9);
            return button;
        }

        private Button CreateHeaderButton(string text, Color background, Color foreground, Color border)
        {
            var button = new Button
            {
                Width = 108,
                Height = 34,
                Text = text,
                BackColor = background,
                ForeColor = foreground,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Segoe UI Semibold", 9F),
                Cursor = Cursors.Hand,
                Margin = new Padding(0, 0, 8, 0),
                UseVisualStyleBackColor = false
            };
            button.FlatAppearance.BorderColor = border;
            button.FlatAppearance.BorderSize = 1;
            button.FlatAppearance.MouseOverBackColor = background == Color.White ? CommunityRowAlternate : CommunityAccentHover;
            ApplyRoundedCorners(button, 9);
            return button;
        }

        private void DrawCommunityGroupTab(object sender, DrawItemEventArgs args)
        {
            Rectangle bounds = tabGroup.GetTabRect(args.Index);
            bounds.Inflate(-3, -3);
            bool selected = args.Index == tabGroup.SelectedIndex;
            using (GraphicsPath path = CreateRoundedPath(bounds, 8))
            using (var fill = new SolidBrush(selected ? Color.FromArgb(229, 241, 253) : Color.White))
            using (var text = new SolidBrush(selected ? CommunityAccent : CommunityMuted))
            {
                args.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                args.Graphics.FillPath(fill, path);
                TextRenderer.DrawText(
                    args.Graphics,
                    tabGroup.TabPages[args.Index].Text,
                    tabGroup.Font,
                    bounds,
                    text.Color,
                    TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
            }
        }

        private static void ApplyRoundedCorners(Control control, int radius)
        {
            Action updateRegion = () =>
            {
                if (control.Width <= 0 || control.Height <= 0)
                {
                    return;
                }
                using (GraphicsPath path = CreateRoundedPath(new Rectangle(0, 0, control.Width, control.Height), radius))
                {
                    Region previous = control.Region;
                    control.Region = new Region(path);
                    previous?.Dispose();
                }
            };
            control.SizeChanged += (sender, args) => updateRegion();
            updateRegion();
        }

        private static void ApplyRoundedSurface(Control control, int radius, Color borderColor)
        {
            ApplyRoundedCorners(control, radius);
            control.Paint += (sender, args) =>
            {
                if (control.Width < 2 || control.Height < 2)
                {
                    return;
                }
                args.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                using (GraphicsPath path = CreateRoundedPath(new Rectangle(0, 0, control.Width - 1, control.Height - 1), radius))
                using (var pen = new Pen(borderColor))
                {
                    args.Graphics.DrawPath(pen, path);
                }
            };
        }

        private static GraphicsPath CreateRoundedPath(Rectangle bounds, int radius)
        {
            int safeRadius = Math.Max(1, Math.Min(radius, Math.Min(bounds.Width, bounds.Height) / 2));
            int diameter = safeRadius * 2;
            var path = new GraphicsPath();
            path.AddArc(bounds.Left, bounds.Top, diameter, diameter, 180, 90);
            path.AddArc(bounds.Right - diameter, bounds.Top, diameter, diameter, 270, 90);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
            path.AddArc(bounds.Left, bounds.Bottom - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }

        private void UpdateCommunityConnectionState(ESysProxyType type)
        {
            bool tunConnected = _tunModeController != null && _tunModeController.IsRunning;
            bool connected = type == ESysProxyType.ForcedChange && config != null && config.GetVmessItem(config.indexId) != null;
            if (_happConnection != null)
            {
                _happConnection.State = connected || tunConnected ? SoraConnectionState.Connected : SoraConnectionState.Disconnected;
            }
            if (_communityConnectionStatus == null)
            {
                UpdateCommunityActiveServer();
                return;
            }

            _communityConnectionStatus.Text = tunConnected ? "Подключено · TUN для всей системы" : connected ? "Подключено · системный прокси" :
                type == ESysProxyType.Unchanged ? "Ядро запущено · прокси не изменён" : "Отключено";
            _communityConnectionStatus.ForeColor = connected || tunConnected ? CommunitySuccess : CommunityMuted;
            _communityConnect.Enabled = !connected && !tunConnected;
            _communityTun.Enabled = !tunConnected;
            _communityDisconnect.Enabled = connected || tunConnected || type == ESysProxyType.Unchanged;
            UpdateCommunityActiveServer();
        }

        private async Task StartCommunityTunAsync()
        {
            if (config == null || config.vmess == null || config.vmess.Count == 0)
            {
                UI.ShowWarning("Сначала добавьте сервер или подписку.");
                return;
            }
            if (!Utils.IsAdministrator())
            {
                RestartCommunityAsAdministrator();
                return;
            }

            var active = config.GetVmessItem(config.indexId);
            if (active == null)
            {
                UI.ShowWarning("Выберите активный сервер.");
                return;
            }

            SetListenerType(ESysProxyType.ForcedClear);
            int socksPort = config.GetLocalPort(Global.InboundSocks);
            if (_communityConnectionStatus != null)
            {
                _communityConnectionStatus.Text = "Подготовка TUN…";
                _communityConnectionStatus.ForeColor = CommunityAccent;
            }
            if (!await WaitForCommunitySocksAsync(socksPort, 15000))
            {
                UpdateCommunityConnectionState(config.sysProxyType);
                UI.ShowWarning("Локальный прокси не запустился. Откройте журнал подключения.");
                return;
            }

            IPAddress[] addresses;
            try
            {
                addresses = await System.Net.Dns.GetHostAddressesAsync(active.address);
            }
            catch (Exception exception)
            {
                UpdateCommunityConnectionState(config.sysProxyType);
                UI.ShowWarning("Не удалось определить адрес сервера для безопасного маршрута: " + exception.Message);
                return;
            }
            if (!addresses.Any(address => address.AddressFamily == AddressFamily.InterNetwork))
            {
                UpdateCommunityConnectionState(config.sysProxyType);
                UI.ShowWarning("У сервера нет IPv4-адреса. Эта сборка TUN для Windows 7 работает только с IPv4.");
                return;
            }

            if (!_tunModeController.Start(
                socksPort,
                addresses,
                message => BeginInvoke(new Action(() => AppendText(false, "[TUN] " + message))),
                exitCode => BeginInvoke(new Action(() => CommunityTunExited(exitCode))),
                out string error))
            {
                UpdateCommunityConnectionState(config.sysProxyType);
                UI.ShowWarning(error);
                return;
            }

            await Task.Delay(700);
            if (!_tunModeController.IsRunning)
            {
                UpdateCommunityConnectionState(config.sysProxyType);
                UI.ShowWarning("TUN завершился при запуске. Подробности находятся в журнале подключения.");
                return;
            }
            UpdateCommunityConnectionState(config.sysProxyType);
        }

        private void RestartCommunityAsAdministrator()
        {
            try
            {
                int processId = Process.GetCurrentProcess().Id;
                Process.Start(new ProcessStartInfo
                {
                    FileName = Application.ExecutablePath,
                    Arguments = $"--tun --wait-for {processId}",
                    UseShellExecute = true,
                    Verb = "runas"
                });
                BeginInvoke(new Action(Application.Exit));
            }
            catch (Win32Exception exception) when (exception.NativeErrorCode == 1223)
            {
                UI.ShowWarning("TUN не включён: запрос прав администратора отменён.");
            }
            catch (Exception exception)
            {
                UI.ShowWarning("Не удалось перезапустить приложение с правами администратора: " + exception.Message);
            }
        }

        private static async Task<bool> WaitForCommunitySocksAsync(int port, int timeoutMilliseconds)
        {
            var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMilliseconds);
            while (DateTime.UtcNow < deadline)
            {
                using (var client = new TcpClient())
                {
                    Task connect = client.ConnectAsync(IPAddress.Loopback, port);
                    if (await Task.WhenAny(connect, Task.Delay(500)) == connect && client.Connected)
                    {
                        return true;
                    }
                }
                await Task.Delay(250);
            }
            return false;
        }

        private void CommunityTunExited(int exitCode)
        {
            UpdateCommunityConnectionState(config.sysProxyType);
            AppendText(false, $"[TUN] Процесс завершён, код {exitCode}.");
        }

        private bool StopCommunityTun()
        {
            bool wasRunning = _tunModeController != null && _tunModeController.IsRunning;
            _tunModeController?.Stop();
            if (config != null)
            {
                UpdateCommunityConnectionState(config.sysProxyType);
            }
            return wasRunning;
        }

        private void DisconnectCommunity()
        {
            if (_happConnection != null)
            {
                _happConnection.State = SoraConnectionState.Disconnecting;
            }
            StopCommunityTun();
            SetListenerType(ESysProxyType.ForcedClear);
        }

        private async Task ReloadCommunityCoreAsync(bool resumeTun)
        {
            await LoadV2ray();
            if (resumeTun)
            {
                await StartCommunityTunAsync();
            }
        }

        private void UpdateCommunityActiveServer()
        {
            if (_communityActiveServer == null || config == null)
            {
                return;
            }
            var active = config.GetVmessItem(config.indexId);
            _communityActiveServer.Text = active == null ? "Сервер не выбран" :
                string.IsNullOrWhiteSpace(active.remarks) ? "Сервер без названия" : active.remarks;
        }

        private void UpdateCommunityEmptyState()
        {
            if (_communityEmptyState == null)
            {
                return;
            }
            _communityEmptyState.Visible = lstVmess == null || lstVmess.Count == 0;
            lvServers.Visible = !_communityEmptyState.Visible;
            if (_communityEmptyState.Visible)
            {
                _communityEmptyState.BringToFront();
            }
        }

        private void TestAllCommunityServers()
        {
            if (lvServers.Items.Count == 0)
            {
                UI.ShowWarning("Нет серверов для проверки.");
                return;
            }
            menuSelectAll_Click(this, EventArgs.Empty);
            Speedtest(ESpeedActionType.Tcping);
        }

        private void SelectBestMeasuredServer()
        {
            if (lstVmess == null || lstVmess.Count == 0)
            {
                UI.ShowWarning("Нет серверов для выбора.");
                return;
            }

            var best = lstVmess
                .Select((item, index) => new { Index = index, Delay = ParseCommunityDelay(item.testResult) })
                .Where(item => item.Delay > 0)
                .OrderBy(item => item.Delay)
                .FirstOrDefault();

            if (best == null)
            {
                UI.ShowWarning("Сначала выполните проверку задержки.");
                return;
            }

            lvServers.SelectedIndices.Clear();
            lvServers.Items[best.Index].Selected = true;
            lvServers.Items[best.Index].Focused = true;
            lvServers.EnsureVisible(best.Index);
            SetDefaultServer(best.Index);
            UpdateCommunityActiveServer();
        }

        private static int ParseCommunityDelay(string value)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return -1;
            }
            var match = Regex.Match(value, @"\d+");
            return match.Success && int.TryParse(match.Value, NumberStyles.None, CultureInfo.InvariantCulture, out int delay)
                ? delay
                : -1;
        }

        private void ExportCommunityDiagnostics()
        {
            CommunityDiagnostics.Export(this);
        }

        private void ShowCommunityAbout()
        {
            UI.Show("Sora " + SoraVersion + "\r\nКлиент подключений для Windows 7\r\n\r\nОткрытый исходный код · GPL-3.0\r\nНезависимый проект");
        }
    }
}
