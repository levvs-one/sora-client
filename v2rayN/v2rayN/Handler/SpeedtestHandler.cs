using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;
using v2rayN.Mode;
using v2rayN.Resx;

namespace v2rayN.Handler
{
    class SpeedtestHandler
    {
        private Config _config;
        private V2rayHandler _v2rayHandler;
        private List<ServerTestItem> _selecteds;
        Action<string, string> _updateFunc;

        public SpeedtestHandler(Config config)
        {
            _config = config;
        }

        public SpeedtestHandler(Config config, V2rayHandler v2rayHandler, List<VmessItem> selecteds, ESpeedActionType actionType, Action<string, string> update)
        {
            _config = config;
            _v2rayHandler = v2rayHandler;
            //_selecteds = Utils.DeepCopy(selecteds);
            _updateFunc = update;

            _selecteds = new List<ServerTestItem>();
            foreach (var it in selecteds)
            {
                var testItem = new ServerTestItem
                {
                    indexId = it.indexId,
                    address = it.address,
                    port = it.port,
                    configType = it.configType
                };
                if (it.configType == EConfigType.Custom)
                {
                    string configPath = File.Exists(it.address) ? it.address : Utils.GetConfigPath(it.address);
                    if (File.Exists(configPath)
                        && ConfigHandler.TryGetSoraXrayEndpoint(File.ReadAllText(configPath), out string address, out int port))
                    {
                        testItem.address = address;
                        testItem.port = port;
                    }
                }
                _selecteds.Add(testItem);
            }

            if (actionType == ESpeedActionType.Ping)
            {
                Task.Run(RunPing);
            }
            else if (actionType == ESpeedActionType.Tcping)
            {
                Task.Run(RunTcping);
            }
            else if (actionType == ESpeedActionType.Realping)
            {
                Task.Run(RunRealPing);
            }
            else if (actionType == ESpeedActionType.Speedtest)
            {
                Task.Run(RunSpeedTestAsync);
            }
        }

        private void RunPingSub(Action<ServerTestItem> updateFun)
        {
            try
            {
                Parallel.ForEach(_selecteds, new ParallelOptions { MaxDegreeOfParallelism = 12 }, it =>
                {
                    try
                    {
                        _updateFunc(it.indexId, "Проверка…");
                        updateFun(it);
                    }
                    catch (Exception ex)
                    {
                        Utils.SaveLog(ex.Message, ex);
                        _updateFunc(it.indexId, FormatOut(-1, "ms"));
                    }
                });
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
        }


        private void RunPing()
        {
            RunPingSub((ServerTestItem it) =>
            {
                long time = Utils.Ping(it.address);

                _updateFunc(it.indexId, FormatOut(time, "ms"));
            });
        }

        private void RunTcping()
        {
            RunPingSub((ServerTestItem it) =>
            {
                int time = GetTcpingTime(it.address, it.port);

                _updateFunc(it.indexId, FormatOut(time, "ms"));
            });
        }

        private void RunRealPing()
        {
            int pid = -1;
            try
            {
                string msg = string.Empty;
                List<ServerTestItem> regular = _selecteds.Where(item => item.configType != EConfigType.Custom).ToList();
                if (regular.Count > 0)
                {
                    pid = _v2rayHandler.LoadV2rayConfigString(_config, regular);
                    if (pid < 0)
                    {
                        foreach (ServerTestItem item in regular)
                        {
                            _updateFunc(item.indexId, "Нет ответа");
                        }
                    }
                }

                DownloadHandle downloadHandle = new DownloadHandle();
                List<Task> tasks = new List<Task>();
                foreach (var it in regular)
                {
                    if (!it.allowTest || pid < 0)
                    {
                        continue;
                    }
                    tasks.Add(Task.Run(() =>
                    {
                        try
                        {
                            WebProxy webProxy = new WebProxy(Global.Loopback, it.port);
                            int responseTime = -1;
                            string status = downloadHandle.GetRealPingTime(_config.constItem.speedPingTestUrl, webProxy, out responseTime);
                            string output = Utils.IsNullOrEmpty(status) ? FormatOut(responseTime, "мс") : "Нет ответа";

                            _config.GetVmessItem(it.indexId)?.SetTestResult(output);
                            _updateFunc(it.indexId, output);
                        }
                        catch (Exception ex)
                        {
                            Utils.SaveLog(ex.Message, ex);
                        }
                    }));
                    //Thread.Sleep(100);
                }
                Task.WaitAll(tasks.ToArray());

                foreach (ServerTestItem item in _selecteds.Where(selected => selected.configType == EConfigType.Custom))
                {
                    RunCustomRealPing(item, downloadHandle);
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
            finally
            {
                if (pid > 0) _v2rayHandler.V2rayStopPid(pid);
            }
        }

        private void RunCustomRealPing(ServerTestItem testItem, DownloadHandle downloadHandle)
        {
            int pid = -1;
            try
            {
                _updateFunc(testItem.indexId, "Проверка…");
                int localPort = FindAvailableLocalPort();
                VmessItem profile = _config.GetVmessItem(testItem.indexId);
                if (profile == null || localPort < 1)
                {
                    _updateFunc(testItem.indexId, "Нет ответа");
                    return;
                }

                pid = _v2rayHandler.LoadCustomSpeedtestConfig(profile, localPort);
                if (pid < 0 || !WaitForLocalPort(localPort, TimeSpan.FromSeconds(10)))
                {
                    _updateFunc(testItem.indexId, "Нет ответа");
                    return;
                }

                var proxy = new WebProxy(Global.Loopback, localPort);
                string status = downloadHandle.GetRealPingTime(_config.constItem.speedPingTestUrl, proxy, out int responseTime);
                string output = Utils.IsNullOrEmpty(status) ? FormatOut(responseTime, "мс") : "Нет ответа";
                profile.SetTestResult(output);
                _updateFunc(testItem.indexId, output);
            }
            catch (Exception exception)
            {
                Utils.SaveLog(exception.Message, exception);
                _updateFunc(testItem.indexId, "Нет ответа");
            }
            finally
            {
                if (pid > 0)
                {
                    _v2rayHandler.V2rayStopPid(pid);
                }
            }
        }

        private static int FindAvailableLocalPort()
        {
            try
            {
                var listener = new TcpListener(IPAddress.Loopback, 0);
                listener.Start();
                int port = ((IPEndPoint)listener.LocalEndpoint).Port;
                listener.Stop();
                return port;
            }
            catch
            {
                return -1;
            }
        }

        private static bool WaitForLocalPort(int port, TimeSpan timeout)
        {
            DateTime deadline = DateTime.UtcNow.Add(timeout);
            while (DateTime.UtcNow < deadline)
            {
                try
                {
                    using (var client = new TcpClient())
                    {
                        Task connection = client.ConnectAsync(IPAddress.Loopback, port);
                        if (connection.Wait(300) && client.Connected)
                        {
                            return true;
                        }
                    }
                }
                catch
                {
                }
                Thread.Sleep(150);
            }
            return false;
        }

        private async Task RunSpeedTestAsync()
        {
            string testIndexId = string.Empty;
            int pid = -1;

            pid = _v2rayHandler.LoadV2rayConfigString(_config, _selecteds);
            if (pid < 0)
            {
                _updateFunc(_selecteds[0].indexId, ResUI.OperationFailed);
                return;
            }

            string url = _config.constItem.speedTestUrl;
            DownloadHandle downloadHandle2 = new DownloadHandle();
            downloadHandle2.UpdateCompleted += (sender2, args) =>
            {
                _config.GetVmessItem(testIndexId)?.SetTestResult(args.Msg);
                _updateFunc(testIndexId, args.Msg);
            };
            downloadHandle2.Error += (sender2, args) =>
            {
                _updateFunc(testIndexId, args.GetException().Message);
            };

            var timeout = 8;
            foreach (var it in _selecteds)
            {
                if (!it.allowTest)
                {
                    continue;
                }
                if (it.configType == EConfigType.Custom)
                {
                    continue;
                }
                testIndexId = it.indexId;
                if (_config.FindIndexId(it.indexId) < 0) continue;

                WebProxy webProxy = new WebProxy(Global.Loopback, it.port);
                await downloadHandle2.DownloadDataAsync(url, webProxy, timeout);
            }

            if (pid > 0) _v2rayHandler.V2rayStopPid(pid);
        }


        private int GetTcpingTime(string url, int port)
        {
            int responseTime = -1;

            try
            {
                if (string.IsNullOrWhiteSpace(url) || port < 1 || port > 65535)
                {
                    return responseTime;
                }
                if (!IPAddress.TryParse(url, out IPAddress ipAddress))
                {
                    IPAddress[] addresses = System.Net.Dns.GetHostAddresses(url);
                    ipAddress = addresses.FirstOrDefault(address => address.AddressFamily == AddressFamily.InterNetwork)
                        ?? addresses.FirstOrDefault();
                }
                if (ipAddress == null)
                {
                    return responseTime;
                }

                IPEndPoint endPoint = new IPEndPoint(ipAddress, port);
                using (var clientSocket = new Socket(endPoint.AddressFamily, SocketType.Stream, ProtocolType.Tcp))
                {
                    var timer = Stopwatch.StartNew();
                    IAsyncResult result = clientSocket.BeginConnect(endPoint, null, null);
                    using (WaitHandle waitHandle = result.AsyncWaitHandle)
                    {
                        if (!waitHandle.WaitOne(TimeSpan.FromSeconds(5)))
                        {
                            return responseTime;
                        }
                    }
                    clientSocket.EndConnect(result);
                    timer.Stop();
                    responseTime = Math.Max(1, (int)Math.Round(timer.Elapsed.TotalMilliseconds));
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
            }
            return responseTime;
        }

        private static string FormatOut(object time, string unit)
        {
            if (time.ToString().Equals("-1"))
            {
                return "Нет ответа";
            }
            return $"{time} {unit}";
        }
    }
}
