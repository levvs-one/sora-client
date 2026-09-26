
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
using v2rayN.Mode;
using v2rayN.Properties;
using v2rayN.Tool;

namespace v2rayN.Handler
{
    public static class SysProxyHandle
    {
        private const string UserWininetConfigFile = "user-wininet.json";

        // In general, this won't change
        // format:
        //  <flags><CR-LF>
        //  <proxy-server><CR-LF>
        //  <bypass-list><CR-LF>
        //  <pac-url>
        enum RET_ERRORS : int
        {
            RET_NO_ERROR = 0,
            INVALID_FORMAT = 1,
            NO_PERMISSION = 2,
            SYSCALL_FAILED = 3,
            NO_MEMORY = 4,
            INVAILD_OPTION_COUNT = 5,
        };

        static SysProxyHandle()
        {
            try
            {
                FileManager.UncompressFile(Utils.GetTempPath("sysproxy.exe"),
                    Environment.Is64BitOperatingSystem ? Resources.sysproxy64_exe : Resources.sysproxy_exe);
            }
            catch (IOException ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
        }


        public static bool UpdateSysProxy(Config config, bool forceDisable)
        {
            var type = config.sysProxyType;

            if (forceDisable && type == ESysProxyType.ForcedChange)
            {
                type = ESysProxyType.ForcedClear;
            }

            try
            {
                if (type == ESysProxyType.ForcedChange)
                {
                    int port = config.GetLocalPort(Global.InboundHttp);
                    int portSocks = config.GetLocalPort(Global.InboundSocks);
                    if (port <= 0)
                    {
                        return false;
                    }
                    var strExceptions = $"{config.constItem.defIEProxyExceptions};{config.systemProxyExceptions}";

                    var strProxy = string.Empty;
                    if (Utils.IsNullOrEmpty(config.systemProxyAdvancedProtocol))
                    {
                        strProxy = $"{Global.Loopback}:{port}";
                    }
                    else
                    {
                        strProxy = config.systemProxyAdvancedProtocol
                            .Replace("{ip}", Global.Loopback)
                            .Replace("{http_port}", port.ToString())
                            .Replace("{socks_port}", portSocks.ToString());
                    }
                    SetIEProxy(true, strProxy, strExceptions);
                }
                else if (type == ESysProxyType.ForcedClear)
                {
                    return ResetIEProxy();
                }
                else if (type == ESysProxyType.Unchanged)
                {
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                return false;
            }
            return true;
        }

        public static void ResetIEProxy4WindowsShutDown()
        {
            try
            {
                ResetIEProxy();
            }
            catch
            {
            }
        }


        public static void SetIEProxy(bool global, string strProxy, string strExceptions)
        {
            RecordUserSettings();
            string arguments = global
                ? $"global {strProxy} {strExceptions}"
                : $"pac {strProxy}";

            ExecSysproxy(arguments);
        }

        public static bool ResetIEProxy()
        {
            try
            {
                string backupPath = Utils.GetPath(UserWininetConfigFile);
                SysproxyConfig userSettings = LoadUserSettings(backupPath);
                if (userSettings?.UserSettingsRecorded == true)
                {
                    string arguments = string.Join(" ", new[]
                    {
                        "set",
                        QuoteArgument(userSettings.Flags),
                        QuoteArgument(userSettings.ProxyServer),
                        QuoteArgument(userSettings.BypassList),
                        QuoteArgument(userSettings.PacUrl)
                    });
                    ExecSysproxy(arguments);
                    File.Delete(backupPath);
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                return false;
            }

            return true;
        }

        private static void RecordUserSettings()
        {
            string backupPath = Utils.GetPath(UserWininetConfigFile);
            if (LoadUserSettings(backupPath)?.UserSettingsRecorded == true)
            {
                return;
            }

            string[] values = ExecSysproxy("query")
                .Replace("\r\n", "\n")
                .Split(new[] { '\n' }, StringSplitOptions.None);
            if (values.Length < 4 || string.IsNullOrWhiteSpace(values[0]))
            {
                throw new InvalidDataException("Не удалось сохранить исходные параметры системного прокси.");
            }

            var settings = new SysproxyConfig
            {
                UserSettingsRecorded = true,
                Flags = values[0].Trim(),
                ProxyServer = NormalizeQueryValue(values[1]),
                BypassList = NormalizeQueryValue(values[2]),
                PacUrl = NormalizeQueryValue(values[3])
            };
            if (Utils.ToJsonFile(settings, backupPath) != 0)
            {
                throw new IOException("Не удалось записать резервную копию параметров системного прокси.");
            }
        }

        private static SysproxyConfig LoadUserSettings(string path)
        {
            if (!File.Exists(path))
            {
                return null;
            }
            SysproxyConfig settings = Utils.FromJson<SysproxyConfig>(Utils.LoadResource(path));
            if (settings == null)
            {
                throw new InvalidDataException("Резервная копия параметров системного прокси повреждена.");
            }
            settings.ProxyServer = NormalizeQueryValue(settings.ProxyServer);
            settings.BypassList = NormalizeQueryValue(settings.BypassList);
            settings.PacUrl = NormalizeQueryValue(settings.PacUrl);
            return settings;
        }

        private static string NormalizeQueryValue(string value)
        {
            return string.Equals(value?.Trim(), "(null)", StringComparison.OrdinalIgnoreCase)
                ? string.Empty
                : value ?? string.Empty;
        }

        private static string QuoteArgument(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return "-";
            }
            if (value.IndexOfAny(new[] { '\r', '\n' }) >= 0)
            {
                throw new InvalidDataException("Параметры системного прокси содержат недопустимый перевод строки.");
            }
            var quoted = new StringBuilder("\"");
            int backslashes = 0;
            foreach (char character in value)
            {
                if (character == '\\')
                {
                    backslashes++;
                    continue;
                }
                if (character == '"')
                {
                    quoted.Append('\\', backslashes * 2 + 1);
                    quoted.Append(character);
                    backslashes = 0;
                    continue;
                }
                quoted.Append('\\', backslashes);
                quoted.Append(character);
                backslashes = 0;
            }
            quoted.Append('\\', backslashes * 2);
            quoted.Append('"');
            return quoted.ToString();
        }

        private static string ExecSysproxy(string arguments)
        {
            // using event to avoid hanging when redirect standard output/error
            // ref: https://stackoverflow.com/questions/139593/processstartinfo-hanging-on-waitforexit-why
            // and http://blog.csdn.net/zhangweixing0/article/details/7356841
            using (AutoResetEvent outputWaitHandle = new AutoResetEvent(false))
            using (AutoResetEvent errorWaitHandle = new AutoResetEvent(false))
            {
                using (Process process = new Process())
                {
                    // Configure the process using the StartInfo properties.
                    process.StartInfo.FileName = Utils.GetTempPath("sysproxy.exe");
                    process.StartInfo.Arguments = arguments;
                    process.StartInfo.WorkingDirectory = Utils.GetTempPath();
                    process.StartInfo.WindowStyle = ProcessWindowStyle.Hidden;
                    process.StartInfo.UseShellExecute = false;
                    process.StartInfo.RedirectStandardError = true;
                    process.StartInfo.RedirectStandardOutput = true;

                    // Need to provide encoding info, or output/error strings we got will be wrong.
                    process.StartInfo.StandardOutputEncoding = Encoding.Unicode;
                    process.StartInfo.StandardErrorEncoding = Encoding.Unicode;

                    process.StartInfo.CreateNoWindow = true;

                    StringBuilder output = new StringBuilder();
                    StringBuilder error = new StringBuilder();

                    process.OutputDataReceived += (sender, e) =>
                    {
                        if (e.Data == null)
                        {
                            outputWaitHandle.Set();
                        }
                        else
                        {
                            output.AppendLine(e.Data);
                        }
                    };
                    process.ErrorDataReceived += (sender, e) =>
                    {
                        if (e.Data == null)
                        {
                            errorWaitHandle.Set();
                        }
                        else
                        {
                            error.AppendLine(e.Data);
                        }
                    };
                    try
                    {
                        process.Start();

                        process.BeginErrorReadLine();
                        process.BeginOutputReadLine();

                        if (!process.WaitForExit(10000))
                        {
                            process.Kill();
                            throw new TimeoutException("sysproxy.exe не завершился за 10 секунд.");
                        }
                        if (!outputWaitHandle.WaitOne(2000) || !errorWaitHandle.WaitOne(2000))
                        {
                            throw new TimeoutException("Не удалось полностью прочитать ответ sysproxy.exe.");
                        }
                    }
                    catch (System.ComponentModel.Win32Exception ex)
                    {
                        throw new Exception("Не удалось запустить sysproxy.exe.", ex);
                    }
                    string stderr = error.ToString();
                    string stdout = output.ToString();

                    int exitCode = process.ExitCode;
                    if (exitCode != (int)RET_ERRORS.RET_NO_ERROR)
                    {
                        throw new Exception(stderr);
                    }
                    return stdout;
                }
            }
        }


    }
}
