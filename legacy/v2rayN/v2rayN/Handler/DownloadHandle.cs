using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Polly;
using Polly.Retry;
using v2rayN.Base;
using v2rayN.Resx;

namespace v2rayN.Handler
{
    /// <summary>
    ///Download
    /// </summary>
    class DownloadHandle
    {
        private static readonly ResiliencePipeline<string> SubscriptionDownloadPipeline =
            new ResiliencePipelineBuilder<string>()
                .AddRetry(new RetryStrategyOptions<string>
                {
                    ShouldHandle = new PredicateBuilder<string>()
                        .Handle<HttpRequestException>()
                        .Handle<TaskCanceledException>(),
                    MaxRetryAttempts = 1,
                    Delay = TimeSpan.FromSeconds(1),
                    BackoffType = DelayBackoffType.Constant,
                    UseJitter = true
                })
                .Build();

        public event EventHandler<ResultEventArgs> UpdateCompleted;

        public event ErrorEventHandler Error;

        public string LastProfileTitle { get; private set; }

        public string LastProfileUpdateInterval { get; private set; }

        public string LastSubscriptionUserinfo { get; private set; }

        public string LastSubscriptionAnnouncement { get; private set; }


        public class ResultEventArgs : EventArgs
        {
            public bool Success;
            public string Msg;

            public ResultEventArgs(bool success, string msg)
            {
                Success = success;
                Msg = msg;
            }
        }

        public async Task<int> DownloadDataAsync(string url, WebProxy webProxy, int downloadTimeout)
        {
            try
            {
                Utils.SetSecurityProtocol(LazyConfig.Instance.GetConfig().enableSecurityProtocolTls13);
                UpdateCompleted?.Invoke(this, new ResultEventArgs(false, ResUI.Speedtesting));

                var client = new HttpClient(new WebRequestHandler()
                {
                    Proxy = webProxy
                });

                var progress = new Progress<string>();
                progress.ProgressChanged += (sender, value) =>
                {
                    if (UpdateCompleted != null)
                    {
                        string msg = $"{value} M/s".PadLeft(9, ' ');
                        UpdateCompleted(this, new ResultEventArgs(false, msg));
                    }
                };

                var cancellationToken = new CancellationTokenSource();
                cancellationToken.CancelAfter(downloadTimeout * 1000);
                await HttpClientHelper.GetInstance().DownloadDataAsync4Speed(client,
                      url,
                      progress,
                      cancellationToken.Token);
            }
            catch (Exception ex)
            {
                //Utils.SaveLog(ex.Message, ex);
                Error?.Invoke(this, new ErrorEventArgs(ex)); 
                if (ex.InnerException != null)
                {
                    Error?.Invoke(this, new ErrorEventArgs(ex.InnerException));
                }
            }
            return 0;
        }

        public void DownloadFileAsync(string url, bool blProxy, int downloadTimeout)
        {
            try
            {
                Utils.SetSecurityProtocol(LazyConfig.Instance.GetConfig().enableSecurityProtocolTls13);
                UpdateCompleted?.Invoke(this, new ResultEventArgs(false, ResUI.Downloading));

                var client = new HttpClient(new WebRequestHandler()
                {
                    Proxy = GetWebProxy(blProxy)
                });

                var progress = new Progress<double>();
                progress.ProgressChanged += (sender, value) =>
                {
                    if (UpdateCompleted != null)
                    {
                        string msg = $"...{value}%";
                        UpdateCompleted(this, new ResultEventArgs(value > 100 ? true : false, msg));
                    }
                };

                var cancellationToken = new CancellationTokenSource();
                _ = HttpClientHelper.GetInstance().DownloadFileAsync(client,
                       url,
                       Utils.GetPath(Utils.GetDownloadFileName(url)),
                       progress,
                       cancellationToken.Token);
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);

                Error?.Invoke(this, new ErrorEventArgs(ex)); 
                if (ex.InnerException != null)
                {
                    Error?.Invoke(this, new ErrorEventArgs(ex.InnerException));
                }
            }
        }

        public async Task<string> UrlRedirectAsync(string url, bool blProxy)
        {
            Utils.SetSecurityProtocol(LazyConfig.Instance.GetConfig().enableSecurityProtocolTls13);
            WebRequestHandler webRequestHandler = new WebRequestHandler
            {
                AllowAutoRedirect = false,
                Proxy = GetWebProxy(blProxy)
            };
            HttpClient client = new HttpClient(webRequestHandler);

            HttpResponseMessage response = await client.GetAsync(url);
            if (response.StatusCode.ToString() == "Redirect")
            {
                return response.Headers.Location.ToString();
            }
            else
            {
                Utils.SaveLog("StatusCode error: " + url);
                return null;
            }
        }

        /// <summary>
        /// DownloadString
        /// </summary> 
        /// <param name="url"></param>
        public async Task<string> DownloadStringAsync(string url, bool blProxy, string userAgent)
        {
            try
            {
                Utils.SetSecurityProtocol(LazyConfig.Instance.GetConfig().enableSecurityProtocolTls13);
                return await SubscriptionDownloadPipeline.ExecuteAsync(async retryToken =>
                {
                    using (var client = new HttpClient(new WebRequestHandler
                    {
                        Proxy = GetWebProxy(blProxy)
                    }))
                    using (var timeout = CancellationTokenSource.CreateLinkedTokenSource(retryToken))
                    {
                        string requestUserAgent = Utils.IsNullOrEmpty(userAgent)
                            ? Utils.GetVersion(false)
                            : userAgent;
                        client.DefaultRequestHeaders.UserAgent.TryParseAdd(requestUserAgent);

                        Uri uri = new Uri(url);
                        if (!Utils.IsNullOrEmpty(uri.UserInfo))
                        {
                            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Basic", Utils.Base64Encode(uri.UserInfo));
                        }

                        timeout.CancelAfter(TimeSpan.FromSeconds(30));
                        using (HttpResponseMessage response = await client.GetAsync(url, timeout.Token))
                        {
                            if (!response.IsSuccessStatusCode)
                            {
                                throw new Exception(string.Format("The request returned with HTTP status code {0}", response.StatusCode));
                            }
                            LastProfileTitle = GetResponseHeader(response, "Profile-Title");
                            LastProfileUpdateInterval = GetResponseHeader(response, "Profile-Update-Interval");
                            LastSubscriptionUserinfo = GetResponseHeader(response, "Subscription-Userinfo");
                            LastSubscriptionAnnouncement = GetResponseHeader(response, "Announce");
                            return await response.Content.ReadAsStringAsync();
                        }
                    }
                }, CancellationToken.None);
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                Error?.Invoke(this, new ErrorEventArgs(ex));
                if (ex.InnerException != null)
                {
                    Error?.Invoke(this, new ErrorEventArgs(ex.InnerException));
                }
            }
            return null;
        }

        private static string GetResponseHeader(HttpResponseMessage response, string name)
        {
            if (!response.Headers.TryGetValues(name, out IEnumerable<string> values)) return null;
            foreach (string value in values) return value;
            return null;
        }

        public int RunAvailabilityCheck(WebProxy webProxy)
        {
            try
            {
                if (webProxy == null)
                {
                    var httpPort = LazyConfig.Instance.GetConfig().GetLocalPort(Global.InboundHttp);
                    webProxy = new WebProxy(Global.Loopback, httpPort);
                }

                try
                {
                    string status = GetRealPingTime(Global.SpeedPingTestUrl, webProxy, out int responseTime);
                    bool noError = Utils.IsNullOrEmpty(status);
                    return noError ? responseTime : -1;
                }
                catch (Exception ex)
                {
                    Utils.SaveLog(ex.Message, ex);
                    return -1;
                }
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                return -1;
            }
        }

        public string GetRealPingTime(string url, WebProxy webProxy, out int responseTime)
        {
            string msg = string.Empty;
            responseTime = -1;
            try
            {
                HttpWebRequest myHttpWebRequest = (HttpWebRequest)WebRequest.Create(url);
                myHttpWebRequest.Timeout = 30 * 1000;
                myHttpWebRequest.Proxy = webProxy;

                Stopwatch timer = new Stopwatch();
                timer.Start();

                HttpWebResponse myHttpWebResponse = (HttpWebResponse)myHttpWebRequest.GetResponse();
                if (myHttpWebResponse.StatusCode != HttpStatusCode.OK
                    && myHttpWebResponse.StatusCode != HttpStatusCode.NoContent)
                {
                    msg = myHttpWebResponse.StatusDescription;
                }
                timer.Stop();
                responseTime = Math.Max(1, (int)Math.Round(timer.Elapsed.TotalMilliseconds));

                myHttpWebResponse.Close();
            }
            catch (Exception ex)
            {
                Utils.SaveLog(ex.Message, ex);
                msg = ex.Message;
            }
            return msg;
        }

        private WebProxy GetWebProxy(bool blProxy)
        {
            if (!blProxy)
            {
                return null;
            }
            var httpPort = LazyConfig.Instance.GetConfig().GetLocalPort(Global.InboundHttp);
            if (!SocketCheck(Global.Loopback, httpPort))
            {
                return null;
            }

            return new WebProxy(Global.Loopback, httpPort);
        }

        private bool SocketCheck(string ip, int port)
        {
            Socket sock = null;
            try
            {
                IPAddress ipa = IPAddress.Parse(ip);
                IPEndPoint point = new IPEndPoint(ipa, port);
                sock = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
                sock.Connect(point);
                return true;
            }
            catch { }
            finally
            {
                if (sock != null)
                {
                    sock.Close();
                    sock.Dispose();
                }
            }
            return false;
        }
    }
}
