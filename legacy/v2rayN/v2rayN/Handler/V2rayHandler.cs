using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json.Linq;
using v2rayN.Mode;
using v2rayN.Resx;

namespace v2rayN.Handler
{

    /// <summary>
    /// 消息委托
    /// </summary>
    /// <param name="notify">是否显示在托盘区</param>
    /// <param name="msg">内容</param>
    public delegate void ProcessDelegate(bool notify, string msg);

    /// <summary>
    /// v2ray进程处理类
    /// </summary>
    class V2rayHandler
    {
        private static string v2rayConfigRes = Global.v2rayConfigFileName;
        private CoreInfo coreInfo;
        public event ProcessDelegate ProcessEvent;
        private int processId = 0;
        private Process _process;

        public bool IsRunning => _process != null && !_process.HasExited;

        public V2rayHandler()
        {
        }

        /// <summary>
        /// 载入V2ray
        /// </summary>
        public void LoadV2ray(Config config)
        {
            if (Global.reloadV2ray)
            {
                var item = ConfigHandler.GetDefaultServer(ref config);
                if (item == null)
                {
                    ShowMsg(false, ResUI.CheckServerSettings);
                    return;
                }

                if (SetCore(config, item) != 0)
                {
                    ShowMsg(false, ResUI.CheckServerSettings);
                    return;
                }
                string fileName = Utils.GetPath(v2rayConfigRes);
                if (V2rayConfigHandler.GenerateClientConfig(item, fileName, out string msg, out string content) != 0)
                {
                    ShowMsg(false, msg);
                }
                else
                {
                    if (item.configType == EConfigType.Custom && coreInfo.coreType == ECoreType.Xray)
                    {
                        NormalizeCustomXrayInbounds(config, fileName);
                    }
                    ShowMsg(false, msg);
                    ShowMsg(true, $"[{config.GetGroupRemarks(item.groupId)}] {item.GetSummary()}");
                    V2rayRestart();
                }

                //start a socks service
                if (_process != null && !_process.HasExited && item.configType == EConfigType.Custom && item.preSocksPort > 0)
                {
                    var itemSocks = new VmessItem()
                    {
                        configType = EConfigType.Socks,
                        address = Global.Loopback,
                        port = item.preSocksPort
                    };
                    if (V2rayConfigHandler.GenerateClientConfig(itemSocks, null, out string msg2, out string configStr) == 0)
                    {
                        processId = V2rayStartNew(configStr);
                    }
                }
            }
        }

        /// <summary>
        /// 新建进程，载入V2ray配置文件字符串
        /// 返回新进程pid。
        /// </summary>
        public int LoadV2rayConfigString(Config config, List<ServerTestItem> _selecteds)
        {
            int pid = -1;
            string configStr = V2rayConfigHandler.GenerateClientSpeedtestConfigString(config, _selecteds, out string msg);
            if (configStr == "")
            {
                ShowMsg(false, msg);
            }
            else
            {
                ShowMsg(false, msg);
                pid = V2rayStartNew(configStr);
                //V2rayRestart();
                // start with -config
            }
            return pid;
        }

        public int LoadCustomSpeedtestConfig(VmessItem item, int localPort)
        {
            try
            {
                string path = File.Exists(item.address) ? item.address : Utils.GetConfigPath(item.address);
                if (!File.Exists(path))
                {
                    return -1;
                }
                JObject custom = JObject.Parse(File.ReadAllText(path));
                JArray outbounds = custom["outbounds"] as JArray;
                if (outbounds == null || outbounds.Count == 0)
                {
                    return -1;
                }

                JObject httpInbound = null;
                JArray inbounds = custom["inbounds"] as JArray;
                if (inbounds != null)
                {
                    foreach (JToken token in inbounds)
                    {
                        JObject inbound = token as JObject;
                        if (inbound == null)
                        {
                            continue;
                        }
                        if (string.Equals((string)inbound["protocol"], Global.InboundHttp, StringComparison.OrdinalIgnoreCase))
                        {
                            httpInbound = (JObject)inbound.DeepClone();
                            break;
                        }
                    }
                }
                if (httpInbound == null)
                {
                    httpInbound = new JObject
                    {
                        ["protocol"] = Global.InboundHttp,
                        ["tag"] = Global.InboundHttp
                    };
                }
                httpInbound["listen"] = Global.Loopback;
                httpInbound["port"] = localPort;
                httpInbound["settings"] = new JObject();
                custom["inbounds"] = new JArray(httpInbound);
                return V2rayStartNew(custom.ToString(Newtonsoft.Json.Formatting.None));
            }
            catch (Exception exception)
            {
                Utils.SaveLog(exception.Message, exception);
                return -1;
            }
        }

        private static void NormalizeCustomXrayInbounds(Config config, string fileName)
        {
            JObject document = JObject.Parse(File.ReadAllText(fileName));
            JArray inbounds = document["inbounds"] as JArray ?? new JArray();
            string listen = config.inbound[0].allowLANConn ? "0.0.0.0" : Global.Loopback;
            SetCustomXrayInbound(inbounds, Global.InboundSocks, config.GetLocalPort(Global.InboundSocks), listen, true);
            SetCustomXrayInbound(inbounds, Global.InboundHttp, config.GetLocalPort(Global.InboundHttp), listen, false);
            document["inbounds"] = inbounds;
            File.WriteAllText(fileName, document.ToString(Newtonsoft.Json.Formatting.None), new UTF8Encoding(false));
        }

        private static void SetCustomXrayInbound(JArray inbounds, string protocol, int port, string listen, bool socks)
        {
            JObject inbound = null;
            foreach (JObject candidate in inbounds.OfType<JObject>())
            {
                if (string.Equals((string)candidate["protocol"], protocol, StringComparison.OrdinalIgnoreCase))
                {
                    inbound = candidate;
                    break;
                }
            }
            if (inbound == null)
            {
                inbound = new JObject
                {
                    ["tag"] = protocol,
                    ["protocol"] = protocol,
                    ["settings"] = socks
                        ? new JObject { ["auth"] = "noauth", ["udp"] = true }
                        : new JObject { ["allowTransparent"] = false }
                };
                inbounds.Add(inbound);
            }
            inbound["listen"] = listen;
            inbound["port"] = port;
        }

        /// <summary>
        /// V2ray重启
        /// </summary>
        private void V2rayRestart()
        {
            V2rayStop();
            V2rayStart();
        }

        /// <summary>
        /// V2ray停止
        /// </summary>
        public void V2rayStop()
        {
            try
            {
                if (_process != null)
                {
                    KillProcess(_process);
                    _process.Dispose();
                    _process = null;
                }
                else
                {
                    if (coreInfo == null || coreInfo.coreExes == null)
                    {
                        return;
                    }
                    foreach (string vName in coreInfo.coreExes)
                    {
                        Process[] existing = Process.GetProcessesByName(vName);
                        foreach (Process p in existing)
                        {
                            try
                            {
                                string path = p.MainModule?.FileName;
                                if (string.Equals(path, $"{Utils.GetPath(vName)}.exe", StringComparison.OrdinalIgnoreCase))
                                {
                                    KillProcess(p);
                                }
                            }
                            catch (Win32Exception)
                            {
                                // A non-elevated client cannot inspect an unrelated elevated process.
                            }
                            catch (InvalidOperationException)
                            {
                                // The process can exit between enumeration and path inspection.
                            }
                            finally
                            {
                                p.Dispose();
                            }
                        }
                    }
                }

                if (processId > 0)
                {
                    V2rayStopPid(processId);
                    processId = 0;
                }

            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
        }
        /// <summary>
        /// V2ray停止
        /// </summary>
        public void V2rayStopPid(int pid)
        {
            try
            {
                Process _p = Process.GetProcessById(pid);
                KillProcess(_p);
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
        }

        private string V2rayFindexe(List<string> lstCoreTemp)
        {
            string fileName = string.Empty;
            foreach (string name in lstCoreTemp)
            {
                string vName = $"{name}.exe";
                vName = Utils.GetPath(vName);
                if (File.Exists(vName))
                {
                    fileName = vName;
                    break;
                }
            }
            if (Utils.IsNullOrEmpty(fileName))
            {
                string msg = string.Format(ResUI.NotFoundCore, string.Join(", ", lstCoreTemp.ToArray()), coreInfo.coreUrl);
                ShowMsg(false, msg);
            }
            return fileName;
        }

        /// <summary>
        /// V2ray启动
        /// </summary>
        private void V2rayStart()
        {
            ShowMsg(false, string.Format(ResUI.StartService, DateTime.Now.ToString()));

            try
            {
                string fileName = V2rayFindexe(coreInfo.coreExes);
                if (fileName == "") return;

                Process p = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = fileName,
                        Arguments = coreInfo.arguments,
                        WorkingDirectory = Utils.StartupPath(),
                        UseShellExecute = false,
                        RedirectStandardOutput = coreInfo.redirectInfo,
                        RedirectStandardError = coreInfo.redirectInfo,
                        CreateNoWindow = true,
                        StandardOutputEncoding = coreInfo.redirectInfo ? Encoding.UTF8 : null,
                        StandardErrorEncoding = coreInfo.redirectInfo ? Encoding.UTF8 : null,
                    }
                };
                var startupErrors = new StringBuilder();
                var startupErrorSync = new object();
                if (coreInfo.redirectInfo)
                {
                    p.OutputDataReceived += (sender, e) =>
                    {
                        if (!String.IsNullOrEmpty(e.Data))
                        {
                            string msg = e.Data + Environment.NewLine;
                            ShowMsg(false, msg);
                        }
                    };
                    p.ErrorDataReceived += (sender, e) =>
                    {
                        if (!String.IsNullOrEmpty(e.Data))
                        {
                            lock (startupErrorSync) startupErrors.AppendLine(e.Data);
                            ShowMsg(false, e.Data + Environment.NewLine);
                        }
                    };
                }
                p.Start();
                if (coreInfo.redirectInfo)
                {
                    p.BeginOutputReadLine();
                    p.BeginErrorReadLine();
                }
                _process = p;

                if (p.WaitForExit(1000))
                {
                    p.WaitForExit();
                    string error;
                    lock (startupErrorSync) error = startupErrors.ToString();
                    throw new Exception(string.IsNullOrWhiteSpace(error)
                        ? $"Ядро завершилось сразу после запуска (код {p.ExitCode}). Проверьте вкладку «Ядро»."
                        : error.Trim());
                }

                Global.processJob.AddProcess(p.Handle);
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                string msg = ex.Message;
                ShowMsg(true, msg);
            }
        }
        /// <summary>
        /// V2ray启动，新建进程，传入配置字符串
        /// </summary>
        private int V2rayStartNew(string configStr)
        {
            ShowMsg(false, string.Format(ResUI.StartService, DateTime.Now.ToString()));

            try
            {
                string fileName = V2rayFindexe(new List<string> { "xray", "wv2ray", "v2ray" });
                if (fileName == "") return -1;

                Process p = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = fileName,
                        Arguments = "run -c stdin:",
                        WorkingDirectory = Utils.StartupPath(),
                        UseShellExecute = false,
                        RedirectStandardInput = true,
                        RedirectStandardOutput = true,
                        RedirectStandardError = true,
                        CreateNoWindow = true,
                        StandardOutputEncoding = Encoding.UTF8,
                        StandardErrorEncoding = Encoding.UTF8
                    }
                };
                var startupErrors = new StringBuilder();
                var startupErrorSync = new object();
                p.OutputDataReceived += (sender, e) =>
                {
                    if (!String.IsNullOrEmpty(e.Data))
                    {
                        string msg = e.Data + Environment.NewLine;
                        ShowMsg(false, msg);
                    }
                };
                p.ErrorDataReceived += (sender, e) =>
                {
                    if (!String.IsNullOrEmpty(e.Data))
                    {
                        lock (startupErrorSync) startupErrors.AppendLine(e.Data);
                        ShowMsg(false, e.Data + Environment.NewLine);
                    }
                };
                p.Start();
                p.BeginOutputReadLine();
                p.BeginErrorReadLine();

                p.StandardInput.Write(configStr);
                p.StandardInput.Close();

                if (p.WaitForExit(1000))
                {
                    p.WaitForExit();
                    string error;
                    lock (startupErrorSync) error = startupErrors.ToString();
                    throw new Exception(string.IsNullOrWhiteSpace(error)
                        ? $"Ядро проверки завершилось сразу после запуска (код {p.ExitCode})."
                        : error.Trim());
                }

                Global.processJob.AddProcess(p.Handle);
                return p.Id;
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                string msg = ex.Message;
                ShowMsg(false, msg);
                return -1;
            }
        }

        /// <summary>
        /// 消息委托
        /// </summary>
        /// <param name="updateToTrayTooltip">是否更新托盘图标的工具提示</param>
        /// <param name="msg">输出到日志框</param>
        private void ShowMsg(bool updateToTrayTooltip, string msg)
        {
            string text = msg ?? string.Empty;
            string tagged = text.StartsWith("[CORE]", StringComparison.Ordinal) ? text : "[CORE] " + text;
            if (!string.IsNullOrWhiteSpace(text))
            {
                Utils.SaveLog(tagged.TrimEnd());
            }
            ProcessEvent?.Invoke(updateToTrayTooltip, tagged);
        }

        private void KillProcess(Process p)
        {
            try
            {
                p.CloseMainWindow();
                p.WaitForExit(100);
                if (!p.HasExited)
                {
                    p.Kill();
                    p.WaitForExit(100);
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
        }

        private int SetCore(Config config, VmessItem item)
        {
            if (item == null)
            {
                return -1;
            }
            var coreType = LazyConfig.Instance.GetCoreType(item, item.configType);

            coreInfo = LazyConfig.Instance.GetCoreInfo(coreType);

            if (coreInfo == null)
            {
                return -1;
            }
            return 0;
        }
    }
}
