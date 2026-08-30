using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using v2rayN.Handler;
using v2rayN.Mode;

namespace v2rayN.Forms
{
    public partial class MainForm
    {
        private enum SoraImportKind
        {
            Empty,
            Subscription,
            ShareLinks,
            EncodedShareLinks,
            ShadowsocksJson,
            XrayJson,
            Unsupported
        }

        private enum SoraImportOutcome
        {
            Imported,
            Duplicate,
            Failed
        }

        private sealed class SoraImportAnalysis
        {
            internal SoraImportKind Kind { get; set; }
            internal string Title { get; set; }
            internal string Detail { get; set; }
            internal int Count { get; set; }
            internal bool CanImport => Kind != SoraImportKind.Empty && Kind != SoraImportKind.Unsupported;
        }

        private void ShowSoraImportDialog()
        {
            using (var dialog = CreateSoraDialog(new Size(780, 560)))
            {
                dialog.Name = "sora.subscription.add.dialog";
                dialog.AccessibleName = "Добавить подписку";
                var title = new Label
                {
                    Location = new Point(32, 20),
                    Size = new Size(650, 32),
                    Text = "Добавить конфигурацию",
                    Font = new Font("Segoe UI Semibold", 14F),
                    ForeColor = HappText,
                    TextAlign = ContentAlignment.MiddleLeft
                };
                var subtitle = new Label
                {
                    Location = new Point(32, 54),
                    Size = new Size(700, 24),
                    Text = "Вставьте ссылку подписки или конфигурацию — формат определится автоматически.",
                    Font = new Font("Segoe UI", 8.5F),
                    ForeColor = HappMuted
                };
                var close = CreateSoraIconButton("x", () => dialog.Close());
                close.Location = new Point(724, 14);
                close.AccessibleName = "Закрыть";
                close.DialogResult = DialogResult.Cancel;

                var inputCaption = new Label
                {
                    Location = new Point(32, 88),
                    Size = new Size(716, 20),
                    Text = "Ссылка или конфигурация",
                    ForeColor = HappMuted,
                    Font = new Font("Segoe UI", 8.5F)
                };
                var inputShell = new Panel
                {
                    Location = new Point(32, 110),
                    Size = new Size(716, 128),
                    Padding = new Padding(12, 10, 12, 10),
                    BackColor = Color.FromArgb(29, 29, 31)
                };
                ApplyRoundedSurface(inputShell, 6, Color.FromArgb(91, 91, 96));
                var input = new RichTextBox
                {
                    Dock = DockStyle.Fill,
                    Multiline = true,
                    MaxLength = 4 * 1024 * 1024,
                    AcceptsTab = false,
                    ScrollBars = RichTextBoxScrollBars.None,
                    BorderStyle = BorderStyle.None,
                    BackColor = inputShell.BackColor,
                    ForeColor = HappText,
                    Font = new Font("Consolas", 9.5F),
                    WordWrap = true,
                    DetectUrls = false
                };
                input.ContextMenuStrip = CreateSoraTextContextMenu(input);
                input.Enter += (sender, args) => inputShell.Invalidate();
                input.Leave += (sender, args) => inputShell.Invalidate();
                inputShell.Controls.Add(input);

                var paste = CreateHappButton("Вставить", () => input.Text = Utils.GetClipboardData().Trim(), false);
                paste.Location = new Point(32, 252);
                paste.Size = new Size(118, 34);
                paste.TabStop = true;
                paste.AccessibleName = "Вставить конфигурацию из буфера обмена";
                paste.Image = HappIconLoader.Load("clipboard-text", HappText);
                paste.ImageAlign = ContentAlignment.MiddleLeft;
                paste.TextImageRelation = TextImageRelation.ImageBeforeText;
                paste.Padding = new Padding(6, 0, 6, 0);

                var detected = new Label
                {
                    Location = new Point(166, 248),
                    Size = new Size(582, 22),
                    ForeColor = HappText,
                    Font = new Font("Segoe UI Semibold", 9F),
                    TextAlign = ContentAlignment.MiddleLeft
                };
                var detail = new Label
                {
                    Location = new Point(166, 270),
                    Size = new Size(582, 34),
                    ForeColor = HappMuted,
                    Font = new Font("Segoe UI", 8.5F),
                    TextAlign = ContentAlignment.TopLeft
                };

                TextBox name = CreateSoraTextField(dialog, "Название — необязательно", 32, 316, 716);
                name.Name = "sora.subscription.name";
                name.AccessibleName = "Название подписки";
                Button interval = CreateSoraIntervalSelector(dialog, 32, 390, 716, 720);
                interval.Name = "sora.subscription.interval";
                SoraImportAnalysis analysis = AnalyzeSoraImport(string.Empty);
                Button import = null;
                import = CreateHappButton("Добавить", () =>
                {
                    analysis = AnalyzeSoraImport(input.Text);
                    if (!analysis.CanImport)
                    {
                        UI.ShowWarning(analysis.Detail);
                        return;
                    }
                    SoraImportOutcome outcome = ImportIntoSora(input.Text, name.Text.Trim(), (int)interval.Tag, analysis, out int imported);
                    if (outcome == SoraImportOutcome.Duplicate)
                    {
                        UI.ShowWarning("Эта подписка уже добавлена.");
                        return;
                    }
                    if (outcome == SoraImportOutcome.Failed || imported < 1)
                    {
                        UI.ShowWarning("Sora не нашла ни одной рабочей конфигурации. Проверьте ссылку или содержимое подписки.");
                        return;
                    }
                    dialog.DialogResult = DialogResult.OK;
                    dialog.Close();
                }, true);
                import.Location = new Point(624, 492);
                import.Size = new Size(124, 38);
                import.TabStop = true;
                import.AccessibleName = "Добавить распознанную конфигурацию";

                Action refreshState = () =>
                {
                    analysis = AnalyzeSoraImport(input.Text);
                    detected.Text = analysis.Title;
                    detail.Text = analysis.Detail;
                    detail.ForeColor = HappMuted;
                    import.Enabled = analysis.CanImport;
                    import.BackColor = import.Enabled ? HappAccent : Color.FromArgb(67, 67, 70);
                    import.ForeColor = import.Enabled ? HappTitle : Color.FromArgb(142, 142, 148);
                };
                input.TextChanged += (sender, args) => refreshState();
                bool automaticNameChange = false;
                string lastAutomaticName = string.Empty;
                input.TextChanged += (sender, args) =>
                {
                    SoraImportAnalysis current = AnalyzeSoraImport(input.Text);
                    if (current.Kind != SoraImportKind.Subscription) return;
                    string suggested = GetSoraSubscriptionHost(input.Text.Trim());
                    if (name.Text.Length == 0 || name.Text == lastAutomaticName)
                    {
                        automaticNameChange = true;
                        name.Text = suggested;
                        automaticNameChange = false;
                        lastAutomaticName = suggested;
                    }
                };
                name.TextChanged += (sender, args) =>
                {
                    if (!automaticNameChange && name.Text != lastAutomaticName)
                    {
                        lastAutomaticName = string.Empty;
                    }
                };

                dialog.Controls.AddRange(new Control[] { title, subtitle, close, inputCaption, inputShell, paste, detected, detail, import });
                dialog.AcceptButton = import;
                dialog.CancelButton = close;
                string clipboard = Utils.GetClipboardData().Trim();
                if (AnalyzeSoraImport(clipboard).CanImport)
                {
                    input.Text = clipboard;
                }
                refreshState();
                dialog.Shown += (sender, args) => input.Focus();
                dialog.ShowDialog(this);
            }
        }

        private SoraImportAnalysis AnalyzeSoraImport(string value)
        {
            string input = (value ?? string.Empty).Trim();
            if (input.Length == 0)
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Empty, Title = "Вставьте конфигурацию", Detail = "Sora определит формат автоматически." };
            }

            string[] lines = input.Split(new[] { '\r', '\n', '\t', ' ' }, StringSplitOptions.RemoveEmptyEntries);
            if (lines.Length == 1 && Uri.TryCreate(lines[0], UriKind.Absolute, out Uri uri) && uri.Scheme == Uri.UriSchemeHttps)
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Subscription, Title = "Подписка", Detail = uri.Host, Count = 1 };
            }
            if (lines.Length == 1 && Uri.TryCreate(lines[0], UriKind.Absolute, out uri) && uri.Scheme == Uri.UriSchemeHttp)
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Unsupported, Title = "Небезопасная HTTP-подписка", Detail = "Sora загружает подписки только по HTTPS. Замените адрес на защищённый." };
            }

            int directCount = CountSoraShareLinks(lines);
            if (directCount > 0)
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.ShareLinks, Title = "Ссылки серверов", Detail = "Распознано: " + directCount, Count = directCount };
            }

            if (TryDecodeSoraBase64(input, out string decoded))
            {
                int decodedCount = CountSoraShareLinks(decoded.Split(new[] { '\r', '\n', '\t', ' ' }, StringSplitOptions.RemoveEmptyEntries));
                if (decodedCount > 0)
                {
                    return new SoraImportAnalysis { Kind = SoraImportKind.EncodedShareLinks, Title = "Base64-подписка", Detail = "Внутри распознано серверов: " + decodedCount, Count = decodedCount };
                }
            }

            int xrayConfigurationCount = ConfigHandler.CountSoraXrayConfigurations(input);
            if (xrayConfigurationCount > 0)
            {
                return new SoraImportAnalysis
                {
                    Kind = SoraImportKind.XrayJson,
                    Title = "Набор конфигураций Xray",
                    Detail = "Совместимых с Win7 x86 серверов: " + xrayConfigurationCount,
                    Count = xrayConfigurationCount
                };
            }

            var shadowsocks = Utils.FromJson<List<SsServer>>(input);
            if (shadowsocks == null || shadowsocks.Count == 0)
            {
                shadowsocks = Utils.FromJson<SsSIP008>(input)?.servers;
            }
            if (shadowsocks != null && shadowsocks.Any(item => !string.IsNullOrWhiteSpace(item.server) && Utils.ToInt(item.server_port) > 0))
            {
                int count = shadowsocks.Count(item => !string.IsNullOrWhiteSpace(item.server) && Utils.ToInt(item.server_port) > 0);
                return new SoraImportAnalysis { Kind = SoraImportKind.ShadowsocksJson, Title = "Shadowsocks SIP008", Detail = "Распознано серверов: " + count, Count = count };
            }

            var xray = Utils.FromJson<V2rayConfig>(input);
            if (xray?.inbounds != null && xray.inbounds.Count > 0 && xray.outbounds != null && xray.outbounds.Count > 0)
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.XrayJson, Title = "Конфигурация Xray", Detail = "Будет запущена встроенным ядром Xray.", Count = 1 };
            }

            string lower = input.ToLowerInvariant();
            if (lower.Contains("proxies:") || lower.Contains("proxy-groups:") || lower.Contains("socks-port:"))
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Unsupported, Title = "Clash/Mihomo пока не поддерживается", Detail = "Нужен совместимый x86-кор; Sora не создаст нерабочую запись." };
            }
            if (lower.Contains("naiveproxy") || (lower.Contains("\"listen\"") && lower.Contains("\"proxy\"")))
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Unsupported, Title = "NaiveProxy пока не поддерживается", Detail = "В сборке нет совместимого x86-ядра NaiveProxy." };
            }
            if (lower.Contains("hysteria") || (lower.Contains("\"up\"") && lower.Contains("\"down\"") && lower.Contains("\"listen\"")))
            {
                return new SoraImportAnalysis { Kind = SoraImportKind.Unsupported, Title = "Hysteria пока не поддерживается", Detail = "В сборке нет совместимого x86-ядра Hysteria." };
            }

            return new SoraImportAnalysis { Kind = SoraImportKind.Unsupported, Title = "Формат не распознан", Detail = "Поддерживаются ссылки серверов, подписки, Base64, SIP008 и Xray JSON." };
        }

        private static int CountSoraShareLinks(IEnumerable<string> values)
        {
            return values.Count(value =>
                value.StartsWith(Global.vmessProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.vlessProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.trojanProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.ssProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.socksProtocol, StringComparison.OrdinalIgnoreCase));
        }

        private static bool TryDecodeSoraBase64(string value, out string decoded)
        {
            decoded = string.Empty;
            string compact = new string((value ?? string.Empty).Where(character => !char.IsWhiteSpace(character)).ToArray());
            if (compact.Length < 16 || compact.Any(character => !char.IsLetterOrDigit(character) && character != '+' && character != '/' && character != '-' && character != '_' && character != '='))
            {
                return false;
            }
            try
            {
                compact = compact.Replace('-', '+').Replace('_', '/');
                compact = compact.PadRight(compact.Length + (4 - compact.Length % 4) % 4, '=');
                decoded = Encoding.UTF8.GetString(Convert.FromBase64String(compact));
                return decoded.Length > 0 && decoded.Count(character => !char.IsControl(character) || character == '\r' || character == '\n' || character == '\t') >= decoded.Length * 0.9;
            }
            catch
            {
                decoded = string.Empty;
                return false;
            }
        }

        private SoraImportOutcome ImportIntoSora(string value, string subscriptionName, int updateIntervalMinutes, SoraImportAnalysis analysis, out int imported)
        {
            imported = 0;
            string input = (value ?? string.Empty).Trim();
            if (analysis.Kind == SoraImportKind.Subscription)
            {
                if (config.subItem.Any(item => string.Equals(item.url, input, StringComparison.OrdinalIgnoreCase)))
                {
                    return SoraImportOutcome.Duplicate;
                }
                if (ConfigHandler.AddSubItem(ref config, input) != 0)
                {
                    return SoraImportOutcome.Failed;
                }
                SubItem item = config.subItem.FirstOrDefault(candidate => string.Equals(candidate.url, input, StringComparison.OrdinalIgnoreCase));
                if (item != null)
                {
                    string automaticName = GetSoraSubscriptionHost(input);
                    item.remarks = !string.IsNullOrWhiteSpace(subscriptionName)
                        ? subscriptionName
                        : automaticName;
                    item.nameCustomized = !string.IsNullOrWhiteSpace(subscriptionName)
                        && !string.Equals(subscriptionName, automaticName, StringComparison.OrdinalIgnoreCase);
                    item.updateIntervalMinutes = NormalizeSoraInterval(updateIntervalMinutes);
                    item.enabled = true;
                }
                ConfigHandler.SaveSubItem(ref config);
                StartSoraSubscriptionUpdate(item?.id);
                imported = 1;
                return SoraImportOutcome.Imported;
            }

            var previousIds = new HashSet<string>(config.vmess.Select(server => server.indexId));
            if (analysis.Kind == SoraImportKind.ShareLinks || analysis.Kind == SoraImportKind.EncodedShareLinks)
            {
                string source = input;
                if (analysis.Kind == SoraImportKind.EncodedShareLinks && !TryDecodeSoraBase64(input, out source))
                {
                    return SoraImportOutcome.Failed;
                }
                string[] candidates = source.Split(new[] { '\r', '\n', '\t', ' ' }, StringSplitOptions.RemoveEmptyEntries);
                foreach (string candidate in candidates.Where(IsSoraShareLink))
                {
                    try
                    {
                        imported += ConfigHandler.AddBatchServers(ref config, candidate, string.Empty, _groupId);
                    }
                    catch (Exception exception)
                    {
                        Utils.SaveLog("Не удалось импортировать одну из ссылок: " + exception.Message);
                    }
                }
            }
            else
            {
                imported = ConfigHandler.AddBatchServers(ref config, input, string.Empty, _groupId);
            }
            if (imported > 0)
            {
                List<VmessItem> addedServers = config.vmess.Where(server => !previousIds.Contains(server.indexId)).ToList();
                if (!string.IsNullOrWhiteSpace(subscriptionName))
                {
                    for (int index = 0; index < addedServers.Count; index++)
                    {
                        addedServers[index].remarks = addedServers.Count == 1
                            ? subscriptionName
                            : subscriptionName + " " + (index + 1);
                    }
                }
                if (analysis.Kind == SoraImportKind.XrayJson)
                {
                    foreach (var server in addedServers.Where(server => string.Equals(server.remarks, "v2ray_custom", StringComparison.OrdinalIgnoreCase)))
                    {
                        server.remarks = "Конфигурация Xray";
                    }
                }
                ConfigHandler.SaveConfig(ref config);
                RefreshServers();
                Global.reloadV2ray = true;
                _ = LoadV2ray();
            }
            return imported > 0 ? SoraImportOutcome.Imported : SoraImportOutcome.Failed;
        }

        private static bool IsSoraShareLink(string value)
        {
            return value.StartsWith(Global.vmessProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.vlessProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.trojanProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.ssProtocol, StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith(Global.socksProtocol, StringComparison.OrdinalIgnoreCase);
        }

        private void ShowSoraServerEditor()
        {
            int index = GetLvSelectedIndex(false);
            if (index < 0 || index >= lstVmess.Count)
            {
                return;
            }
            VmessItem item = lstVmess[index];
            SubItem subscription = config.subItem?.FirstOrDefault(candidate => candidate.id == item.subid);
            bool locked = subscription != null && subscription.serverSettingsLocked;

            using (var dialog = CreateSoraDialog(new Size(820, item.configType == EConfigType.Custom ? 440 : 650)))
            {
                var title = new Label
                {
                    Location = new Point(32, 22),
                    Size = new Size(660, 34),
                    Text = item.configType == EConfigType.Custom ? "Пользовательская конфигурация" : "Настройки сервера",
                    Font = new Font("Segoe UI Semibold", 15F),
                    ForeColor = HappText,
                    TextAlign = ContentAlignment.MiddleLeft
                };
                var protocol = new Label
                {
                    Location = new Point(32, 58),
                    Size = new Size(680, 24),
                    Text = GetSoraProtocolName(item) + (subscription == null ? string.Empty : "  ·  " + subscription.remarks),
                    Font = new Font("Segoe UI", 9F),
                    ForeColor = locked ? Color.FromArgb(238, 178, 178) : HappMuted
                };
                var close = CreateSoraIconButton("x", () => dialog.Close());
                close.Location = new Point(764, 18);
                close.AccessibleName = "Закрыть";
                close.DialogResult = DialogResult.Cancel;
                dialog.Controls.AddRange(new Control[] { title, protocol, close });

                TextBox remarks = CreateSoraTextField(dialog, "Название", 32, 96, 756, item.remarks);
                Button save;
                if (item.configType == EConfigType.Custom)
                {
                    var details = new Panel
                    {
                        Location = new Point(32, 178),
                        Size = new Size(756, 108),
                        BackColor = Color.FromArgb(31, 31, 33)
                    };
                    ApplyRoundedSurface(details, 6, Color.FromArgb(76, 76, 80));
                    var pathName = new Label { Location = new Point(16, 1), Size = new Size(190, 52), Text = "Файл конфигурации", ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 9F) };
                    var pathValue = new Label { Location = new Point(220, 1), Size = new Size(520, 52), Text = item.address, ForeColor = HappMuted, TextAlign = ContentAlignment.MiddleRight, AutoEllipsis = true, Font = new Font("Segoe UI", 8.5F) };
                    var divider = new Panel { Location = new Point(0, 53), Size = new Size(756, 1), BackColor = Color.FromArgb(76, 76, 80) };
                    var coreName = new Label { Location = new Point(16, 55), Size = new Size(190, 51), Text = "Компонент подключения", ForeColor = HappText, TextAlign = ContentAlignment.MiddleLeft, Font = new Font("Segoe UI", 9F) };
                    var coreValue = new Label { Location = new Point(520, 55), Size = new Size(220, 51), Text = item.coreType == ECoreType.Xray ? "Xray · встроен" : item.coreType?.ToString() ?? "Не определено", ForeColor = item.coreType == ECoreType.Xray ? HappText : HappMuted, TextAlign = ContentAlignment.MiddleRight, Font = new Font("Segoe UI Semibold", 9F) };
                    details.Controls.AddRange(new Control[] { pathName, pathValue, divider, coreName, coreValue });
                    var warning = new Label
                    {
                        Location = new Point(32, 304),
                        Size = new Size(756, 42),
                        Text = item.coreType == ECoreType.Xray ? "Sora запускает этот файл встроенным Xray. Путь защищён от случайного изменения." : "Этот компонент не входит в x86-сборку Sora. Подключение работать не будет.",
                        ForeColor = HappMuted,
                        Font = new Font("Segoe UI", 9F)
                    };
                    dialog.Controls.AddRange(new Control[] { details, warning });
                    save = CreateHappButton("Сохранить", () =>
                    {
                        if (string.IsNullOrWhiteSpace(remarks.Text))
                        {
                            UI.ShowWarning("Введите название конфигурации.");
                            return;
                        }
                        item.remarks = remarks.Text.Trim();
                        ConfigHandler.SaveConfig(ref config, false);
                        RefreshServers();
                        dialog.DialogResult = DialogResult.OK;
                        dialog.Close();
                    }, true);
                    save.Location = new Point(664, 374);
                }
                else
                {
                    TextBox address = CreateSoraTextField(dialog, "Адрес", 32, 168, 548, item.address);
                    TextBox port = CreateSoraTextField(dialog, "Порт", 596, 168, 192, item.port.ToString());
                    string credentialCaption = item.configType == EConfigType.Shadowsocks || item.configType == EConfigType.Trojan || item.configType == EConfigType.Socks ? "Пароль" : "UUID / пользователь";
                    string securityCaption = item.configType == EConfigType.Socks ? "Пользователь" : "Шифрование";
                    TextBox credential = CreateSoraTextField(dialog, credentialCaption, 32, 240, 470, item.id);
                    TextBox security = CreateSoraTextField(dialog, securityCaption, 518, 240, 270, item.security);
                    TextBox network = CreateSoraTextField(dialog, "Транспорт", 32, 312, 230, item.network);
                    TextBox tls = CreateSoraTextField(dialog, "TLS", 278, 312, 230, string.IsNullOrWhiteSpace(item.streamSecurity) ? "none" : item.streamSecurity);
                    TextBox flow = CreateSoraTextField(dialog, "Режим потока (Flow)", 524, 312, 264, item.flow);
                    TextBox sni = CreateSoraTextField(dialog, "Имя сервера (SNI)", 32, 384, 368, item.sni);
                    TextBox host = CreateSoraTextField(dialog, "Заголовок Host", 416, 384, 372, item.requestHost);
                    TextBox path = CreateSoraTextField(dialog, "Путь или имя сервиса", 32, 456, 756, item.path);
                    foreach (TextBox field in new[] { remarks, address, port, credential, security, network, tls, flow, sni, host, path })
                    {
                        field.ReadOnly = locked;
                        if (locked)
                        {
                            field.ContextMenuStrip = CreateSoraTextContextMenu(field);
                        }
                    }
                    if (locked)
                    {
                        protocol.Text = "Настройки скрыты владельцем подписки  ·  " + subscription.remarks;
                    }
                    save = CreateHappButton("Сохранить", () =>
                    {
                        if (SaveSoraServer(item, remarks, address, port, credential, security, network, tls, flow, sni, host, path))
                        {
                            dialog.DialogResult = DialogResult.OK;
                            dialog.Close();
                        }
                    }, true);
                    save.Location = new Point(664, 576);
                    save.Enabled = !locked;
                    if (locked)
                    {
                        save.BackColor = Color.FromArgb(67, 67, 70);
                        save.ForeColor = Color.FromArgb(142, 142, 148);
                    }
                }
                save.Size = new Size(124, 38);
                save.TabStop = true;
                save.AccessibleName = "Сохранить настройки сервера";

                var copy = CreateHappButton("Копировать", () => CopySoraServer(item), false);
                copy.Location = new Point(32, dialog.ClientSize.Height - 64);
                copy.Size = new Size(144, 38);
                copy.TabStop = true;
                copy.AccessibleName = "Копировать ссылку сервера";
                copy.Image = HappIconLoader.Load("copy", HappText);
                copy.ImageAlign = ContentAlignment.MiddleLeft;
                copy.TextImageRelation = TextImageRelation.ImageBeforeText;
                copy.Padding = new Padding(8, 0, 8, 0);
                copy.Enabled = !string.IsNullOrWhiteSpace(ShareHandler.GetShareUrl(item));
                copy.Visible = copy.Enabled;

                var delete = CreateHappButton("Удалить", () =>
                {
                    if (UI.ShowYesNo("Удалить «" + item.remarks + "»?") != DialogResult.Yes)
                    {
                        return;
                    }
                    ConfigHandler.RemoveServer(config, new List<VmessItem> { item });
                    RefreshServers();
                    Global.reloadV2ray = true;
                    _ = LoadV2ray();
                    dialog.DialogResult = DialogResult.OK;
                    dialog.Close();
                }, false);
                delete.Location = new Point(copy.Visible ? 188 : 32, dialog.ClientSize.Height - 64);
                delete.Size = new Size(128, 38);
                delete.TabStop = true;
                delete.AccessibleName = "Удалить сервер";
                delete.ForeColor = HappText;
                delete.Image = HappIconLoader.Load("trash", delete.ForeColor);
                delete.ImageAlign = ContentAlignment.MiddleLeft;
                delete.TextImageRelation = TextImageRelation.ImageBeforeText;
                delete.Padding = new Padding(8, 0, 8, 0);

                dialog.Controls.AddRange(new Control[] { save, copy, delete });
                dialog.AcceptButton = save;
                dialog.CancelButton = close;
                dialog.ShowDialog(this);
            }
        }

        private bool SaveSoraServer(VmessItem item, TextBox remarks, TextBox address, TextBox port, TextBox credential, TextBox security, TextBox network, TextBox tls, TextBox flow, TextBox sni, TextBox host, TextBox path)
        {
            if (string.IsNullOrWhiteSpace(remarks.Text) || string.IsNullOrWhiteSpace(address.Text))
            {
                UI.ShowWarning("Название и адрес не могут быть пустыми.");
                return false;
            }
            if (!int.TryParse(port.Text.Trim(), out int parsedPort) || parsedPort < 1 || parsedPort > 65535)
            {
                UI.ShowWarning("Порт должен быть числом от 1 до 65535.");
                return false;
            }
            if (item.configType != EConfigType.Socks && string.IsNullOrWhiteSpace(credential.Text))
            {
                UI.ShowWarning("Укажите UUID или пароль сервера.");
                return false;
            }
            string normalizedNetwork = network.Text.Trim().ToLowerInvariant();
            string normalizedSecurity = security.Text.Trim().ToLowerInvariant();
            string normalizedTls = tls.Text.Trim().ToLowerInvariant();
            if (normalizedTls == "none")
            {
                normalizedTls = string.Empty;
            }
            if (normalizedNetwork.Length > 0 && !Global.networks.Contains(normalizedNetwork))
            {
                UI.ShowWarning("Транспорт: tcp, kcp, ws, h2, quic или grpc.");
                return false;
            }
            if (item.configType == EConfigType.VMess && !Global.vmessSecuritys.Contains(normalizedSecurity))
            {
                UI.ShowWarning("Для VMess выберите поддерживаемое шифрование.");
                return false;
            }
            if (item.configType == EConfigType.Shadowsocks && !LazyConfig.Instance.GetShadowsocksSecuritys(item).Contains(normalizedSecurity))
            {
                UI.ShowWarning("Выберите метод шифрования Shadowsocks, который поддерживает встроенное ядро.");
                return false;
            }
            if (item.configType == EConfigType.Socks && string.IsNullOrWhiteSpace(credential.Text) != string.IsNullOrWhiteSpace(security.Text))
            {
                UI.ShowWarning("Для SOCKS укажите и пользователя, и пароль либо оставьте оба поля пустыми.");
                return false;
            }
            if (normalizedTls != string.Empty && normalizedTls != Global.StreamSecurity && normalizedTls != Global.StreamSecurityX)
            {
                UI.ShowWarning("TLS: none, tls или xtls.");
                return false;
            }
            if (normalizedTls == Global.StreamSecurityX && item.configType != EConfigType.VLESS && item.configType != EConfigType.Trojan)
            {
                UI.ShowWarning("XTLS доступен только для VLESS и Trojan.");
                return false;
            }

            item.remarks = remarks.Text.Trim();
            item.address = address.Text.Trim();
            item.port = parsedPort;
            item.id = credential.Text.Trim();
            item.security = item.configType == EConfigType.VMess || item.configType == EConfigType.Shadowsocks ? normalizedSecurity : security.Text.Trim();
            item.network = normalizedNetwork;
            item.streamSecurity = normalizedTls;
            item.flow = flow.Text.Trim();
            item.sni = sni.Text.Trim();
            item.requestHost = host.Text.Trim();
            item.path = path.Text.Trim();
            ConfigHandler.SaveConfig(ref config);
            RefreshServers();
            Global.reloadV2ray = true;
            _ = LoadV2ray();
            return true;
        }

        private static string GetSoraProtocolName(VmessItem item)
        {
            if (item.configType == EConfigType.Custom)
            {
                return item.coreType?.ToString() ?? "Пользовательская конфигурация";
            }
            return item.configType == EConfigType.Shadowsocks ? "SHADOWSOCKS" : item.configType.ToString().ToUpperInvariant();
        }

        private static string GetSoraCountryCode(string remarks)
        {
            string value = (remarks ?? string.Empty).Trim().ToLowerInvariant();
            var countries = new[]
            {
                new[] { "france", "франц", "FR" }, new[] { "poland", "польш", "PL" },
                new[] { "sweden", "швец", "SE" }, new[] { "germany", "герман", "DE" },
                new[] { "finland", "финлянд", "FI" }, new[] { "netherlands", "нидерланд", "NL" },
                new[] { "united kingdom", "британ", "GB" }, new[] { "united states", "сша", "US" },
                new[] { "canada", "канад", "CA" }, new[] { "japan", "япон", "JP" },
                new[] { "singapore", "сингапур", "SG" }, new[] { "hong kong", "гонконг", "HK" },
                new[] { "russia", "росси", "RU" }, new[] { "ukraine", "украин", "UA" }
            };
            foreach (string[] country in countries)
            {
                if (value.Contains(country[0]) || value.Contains(country[1]))
                {
                    return country[2];
                }
            }
            return string.Empty;
        }

        private void CopySoraServer(VmessItem item)
        {
            string share = ShareHandler.GetShareUrl(item);
            if (!string.IsNullOrWhiteSpace(share))
            {
                Utils.SetClipboardData(share);
            }
        }

        private void ShowSoraBackupMenu()
        {
            var menu = BuildHappMenu();
            menu.Items.Add("Создать резервную копию", null, (sender, args) => MainFormHandler.Instance.BackupGuiNConfig(config));
            IReadOnlyList<string> backups = MainFormHandler.Instance.GetGuiNConfigBackups();
            if (backups.Count == 0)
            {
                var empty = menu.Items.Add("Копий пока нет");
                empty.Enabled = false;
            }
            else
            {
                menu.Items.Add(new ToolStripSeparator());
                var heading = menu.Items.Add("Восстановить");
                heading.Enabled = false;
                foreach (string backup in backups.Take(8))
                {
                    string path = backup;
                    string label = System.IO.File.GetLastWriteTime(path).ToString("dd.MM.yyyy  HH:mm:ss");
                    menu.Items.Add(label, null, (sender, args) =>
                    {
                        if (UI.ShowYesNo("Восстановить настройки из копии " + label + "? Текущая конфигурация будет автоматически сохранена.") != DialogResult.Yes)
                        {
                            return;
                        }
                        if (MainFormHandler.Instance.RestoreGuiNConfig(ref config, path))
                        {
                            RefreshServers();
                            Global.reloadV2ray = true;
                            _ = LoadV2ray();
                            ShowHappPage(BuildHappSettingsPage());
                        }
                    });
                }
            }
            menu.Show(Cursor.Position);
        }

        private ContextMenuStrip BuildSoraTrayMenu()
        {
            var menu = BuildHappMenu();
            menu.Items.Add("Открыть Sora", null, (sender, args) => ShowForm());
            var connection = menu.Items.Add("Подключить");
            connection.Click += async (sender, args) =>
            {
                bool active = (config != null && config.sysProxyType == ESysProxyType.ForcedChange) || (_tunModeController != null && _tunModeController.IsRunning);
                if (active)
                {
                    DisconnectCommunity();
                }
                else if (config?.GetVmessItem(config.indexId) != null)
                {
                    if (_happUseTun)
                    {
                        await StartCommunityTunAsync();
                    }
                    else
                    {
                        SetListenerType(ESysProxyType.ForcedChange);
                    }
                }
                else
                {
                    UI.ShowWarning("Сначала добавьте и выберите сервер.");
                }
            };
            menu.Items.Add("Обновить подписки", null, (sender, args) => UpdateSubscriptionProcess(string.Empty, false));
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Выйти", null, menuExit_Click);
            menu.Opening += (sender, args) =>
            {
                bool active = (config != null && config.sysProxyType == ESysProxyType.ForcedChange) || (_tunModeController != null && _tunModeController.IsRunning);
                connection.Text = active ? "Отключить" : _happUseTun ? "Подключить через TUN" : "Подключить для приложений";
            };
            return menu;
        }

        private Form CreateSoraDialog(Size size)
        {
            var dialog = new Form
            {
                FormBorderStyle = FormBorderStyle.None,
                StartPosition = FormStartPosition.CenterParent,
                ClientSize = size,
                BackColor = Color.FromArgb(37, 37, 39),
                ForeColor = HappText,
                ShowInTaskbar = false,
                MinimizeBox = false,
                MaximizeBox = false,
                KeyPreview = true
            };
            ApplyRoundedCorners(dialog, 10);
            dialog.Paint += (sender, args) =>
            {
                using (var pen = new Pen(Color.FromArgb(82, 82, 87)))
                {
                    args.Graphics.DrawRectangle(pen, 0, 0, dialog.ClientSize.Width - 1, dialog.ClientSize.Height - 1);
                }
            };
            dialog.KeyDown += (sender, args) =>
            {
                if (args.KeyCode == Keys.Escape)
                {
                    dialog.Close();
                }
            };
            return dialog;
        }

        private Button CreateSoraIconButton(string icon, Action action)
        {
            var button = new Button
            {
                Size = new Size(40, 40),
                FlatStyle = FlatStyle.Flat,
                BackColor = Color.FromArgb(37, 37, 39),
                Image = HappIconLoader.Load(icon, HappMuted),
                Cursor = Cursors.Hand,
                TabStop = false
            };
            button.FlatAppearance.BorderSize = 0;
            button.FlatAppearance.MouseOverBackColor = Color.FromArgb(54, 54, 57);
            button.Click += (sender, args) => action();
            ApplyRoundedCorners(button, 5);
            return button;
        }

        private TextBox CreateSoraTextField(Control parent, string caption, int x, int y, int width, string value = "", bool readOnly = false)
        {
            parent.Controls.Add(new Label
            {
                Location = new Point(x, y),
                Size = new Size(width, 20),
                Text = caption,
                ForeColor = HappMuted,
                Font = new Font("Segoe UI", 8.5F)
            });
            var shell = new Panel
            {
                Location = new Point(x, y + 22),
                Size = new Size(width, 38),
                Padding = new Padding(11, 9, 11, 6),
                BackColor = readOnly ? Color.FromArgb(35, 35, 38) : Color.FromArgb(44, 44, 47)
            };
            ApplyRoundedCorners(shell, 5);
            var box = new TextBox
            {
                Dock = DockStyle.Fill,
                BorderStyle = BorderStyle.None,
                BackColor = shell.BackColor,
                ForeColor = readOnly ? Color.FromArgb(157, 157, 163) : HappText,
                Font = new Font("Segoe UI", 9.5F),
                Text = value ?? string.Empty,
                ReadOnly = readOnly
            };
            box.ContextMenuStrip = CreateSoraTextContextMenu(box);
            shell.Paint += (sender, args) =>
            {
                using (var pen = new Pen(box.Focused && !box.ReadOnly ? HappAccent : Color.FromArgb(91, 91, 96)))
                {
                    args.Graphics.DrawRectangle(pen, 0, 0, shell.Width - 1, shell.Height - 1);
                }
            };
            box.Enter += (sender, args) => shell.Invalidate();
            box.Leave += (sender, args) => shell.Invalidate();
            shell.Controls.Add(box);
            parent.Controls.Add(shell);
            return box;
        }

        private void SoraServersDoubleClick(object sender, EventArgs e)
        {
            ShowSoraServerEditor();
        }

        private void SoraServersMouseUp(object sender, MouseEventArgs e)
        {
            if (e.Button == MouseButtons.Right)
            {
                ListViewItem clicked = lvServers.GetItemAt(e.X, e.Y);
                if (clicked == null)
                {
                    lvServers.SelectedItems.Clear();
                }
                else if (!clicked.Selected)
                {
                    lvServers.SelectedItems.Clear();
                    clicked.Selected = true;
                    clicked.Focused = true;
                }
                ShowHappServerMenu();
            }
        }

        private ContextMenuStrip CreateSoraTextContextMenu(TextBoxBase box)
        {
            var menu = BuildHappMenu();
            menu.ShowImageMargin = false;
            if (!box.ReadOnly)
            {
                menu.Items.Add("Вырезать", null, (sender, args) => box.Cut());
            }
            menu.Items.Add("Копировать", null, (sender, args) => box.Copy());
            if (!box.ReadOnly)
            {
                menu.Items.Add("Вставить", null, (sender, args) => box.Paste());
            }
            menu.Items.Add(new ToolStripSeparator());
            menu.Items.Add("Выделить всё", null, (sender, args) => box.SelectAll());
            return menu;
        }

        private void SoraServersKeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control && e.KeyCode == Keys.V)
            {
                ShowSoraImportDialog();
                e.Handled = true;
            }
            else if (e.Control && e.KeyCode == Keys.C)
            {
                menuExport2ShareUrl_Click(null, null);
                e.Handled = true;
            }
            else if (e.KeyCode == Keys.Enter)
            {
                menuSetDefaultServer_Click(null, null);
                e.Handled = true;
            }
            else if (e.KeyCode == Keys.Delete)
            {
                DeleteSelectedSoraServers();
                e.Handled = true;
            }
        }

        private void DeleteSelectedSoraServers()
        {
            if (GetLvSelectedIndex(false) < 0 || lstSelecteds.Count == 0)
            {
                return;
            }
            string description = lstSelecteds.Count == 1 ? "«" + lstSelecteds[0].remarks + "»" : lstSelecteds.Count + " серверов";
            if (UI.ShowYesNo("Удалить " + description + "?") != DialogResult.Yes)
            {
                return;
            }
            ConfigHandler.RemoveServer(config, lstSelecteds.ToList());
            RefreshServers();
            Global.reloadV2ray = true;
            _ = LoadV2ray();
        }

        private void ConfigureSoraServerList()
        {
            if (lvServers.Columns.Count < 10)
            {
                return;
            }
            int available = Math.Max(220, lvServers.ClientSize.Width - 108);
            for (int index = 0; index < lvServers.Columns.Count; index++)
            {
                lvServers.Columns[index].Width = 0;
            }
            lvServers.Columns[0].Width = 32;
            lvServers.Columns[(int)EServerColName.remarks].Width = available;
            lvServers.Columns[(int)EServerColName.testResult].Width = 74;
        }
    }
}
