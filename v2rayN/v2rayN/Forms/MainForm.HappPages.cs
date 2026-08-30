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
        private Timer _soraSubscriptionScheduleTimer;
        private bool _soraSubscriptionScheduleRunning;

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
            page.Name = "sora.subscriptions.page";
            page.AccessibleName = "Подписки";
            _happSubscriptionsPage = page;

            var toolbar = new Panel { Width = 850, Height = 48, BackColor = HappNav, Margin = new Padding(0, 4, 0, 8) };
            var updateAll = CreateHappButton("Обновить все", StartSoraAllSubscriptionUpdates, false);
            updateAll.Name = "sora.subscriptions.updateAll";
            updateAll.AccessibleName = "Обновить все подписки";
            updateAll.Size = new Size(132, 34);
            updateAll.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            updateAll.Location = new Point(toolbar.Width - 280, 7);
            var add = CreateHappButton("Добавить", ShowHappAddConfiguration, true);
            add.Name = "sora.subscriptions.add";
            add.AccessibleName = "Добавить подписку";
            add.Size = new Size(132, 34);
            add.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            add.Location = new Point(toolbar.Width - 136, 7);
            toolbar.Resize += (sender, args) =>
            {
                updateAll.Left = toolbar.ClientSize.Width - 280;
                add.Left = toolbar.ClientSize.Width - 136;
            };
            toolbar.Controls.Add(updateAll);
            toolbar.Controls.Add(add);
            page.Content.Controls.Add(toolbar);

            if (config?.subItem == null || config.subItem.Count == 0)
            {
                AddHappSection(page, "Все подписки", CreateHappSettingRow("Подписок пока нет", "Добавьте первую выше"));
                return page;
            }

            var list = new FlowLayoutPanel
            {
                Name = "sora.subscriptions.list",
                AccessibleName = "Список подписок",
                Width = 850,
                Height = config.subItem.Count * 72,
                FlowDirection = FlowDirection.TopDown,
                WrapContents = false,
                BackColor = HappSurface,
                Margin = Padding.Empty
            };
            ApplyRoundedCorners(list, 6);
            foreach (SubItem subscription in config.subItem.ToArray())
            {
                Control row = CreateSoraSubscriptionRow(subscription);
                row.Width = list.Width;
                list.Controls.Add(row);
            }
            list.Resize += (sender, args) => { foreach (Control row in list.Controls) row.Width = list.ClientSize.Width; };
            page.Content.Controls.Add(new Label { Width = 850, Height = 28, Text = "Все подписки", ForeColor = HappText, Font = new Font("Segoe UI Semibold", 9F), TextAlign = ContentAlignment.BottomLeft, Margin = new Padding(0, 0, 0, 6) });
            page.Content.Controls.Add(list);
            return page;
        }

        private Control CreateSoraSubscriptionRow(SubItem subscription)
        {
            string title = GetSoraSubscriptionTitle(subscription);
            string endpoint = GetSoraSubscriptionHost(subscription.url);
            int serverCount = config.vmess.Count(server => server.subid == subscription.id);
            bool updating = _soraSubscriptionUpdates.Contains(subscription.id);
            string state = updating
                ? "Обновляется…"
                : !string.IsNullOrWhiteSpace(subscription.lastUpdateError)
                    ? "Ошибка обновления"
                    : subscription.lastUpdateSuccessUtcTicks > 0
                        ? "Обновлено " + FormatSoraRelativeTime(subscription.lastUpdateSuccessUtcTicks)
                        : serverCount > 0 ? "Готова" : "Ещё не обновлялась";
            string schedule = subscription.enabled
                ? FormatSoraSchedule(subscription.updateIntervalMinutes)
                : "автообновление выключено";
            var row = new Button
            {
                Name = "sora.subscription." + subscription.id,
                Height = 72,
                Margin = Padding.Empty,
                FlatStyle = FlatStyle.Flat,
                BackColor = HappSurface,
                Cursor = Cursors.Hand,
                TabStop = true,
                UseVisualStyleBackColor = false,
                AccessibleName = title + ", " + serverCount + " серверов, " + state,
                AccessibleRole = AccessibleRole.ListItem
            };
            row.FlatAppearance.BorderSize = 0;
            row.FlatAppearance.MouseOverBackColor = Color.FromArgb(61, 61, 65);
            var name = new Label { Location = new Point(16, 8), Size = new Size(470, 22), Text = title, AutoEllipsis = true, ForeColor = HappText, Font = new Font("Segoe UI Semibold", 10F), TextAlign = ContentAlignment.MiddleLeft, BackColor = Color.Transparent };
            var detail = new Label { Location = new Point(16, 31), Size = new Size(610, 30), Text = endpoint + " · " + serverCount + " серверов\r\n" + state + " · " + schedule, AutoEllipsis = true, ForeColor = HappMuted, Font = new Font("Segoe UI", 8F), BackColor = Color.Transparent };
            var chevron = new PictureBox { Anchor = AnchorStyles.Top | AnchorStyles.Right, Location = new Point(row.Width - 38, 24), Size = new Size(20, 20), Image = HappIconLoader.Load("caret-right", HappMuted), SizeMode = PictureBoxSizeMode.CenterImage, BackColor = Color.Transparent };
            var divider = new Panel { Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom, Location = new Point(0, 71), Size = new Size(row.Width, 1), BackColor = Color.FromArgb(85, 85, 89) };
            Action open = () => ShowSoraSubscriptionEditor(subscription);
            row.Click += (sender, args) => open();
            name.Click += (sender, args) => open();
            detail.Click += (sender, args) => open();
            chevron.Click += (sender, args) => open();
            row.Resize += (sender, args) => { chevron.Left = row.ClientSize.Width - 38; divider.Width = row.ClientSize.Width; detail.Width = Math.Max(200, row.ClientSize.Width - 76); name.Width = Math.Max(200, row.ClientSize.Width - 76); };
            row.Controls.AddRange(new Control[] { name, detail, chevron, divider });
            return row;
        }

        private void ShowSoraSubscriptionEditor(SubItem subscription)
        {
            if (subscription == null || config.subItem.All(item => item.id != subscription.id))
            {
                return;
            }
            using (var dialog = CreateSoraDialog(new Size(760, 548)))
            {
                dialog.Name = "sora.subscription.edit.dialog";
                dialog.AccessibleName = "Настройки подписки";
                var title = new Label { Location = new Point(32, 20), Size = new Size(620, 32), Text = "Настройки подписки", Font = new Font("Segoe UI Semibold", 14F), ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft };
                var close = CreateSoraIconButton("x", () => dialog.Close());
                close.Location = new Point(704, 14);
                close.AccessibleName = "Закрыть";
                close.DialogResult = DialogResult.Cancel;
                TextBox name = CreateSoraTextField(dialog, "Название", 32, 78, 696, GetSoraSubscriptionTitle(subscription));
                name.Name = "sora.subscription.name";
                name.AccessibleName = "Название подписки";
                TextBox url = CreateSoraTextField(dialog, "Адрес подписки", 32, 154, 696, subscription.url);
                url.Name = "sora.subscription.url";
                url.AccessibleName = "Адрес подписки";
                Button interval = CreateSoraIntervalSelector(dialog, 32, 230, 696, subscription.updateIntervalMinutes);
                interval.Name = "sora.subscription.interval";

                var autoPanel = new Panel { Location = new Point(32, 306), Size = new Size(696, 48), BackColor = Color.FromArgb(44, 44, 47) };
                ApplyRoundedCorners(autoPanel, 5);
                autoPanel.Controls.Add(new Label { Dock = DockStyle.Left, Width = 540, Padding = new Padding(12, 0, 0, 0), Text = "Автообновление", ForeColor = HappText, Font = new Font("Segoe UI", 9F), TextAlign = ContentAlignment.MiddleLeft });
                var autoUpdate = new HappToggle { Checked = subscription.enabled, Location = new Point(640, 13), AccessibleName = "Автообновление «" + GetSoraSubscriptionTitle(subscription) + "»" };
                autoUpdate.Name = "sora.subscription.autoUpdate";
                autoPanel.Controls.Add(autoUpdate);

                int serverCount = config.vmess.Count(server => server.subid == subscription.id);
                string last = subscription.lastUpdateSuccessUtcTicks > 0 ? FormatSoraRelativeTime(subscription.lastUpdateSuccessUtcTicks) : "Ещё не обновлялась";
                string next = GetSoraNextUpdateDisplay(subscription);
                var state = new Label
                {
                    Location = new Point(44, 374),
                    Size = new Size(672, 62),
                    Text = serverCount + " серверов\r\nПоследнее обновление: " + last + " · следующее: " + next + (string.IsNullOrWhiteSpace(subscription.lastUpdateError) ? string.Empty : "\r\n" + subscription.lastUpdateError),
                    ForeColor = HappMuted,
                    Font = new Font("Segoe UI", 8.5F),
                    AutoEllipsis = true
                };

                Action save = () =>
                {
                    string trimmedName = name.Text.Trim();
                    string trimmedUrl = url.Text.Trim();
                    if (trimmedName.Length == 0)
                    {
                        UI.ShowWarning("Введите название подписки.");
                        return;
                    }
                    if (!Uri.TryCreate(trimmedUrl, UriKind.Absolute, out Uri parsed) || parsed.Scheme != Uri.UriSchemeHttps)
                    {
                        UI.ShowWarning("Адрес подписки должен начинаться с HTTPS.");
                        return;
                    }
                    if (config.subItem.Any(item => item.id != subscription.id && string.Equals(item.url, trimmedUrl, StringComparison.OrdinalIgnoreCase)))
                    {
                        UI.ShowWarning("Подписка с таким адресом уже добавлена.");
                        return;
                    }
                    subscription.remarks = trimmedName.Substring(0, Math.Min(80, trimmedName.Length));
                    subscription.nameCustomized = true;
                    subscription.url = trimmedUrl;
                    subscription.enabled = autoUpdate.Checked;
                    subscription.updateIntervalMinutes = (int)interval.Tag;
                    ConfigHandler.SaveSubItem(ref config);
                    dialog.DialogResult = DialogResult.OK;
                    dialog.Close();
                    RefreshSoraSubscriptionsPage();
                };

                var updateNow = CreateHappButton("Обновить сейчас", () =>
                {
                    save();
                    if (dialog.IsDisposed || dialog.DialogResult == DialogResult.OK)
                    {
                        StartSoraSubscriptionUpdate(subscription.id);
                    }
                }, false);
                updateNow.Name = "sora.subscription.updateNow";
                updateNow.Size = new Size(154, 36);
                updateNow.Location = new Point(32, 476);
                var delete = CreateHappButton("Удалить", () =>
                {
                    if (_soraSubscriptionUpdates.Contains(subscription.id))
                    {
                        UI.ShowWarning("Дождитесь завершения обновления этой подписки.");
                        return;
                    }
                    if (UI.ShowYesNo("Удалить «" + GetSoraSubscriptionTitle(subscription) + "» и все добавленные ею серверы?") != DialogResult.Yes)
                    {
                        return;
                    }
                    ConfigHandler.RemoveSubscription(ref config, subscription.id);
                    _soraSubscriptionStatuses.Remove(subscription.id);
                    dialog.DialogResult = DialogResult.OK;
                    dialog.Close();
                    RefreshServers();
                    ShowHappPage(BuildHappSubscriptionsPage());
                }, false);
                delete.Name = "sora.subscription.delete";
                delete.Size = new Size(112, 36);
                delete.Location = new Point(198, 476);
                var saveButton = CreateHappButton("Сохранить", save, true);
                saveButton.Size = new Size(128, 36);
                saveButton.Location = new Point(600, 476);
                dialog.Controls.AddRange(new Control[] { title, close, autoPanel, state, updateNow, delete, saveButton });
                dialog.AcceptButton = saveButton;
                dialog.CancelButton = close;
                dialog.ShowDialog(this);
            }
        }

        private Button CreateSoraIntervalSelector(Control parent, int x, int y, int width, int currentMinutes)
        {
            parent.Controls.Add(new Label { Location = new Point(x, y), Size = new Size(width, 20), Text = "Период обновления", ForeColor = HappMuted, Font = new Font("Segoe UI", 8.5F) });
            int selected = NormalizeSoraInterval(currentMinutes);
            var button = CreateHappButton(FormatSoraInterval(selected), null, false);
            button.Location = new Point(x, y + 22);
            button.Size = new Size(width, 38);
            button.Tag = selected;
            button.TextAlign = ContentAlignment.MiddleLeft;
            button.Padding = new Padding(12, 0, 36, 0);
            button.Image = HappIconLoader.Load("caret-right", HappMuted);
            button.ImageAlign = ContentAlignment.MiddleRight;
            button.AccessibleName = "Период обновления";
            button.Click += (sender, args) =>
            {
                var menu = BuildHappMenu();
                foreach (int minutes in new[] { 30, 60, 180, 360, 720, 1440, 4320, 10080 })
                {
                    int value = minutes;
                    var item = (ToolStripMenuItem)menu.Items.Add(FormatSoraInterval(value));
                    item.Checked = (int)button.Tag == value;
                    item.Click += (menuSender, menuArgs) => { button.Tag = value; button.Text = FormatSoraInterval(value); };
                }
                menu.Show(button, new Point(0, button.Height));
            };
            parent.Controls.Add(button);
            return button;
        }

        private static int NormalizeSoraInterval(int minutes)
        {
            int[] values = { 30, 60, 180, 360, 720, 1440, 4320, 10080 };
            return values.Contains(minutes) ? minutes : 720;
        }

        private static string FormatSoraInterval(int minutes)
        {
            if (minutes < 60) return minutes + " минут";
            if (minutes == 60) return "1 час";
            if (minutes < 1440) return minutes / 60 + " часов";
            if (minutes == 1440) return "1 день";
            return minutes / 1440 + " дней";
        }

        private static string FormatSoraSchedule(int minutes)
        {
            if (minutes == 60) return "каждый час";
            if (minutes == 1440) return "каждый день";
            return "каждые " + FormatSoraInterval(minutes);
        }

        private static string GetSoraSubscriptionTitle(SubItem subscription)
        {
            return string.IsNullOrWhiteSpace(subscription?.remarks) ? GetSoraSubscriptionHost(subscription?.url) : subscription.remarks.Trim();
        }

        private static string GetSoraSubscriptionHost(string url)
        {
            if (!Uri.TryCreate(url, UriKind.Absolute, out Uri parsed)) return "Некорректный адрес";
            string host = parsed.Host.ToLowerInvariant();
            string[] labels = host.Split('.');
            if (labels.Length > 2 && (labels[0] == "s" || labels[0] == "sub" || labels[0] == "subscribe" || labels[0] == "www"))
            {
                host = string.Join(".", labels.Skip(1));
            }
            return host;
        }

        private static string FormatSoraRelativeTime(long utcTicks)
        {
            if (utcTicks <= 0) return "никогда";
            DateTime local = new DateTime(utcTicks, DateTimeKind.Utc).ToLocalTime();
            DateTime today = DateTime.Today;
            if (local.Date == today) return "сегодня, " + local.ToString("HH:mm");
            if (local.Date == today.AddDays(-1)) return "вчера, " + local.ToString("HH:mm");
            return local.ToString("dd.MM.yyyy, HH:mm");
        }

        private static string GetSoraNextUpdateDisplay(SubItem subscription)
        {
            if (subscription == null || !subscription.enabled || subscription.updateIntervalMinutes <= 0) return "выключено";
            long basis = Math.Max(subscription.lastUpdateAttemptUtcTicks, subscription.lastUpdateSuccessUtcTicks);
            if (basis <= 0) return "при следующей проверке";
            DateTime next = new DateTime(basis, DateTimeKind.Utc).AddMinutes(subscription.updateIntervalMinutes);
            return next.ToLocalTime().ToString("dd.MM, HH:mm");
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
                CreateHappToggleRow("Собирать статистику", config.enableStatistics, SetSoraStatisticsEnabled),
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

        private async void StartSoraSubscriptionUpdate(string subscriptionId)
        {
            if (string.IsNullOrWhiteSpace(subscriptionId) || _soraSubscriptionUpdates.Contains(subscriptionId))
            {
                return;
            }
            await RunSoraSubscriptionUpdatesAsync(new[] { subscriptionId }, true);
        }

        private async void StartSoraAllSubscriptionUpdates()
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
            await RunSoraSubscriptionUpdatesAsync(subscriptionIds, false);
        }

        private async System.Threading.Tasks.Task<List<UpdateHandle.SubscriptionUpdateResult>> RunSoraSubscriptionUpdatesAsync(string[] subscriptionIds, bool includeDisabled)
        {
            foreach (string subscriptionId in subscriptionIds)
            {
                _soraSubscriptionUpdates.Add(subscriptionId);
                _soraSubscriptionStatuses[subscriptionId] = "Получение серверов…";
            }
            RefreshSoraSubscriptionsPage();
            Action<bool, string> update = (completed, message) =>
            {
                if (!IsDisposed && !Disposing && IsHandleCreated)
                {
                    BeginInvoke(new Action(() => AppendText(false, message.StartsWith("[SUBSCRIPTION]", StringComparison.Ordinal) ? message : "[SUBSCRIPTION] " + message)));
                }
            };

            List<UpdateHandle.SubscriptionUpdateResult> results;
            try
            {
                var updater = new UpdateHandle();
                results = await System.Threading.Tasks.Task.Run(async () =>
                    await updater.UpdateSubscriptionsAsync(config, subscriptionIds, false, includeDisabled, update));
                foreach (UpdateHandle.SubscriptionUpdateResult result in results)
                {
                    _soraSubscriptionStatuses[result.SubscriptionId] = result.Success
                        ? result.ServerCount + " серверов · обновлено"
                        : result.Error;
                }
            }
            catch (Exception exception)
            {
                Utils.SaveLog("Subscription batch failed", exception);
                foreach (string subscriptionId in subscriptionIds)
                {
                    _soraSubscriptionStatuses[subscriptionId] = exception.Message;
                }
                results = new List<UpdateHandle.SubscriptionUpdateResult>();
            }
            finally
            {
                foreach (string subscriptionId in subscriptionIds) _soraSubscriptionUpdates.Remove(subscriptionId);
                RefreshServers();
                RefreshSoraSubscriptionsPage();
            }
            return results;
        }

        private void StartSoraSubscriptionScheduler()
        {
            if (_soraSubscriptionScheduleTimer != null) return;
            _soraSubscriptionScheduleTimer = new Timer(components) { Interval = 30000 };
            _soraSubscriptionScheduleTimer.Tick += async (sender, args) =>
            {
                if (_soraSubscriptionScheduleRunning || config?.subItem == null) return;
                DateTime utcNow = DateTime.UtcNow;
                string[] due = config.subItem
                    .Where(item => item.enabled && item.updateIntervalMinutes > 0 && !_soraSubscriptionUpdates.Contains(item.id))
                    .Where(item =>
                    {
                        long basis = Math.Max(item.lastUpdateAttemptUtcTicks, item.lastUpdateSuccessUtcTicks);
                        return basis <= 0 || new DateTime(basis, DateTimeKind.Utc).AddMinutes(item.updateIntervalMinutes) <= utcNow;
                    })
                    .Select(item => item.id)
                    .ToArray();
                if (due.Length == 0) return;
                _soraSubscriptionScheduleRunning = true;
                try
                {
                    await RunSoraSubscriptionUpdatesAsync(due, false);
                }
                finally
                {
                    _soraSubscriptionScheduleRunning = false;
                }
            };
            _soraSubscriptionScheduleTimer.Start();
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

        private void SetSoraStatisticsEnabled(bool enabled)
        {
            config.enableStatistics = enabled;
            if (statistics == null && enabled)
            {
                statistics = new StatisticsHandler(config, UpdateStatisticsHandler) { UpdateUI = Visible };
            }
            else if (statistics != null)
            {
                statistics.Enable = enabled;
                statistics.UpdateUI = enabled && Visible;
            }
            SaveAndReloadHapp();
        }
    }
}
