using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

namespace v2rayN.Tool
{
    internal static class CommunityDiagnostics
    {
        private static readonly string[] ComponentFiles =
        {
            "xray.exe",
            "sing-box.exe",
            Path.Combine("tun2proxy", "tun2proxy-bin.exe"),
            Path.Combine("tun2proxy", "tun2proxy.dll"),
            Path.Combine("tun2proxy", "udpgw-server.exe"),
            Path.Combine("tun2proxy", "wintun.dll")
        };

        public static void Export(IWin32Window owner)
        {
            string downloads = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
            if (!Directory.Exists(downloads))
            {
                downloads = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
            }
            string prefix = Path.Combine(downloads, "Sora-Diagnostics-" + DateTime.Now.ToString("yyyyMMdd-HHmmss"));
            string destination = prefix + ".zip";
            int suffix = 2;
            while (File.Exists(destination))
            {
                destination = prefix + "-" + suffix++ + ".zip";
            }
            string temporaryDirectory = Path.Combine(
                Path.GetTempPath(),
                "Sora-Diagnostics-" + Guid.NewGuid().ToString("N"));

            try
            {
                Directory.CreateDirectory(temporaryDirectory);
                File.WriteAllText(
                    Path.Combine(temporaryDirectory, "diagnostics.txt"),
                    BuildReport(),
                    new UTF8Encoding(false));

                ZipFile.CreateFromDirectory(temporaryDirectory, destination, CompressionLevel.Optimal, false);

                UI.Show("Диагностика сохранена без системного окна:\r\n" + destination + "\r\n\r\nСсылки подписок, идентификаторы серверов и конфигурация в архив не включаются.");

                Process.Start("explorer.exe", "/select,\"" + destination + "\"");
            }
            catch (Exception exception)
            {
                UI.ShowError("Не удалось создать диагностику:\r\n" + exception.Message);
            }
            finally
            {
                if (Directory.Exists(temporaryDirectory))
                {
                    try
                    {
                        Directory.Delete(temporaryDirectory, true);
                    }
                    catch (IOException exception)
                    {
                        Utils.SaveLog(exception.Message, exception);
                    }
                    catch (UnauthorizedAccessException exception)
                    {
                        Utils.SaveLog(exception.Message, exception);
                    }
                }
            }
        }

        private static string BuildReport()
        {
            string applicationDirectory = AppDomain.CurrentDomain.BaseDirectory;
            var report = new StringBuilder();
            report.AppendLine("Sora diagnostics");
            report.AppendLine("Generated: " + DateTimeOffset.Now.ToString("O"));
            report.AppendLine("Application version: " + Assembly.GetExecutingAssembly().GetName().Version);
            report.AppendLine("Application directory: omitted for privacy");
            report.AppendLine("Operating system: " + Environment.OSVersion);
            report.AppendLine("64-bit operating system: " + Environment.Is64BitOperatingSystem);
            report.AppendLine("64-bit process: " + Environment.Is64BitProcess);
            report.AppendLine(".NET runtime: " + Environment.Version);
            report.AppendLine("Machine name omitted for privacy");
            report.AppendLine();
            report.AppendLine("Components:");

            foreach (string component in ComponentFiles)
            {
                AppendComponent(report, Path.Combine(applicationDirectory, component));
            }

            report.AppendLine();
            report.AppendLine("Privacy:");
            report.AppendLine("Configuration, subscriptions, UUIDs, credentials, server addresses and application logs are not exported.");
            return report.ToString();
        }

        private static void AppendComponent(StringBuilder report, string path)
        {
            string name = Path.GetFileName(path);
            if (!File.Exists(path))
            {
                report.AppendLine(name + ": MISSING");
                return;
            }

            var info = new FileInfo(path);
            string version = FileVersionInfo.GetVersionInfo(path).FileVersion;
            report.AppendLine(name + ":");
            report.AppendLine("  Size: " + info.Length);
            report.AppendLine("  File version: " + (string.IsNullOrWhiteSpace(version) ? "not present" : version));
            report.AppendLine("  SHA-256: " + ComputeSha256(path));
        }

        private static string ComputeSha256(string path)
        {
            using (var algorithm = SHA256.Create())
            using (var stream = File.OpenRead(path))
            {
                byte[] hash = algorithm.ComputeHash(stream);
                return BitConverter.ToString(hash).Replace("-", string.Empty);
            }
        }
    }
}
