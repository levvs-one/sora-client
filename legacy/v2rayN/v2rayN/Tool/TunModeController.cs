using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;

namespace v2rayN.Tool
{
    internal sealed class TunModeController : IDisposable
    {
        private readonly string _directory;
        private Process _process;

        public TunModeController(string applicationDirectory)
        {
            _directory = Path.Combine(applicationDirectory, "tun2proxy");
        }

        public bool IsRunning => _process != null && !_process.HasExited;

        public bool Start(int socksPort, IEnumerable<IPAddress> bypassAddresses, Action<string> log, Action<int> exited, out string error)
        {
            error = string.Empty;
            if (IsRunning)
            {
                return true;
            }

            string executable = Path.Combine(_directory, "tun2proxy-bin.exe");
            string wintun = Path.Combine(_directory, "wintun.dll");
            if (!File.Exists(executable) || !File.Exists(wintun))
            {
                error = "Компоненты TUN не установлены. Переустановите Sora.";
                return false;
            }

            var bypass = bypassAddresses
                .Where(address => address.AddressFamily == System.Net.Sockets.AddressFamily.InterNetwork)
                .Distinct()
                .Select(address => $" --bypass \"{address}\"");
            string arguments = $"--setup --tun Sora --proxy \"socks5://127.0.0.1:{socksPort}\" --dns virtual --verbosity info --exit-on-fatal-error{string.Concat(bypass)}";

            try
            {
                _process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = executable,
                        Arguments = arguments,
                        WorkingDirectory = _directory,
                        UseShellExecute = false,
                        CreateNoWindow = true,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true
                    },
                    EnableRaisingEvents = true
                };
                _process.OutputDataReceived += (sender, args) =>
                {
                    if (!string.IsNullOrWhiteSpace(args.Data)) log(args.Data);
                };
                _process.ErrorDataReceived += (sender, args) =>
                {
                    if (!string.IsNullOrWhiteSpace(args.Data)) log(args.Data);
                };
                _process.Exited += (sender, args) =>
                {
                    var completed = (Process)sender;
                    if (ReferenceEquals(_process, completed))
                    {
                        _process = null;
                        exited(completed.ExitCode);
                    }
                };
                _process.Start();
                Global.processJob.AddProcess(_process.Handle);
                _process.BeginOutputReadLine();
                _process.BeginErrorReadLine();
                return true;
            }
            catch (Exception exception)
            {
                error = exception.Message;
                Stop();
                return false;
            }
        }

        public void Stop()
        {
            Process process = _process;
            _process = null;
            if (process == null)
            {
                return;
            }
            try
            {
                if (!process.HasExited)
                {
                    process.Kill();
                    process.WaitForExit(5000);
                }
            }
            catch (Exception exception)
            {
                Utils.SaveLog("Не удалось остановить TUN", exception);
            }
            finally
            {
                process.Dispose();
            }
        }

        public void Dispose()
        {
            Stop();
        }
    }
}
