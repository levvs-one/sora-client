using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace Sora.Centers
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            string directory = args.Length == 2 && args[0] == "--app-dir" ? Path.GetFullPath(args[1]) : AppDomain.CurrentDomain.BaseDirectory;
            if (args.Length == 0)
            {
                string parent = Path.GetFullPath(Path.Combine(directory, "..", ".."));
                if (Directory.Exists(parent) && Directory.GetFiles(parent, "sora_win*.exe").Length > 0) directory = parent;
            }
            Application.Run(new LogWindow(directory));
        }
    }

    internal sealed class LogWindow : CenterWindow
    {
        private readonly LogCatalog _catalog;
        private readonly DataGridView _grid;
        private readonly TextBox _search;
        private readonly ComboBox _level;
        private readonly ComboBox _source;
        private readonly TextBox _details;
        private readonly Timer _refresh = new Timer { Interval = 1500 };
        private List<LogEntry> _entries = new List<LogEntry>();
        private List<LogEntry> _visible = new List<LogEntry>();
        private bool _busy;
        private bool _paused;
        private bool _descending = true;
        private int _sortColumn;
        private DateTime _statusUntil;

        internal LogWindow(string directory) : base("Sora Logs")
        {
            _catalog = new LogCatalog(directory);
            _search = new TextBox { Width = 230, BackColor = Surface, ForeColor = Ink, BorderStyle = BorderStyle.FixedSingle, AccessibleName = "Поиск в журнале" };
            _level = Filter(new[] { "Все уровни", "ERROR", "WARN", "INFO", "DEBUG", "FATAL" });
            _source = Filter(new[] { "Все источники", "Sora", "CORE", "TUN", "PROXY", "SUBSCRIPTION", "UPDATE", "UI" });
            var pause = Button("Пауза", (sender, args) => { _paused = !_paused; ((Button)sender).Text = _paused ? "Продолжить" : "Пауза"; Report(_paused ? "Просмотр приостановлен. Запись журнала продолжается." : "Просмотр возобновлён."); });
            Actions.Controls.AddRange(new Control[] { _search, _level, _source, pause, Button("Экспорт JSONL", Export) });
            _grid = new DataGridView { Dock = DockStyle.Fill, VirtualMode = true, ReadOnly = true, AllowUserToAddRows = false, AllowUserToDeleteRows = false, AllowUserToResizeRows = false, MultiSelect = false, RowHeadersVisible = false, SelectionMode = DataGridViewSelectionMode.FullRowSelect, BackgroundColor = Surface, BorderStyle = BorderStyle.None, GridColor = Color.FromArgb(49, 49, 52), EnableHeadersVisualStyles = false, AutoSizeRowsMode = DataGridViewAutoSizeRowsMode.None };
            _grid.DefaultCellStyle.BackColor = Surface;
            _grid.DefaultCellStyle.ForeColor = Ink;
            _grid.DefaultCellStyle.SelectionBackColor = Color.FromArgb(67, 67, 71);
            _grid.DefaultCellStyle.SelectionForeColor = Ink;
            _grid.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(40, 40, 43);
            _grid.ColumnHeadersDefaultCellStyle.ForeColor = Ink;
            _grid.ColumnHeadersDefaultCellStyle.SelectionBackColor = Color.FromArgb(49, 49, 52);
            _grid.ColumnHeadersDefaultCellStyle.SelectionForeColor = Ink;
            _grid.ColumnHeadersBorderStyle = DataGridViewHeaderBorderStyle.None;
            _grid.ColumnHeadersHeight = 36;
            _grid.CellBorderStyle = DataGridViewCellBorderStyle.SingleHorizontal;
            _grid.RowTemplate.Height = 30;
            foreach (var column in new[] { new DataGridViewTextBoxColumn { HeaderText = "Время", Width = 155 }, new DataGridViewTextBoxColumn { HeaderText = "Уровень", Width = 80 }, new DataGridViewTextBoxColumn { HeaderText = "Источник", Width = 115 }, new DataGridViewTextBoxColumn { HeaderText = "Сообщение", AutoSizeMode = DataGridViewAutoSizeColumnMode.Fill } }) { column.SortMode = DataGridViewColumnSortMode.Programmatic; _grid.Columns.Add(column); }
            _grid.CellValueNeeded += (sender, args) => { if (args.RowIndex >= _visible.Count) return; var entry = _visible[args.RowIndex]; args.Value = args.ColumnIndex == 0 ? entry.Time.ToString("dd.MM HH:mm:ss.fff") : args.ColumnIndex == 1 ? entry.Level : args.ColumnIndex == 2 ? entry.Source : entry.Message.Split('\n')[0]; };
            _grid.ColumnHeaderMouseClick += (sender, args) => { _descending = args.ColumnIndex == _sortColumn ? !_descending : false; _sortColumn = args.ColumnIndex; ApplyFilter(); };
            _details = new TextBox { Dock = DockStyle.Bottom, Height = 150, Multiline = true, ReadOnly = true, WordWrap = true, ScrollBars = ScrollBars.Vertical, BorderStyle = BorderStyle.None, BackColor = BackColor, ForeColor = Ink, Font = new Font("Consolas", 10F), AccessibleName = "Подробности записи" };
            _grid.SelectionChanged += (sender, args) => ShowDetails();
            Content.Controls.Add(_grid);
            Content.Controls.Add(_details);
            _search.TextChanged += (sender, args) => ApplyFilter();
            _level.SelectedIndexChanged += (sender, args) => ApplyFilter();
            _source.SelectedIndexChanged += (sender, args) => ApplyFilter();
            _refresh.Tick += async (sender, args) => await RefreshLogs();
            Shown += async (sender, args) => { await RefreshLogs(); if (!IsDisposed && !Disposing) _refresh.Start(); };
            Report("Читаем журналы Sora…");
        }

        private ComboBox Filter(string[] items)
        {
            var box = new ComboBox { Width = 145, DropDownStyle = ComboBoxStyle.DropDownList, FlatStyle = FlatStyle.Flat, BackColor = Surface, ForeColor = Ink };
            box.Items.AddRange(items);
            box.SelectedIndex = 0;
            return box;
        }

        private async Task RefreshLogs()
        {
            if (_busy || _paused) return;
            _busy = true;
            try
            {
                var entries = await Task.Run(() => _catalog.Read());
                if (IsDisposed) return;
                _entries = entries;
                ApplyFilter();
            }
            catch (Exception exception) { Report("Не удалось прочитать журнал: " + exception.Message); }
            finally { _busy = false; }
        }

        private void ApplyFilter()
        {
            if (_grid == null) return;
            var selected = _grid.CurrentCell != null && _grid.CurrentCell.RowIndex < _visible.Count ? _visible[_grid.CurrentCell.RowIndex] : null;
            string query = _search.Text.Trim();
            var filtered = _entries.Where(entry => (_level.SelectedIndex == 0 || entry.Level == (string)_level.SelectedItem) && (_source.SelectedIndex == 0 || entry.Source == (string)_source.SelectedItem) && (query.Length == 0 || entry.Message.IndexOf(query, StringComparison.OrdinalIgnoreCase) >= 0));
            Func<LogEntry, IComparable> key = entry => _sortColumn == 0 ? (IComparable)entry.Time : _sortColumn == 1 ? entry.Level : _sortColumn == 2 ? entry.Source : entry.Message;
            _visible = (_descending ? filtered.OrderByDescending(key) : filtered.OrderBy(key)).ToList();
            _grid.RowCount = _visible.Count;
            _details.Visible = _visible.Count > 0;
            _grid.Invalidate();
            int restored = selected == null ? -1 : _visible.FindIndex(entry => entry.Time == selected.Time && entry.File == selected.File && entry.Line == selected.Line);
            if (restored >= 0) _grid.CurrentCell = _grid.Rows[restored].Cells[0];
            ShowDetails();
            if (DateTime.UtcNow >= _statusUntil) Report(_catalog.LastWarning ?? (_entries.Count == 0 ? "Журнал пока пуст. События появятся после запуска Sora." : $"Показано {_visible.Count:N0} из {_entries.Count:N0}. Последние 20 000 записей; исходные файлы сохранены."));
        }

        private void ShowDetails()
        {
            int row = _grid.CurrentCell?.RowIndex ?? -1;
            _details.Text = row >= 0 && row < _visible.Count ? _visible[row].File + Environment.NewLine + _visible[row].Message : string.Empty;
            _details.ScrollBars = (_details.GetLineFromCharIndex(_details.TextLength) + 1) * _details.Font.Height > _details.ClientSize.Height ? ScrollBars.Vertical : ScrollBars.None;
        }

        private async void Export(object sender, EventArgs args)
        {
            var button = (Button)sender;
            button.Enabled = false;
            try
            {
                string directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), "Downloads");
                if (!Directory.Exists(directory)) directory = Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments);
                string path = Path.Combine(directory, "sora-logs-" + DateTime.Now.ToString("yyyyMMdd-HHmmss-fff") + ".jsonl");
                var snapshot = _visible.ToArray();
                await Task.Run(() =>
                {
                    using (var stream = new FileStream(path, FileMode.CreateNew, FileAccess.Write, FileShare.Read))
                    using (var writer = new StreamWriter(stream, new UTF8Encoding(false)))
                        foreach (LogEntry entry in snapshot) writer.WriteLine(JsonConvert.SerializeObject(entry));
                });
                _statusUntil = DateTime.UtcNow.AddSeconds(10);
                Report("Сохранено: " + path + ". Перед отправкой проверьте адреса и личные данные.");
            }
            catch (Exception exception) { Report("Экспорт не выполнен: " + exception.Message); }
            finally { if (!button.IsDisposed) button.Enabled = true; }
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing) _refresh.Dispose();
            base.Dispose(disposing);
        }
    }
}
