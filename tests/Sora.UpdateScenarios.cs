using System;
using System.IO;
using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using System.Text;
using System.Threading.Tasks;
using Chaos.NaCl;
using NetSparkleUpdater;
using NetSparkleUpdater.AssemblyAccessors;
using NetSparkleUpdater.Configurations;
using NetSparkleUpdater.Enums;
using NetSparkleUpdater.SignatureVerifiers;

public static class SoraUpdateScenarios
{
    // A real loopback HTTP fixture; no installer is ever executed by this test.
    public static async Task<string> Run(string executable, string root)
    {
        var seed = new byte[32];
        using (var rng = RandomNumberGenerator.Create()) rng.GetBytes(seed);
        var expanded = Ed25519.ExpandedPrivateKeyFromSeed(seed);
        var verifier = new Ed25519Checker(SecurityMode.Strict, Convert.ToBase64String(Ed25519.PublicKeyFromSeed(seed)));
        var probe = new TcpListener(IPAddress.Loopback, 0);
        probe.Start();
        int port = ((IPEndPoint)probe.LocalEndpoint).Port;
        probe.Stop();
        string origin = "http://localhost:" + port + "/";
        var payload = Encoding.UTF8.GetBytes(new string('s', 1024 * 1024));
        string signature = Convert.ToBase64String(Ed25519.Sign(payload, expanded));
        string feed = "<rss version=\"2.0\" xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\"><channel><title>Sora QA</title><item><title>Sora QA</title><enclosure url=\"" + origin + "package.exe\" sparkle:version=\"99.0.0\" sparkle:os=\"windows\" length=\"" + payload.Length + "\" type=\"application/octet-stream\" sparkle:signature=\"" + signature + "\" /></item></channel></rss>";
        string feedSignature = Convert.ToBase64String(Ed25519.Sign(Encoding.UTF8.GetBytes(feed), expanded));
        string mode = "valid";
        var received = new TaskCompletionSource<bool>(TaskCreationOptions.RunContinuationsAsynchronously);
        using (var listener = new HttpListener())
        {
            listener.Prefixes.Add(origin);
            listener.Start();
            var server = Task.Run(async () =>
            {
                while (listener.IsListening)
                {
                    HttpListenerContext context;
                    try { context = await listener.GetContextAsync(); }
                    catch (HttpListenerException) { break; }
                    catch (ObjectDisposedException) { break; }
                    try
                    {
                        string path = context.Request.Url.AbsolutePath;
                        byte[] content;
                        if (path == "/appcast.xml") content = Encoding.UTF8.GetBytes(mode == "bad-feed" ? feed + " " : feed);
                        else if (path == "/appcast.xml.signature") content = Encoding.UTF8.GetBytes(feedSignature);
                        else if (path == "/package.exe")
                        {
                            if (mode == "http-error") { context.Response.StatusCode = 503; context.Response.Close(); continue; }
                            content = (byte[])payload.Clone();
                            if (mode == "bad-package") content[0] ^= 1;
                        }
                        else { context.Response.StatusCode = 404; context.Response.Close(); continue; }
                        context.Response.ContentLength64 = content.Length;
                        if (path == "/package.exe" && mode == "slow")
                        {
                            await context.Response.OutputStream.WriteAsync(content, 0, 32768);
                            await context.Response.OutputStream.FlushAsync();
                            received.TrySetResult(true);
                            await Task.Delay(1000);
                            await context.Response.OutputStream.WriteAsync(content, 32768, content.Length - 32768);
                        }
                        else await context.Response.OutputStream.WriteAsync(content, 0, content.Length);
                    }
                    catch (HttpListenerException) { /* Cancellation closes the client socket. */ }
                    catch (IOException) { /* Cancellation closes the client socket. */ }
                    finally { context.Response.Close(); }
                }
            });
            try
            {
                using (var updater = new SparkleUpdater(origin + "appcast.xml", verifier, executable))
                {
                    updater.Configuration = new DefaultConfiguration(new AssemblyDiagnosticsAccessor(executable));
                    updater.UserInteractionMode = UserInteractionMode.DownloadNoInstall;
                    updater.CheckServerFileName = false;
                    updater.TmpDownloadFilePath = root;
                    var outcome = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                    updater.DownloadFinished += (item, path) => outcome.TrySetResult("valid");
                    updater.DownloadedFileIsCorrupt += (item, path) => outcome.TrySetResult("corrupt");
                    updater.DownloadHadError += (item, path, error) => outcome.TrySetResult("error");
                    updater.DownloadCanceled += (item, path) => outcome.TrySetResult("canceled");
                    Console.WriteLine("SCENARIO: signed feed");
                    var check = await Deadline(updater.CheckForUpdatesQuietly(true));
                    if (check.Status != UpdateStatus.UpdateAvailable) throw new Exception("Signed HTTP feed did not yield an update: " + check.Status);
                    var update = check.Updates[0];
                    foreach (string scenario in new[] { "valid", "bad-package", "http-error", "valid" })
                    {
                        mode = scenario;
                        Console.WriteLine("SCENARIO: " + scenario);
                        outcome = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                        updater.TmpDownloadFileNameWithExtension = Guid.NewGuid().ToString("N") + ".exe";
                        await Deadline(updater.InitAndBeginDownload(update));
                        string result = await Deadline(outcome.Task);
                        string expected = scenario == "bad-package" ? "corrupt" : scenario == "http-error" ? "error" : "valid";
                        if (result != expected) throw new Exception(scenario + ": expected " + expected + ", got " + result);
                        // NetSparkle raises both corrupt and error before clearing its active item.
                        if (result != "error")
                        {
                            var until = DateTime.UtcNow.AddSeconds(5);
                            while (updater.IsDownloadingItem(update) && DateTime.UtcNow < until) await Task.Delay(1);
                            if (updater.IsDownloadingItem(update)) throw new Exception("Completed download retained its active item.");
                        }
                    }
                    mode = "slow";
                    Console.WriteLine("SCENARIO: cancel");
                    outcome = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                    updater.TmpDownloadFileNameWithExtension = Guid.NewGuid().ToString("N") + ".exe";
                    var download = updater.InitAndBeginDownload(update);
                    await Deadline(received.Task);
                    updater.CancelFileDownload();
                    string cancellation = await Deadline(outcome.Task);
                    await Deadline(download);
                    if (cancellation == "valid") throw new Exception("Canceled download was accepted.");
                    mode = "bad-feed";
                    Console.WriteLine("SCENARIO: tampered feed");
                    check = await Deadline(updater.CheckForUpdatesQuietly(true));
                    if (check.Status != UpdateStatus.CouldNotDetermine) throw new Exception("Tampered feed was accepted: " + check.Status);
                    return "PASS: signed HTTP feed, download, corrupt package, HTTP 503, retry, tampered feed. Cancellation event: " + cancellation;
                }
            }
            finally
            {
                listener.Stop();
                Deadline(server).GetAwaiter().GetResult();
                Array.Clear(seed, 0, seed.Length);
                Array.Clear(expanded, 0, expanded.Length);
            }
        }
    }

    private static async Task<T> Deadline<T>(Task<T> task)
    {
        await Deadline((Task)task);
        return await task;
    }

    private static async Task Deadline(Task task)
    {
        if (await Task.WhenAny(task, Task.Delay(20000)) != task) throw new TimeoutException("Update scenario timed out.");
        await task;
    }
}
