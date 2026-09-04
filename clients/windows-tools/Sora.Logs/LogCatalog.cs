using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace Sora.Centers
{
    internal sealed class LogEntry
    {
        public DateTime Time { get; set; }
        public string Level { get; set; }
        public string Source { get; set; }
        public string Message { get; set; }
        public string File { get; set; }
        public int Line { get; set; }
    }

    internal sealed class LogCatalog
    {
        internal const int MaximumEntries = 20000;
        private const int MaximumFileBytes = 4 * 1024 * 1024;
        private static readonly Regex Header = new Regex(@"^(?<time>\d{4}-\d\d-\d\d \d\d:\d\d:\d\d,\d{3}) \[[^\]\r\n]+\]\s+(?<level>\w+)\s+\S+ - (?<message>.*)$", RegexOptions.Compiled, TimeSpan.FromMilliseconds(100));
        private static readonly Regex SourceTag = new Regex(@"^\[(CORE|TUN|PROXY|SUBSCRIPTION|UPDATE|UI)\]\s*", RegexOptions.Compiled, TimeSpan.FromMilliseconds(100));
        private readonly string[] _directories;
        private readonly Dictionary<string, Tuple<long, DateTime, List<LogEntry>>> _cache = new Dictionary<string, Tuple<long, DateTime, List<LogEntry>>>(StringComparer.OrdinalIgnoreCase);
        internal string LastWarning { get; private set; }

        internal LogCatalog(string applicationDirectory)
        {
            _directories = new[] { Path.Combine(applicationDirectory, "guiLogs"), Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Sora", "Updates", "logs") };
        }

        internal List<LogEntry> Read()
        {
            LastWarning = null;
            var files = new List<FileInfo>();
            foreach (string directory in _directories)
            {
                try
                {
                    if (Directory.Exists(directory)) files.AddRange(new DirectoryInfo(directory).EnumerateFiles("*.txt*"));
                }
                catch (IOException) { LastWarning = "Часть журналов временно недоступна."; }
                catch (UnauthorizedAccessException) { LastWarning = "Нет доступа к одному из каталогов журналов."; }
            }
            var current = files.OrderByDescending(file => file.LastWriteTimeUtc).Take(12).ToList();
            foreach (string stale in _cache.Keys.Except(current.Select(file => file.FullName), StringComparer.OrdinalIgnoreCase).ToArray()) _cache.Remove(stale);
            foreach (FileInfo file in current)
            {
                try
                {
                    long length = file.Length;
                    DateTime modified = file.LastWriteTimeUtc;
                    if (_cache.TryGetValue(file.FullName, out var saved) && saved.Item1 == length && saved.Item2 == modified) continue;
                    using (var stream = new FileStream(file.FullName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite | FileShare.Delete))
                    {
                        bool tail = length > MaximumFileBytes;
                        if (tail) stream.Seek(length - MaximumFileBytes, SeekOrigin.Begin);
                        // Read a bounded snapshot: a continuously growing log must not keep this worker alive forever.
                        byte[] bytes = new byte[(int)Math.Min(length, MaximumFileBytes)];
                        int count = 0;
                        while (count < bytes.Length)
                        {
                            int read = stream.Read(bytes, count, bytes.Length - count);
                            if (read == 0) break;
                            count += read;
                        }
                        using (var reader = new StreamReader(new MemoryStream(bytes, 0, count), Encoding.UTF8, true))
                        {
                            if (tail) reader.ReadLine();
                            var entries = Parse(reader, file.FullName, file.LastWriteTime, tail ? -1 : 1);
                            _cache[file.FullName] = Tuple.Create(length, modified, entries);
                        }
                    }
                }
                catch (IOException) { LastWarning = "Файл журнала занят. Повторим чтение автоматически."; }
                catch (UnauthorizedAccessException) { LastWarning = "Не удалось прочитать один из журналов: недостаточно прав."; }
            }
            return _cache.Values.SelectMany(item => item.Item3).OrderByDescending(entry => entry.Time).Take(MaximumEntries).ToList();
        }

        internal static List<LogEntry> Parse(TextReader reader, string file, DateTime fallback, int firstLine = 1)
        {
            var result = new Queue<LogEntry>();
            LogEntry previous = null;
            string line;
            int lineNumber = firstLine;
            while ((line = reader.ReadLine()) != null)
            {
                Match match = Header.Match(line);
                if (match.Success)
                {
                    if (!DateTime.TryParseExact(match.Groups["time"].Value, "yyyy-MM-dd HH:mm:ss,fff", CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTime timestamp)) timestamp = fallback;
                    string message = match.Groups["message"].Value;
                    if (message.Length > 65536) message = message.Substring(0, 65536);
                    Match tag = SourceTag.Match(message);
                    previous = new LogEntry { Time = timestamp, Level = match.Groups["level"].Value, Source = tag.Success ? tag.Groups[1].Value : "Sora", Message = message, File = file, Line = lineNumber };
                    result.Enqueue(previous);
                }
                else if (previous != null && previous.Message.Length < 65536)
                {
                    string continuation = Environment.NewLine + line;
                    previous.Message += continuation.Substring(0, Math.Min(continuation.Length, 65536 - previous.Message.Length));
                }
                else if (previous == null && !string.IsNullOrWhiteSpace(line))
                {
                    previous = new LogEntry { Time = fallback, Level = "INFO", Source = "Sora", Message = line.Substring(0, Math.Min(line.Length, 65536)), File = file, Line = lineNumber };
                    result.Enqueue(previous);
                }
                if (lineNumber >= 0) lineNumber++;
                while (result.Count > MaximumEntries) result.Dequeue();
            }
            return result.ToList();
        }
    }
}
