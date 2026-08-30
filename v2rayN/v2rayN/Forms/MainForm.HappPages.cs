using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using System.Windows.Forms;
using v2rayN.Handler;
using v2rayN.Resx;
using v2rayN.Tool;

namespace v2rayN.Forms
{
    public partial class MainForm
    {
        private readonly Dictionary<string, string> _soraSubscriptionStatuses = new Dictionary<string, string>();
        private readonly HashSet<string> _soraSubscriptionUpdates = new HashSet<string>();
        private Control _happSubscriptionsPage;
        private Control _happLogsPage;

        private Control BuildHappSettingsPage()
        {
            string routingName = "Базовые";
            if (config?.routings != null && config.routingIndex >= 0 && config.routingIndex < config.routings.Count)
            {
                routingName = GetHappRoutingDisplayName(config.routings[config.routingIndex].remarks, config.routingIndex);
            }
            var page = CreateHappScrollablePage("Настройки");
            AddHappSection(page, "Подключение",
                CreateHappSettingRow("Маршрутизация", routingName, () => ShowHappPage(BuildHappRoutingPage())),
                CreateHappSettingRow("Локальный прокси", config != null && config.inbound[0].allowLANConn ? "Доступ из локальной сети" : "Только этот компьютер", () => ShowHappPage(BuildHappInboundPage())));
            AddHappSection(page, "Данные",
                CreateHappSettingRow("Подписки", config?.subItem == null ? "0" : config.subItem.Count.ToString(), () => ShowHappPage(BuildHappSubscriptionsPage())),
                CreateHappSettingRow("Проверить задержку", "", TestAllCommunityServers));
            AddHappSection(page, "Sora",
                CreateHappSettingRow("Журнал", "", () => ShowHappPage(BuildHappLogsPage())),
                CreateHappSettingRow("Резервные копии", "", ShowSoraBackupMenu));
            AddHappSection(page, "О приложении",
                CreateHappSettingRow("О Sora", "", ShowCommunityAbout));
            return page;
        }

        private Control BuildHappSubscriptionsPage()
        {
            var page = CreateHappScrollablePage("Подписки", true);
            _happSubscriptionsPage = page;
            AddHappSection(page, "Действия",
                CreateHappSettingRow("Добавить подписку", "", ShowHappAddConfiguration),
                CreateHappSettingRow("Обновить все", "", StartSoraAllSubscriptionUpdates));

            if (config?.subItem == null || config.subItem.Count == 0)
            {
                AddHappSection(page, "Список", CreateHappSettingRow("Подписок пока нет", "Добавьте первую выше"));
                return page;
            }

            foreach (var subscription in config.subItem.ToArray())
            {
                string title = string.IsNullOrWhiteSpace(subscription.remarks) ? "Подписка" : subscription.remarks;
                string endpoint = "Некорректный URL";
                if (Uri.TryCreate(subscription.url, UriKind.Absolute, out Uri parsed))
                {
                    endpoint = parsed.IsDefaultPort ? parsed.Host : parsed.Host + ":" + parsed.Port;
                }
                int serverCount = config.vmess.Count(server => server.subid == subscription.id);
                string status = _soraSubscriptionStatuses.TryGetValue(subscription.id, out string currentStatus)
                    ? currentStatus
                    : serverCount > 0 ? "Серверов: " + serverCount : "Серверы не загружены";
                bool updating = _soraSubscriptionUpdates.Contains(subscription.id);
                string updateTitle = status.StartsWith("Не удалось", StringComparison.Ordinal) ? "Повторить" : "Обновить";
                AddHappSection(page, title,
                    CreateHappSettingRow("Источник", endpoint),
                    CreateHappSettingRow("Состояние", status),
                    CreateHappToggleRow("Включена", subscription.enabled, value =>
                    {
                        subscription.enabled = value;
                        ConfigHandler.SaveSubItem(ref config);
                    }),
                    CreateHappSettingRow(updating ? "Обновление идёт" : updateTitle, updating ? "Подождите" : "", updating ? (Action)null : () => StartSoraSubscriptionUpdate(subscription.id)),
                    CreateHappSettingRow("Удалить", "", () =>
                    {
                        if (UI.ShowYesNo("Удалить подписку «" + title + "» и добавленные ею серверы?") != DialogResult.Yes)
                        {
                            return;
                        }
                        ConfigHandler.RemoveServerViaSubid(ref config, subscription.id);
                        config.subItem.Remove(subscription);
                        ConfigHandler.SaveSubItem(ref config);
                        _soraSubscriptionStatuses.Remove(subscription.id);
                        _soraSubscriptionUpdates.Remove(subscription.id);
                        RefreshServers();
                        ShowHappPage(BuildHappSubscriptionsPage());
                    }));
            }
            return page;
        }

        private Control BuildHappRoutingPage()
        {
            ConfigHandler.InitBuiltinRouting(ref config);
            var page = CreateHappScrollablePage("Маршрутизация", true);
            AddHappSection(page, "Общие настройки",
                CreateHappSettingRow("Стратегия доменов", GetHappSettingValueDisplay(config.domainStrategy), () =>
                    ShowHappChoiceMenu(new[] { "AsIs", "IPIfNonMatch", "IPOnDemand" }, config.domainStrategy, value =>
                    {
                        config.domainStrategy = value;
                        ConfigHandler.SaveRouting(ref config);
                        SaveAndReloadHapp();
                        ShowHappPage(BuildHappRoutingPage());
                    })),
                CreateHappSettingRow("Сопоставление доменов", GetHappSettingValueDisplay(string.IsNullOrWhiteSpace(config.domainMatcher) ? "linear" : config.domainMatcher), () =>
                    ShowHappChoiceMenu(new[] { "linear", "mph" }, config.domainMatcher, value =>
                    {
                        config.domainMatcher = value;
                        ConfigHandler.SaveRouting(ref config);
                        SaveAndReloadHapp();
                        ShowHappPage(BuildHappRoutingPage());
                    })),
                CreateHappToggleRow("Расширенные правила", config.enableRoutingAdvanced, value =>
                {
                    config.enableRoutingAdvanced = value;
                    ConfigHandler.SaveRouting(ref config);
                    SaveAndReloadHapp();
                }));

            var routeRows = new List<Control>();
            for (int index = 0; index < config.routings.Count; index++)
            {
                int routeIndex = index;
                var route = config.routings[index];
                string name = GetHappRoutingDisplayName(route.remarks, index);
                string detail = route.rules == null ? "0 правил" : route.rules.Count + " правил";
                if (index == config.routingIndex)
                {
                    detail += " · выбран";
                }
                routeRows.Add(CreateHappSettingRow(name, detail, () =>
                {
                    if (ConfigHandler.SetDefaultRouting(ref config, routeIndex) == 0)
                    {
                        SaveAndReloadHapp();
                        ShowHappPage(BuildHappRoutingPage());
                    }
                }));
            }
            AddHappSection(page, "Наборы правил", routeRows.ToArray());
            return page;
        }

        private static string GetHappRoutingDisplayName(string name, int index)
        {
            if (string.IsNullOrWhiteSpace(name))
            {
                return "Набор правил " + (index + 1);
            }
            if (name.IndexOf("Whitelist", StringComparison.OrdinalIgnoreCase) >= 0) return "Белый список";
            if (name.IndexOf("Blacklist", StringComparison.OrdinalIgnoreCase) >= 0) return "Чёрный список";
            if (name.IndexOf("Global", StringComparison.OrdinalIgnoreCase) >= 0) return "Глобальный маршрут";
            if (string.Equals(name, "locked", StringComparison.OrdinalIgnoreCase)) return "Базовые правила";
            return name;
        }

        private void NormalizeSoraVisibleConfiguration()
        {
            bool routingChanged = false;
            if (config?.routings != null)
            {
                for (int index = 0; index < config.routings.Count; index++)
                {
                    string displayName = GetHappRoutingDisplayName(config.routings[index].remarks, index);
                    if (!string.Equals(config.routings[index].remarks, displayName, StringComparison.Ordinal))
                    {
                        config.routings[index].remarks = displayName;
                        routingChanged = true;
                    }
                }
            }

            bool serversChanged = false;
            if (config?.vmess != null)
            {
                foreach (var server in config.vmess.Where(server => string.Equals(server.remarks, "v2ray_custom", StringComparison.OrdinalIgnoreCase)))
                {
                    server.remarks = "Конфигурация Xray";
                    serversChanged = true;
                }
            }
            if (routingChanged) ConfigHandler.SaveRouting(ref config);
            if (routingChanged || serversChanged) ConfigHandler.SaveConfig(ref config, false);
        }

        private Control BuildHappInboundPage()
        {
            var page = CreateHappScrollablePage("Локальный прокси", true);
            if (config?.inbound == null || config.inbound.Count == 0)
            {
                AddHappSection(page, "Состояние", CreateHappSettingRow("Локальный вход не настроен", ""));
                return page;
            }
            var inbound = config.inbound[0];
            AddHappSection(page, "Локальный вход",
                CreateHappSettingRow("Адрес", inbound.allowLANConn ? "0.0.0.0" : "127.0.0.1"),
                CreateHappSettingRow("Порт", inbound.localPort.ToString()),
                CreateHappSettingRow("Протокол", inbound.protocol),
                CreateHappToggleRow("UDP", inbound.udpEnabled, value => { inbound.udpEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Определять протоколы", inbound.sniffingEnabled, value => { inbound.sniffingEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Доступ из локальной сети", inbound.allowLANConn, value => { inbound.allowLANConn = value; SaveAndReloadHapp(); }));
            AddHappSection(page, "Дополнительно",
                CreateHappToggleRow("Объединять подключения", config.muxEnabled, value => { config.muxEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Собирать статистику", config.enableStatistics, value => { config.enableStatistics = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Подробный журнал", config.logEnabled, value => { config.logEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Разрешать соединения без проверки сертификата", config.defAllowInsecure, value => { config.defAllowInsecure = value; SaveAndReloadHapp(); }),
                CreateHappSettingRow("IP-версия", GetHappSettingValueDisplay(config.domainStrategy4Freedom), () =>
                    ShowHappChoiceMenu(Global.domainStrategy4Freedoms.Where(value => !string.IsNullOrWhiteSpace(value)).ToArray(), config.domainStrategy4Freedom, value =>
                    {
                        config.domainStrategy4Freedom = value;
                        SaveAndReloadHapp();
                        ShowHappPage(BuildHappInboundPage());
                    })));
            return page;
        }

        private void ShowHappChoiceMenu(string[] values, string current, Action<string> selected)
        {
            var menu = BuildHappMenu();
            foreach (string value in values)
            {
                var item = (ToolStripMenuItem)menu.Items.Add(GetHappSettingValueDisplay(value));
                item.Checked = string.Equals(value, current, StringComparison.OrdinalIgnoreCase);
                item.Click += (sender, args) => selected(value);
            }
            menu.Show(Cursor.Position);
        }

        private static string GetHappSettingValueDisplay(string value)
        {
            if (string.Equals(value, "AsIs", StringComparison.OrdinalIgnoreCase)) return "Как есть";
            if (string.Equals(value, "IPIfNonMatch", StringComparison.OrdinalIgnoreCase)) return "IP при отсутствии совпадения";
            if (string.Equals(value, "IPOnDemand", StringComparison.OrdinalIgnoreCase)) return "IP по запросу";
            if (string.Equals(value, "UseIP", StringComparison.OrdinalIgnoreCase)) return "Использовать IP";
            if (string.Equals(value, "UseIPv4", StringComparison.OrdinalIgnoreCase)) return "Только IPv4";
            if (string.Equals(value, "UseIPv6", StringComparison.OrdinalIgnoreCase)) return "Только IPv6";
            if (string.Equals(value, "linear", StringComparison.OrdinalIgnoreCase)) return "Обычное";
            if (string.Equals(value, "mph", StringComparison.OrdinalIgnoreCase)) return "Быстрое";
            return string.IsNullOrWhiteSpace(value) ? "Не задано" : value;
        }

        private HappScrollPage CreateHappScrollablePage(string title, bool showBack = false)
        {
            var page = new HappScrollPage(HappNav, Color.FromArgb(112, 112, 116)) { Dock = DockStyle.Fill };
            var header = new Panel { Width = 850, Height = 42, BackColor = HappNav, Margin = Padding.Empty };
            int titleLeft = 0;
            if (showBack)
            {
                Image backImage = HappIconLoader.Load("caret-right", HappText);
                backImage.RotateFlip(RotateFlipType.Rotate180FlipNone);
                var back = new Button { Location = new Point(0, 5), Size = new Size(32, 32), FlatStyle = FlatStyle.Flat, BackColor = HappNav, Image = backImage, Cursor = Cursors.Hand, AccessibleName = "Назад к настройкам", AccessibleRole = AccessibleRole.PushButton };
                back.FlatAppearance.BorderSize = 0;
                back.FlatAppearance.MouseOverBackColor = HappSurface;
                back.Click += (sender, args) => ShowHappPage(BuildHappSettingsPage());
                header.Controls.Add(back);
                titleLeft = 44;
            }
            header.Controls.Add(new Label { Location = new Point(titleLeft, 0), Size = new Size(806, 42), Text = title, ForeColor = HappText, Font = new Font("Segoe UI Semibold", 17F), TextAlign = ContentAlignment.MiddleLeft });
            page.Content.Controls.Add(header);
            page.Content.Resize += (sender, args) => { foreach (Control child in page.Content.Controls) child.Width = Math.Max(400, page.Content.ClientSize.Width - 52); };
            return page;
        }

        private void AddHappSection(HappScrollPage page, string title, params Control[] rows)
        {
            page.Content.Controls.Add(new Label { Width = 850, Height = 28, Text = title, ForeColor = HappText, Font = new Font("Segoe UI Semibold", 9F), TextAlign = ContentAlignment.BottomLeft, Margin = new Padding(0, 8, 0, 6) });
            var card = new FlowLayoutPanel { Width = 850, Height = rows.Length * 44, FlowDirection = FlowDirection.TopDown, WrapContents = false, BackColor = HappSurface, Margin = Padding.Empty };
            ApplyRoundedCorners(card, 5);
            foreach (Control row in rows) { row.Width = card.Width; card.Controls.Add(row); }
            card.Resize += (sender, args) => { foreach (Control row in card.Controls) row.Width = card.ClientSize.Width; };
            page.Content.Controls.Add(card);
        }

        private Control CreateHappSettingRow(string title, string value, Action action = null)
        {
            Control row = action == null ? (Control)new Panel() : new Button();
            row.Height = 44;
            row.BackColor = HappSurface;
            row.Margin = Padding.Empty;
            row.Cursor = action == null ? Cursors.Default : Cursors.Hand;
            row.TabStop = action != null;
            row.AccessibleRole = action == null ? AccessibleRole.StaticText : AccessibleRole.PushButton;
            row.AccessibleName = string.IsNullOrEmpty(value) ? title : title + ": " + value;
            if (row is Button rowButton)
            {
                rowButton.FlatStyle = FlatStyle.Flat;
                rowButton.FlatAppearance.BorderSize = 0;
                rowButton.FlatAppearance.MouseOverBackColor = Color.FromArgb(61, 61, 65);
                rowButton.UseVisualStyleBackColor = false;
                rowButton.Text = string.Empty;
            }
            var label = new Label { Dock = DockStyle.Left, Width = 420, Padding = new Padding(16, 0, 0, 0), Text = title, ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 9F) };
            var detail = new Label { Dock = DockStyle.Right, Width = 260, Padding = new Padding(0, 0, action == null ? 16 : 36, 0), Text = value, ForeColor = HappMuted, TextAlign = ContentAlignment.MiddleRight, Font = new Font("Segoe UI", 9F) };
            if (action != null)
            {
                detail.Image = HappIconLoader.Load("caret-right", HappMuted);
                detail.ImageAlign = ContentAlignment.MiddleRight;
                row.Click += (sender, args) => action();
                label.Click += (sender, args) => action();
                detail.Click += (sender, args) => action();
                row.KeyDown += (sender, args) =>
                {
                    if (args.KeyCode == Keys.Enter || args.KeyCode == Keys.Space)
                    {
                        action();
                        args.Handled = true;
                        args.SuppressKeyPress = true;
                    }
                };
            }
            var divider = new Panel { Location = new Point(0, 43), Height = 1, Width = row.Width, Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom, BackColor = HappLine };
            row.Controls.Add(detail); row.Controls.Add(label); row.Controls.Add(divider); divider.BringToFront(); return row;
        }

        private Control CreateHappToggleRow(string title, bool value, Action<bool> changed)
        {
            var row = CreateHappSettingRow(title, string.Empty);
            var toggle = new HappToggle { Checked = value, Anchor = AnchorStyles.Top | AnchorStyles.Right, Location = new Point(row.Width - 62, 11), AccessibleName = title };
            row.Resize += (sender, args) => toggle.Left = row.ClientSize.Width - 62;
            toggle.CheckedChanged += (sender, args) => changed(toggle.Checked);
            row.Controls.Add(toggle); toggle.BringToFront(); return row;
        }

        private Control BuildHappStatisticsPage()
        {
            var page = CreateHappScrollablePage("Статистика");
            var active = config?.GetVmessItem(config.indexId);
            var activeStatistics = active == null ? null : statistics?.Statistic?.FirstOrDefault(item => item.itemId == active.indexId);
            string connectedAt = _happConnection?.ConnectedAt?.ToString("HH:mm:ss") ?? "—";
            string downloadRate = Utils.HumanFy((ulong)Math.Max(0L, Interlocked.Read(ref _happDownloadRate))) + "/s";
            string uploadRate = Utils.HumanFy((ulong)Math.Max(0L, Interlocked.Read(ref _happUploadRate))) + "/s";
            AddHappSection(page, "Сеанс",
                CreateHappSettingRow("Sora запущена", _happStartedAt.ToString("HH:mm:ss")),
                CreateHappSettingRow("Подключение установлено", connectedAt));
            AddHappSection(page, "Текущая скорость",
                CreateHappSettingRow("Загрузка", downloadRate),
                CreateHappSettingRow("Выгрузка", uploadRate));
            AddHappSection(page, "Передано через сервер",
                CreateHappSettingRow("Загрузка", activeStatistics == null ? "Нет данных" : Utils.HumanFy(activeStatistics.totalDown)),
                CreateHappSettingRow("Выгрузка", activeStatistics == null ? "Нет данных" : Utils.HumanFy(activeStatistics.totalUp)));
            return page;
        }

        private Control BuildHappLogsPage()
        {
            var page = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappNav, ColumnCount = 1, RowCount = 4, Padding = new Padding(24, 16, 24, 18) };
            _happLogsPage = page;
            page.RowStyles.Add(new RowStyle(SizeType.Absolute, 50F)); page.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F)); page.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F)); page.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            page.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Журнал", ForeColor = HappText, Font = new Font("Segoe UI Semibold", 17F), TextAlign = ContentAlignment.MiddleLeft }, 0, 0);
            page.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Ctrl+S — сохранить · Ctrl+R — создать архив диагностики", ForeColor = HappMuted, Font = new Font("Segoe UI", 9F), TextAlign = ContentAlignment.MiddleLeft }, 0, 1);
            var tabs = new FlowLayoutPanel { Dock = DockStyle.Fill, BackColor = HappNav, FlowDirection = FlowDirection.LeftToRight, WrapContents = false };
            var buttons = new[]
            {
                CreateHappLogTab("События", string.Empty, true),
                CreateHappLogTab("Ядро", @"\[(CORE|XRAY|V2RAY|SING-BOX|PROC|DAEMON)]", false),
                CreateHappLogTab("TUN", @"\[TUN]", false),
                CreateHappLogTab("Подписки", @"\[SUBSCRIPTION]", false)
            };
            foreach (Button button in buttons)
            {
                button.Click += (sender, args) =>
                {
                    foreach (Button item in buttons) item.BackColor = item == button ? Color.FromArgb(24, 24, 24) : HappNav;
                    mainMsgControl.SetCommunityFilter((string)button.Tag);
                };
                tabs.Controls.Add(button);
            }
            var actions = CreateHappSmallButton("dots-three", () =>
            {
                var menu = BuildHappMenu();
                menu.Items.Add("Сохранить текущую вкладку (.txt)", null, (sender, args) => ExportVisibleSoraLog());
                menu.Items.Add("Скопировать текущую вкладку", null, (sender, args) => Utils.SetClipboardData(mainMsgControl.GetVisibleText()));
                menu.Items.Add(new ToolStripSeparator());
                menu.Items.Add("Создать архив диагностики", null, (sender, args) => ExportCommunityDiagnostics());
                menu.Items.Add("Очистить журнал", null, (sender, args) => mainMsgControl.ClearMsg());
                menu.Show(Cursor.Position);
            });
            actions.Dock = DockStyle.None; actions.Size = new Size(38, 32); actions.Margin = Padding.Empty;
            tabs.Controls.Add(actions);
            page.Controls.Add(tabs, 0, 2);
            mainMsgControl.ApplySoraTheme(HappNav, Color.FromArgb(24, 24, 25), HappText, HappMuted, HappLine); mainMsgControl.Parent = page; mainMsgControl.Dock = DockStyle.Fill;
            page.Controls.Add(mainMsgControl, 0, 3);
            if (!_happReportShortcutWired)
            {
                _happReportShortcutWired = true;
                KeyPreview = true;
                KeyDown += (sender, args) =>
                {
                    if (_happLogsPage?.Visible == true && args.Control && args.KeyCode == Keys.R)
                    {
                        ExportCommunityDiagnostics();
                        args.Handled = true;
                    }
                    else if (_happLogsPage?.Visible == true && args.Control && args.KeyCode == Keys.S)
                    {
                        ExportVisibleSoraLog();
                        args.Handled = true;
                    }
                };
            }
            return page;
        }

        private void ExportVisibleSoraLog()
        {
            string content = mainMsgControl.GetVisibleText();
            if (string.IsNullOrWhiteSpace(content))
            {
                UI.ShowWarning("В текущей вкладке пока нет записей.");
                return;
            }

            string destinationDirectory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
            if (!Directory.Exists(destinationDirectory))
            {
                destinationDirectory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            }
            string path = Path.Combine(destinationDirectory, "Sora-Log-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".txt");
            try
            {
                File.WriteAllText(path, content, new UTF8Encoding(false));
                UI.Show("Журнал сохранён:\r\n" + path);
                Process.Start("explorer.exe", "/select,\"" + path + "\"");
            }
            catch (Exception exception)
            {
                UI.ShowError("Не удалось сохранить журнал:\r\n" + exception.Message);
            }
        }

        private Button CreateHappLogTab(string text, string pattern, bool selected)
        {
            var button = new Button { AutoSize = true, Height = 32, MinimumSize = new Size(120, 32), Text = text, Tag = pattern, FlatStyle = FlatStyle.Flat, BackColor = selected ? Color.FromArgb(24, 24, 24) : HappNav, ForeColor = HappText, Margin = Padding.Empty };
            button.FlatAppearance.BorderColor = HappLine; button.FlatAppearance.BorderSize = 1; return button;
        }

        private void ShowHappAddConfiguration()
        {
            ShowSoraImportDialog();
        }

        private void StartSoraSubscriptionUpdate(string subscriptionId)
        {
            if (string.IsNullOrWhiteSpace(subscriptionId) || _soraSubscriptionUpdates.Contains(subscriptionId))
            {
                return;
            }

            _soraSubscriptionUpdates.Add(subscriptionId);
            _soraSubscriptionStatuses[subscriptionId] = "Получение серверов…";
            RefreshSoraSubscriptionsPage();
            bool contentReceived = false;
            bool imported = false;
            Action<bool, string> update = (completed, message) =>
            {
                AppendText(false, message.StartsWith("[SUBSCRIPTION]", StringComparison.Ordinal) ? message : "[SUBSCRIPTION] " + message);
                if (!completed)
                {
                    if (message.IndexOf(ResUI.MsgGetSubscriptionSuccessfully, StringComparison.Ordinal) >= 0)
                    {
                        contentReceived = true;
                    }
                    if (message.IndexOf(ResUI.MsgUpdateSubscriptionEnd, StringComparison.Ordinal) >= 0)
                    {
                        imported = true;
                    }
                    return;
                }

                if (IsDisposed || Disposing || !IsHandleCreated)
                {
                    return;
                }
                BeginInvoke(new Action(() =>
                {
                    int serverCount = config.vmess.Count(server => server.subid == subscriptionId);
                    _soraSubscriptionStatuses[subscriptionId] = contentReceived && imported && serverCount > 0
                        ? "Серверов: " + serverCount + " · обновлено"
                        : "Не удалось получить серверы";
                    _soraSubscriptionUpdates.Remove(subscriptionId);
                    RefreshServers();
                    RefreshSoraSubscriptionsPage();
                }));
            };
            (new UpdateHandle()).UpdateSubscriptionProcess(config, subscriptionId, false, update);
        }

        private void StartSoraAllSubscriptionUpdates()
        {
            string[] subscriptionIds = config?.subItem?
                .Where(subscription => subscription.enabled && !_soraSubscriptionUpdates.Contains(subscription.id))
                .Select(subscription => subscription.id)
                .ToArray() ?? Array.Empty<string>();
            if (subscriptionIds.Length == 0)
            {
                UI.ShowWarning("Нет включённых подписок для обновления.");
                return;
            }

            foreach (string subscriptionId in subscriptionIds)
            {
                _soraSubscriptionUpdates.Add(subscriptionId);
                _soraSubscriptionStatuses[subscriptionId] = "Получение серверов…";
            }
            RefreshSoraSubscriptionsPage();
            bool anyContentReceived = false;
            Action<bool, string> update = (completed, message) =>
            {
                AppendText(false, message.StartsWith("[SUBSCRIPTION]", StringComparison.Ordinal) ? message : "[SUBSCRIPTION] " + message);
                if (!completed)
                {
                    anyContentReceived |= message.IndexOf(ResUI.MsgGetSubscriptionSuccessfully, StringComparison.Ordinal) >= 0;
                    return;
                }

                if (IsDisposed || Disposing || !IsHandleCreated)
                {
                    return;
                }
                BeginInvoke(new Action(() =>
                {
                    foreach (string subscriptionId in subscriptionIds)
                    {
                        int serverCount = config.vmess.Count(server => server.subid == subscriptionId);
                        _soraSubscriptionStatuses[subscriptionId] = anyContentReceived && serverCount > 0
                            ? "Серверов: " + serverCount
                            : "Не удалось получить серверы";
                        _soraSubscriptionUpdates.Remove(subscriptionId);
                    }
                    RefreshServers();
                    RefreshSoraSubscriptionsPage();
                }));
            };
            (new UpdateHandle()).UpdateSubscriptionProcess(config, string.Empty, false, update);
        }

        private void RefreshSoraSubscriptionsPage()
        {
            if (_happSubscriptionsPage != null && _happSubscriptionsPage.Visible)
            {
                ShowHappPage(BuildHappSubscriptionsPage());
            }
        }

        private void SaveAndReloadHapp()
        {
            ConfigHandler.SaveConfig(ref config, false); Global.reloadV2ray = true; _ = ReloadCommunityCoreAsync(_tunModeController != null && _tunModeController.IsRunning);
        }
    }
}
