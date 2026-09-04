using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Windows.Forms;
using v2rayN.Base;
using v2rayN.Mode;
using v2rayN.Resx;

namespace v2rayN.Forms
{
    public partial class MainMsgControl : UserControl
    {
        private const int MaximumHistoryEntries = 2000;
        private const int MaximumVisibleEntries = 1000;
        private const int MaximumFlushBatchEntries = 250;
        private const int LogFlushIntervalMilliseconds = 80;
        private string _msgFilter = string.Empty;
        private readonly List<string> _history = new List<string>();
        private readonly Queue<string> _pendingMessages = new Queue<string>();
        private readonly System.Windows.Forms.Timer _flushTimer;
        private Regex _filter;
        private int _flushRequested;
        private int _visibleEntryCount;

        public MainMsgControl()
        {
            InitializeComponent();
            SetStyle(ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
            _flushTimer = new System.Windows.Forms.Timer(components) { Interval = LogFlushIntervalMilliseconds };
            _flushTimer.Tick += (sender, args) => FlushPendingMessages(MaximumFlushBatchEntries);
            HandleCreated += (sender, args) => SetCommunityFilter(_msgFilter);
        }

        private void MainMsgControl_Load(object sender, EventArgs e)
        {
            _msgFilter = Utils.RegReadValue(Global.MyRegPath, Utils.MainMsgFilterKey, "");
            SetCommunityFilter(_msgFilter);
            if (!Utils.IsNullOrEmpty(_msgFilter))
            {
                gbMsgTitle.Text = string.Format(ResUI.MsgInformationTitle, _msgFilter);
            }
        }

        #region 提示信息

        public void AppendText(string text)
        {
            text = SanitizeSoraLogText(text);
            lock (_history)
            {
                Remember(text);
                _pendingMessages.Enqueue(text);
                while (_pendingMessages.Count > MaximumHistoryEntries) _pendingMessages.Dequeue();
            }

            ScheduleFlush();
        }

        private void ScheduleFlush()
        {
            if (IsDisposed || Disposing || !IsHandleCreated || Interlocked.CompareExchange(ref _flushRequested, 1, 0) != 0)
            {
                return;
            }

            try
            {
                if (InvokeRequired)
                {
                    BeginInvoke((Action)StartFlushTimer);
                }
                else
                {
                    StartFlushTimer();
                }
            }
            catch (ObjectDisposedException)
            {
                Interlocked.Exchange(ref _flushRequested, 0);
            }
            catch (InvalidOperationException)
            {
                Interlocked.Exchange(ref _flushRequested, 0);
            }
        }

        private void StartFlushTimer()
        {
            if (IsDisposed || Disposing)
            {
                Interlocked.Exchange(ref _flushRequested, 0);
                return;
            }
            _flushTimer.Start();
        }

        private static string SanitizeSoraLogText(string text)
        {
            return (text ?? string.Empty)
                .Replace("v2rayN.", "Sora.")
                .Replace("v2rayN", "Sora");
        }

        private void FlushPendingMessages(int maximumEntries)
        {
            if (IsDisposed || Disposing || !IsHandleCreated)
            {
                return;
            }

            var messages = new List<string>(Math.Min(maximumEntries, MaximumFlushBatchEntries));
            bool hasMore;
            lock (_history)
            {
                while (_pendingMessages.Count > 0 && messages.Count < maximumEntries)
                {
                    messages.Add(_pendingMessages.Dequeue());
                }
                hasMore = _pendingMessages.Count > 0;
            }

            if (messages.Count > 0)
            {
                string[] visible = messages.Where(MatchesFilter).ToArray();
                if (visible.Length > 0)
                {
                    if (_visibleEntryCount + visible.Length > MaximumVisibleEntries)
                    {
                        RenderHistory();
                        hasMore = false;
                    }
                    else
                    {
                        txtMsgBox.AppendText(JoinLogMessages(visible));
                        _visibleEntryCount += visible.Length;
                        txtMsgBox.SelectionStart = txtMsgBox.TextLength;
                        txtMsgBox.ScrollToCaret();
                    }
                }
            }

            if (hasMore)
            {
                return;
            }

            _flushTimer.Stop();
            Interlocked.Exchange(ref _flushRequested, 0);
            lock (_history)
            {
                hasMore = _pendingMessages.Count > 0;
            }
            if (hasMore)
            {
                ScheduleFlush();
            }
        }

        /// <summary>
        /// 清除信息
        /// </summary>
        public void ClearMsg()
        {
            if (IsDisposed)
            {
                return;
            }
            if (!IsHandleCreated)
            {
                lock (_history)
                {
                    _history.Clear();
                    _pendingMessages.Clear();
                }
                return;
            }
            if (txtMsgBox.InvokeRequired)
            {
                BeginInvoke((Action)ClearMsg);
                return;
            }
            lock (_history)
            {
                _history.Clear();
                _pendingMessages.Clear();
            }
            _flushTimer.Stop();
            Interlocked.Exchange(ref _flushRequested, 0);
            _visibleEntryCount = 0;
            txtMsgBox.Clear();
        }

        private void Remember(string text)
        {
            _history.Add(text);
            if (_history.Count > MaximumHistoryEntries)
            {
                _history.RemoveRange(0, _history.Count - MaximumHistoryEntries);
            }
        }

        public void SetCommunityFilter(string pattern)
        {
            if (IsDisposed || Disposing)
            {
                return;
            }
            if (txtMsgBox.InvokeRequired)
            {
                txtMsgBox.Invoke((Action)(() => SetCommunityFilter(pattern)));
                return;
            }
            _msgFilter = pattern ?? string.Empty;
            _filter = CreateFilter(_msgFilter);
            _flushTimer.Stop();
            Interlocked.Exchange(ref _flushRequested, 0);
            RenderHistory();
        }

        private static Regex CreateFilter(string pattern)
        {
            if (Utils.IsNullOrEmpty(pattern))
            {
                return null;
            }
            try
            {
                return new Regex(pattern, RegexOptions.IgnoreCase | RegexOptions.CultureInvariant, TimeSpan.FromMilliseconds(100));
            }
            catch (ArgumentException)
            {
                return null;
            }
        }

        private bool MatchesFilter(string message)
        {
            try { return _filter == null || _filter.IsMatch(message ?? string.Empty); }
            catch (RegexMatchTimeoutException)
            {
                _filter = null;
                return true;
            }
        }

        private void RenderHistory()
        {
            string[] visible;
            lock (_history)
            {
                _pendingMessages.Clear();
                string[] matching = _history.Where(MatchesFilter).ToArray();
                visible = matching.Skip(Math.Max(0, matching.Length - MaximumVisibleEntries)).ToArray();
            }
            txtMsgBox.Text = JoinLogMessages(visible);
            _visibleEntryCount = visible.Length;
            txtMsgBox.SelectionStart = txtMsgBox.TextLength;
            txtMsgBox.ScrollToCaret();
        }

        private static string JoinLogMessages(IEnumerable<string> messages)
        {
            var text = new StringBuilder();
            foreach (string message in messages)
            {
                text.Append((message ?? string.Empty).TrimEnd('\r', '\n'));
                text.Append(Environment.NewLine);
            }
            return text.ToString();
        }

        internal void ApplySoraTheme(Color background, Color surface, Color text, Color border)
        {
            SuspendLayout();
            BackColor = background;
            Padding = new Padding(0, 8, 0, 0);
            Controls.Clear();
            gbMsgTitle.Visible = false;
            txtMsgBox.Parent = this;
            txtMsgBox.Dock = DockStyle.Fill;
            txtMsgBox.BackColor = surface;
            txtMsgBox.ForeColor = text;
            txtMsgBox.BorderStyle = BorderStyle.None;
            txtMsgBox.Font = new Font("Consolas", 9F);
            txtMsgBox.ScrollBars = ScrollBars.Vertical;
            txtMsgBox.WordWrap = false;
            txtMsgBox.HideSelection = false;
            ssMain.Parent = this;
            ssMain.Dock = DockStyle.Bottom;
            ssMain.Height = 24;
            ssMain.BackColor = background;
            ssMain.ForeColor = text;
            ssMain.SizingGrip = false;
            foreach (ToolStripItem item in ssMain.Items)
            {
                item.ForeColor = text;
                item.BackColor = background;
            }
            cmsMsgBox.BackColor = surface;
            cmsMsgBox.ForeColor = text;
            cmsMsgBox.ShowImageMargin = false;
            cmsMsgBox.Items.Clear();
            cmsMsgBox.Items.Add("Копировать", null, menuMsgBoxCopy_Click);
            cmsMsgBox.Items.Add("Копировать всё", null, menuMsgBoxCopyAll_Click);
            cmsMsgBox.Items.Add("Очистить", null, menuMsgBoxClear_Click);
            foreach (ToolStripItem item in cmsMsgBox.Items)
            {
                item.BackColor = surface;
                item.ForeColor = text;
            }
            Controls.Add(txtMsgBox);
            Controls.Add(ssMain);
            ssMain.BringToFront();
            ResumeLayout(true);
        }

        internal string GetVisibleText()
        {
            if (txtMsgBox.InvokeRequired)
            {
                return (string)txtMsgBox.Invoke(new Func<string>(GetVisibleText));
            }
            FlushPendingMessages(int.MaxValue);
            return txtMsgBox.Text;
        }

        public void DisplayToolStatus(Config config)
        {
            StringBuilder sb = new StringBuilder();
            sb.Append("Локально:");
            sb.Append($"[{Global.InboundSocks}:{config.GetLocalPort(Global.InboundSocks)}]");
            sb.Append(" | ");
            if (config.sysProxyType == ESysProxyType.ForcedChange)
            {
                sb.Append($"[{Global.InboundHttp}({ResUI.SystemProxy}):{config.GetLocalPort(Global.InboundHttp)}]");
            }
            else
            {
                sb.Append($"[{Global.InboundHttp}:{config.GetLocalPort(Global.InboundHttp)}]");
            }

            if (config.inbound[0].allowLANConn)
            {
                sb.Append($"  {ResUI.LabLAN}:");
                sb.Append($"[{Global.InboundSocks}:{config.GetLocalPort(Global.InboundSocks2)}]");
                sb.Append(" | ");
                sb.Append($"[{Global.InboundHttp}:{config.GetLocalPort(Global.InboundHttp2)}]");
            }

            SetToolSslInfo("inbound", sb.ToString());
        }

        public void SetToolSslInfo(string type, string value)
        {
            switch (type)
            {
                case "speed":
                    toolSslServerSpeed.Text = value;
                    break;
                case "inbound":
                    toolSslInboundInfo.Text = value;
                    break;
                case "routing":
                    toolSslRoutingRule.Text = value;
                    break;
            }

        }

        public void ScrollToCaret()
        {
            txtMsgBox.ScrollToCaret();
        }
        #endregion


        #region MsgBoxMenu
        private void menuMsgBoxSelectAll_Click(object sender, EventArgs e)
        {
            txtMsgBox.Focus();
            txtMsgBox.SelectAll();
        }

        private void menuMsgBoxCopy_Click(object sender, EventArgs e)
        {
            var data = txtMsgBox.SelectedText.TrimEx();
            Utils.SetClipboardData(data);
        }

        private void menuMsgBoxCopyAll_Click(object sender, EventArgs e)
        {
            var data = txtMsgBox.Text;
            Utils.SetClipboardData(data);
        }
        private void menuMsgBoxClear_Click(object sender, EventArgs e)
        {
            ClearMsg();
        }
        private void txtMsgBox_KeyDown(object sender, KeyEventArgs e)
        {
            if (e.Control)
            {
                switch (e.KeyCode)
                {
                    case Keys.A:
                        menuMsgBoxSelectAll_Click(null, null);
                        break;
                    case Keys.C:
                        menuMsgBoxCopy_Click(null, null);
                        break;
                }
            }

        }
        private void ssMain_ItemClicked(object sender, ToolStripItemClickedEventArgs e)
        {
            if (!Utils.IsNullOrEmpty(e.ClickedItem.Text))
            {
                Utils.SetClipboardData(e.ClickedItem.Text);
            }
        }
        #endregion


    }
}
