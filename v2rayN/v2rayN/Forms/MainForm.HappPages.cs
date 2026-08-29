using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Threading;
using System.Windows.Forms;
using v2rayN.Handler;
using v2rayN.Tool;

namespace v2rayN.Forms
{
    public partial class MainForm
    {
        private Control BuildHappSettingsPage()
        {
            string routingName = "Базовые";
            if (config?.routings != null && config.routingIndex >= 0 && config.routingIndex < config.routings.Count)
            {
                routingName = string.IsNullOrWhiteSpace(config.routings[config.routingIndex].remarks) ? "Без названия" : config.routings[config.routingIndex].remarks;
            }
            var page = CreateHappScrollablePage("Настройки");
            AddHappSection(page, "Настройки интерфейса",
                CreateHappSettingRow("Язык", "Русский"),
                CreateHappSettingRow("Тема", "Тёмная"));
            AddHappSection(page, "Настройки туннеля",
                CreateHappSettingRow("Правила маршрутизации", routingName, () => ShowHappPage(BuildHappRoutingPage())),
                CreateHappToggleRow("Включить мультиплексор", config != null && config.muxEnabled, value => { config.muxEnabled = value; SaveAndReloadHapp(); }),
                CreateHappSettingRow("Предпочитаемый тип IP", config?.domainStrategy4Freedom ?? "AsIs"),
                CreateHappSettingRow("Inbounds", config != null && config.inbound[0].allowLANConn ? "LAN включён" : "Локально", () => ShowHappPage(BuildHappInboundPage())));
            AddHappSection(page, "Дополнительные настройки",
                CreateHappSettingRow("Подписки", config?.subItem == null ? "0" : config.subItem.Count.ToString(), () => ShowHappPage(BuildHappSubscriptionsPage())),
                CreateHappSettingRow("Пинг", "", TestAllCommunityServers),
                CreateHappToggleRow("Разрешить подключения из LAN", config != null && config.inbound[0].allowLANConn, value => { config.inbound[0].allowLANConn = value; SaveAndReloadHapp(); }));
            AddHappSection(page, "Другие",
                CreateHappSettingRow("Логи", "", () => ShowHappPage(BuildHappLogsPage())),
                CreateHappSettingRow("Резервные копии", "", ShowCommunityBackupMenu));
            AddHappSection(page, "О программе",
                CreateHappSettingRow("Часто задаваемые вопросы", "", ShowCommunityAbout),
                CreateHappSettingRow("О программе", "", ShowCommunityAbout));
            return page;
        }

        private Control BuildHappSubscriptionsPage()
        {
            var page = CreateHappScrollablePage("Подписки");
            AddHappSection(page, "Действия",
                CreateHappSettingRow("Добавить подписку", "", () =>
                {
                    ShowHappAddConfiguration();
                    ShowHappPage(BuildHappSubscriptionsPage());
                }),
                CreateHappSettingRow("Обновить все", "", () => UpdateSubscriptionProcess(string.Empty, false)));

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
                AddHappSection(page, title,
                    CreateHappSettingRow("Источник", endpoint),
                    CreateHappToggleRow("Включена", subscription.enabled, value =>
                    {
                        subscription.enabled = value;
                        ConfigHandler.SaveSubItem(ref config);
                    }),
                    CreateHappSettingRow("Обновить", "", () => UpdateSubscriptionProcess(subscription.id, false)),
                    CreateHappSettingRow("Удалить", "", () =>
                    {
                        if (UI.ShowYesNo("Удалить подписку «" + title + "» и добавленные ею серверы?") != DialogResult.Yes)
                        {
                            return;
                        }
                        ConfigHandler.RemoveServerViaSubid(ref config, subscription.id);
                        config.subItem.Remove(subscription);
                        ConfigHandler.SaveSubItem(ref config);
                        RefreshServers();
                        ShowHappPage(BuildHappSubscriptionsPage());
                    }));
            }
            return page;
        }

        private Control BuildHappRoutingPage()
        {
            ConfigHandler.InitBuiltinRouting(ref config);
            var page = CreateHappScrollablePage("Маршрутизация");
            AddHappSection(page, "Общие настройки",
                CreateHappSettingRow("Стратегия доменов", config.domainStrategy, () =>
                    ShowHappChoiceMenu(new[] { "AsIs", "IPIfNonMatch", "IPOnDemand" }, config.domainStrategy, value =>
                    {
                        config.domainStrategy = value;
                        ConfigHandler.SaveRouting(ref config);
                        SaveAndReloadHapp();
                        ShowHappPage(BuildHappRoutingPage());
                    })),
                CreateHappSettingRow("Сопоставление доменов", string.IsNullOrWhiteSpace(config.domainMatcher) ? "linear" : config.domainMatcher, () =>
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
                string name = string.IsNullOrWhiteSpace(route.remarks) ? "Набор правил " + (index + 1) : route.remarks;
                if (name.IndexOf("Whitelist", StringComparison.OrdinalIgnoreCase) >= 0) name = "Белый список";
                else if (name.IndexOf("Blacklist", StringComparison.OrdinalIgnoreCase) >= 0) name = "Чёрный список";
                else if (name.IndexOf("Global", StringComparison.OrdinalIgnoreCase) >= 0) name = "Глобальный маршрут";
                else if (string.Equals(name, "locked", StringComparison.OrdinalIgnoreCase)) name = "Базовые правила";
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

        private Control BuildHappInboundPage()
        {
            var page = CreateHappScrollablePage("Inbounds");
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
                CreateHappToggleRow("Анализ трафика", inbound.sniffingEnabled, value => { inbound.sniffingEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Доступ из LAN", inbound.allowLANConn, value => { inbound.allowLANConn = value; SaveAndReloadHapp(); }));
            AddHappSection(page, "Ядро и трафик",
                CreateHappToggleRow("Мультиплексор", config.muxEnabled, value => { config.muxEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Статистика", config.enableStatistics, value => { config.enableStatistics = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Логи ядра", config.logEnabled, value => { config.logEnabled = value; SaveAndReloadHapp(); }),
                CreateHappToggleRow("Разрешать небезопасные серверы", config.defAllowInsecure, value => { config.defAllowInsecure = value; SaveAndReloadHapp(); }),
                CreateHappSettingRow("Предпочитаемый IP", config.domainStrategy4Freedom, () =>
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
                var item = (ToolStripMenuItem)menu.Items.Add(value);
                item.Checked = string.Equals(value, current, StringComparison.OrdinalIgnoreCase);
                item.Click += (sender, args) => selected(value);
            }
            menu.Show(Cursor.Position);
        }

        private HappScrollPage CreateHappScrollablePage(string title)
        {
            var page = new HappScrollPage(HappNav, Color.FromArgb(112, 112, 116)) { Dock = DockStyle.Fill };
            page.Content.Controls.Add(new Label { Width = 850, Height = 42, Text = title, ForeColor = HappText, Font = new Font("Segoe UI Semibold", 17F), TextAlign = ContentAlignment.MiddleLeft, Margin = Padding.Empty });
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
            var row = new Panel { Height = 44, BackColor = HappSurface, Margin = Padding.Empty, Cursor = action == null ? Cursors.Default : Cursors.Hand };
            var label = new Label { Dock = DockStyle.Left, Width = 420, Padding = new Padding(16, 0, 0, 0), Text = title, ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 9F) };
            var detail = new Label { Dock = DockStyle.Right, Width = 260, Padding = new Padding(0, 0, 16, 0), Text = string.IsNullOrEmpty(value) ? "›" : value + (action == null ? "" : "  ›"), ForeColor = HappMuted, TextAlign = ContentAlignment.MiddleRight, Font = new Font("Segoe UI", 9F) };
            if (action != null) { row.Click += (sender, args) => action(); label.Click += (sender, args) => action(); detail.Click += (sender, args) => action(); }
            var divider = new Panel { Location = new Point(0, 43), Height = 1, Width = row.Width, Anchor = AnchorStyles.Left | AnchorStyles.Right | AnchorStyles.Bottom, BackColor = HappLine };
            row.Controls.Add(detail); row.Controls.Add(label); row.Controls.Add(divider); divider.BringToFront(); return row;
        }

        private Control CreateHappToggleRow(string title, bool value, Action<bool> changed)
        {
            var row = CreateHappSettingRow(title, string.Empty);
            var toggle = new HappToggle { Checked = value, Anchor = AnchorStyles.Top | AnchorStyles.Right, Location = new Point(row.Width - 62, 11) };
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
            AddHappSection(page, "Сервер",
                CreateHappSettingRow("Время начала", _happStartedAt.ToString("HH:mm:ss")),
                CreateHappSettingRow("Время подключения", connectedAt));
            AddHappSection(page, "Пропускная способность прокси",
                CreateHappSettingRow("Загрузка", downloadRate),
                CreateHappSettingRow("Выгрузка", uploadRate));
            AddHappSection(page, "Использование данных через прокси",
                CreateHappSettingRow("Загрузка", activeStatistics == null ? "Нет данных" : Utils.HumanFy(activeStatistics.totalDown)),
                CreateHappSettingRow("Выгрузка", activeStatistics == null ? "Нет данных" : Utils.HumanFy(activeStatistics.totalUp)));
            AddHappSection(page, "Прямое использование данных",
                CreateHappSettingRow("Прямая загрузка", "Нет данных"),
                CreateHappSettingRow("Прямая выгрузка", "Нет данных"));
            return page;
        }

        private Control BuildHappLogsPage()
        {
            var page = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = HappNav, ColumnCount = 1, RowCount = 4, Padding = new Padding(24, 16, 24, 18) };
            page.RowStyles.Add(new RowStyle(SizeType.Absolute, 50F)); page.RowStyles.Add(new RowStyle(SizeType.Absolute, 28F)); page.RowStyles.Add(new RowStyle(SizeType.Absolute, 42F)); page.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));
            page.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Логи", ForeColor = HappText, Font = new Font("Segoe UI Semibold", 17F), TextAlign = ContentAlignment.MiddleLeft }, 0, 0);
            page.Controls.Add(new Label { Dock = DockStyle.Fill, Text = "Ctrl+R — создать диагностический отчёт", ForeColor = HappMuted, Font = new Font("Segoe UI", 9F), TextAlign = ContentAlignment.MiddleLeft }, 0, 1);
            var tabs = new FlowLayoutPanel { Dock = DockStyle.Fill, BackColor = HappNav, FlowDirection = FlowDirection.LeftToRight, WrapContents = false };
            var buttons = new[]
            {
                CreateHappLogTab("Основной лог", string.Empty, true),
                CreateHappLogTab("Лог ядра", @"\[(CORE|XRAY|V2RAY|SING-BOX|PROC|DAEMON)]", false),
                CreateHappLogTab("Лог туннеля", @"\[TUN]", false),
                CreateHappLogTab("Лог AntiFilter", @"\[ANTIFILTER]", false),
                CreateHappLogTab("Лог подписок", @"\[SUBSCRIPTION]", false),
                CreateHappLogTab("Лог службы", @"\[(SERVICE|DAEMON|PROC)]", false),
                CreateHappLogTab("Лог пушей", @"\[PUSH]", false)
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
                menu.Items.Add("Создать отчёт", null, (sender, args) => ExportCommunityDiagnostics());
                menu.Items.Add("Очистить логи", null, (sender, args) => mainMsgControl.ClearMsg());
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
                    if (args.Control && args.KeyCode == Keys.R)
                    {
                        ExportCommunityDiagnostics();
                        args.Handled = true;
                    }
                };
            }
            return page;
        }

        private Button CreateHappLogTab(string text, string pattern, bool selected)
        {
            var button = new Button { AutoSize = true, Height = 32, MinimumSize = new Size(120, 32), Text = text, Tag = pattern, FlatStyle = FlatStyle.Flat, BackColor = selected ? Color.FromArgb(24, 24, 24) : HappNav, ForeColor = HappText, Margin = Padding.Empty };
            button.FlatAppearance.BorderColor = HappLine; button.FlatAppearance.BorderSize = 1; return button;
        }

        private void ShowHappAddConfiguration()
        {
            using (var dialog = new Form { FormBorderStyle = FormBorderStyle.None, StartPosition = FormStartPosition.CenterParent, Size = new Size(800, 658), BackColor = Color.FromArgb(37, 37, 37), ForeColor = HappText, ShowInTaskbar = false })
            {
                ApplyRoundedCorners(dialog, 10);
                var title = new Label { Location = new Point(36, 30), Size = new Size(650, 34), Text = "Добавить конфигурацию", Font = new Font("Segoe UI Semibold", 15F), ForeColor = HappText };
                var close = new Button { Location = new Point(730, 24), Size = new Size(42, 38), Text = "×", FlatStyle = FlatStyle.Flat, BackColor = dialog.BackColor, ForeColor = HappMuted, Font = new Font("Segoe UI", 17F), Cursor = Cursors.Hand, TabStop = false };
                close.FlatAppearance.BorderSize = 0; close.FlatAppearance.MouseOverBackColor = Color.FromArgb(50, 50, 52); close.Click += (sender, args) => dialog.Close();
                dialog.Controls.Add(new Label { Location = new Point(36, 84), Size = new Size(720, 20), Text = "Тип", ForeColor = HappMuted });
                var type = CreateHappDialogSelect(36, 108);
                var name = CreateHappDialogTextBox("Имя подписки", 36, 150, dialog);
                var url = CreateHappDialogTextBox("URL подписки", 36, 220, dialog);
                var hidden = CreateHappModalToggle("Скрыть настройки сервера", "Вы не сможете редактировать настройки сервера в этой подписке", 300, dialog, false);
                AddHappModalDivider(dialog, 36, 350);
                var encrypted = CreateHappModalToggle("Зашифрованная подписка", "Ссылка, которую вы добавляете, зашифрована", 364, dialog, true);
                AddHappModalDivider(dialog, 36, 412);
                var insecure = CreateHappModalToggle("Не проверять TLS-сертификаты серверов", "Применяется только к серверам из этой подписки", 426, dialog, false);
                AddHappModalDivider(dialog, 36, 474);
                dialog.Controls.Add(new Label { Location = new Point(36, 488), Size = new Size(700, 44), Text = "Если вы включите скрытые настройки сервера или добавите зашифрованную подписку, вы больше не сможете\r\nредактировать эту подписку.", ForeColor = HappText, Font = new Font("Segoe UI", 9F) });
                var add = CreateHappButton("Добавить", () =>
                {
                    string subscriptionUrl = url.Text.Trim();
                    if (config.subItem.Any(entry => string.Equals(entry.url, subscriptionUrl, StringComparison.OrdinalIgnoreCase)))
                    {
                        UI.ShowWarning("Эта подписка уже добавлена.");
                        return;
                    }
                    if (ConfigHandler.AddSubItem(ref config, subscriptionUrl) == 0)
                    {
                        var item = config.subItem.FirstOrDefault(entry => entry.url == subscriptionUrl);
                        if (item != null)
                        {
                            if (!string.IsNullOrWhiteSpace(name.Text)) item.remarks = name.Text.Trim();
                            item.serverSettingsLocked = hidden.Checked;
                            item.allowInsecure = insecure.Checked;
                        }
                        ConfigHandler.SaveSubItem(ref config); UpdateSubscriptionProcess(string.Empty, false); dialog.DialogResult = DialogResult.OK;
                    }
                }, true);
                add.Location = new Point(655, 558); add.Size = new Size(109, 34); add.Enabled = false; add.BackColor = Color.FromArgb(67, 67, 70); add.ForeColor = Color.FromArgb(142, 142, 148);
                url.TextChanged += (sender, args) =>
                {
                    add.Enabled = Uri.TryCreate(url.Text.Trim(), UriKind.Absolute, out Uri parsed) && parsed.Scheme == Uri.UriSchemeHttps;
                    add.BackColor = add.Enabled ? HappAccent : Color.FromArgb(67, 67, 70);
                    add.ForeColor = add.Enabled ? HappTitle : Color.FromArgb(142, 142, 148);
                };
                dialog.Controls.AddRange(new Control[] { title, close, type, add });
                dialog.ShowDialog(this);
            }
        }

        private Control CreateHappDialogSelect(int x, int y)
        {
            var box = new Panel { Location = new Point(x, y), Size = new Size(728, 32), BackColor = Color.FromArgb(68, 68, 68), Cursor = Cursors.Hand };
            var value = new Label { Dock = DockStyle.Fill, Padding = new Padding(10, 0, 0, 0), Text = "Подписка", ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft, Cursor = Cursors.Hand };
            Image arrowImage = HappIconLoader.Load("caret-right", HappMuted);
            arrowImage.RotateFlip(RotateFlipType.Rotate90FlipNone);
            var arrow = new PictureBox { Dock = DockStyle.Right, Width = 34, Image = arrowImage, SizeMode = PictureBoxSizeMode.CenterImage, BackColor = box.BackColor, Cursor = Cursors.Hand };
            Action show = () =>
            {
                var menu = BuildHappMenu();
                var item = menu.Items.Add("Подписка");
                item.Enabled = false;
                menu.Show(box, new Point(0, box.Height));
            };
            box.Click += (sender, args) => show(); value.Click += (sender, args) => show(); arrow.Click += (sender, args) => show();
            box.Paint += (sender, args) => { using (var pen = new Pen(Color.FromArgb(112, 112, 116))) args.Graphics.DrawRectangle(pen, 0, 0, box.Width - 1, box.Height - 1); };
            box.Controls.Add(value); box.Controls.Add(arrow); arrow.BringToFront();
            return box;
        }

        private TextBox CreateHappDialogTextBox(string caption, int x, int y, Control parent)
        {
            parent.Controls.Add(new Label { Location = new Point(x, y), Size = new Size(720, 22), Text = caption, ForeColor = HappMuted });
            var shell = new Panel { Location = new Point(x, y + 26), Size = new Size(728, 34), BackColor = Color.FromArgb(68, 68, 68), Padding = new Padding(10, 7, 10, 4) };
            var box = new TextBox { Dock = DockStyle.Fill, BackColor = shell.BackColor, ForeColor = HappText, BorderStyle = BorderStyle.None, Font = new Font("Segoe UI", 10F) };
            shell.Paint += (sender, args) => { using (var pen = new Pen(box.Focused ? HappAccent : Color.FromArgb(112, 112, 116))) args.Graphics.DrawRectangle(pen, 0, 0, shell.Width - 1, shell.Height - 1); };
            box.Enter += (sender, args) => shell.Invalidate(); box.Leave += (sender, args) => shell.Invalidate();
            shell.Controls.Add(box); parent.Controls.Add(shell); return box;
        }

        private HappToggle CreateHappModalToggle(string title, string description, int y, Control parent, bool disabled)
        {
            Color color = disabled ? Color.FromArgb(92, 92, 98) : HappText;
            parent.Controls.Add(new Label { Location = new Point(36, y), Size = new Size(580, 22), Text = title, ForeColor = color, Font = new Font("Segoe UI Semibold", 9F) });
            parent.Controls.Add(new Label { Location = new Point(36, y + 24), Size = new Size(620, 22), Text = description, ForeColor = color });
            var toggle = new HappToggle { Location = new Point(684, y + 7), Enabled = !disabled }; parent.Controls.Add(toggle); return toggle;
        }

        private static void AddHappModalDivider(Control parent, int x, int y) => parent.Controls.Add(new Panel { Location = new Point(x, y), Size = new Size(728, 1), BackColor = Color.FromArgb(73, 73, 76) });

        private void SaveAndReloadHapp()
        {
            ConfigHandler.SaveConfig(ref config, false); Global.reloadV2ray = true; _ = ReloadCommunityCoreAsync(_tunModeController != null && _tunModeController.IsRunning);
        }
    }
}
