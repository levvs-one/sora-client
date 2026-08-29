using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Forms;
using v2rayN.Base;
using v2rayN.Mode;
using v2rayN.Resx;

namespace v2rayN.Forms
{
    public partial class MainMsgControl : UserControl
    {
        private const int MaximumHistoryEntries = 2000;
        private string _msgFilter = string.Empty;
        private readonly List<string> _history = new List<string>();
        delegate void AppendTextDelegate(string text);

        public MainMsgControl()
        {
            InitializeComponent();
            HandleCreated += (sender, args) => SetCommunityFilter(_msgFilter);
        }

        private void MainMsgControl_Load(object sender, EventArgs e)
        {
            _msgFilter = Utils.RegReadValue(Global.MyRegPath, Utils.MainMsgFilterKey, "");
            if (!Utils.IsNullOrEmpty(_msgFilter))
            {
                gbMsgTitle.Text = string.Format(ResUI.MsgInformationTitle, _msgFilter);
            }
        }

        #region 提示信息

        public void AppendText(string text)
        {
            if (!IsHandleCreated)
            {
                lock (_history)
                {
                    Remember(text);
                }
                return;
            }
            if (txtMsgBox.InvokeRequired)
            {
                BeginInvoke(new AppendTextDelegate(AppendText), text);
            }
            else
            {
                lock (_history)
                {
                    Remember(text);
                }
                if (!Utils.IsNullOrEmpty(_msgFilter))
                {
                    if (!Regex.IsMatch(text, _msgFilter))
                    {
                        return;
                    }
                }
                //this.txtMsgBox.AppendText(text);
                ShowMsg(text);
            }
        }

        /// <summary>
        /// 提示信息
        /// </summary>
        /// <param name="msg"></param>
        private void ShowMsg(string msg)
        {
            if (txtMsgBox.Lines.Length > 999)
            {
                txtMsgBox.Clear();
            }
            txtMsgBox.AppendText(msg);
            if (!msg.EndsWith(Environment.NewLine))
            {
                txtMsgBox.AppendText(Environment.NewLine);
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
                }
                txtMsgBox.Text = string.Empty;
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
            }
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
            if (txtMsgBox.InvokeRequired)
            {
                txtMsgBox.Invoke((Action)(() => SetCommunityFilter(pattern)));
                return;
            }
            _msgFilter = pattern ?? string.Empty;
            txtMsgBox.Clear();
            string[] messages;
            lock (_history)
            {
                messages = _history.ToArray();
            }
            foreach (string message in messages)
            {
                if (Utils.IsNullOrEmpty(_msgFilter) || Regex.IsMatch(message, _msgFilter, RegexOptions.IgnoreCase))
                {
                    ShowMsg(message);
                }
            }
        }

        internal void ApplySoraTheme(Color background, Color surface, Color text, Color muted, Color border)
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
            ssMain.Parent = this;
            ssMain.Dock = DockStyle.Bottom;
            ssMain.Height = 24;
            ssMain.BackColor = background;
            ssMain.ForeColor = muted;
            ssMain.SizingGrip = false;
            foreach (ToolStripItem item in ssMain.Items)
            {
                item.ForeColor = muted;
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
