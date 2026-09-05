using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using log4net;
using log4net.Appender;
using log4net.Config;
using log4net.Layout;
using NetSparkleUpdater;
using NetSparkleUpdater.Enums;
using NetSparkleUpdater.SignatureVerifiers;

namespace Sora.Centers
{
    internal static class Program
    {
        [STAThread]
        private static int Main(string[] args)
        {
            if (args.Length == 1 && args[0] == "--verify-release-key")
            {
                try { ReadPublicKey(); return 0; }
                catch (Exception) { return 2; }
            }
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            ConfigureLogging(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Sora", "Updates", "logs"));
            try { Application.Run(new UpdateWindow(args)); }
            finally { LogManager.Shutdown(); }
            return 0;
        }

        internal static void ConfigureLogging(string logs)
        {
            var layout = new PatternLayout("%date [%thread] %-5level %logger - [UPDATE] %message%newline");
            layout.ActivateOptions();
            var appender = new RollingFileAppender { File = Path.Combine(logs, "updates.txt"), AppendToFile = true, Encoding = new UTF8Encoding(false), MaximumFileSize = "4MB", MaxSizeRollBackups = 5, RollingStyle = RollingFileAppender.RollingMode.Size, Layout = layout };
            appender.ActivateOptions();
            BasicConfigurator.Configure(appender);
        }

        internal static string ReadPublicKey()
        {
            using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("Sora.Update.PublicKey"))
            {
                if (stream == null) throw new InvalidOperationException("В этой тестовой сборке не настроен ключ обновлений. Установка через центр отключена.");
                using (var reader = new StreamReader(stream))
                {
                    string key = reader.ReadToEnd().Trim();
                    if (Convert.FromBase64String(key).Length != 32) throw new InvalidOperationException("Ключ обновлений повреждён. Переустановите Sora из официального релиза.");
                    return key;
                }
            }
        }
    }

    internal sealed class UpdateWindow : CenterWindow
    {
        private readonly ILog _log = LogManager.GetLogger(typeof(UpdateWindow));
        private readonly Button _check;
        private readonly Button _download;
        private readonly Button _install;
        private readonly Button _cancel;
        private readonly Label _version;
        private readonly TextBox _history;
        private SparkleUpdater _updater;
        private Ed25519Checker _verifier;
        private AppCastItem _available;
        private string _verifiedPath;
        private string _application;
        private string _target;
        private bool _cancelRequested;
        private bool _downloadCompleted;

        internal UpdateWindow(string[] args) : base("Sora Update")
        {
            _check = Button("Проверить", async (sender, e) => await Check());
            _download = Button("Скачать", async (sender, e) => await Download(), true);
            _install = Button("Установить", async (sender, e) => await Install(), true);
            _cancel = Button("Отменить загрузку", (sender, e) =>
            {
                _cancelRequested = true;
                _cancel.Enabled = false;
                _updater?.UpdateDownloader.CancelDownload();
            });
            _download.Enabled = _install.Enabled = _cancel.Enabled = false;
            Actions.Controls.AddRange(new Control[] { _check, _download, _install, _cancel });
            _version = new Label { Dock = DockStyle.Top, Height = 74, Text = "Обновления Sora", Font = new Font("Segoe UI Semibold", 14F) };
            _history = new TextBox { Dock = DockStyle.Fill, Multiline = true, ReadOnly = true, BorderStyle = BorderStyle.None, BackColor = Surface, ForeColor = Ink, ScrollBars = ScrollBars.Vertical, Font = new Font("Segoe UI", 10F) };
            Content.Controls.Add(_history);
            Content.Controls.Add(_version);
            Shown += (sender, e) => Initialize(args);
        }

        private void Initialize(string[] args)
        {
            try
            {
                string directory = args.Length == 2 && args[0] == "--app-dir" ? Path.GetFullPath(args[1]) : AppDomain.CurrentDomain.BaseDirectory;
                if (!Directory.GetFiles(directory, "sora_win*.exe").Any()) directory = Path.GetFullPath(Path.Combine(directory, "..", ".."));
                var candidates = new[] { "win7", "win8", "win10", "win11" }.Select(target => Path.Combine(directory, "sora_" + target + ".exe")).Where(File.Exists).ToArray();
                if (candidates.Length != 1) throw new InvalidOperationException("Откройте центр обновлений из установленной Sora. В каталоге должна быть одна Windows-версия клиента.");
                _application = candidates[0];
                _target = Path.GetFileNameWithoutExtension(_application).Substring(5);
                var installed = FileVersionInfo.GetVersionInfo(_application);
                _version.Text = "Установлена Sora " + new Version(installed.FileMajorPart, installed.FileMinorPart, installed.FileBuildPart) + Environment.NewLine + "Windows " + _target.Substring(3);
                _verifier = new Ed25519Checker(SecurityMode.Strict, Program.ReadPublicKey(), readFileBeingVerifiedInChunks: true, chunkSize: 1024 * 1024);
                _updater = new SparkleUpdater("https://raw.githubusercontent.com/levvs-one/sora-client/main/updates/" + _target + ".xml", _verifier, _application)
                {
                    UserInteractionMode = UserInteractionMode.DownloadNoInstall,
                    UseNotificationToast = false,
                    CheckServerFileName = false,
                    TmpDownloadFilePath = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Sora", "Updates", "downloads"),
                    CustomInstallerArguments = "/NORESTART",
                    ShouldKillParentProcessWhenStartingInstaller = false
                };
                _updater.DownloadMadeProgress += (sender, item, progress) => Report("Загрузка: " + progress.ProgressPercentage + "%");
                _updater.DownloadFinished += (item, path) => Dispatch(() => FinishDownload(path, null));
                _updater.DownloadCanceled += (item, path) => Dispatch(() => FinishDownload(null, "Загрузка отменена. Установленная версия не изменена."));
                _updater.DownloadHadError += (item, path, error) => Dispatch(() => FinishDownload(null, "Не удалось загрузить обновление: " + error.Message));
                _updater.DownloadedFileIsCorrupt += (item, path) => Dispatch(() => FinishDownload(null, "Подпись файла не совпала. Установка заблокирована."));
                _updater.DownloadedFileThrewWhileCheckingSignature += (item, path) => Dispatch(() => FinishDownload(null, "Не удалось проверить подпись. Установка заблокирована."));
                _updater.InstallUpdateFailed += (reason, path) => { Dispatch(() => Failed("Установка не запущена: " + reason)); return false; };
                _updater.CloseApplication += () => Dispatch(Close);
                Event("Проверка и скачивание не отключают VPN. Установка запускается только по вашей кнопке.");
            }
            catch (Exception error) { _check.Enabled = false; Event(error.Message, true); }
        }

        private async Task Check()
        {
            _check.Enabled = _download.Enabled = _install.Enabled = false;
            _available = null;
            _verifiedPath = null;
            try
            {
                Event("Проверяем подписанный список версий…");
                var result = await _updater.CheckForUpdatesQuietly(true);
                if (IsDisposed) return;
                if (result.Status == UpdateStatus.UpdateNotAvailable) { Event("Установлена актуальная версия."); return; }
                if (result.Status != UpdateStatus.UpdateAvailable || result.Updates == null || result.Updates.Count == 0) throw new InvalidOperationException("Список версий недоступен или его подпись не прошла проверку. Попробуйте позже.");
                var item = result.Updates[0];
                if (!IsAllowedDownload(item.DownloadLink, _target)) throw new InvalidOperationException("Ссылка обновления не соответствует официальному Windows-релизу Sora.");
                _available = item;
                _download.Enabled = true;
                Event("Доступна Sora " + item.Version + ". Можно скачать без отключения VPN.");
            }
            catch (Exception error) { Failed(error.Message); }
            finally { if (!IsDisposed) _check.Enabled = true; }
        }

        internal static bool IsAllowedDownload(string address, string target)
        {
            if (!new[] { "win7", "win8", "win10", "win11" }.Contains(target)) return false;
            return Uri.TryCreate(address, UriKind.Absolute, out Uri uri) && uri.Scheme == Uri.UriSchemeHttps && uri.Host == "github.com" && uri.IsDefaultPort && string.IsNullOrEmpty(uri.UserInfo) && string.IsNullOrEmpty(uri.Query) && string.IsNullOrEmpty(uri.Fragment)
                && uri.AbsolutePath.StartsWith("/levvs-one/sora-client/releases/download/", StringComparison.Ordinal)
                && uri.AbsolutePath.EndsWith("/sora_" + target + ".exe", StringComparison.Ordinal);
        }

        private async Task Download()
        {
            if (_available == null) return;
            _download.Enabled = _check.Enabled = _install.Enabled = false;
            _cancel.Enabled = true;
            _verifiedPath = null;
            _cancelRequested = _downloadCompleted = false;
            try
            {
                _updater.TmpDownloadFileNameWithExtension = "sora_" + _target + "_" + Guid.NewGuid().ToString("N") + ".exe";
                Event("Скачиваем обновление…");
                await _updater.InitAndBeginDownload(_available);
            }
            catch (Exception error) { FinishDownload(null, "Загрузка не началась: " + error.Message); }
        }

        private void FinishDownload(string path, string error)
        {
            // NetSparkle reports a corrupt file through both signature and general error events.
            if (_downloadCompleted) return;
            _downloadCompleted = true;
            if (_cancelRequested) error = "Загрузка отменена. Установленная версия не изменена.";
            if (error != null) { Failed(error); return; }
            _verifiedPath = path;
            _cancel.Enabled = false;
            _check.Enabled = _install.Enabled = true;
            Event("Файл загружен. Подпись проверена. Перед установкой закройте Sora — соединение прервётся.");
        }

        private async Task Install()
        {
            if (_available == null || _verifiedPath == null) return;
            _install.Enabled = _check.Enabled = false;
            try
            {
                foreach (var process in Process.GetProcessesByName(Path.GetFileNameWithoutExtension(_application)))
                {
                    using (process) if (!process.HasExited)
                    {
                        Event("Сначала завершите Sora через меню в трее. VPN отключится на время установки.");
                        _install.Enabled = true;
                        return;
                    }
                }
                string path = _verifiedPath;
                bool valid = await Task.Run(() => _verifier.VerifySignatureOfFile(_available.DownloadSignature, path) == ValidationResult.Valid);
                if (IsDisposed) return;
                if (!valid) throw new InvalidOperationException("Файл изменился после загрузки. Установка заблокирована — скачайте заново.");
                Event("Запускаем проверенный установщик…");
                await _updater.InstallUpdate(_available, path);
            }
            catch (Exception error) { Failed(error.Message); }
            finally { if (!IsDisposed) _check.Enabled = true; }
        }

        private void Failed(string message)
        {
            _verifiedPath = null;
            _install.Enabled = _cancel.Enabled = false;
            _check.Enabled = _updater != null;
            _download.Enabled = _available != null;
            Event(message, true);
        }

        private void Event(string message, bool error = false)
        {
            if (IsDisposed || Disposing) return;
            if (error) _log.Warn(message); else _log.Info(message);
            if (_history.TextLength > 32000) _history.Text = _history.Text.Substring(_history.TextLength - 16000);
            _history.AppendText(DateTime.Now.ToString("HH:mm:ss") + "  " + message + Environment.NewLine + Environment.NewLine);
            Report(message);
        }

        private void Dispatch(Action action)
        {
            if (IsDisposed || Disposing || !IsHandleCreated) return;
            try { BeginInvoke(new Action(() => { if (!IsDisposed && !Disposing) action(); })); }
            catch (InvalidOperationException) { /* A download can finish while the window is closing. */ }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) { _updater?.CancelFileDownload(); _updater?.Dispose(); }
            base.Dispose(disposing);
        }
    }
}
