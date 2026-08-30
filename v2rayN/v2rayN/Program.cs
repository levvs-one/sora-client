using System;
using System.Linq;
using System.Diagnostics;
using System.Threading;
using System.Windows.Forms;
using v2rayN.Forms;
using v2rayN.Tool;

namespace v2rayN
{
    static class Program
    {
        /// <summary>
        /// 应用程序的主入口点。
        /// </summary>
        [STAThread]
        static void Main(string[] args)
        {
            if (args.Any(arg => string.Equals(arg, "--restore-proxy", StringComparison.OrdinalIgnoreCase)))
            {
                Logging.Setup();
                Environment.ExitCode = Handler.SysProxyHandle.ResetIEProxy() ? 0 : 1;
                return;
            }
            WaitForPreviousInstance(args);
            if (Environment.OSVersion.Version.Major >= 6)
            {
                Utils.SetProcessDPIAware();
            }

            Application.SetUnhandledExceptionMode(UnhandledExceptionMode.CatchException);
            Application.ThreadException += Application_ThreadException;
            AppDomain.CurrentDomain.UnhandledException += CurrentDomain_UnhandledException;


            //AppDomain.CurrentDomain.AssemblyResolve += CurrentDomain_AssemblyResolve;

            if (!IsDuplicateInstance())
            {
                Logging.Setup();
            Utils.SaveLog($"Sora start up | {Utils.GetVersion()}");
                Logging.ClearLogs();

                var culture = SoraText.CurrentCulture;
                Thread.CurrentThread.CurrentCulture = culture;
                Thread.CurrentThread.CurrentUICulture = culture;

                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new MainForm(
                    args.Any(arg => string.Equals(arg, "--silent", StringComparison.OrdinalIgnoreCase)),
                    args.Any(arg => string.Equals(arg, "--tun", StringComparison.OrdinalIgnoreCase))));
            }
            else
            {
                try
                {
                    //read handle from reg and show the window
                    long.TryParse(Utils.RegReadValue(Global.MyRegPath, Utils.WindowHwndKey, ""), out long llong);
                    if (llong > 0)
                    {
                        var hwnd = (IntPtr)llong;
                        if (Utils.IsWindow(hwnd))
                        {
                            Utils.ShowWindow(hwnd, 4);
                            Utils.SwitchToThisWindow(hwnd, true);
                            return;
                        }
                    }
                }
                catch { }
                UI.ShowWarning("Sora уже запущен.");
            }
        }

        private static void WaitForPreviousInstance(string[] args)
        {
            int marker = Array.FindIndex(args, arg => string.Equals(arg, "--wait-for", StringComparison.OrdinalIgnoreCase));
            if (marker < 0 || marker + 1 >= args.Length || !int.TryParse(args[marker + 1], out int processId))
            {
                return;
            }
            try
            {
                Process.GetProcessById(processId).WaitForExit(15000);
            }
            catch
            {
            }
        }

        //private static Assembly CurrentDomain_AssemblyResolve(object sender, ResolveEventArgs args)
        //{
        //    try
        //    {
        //        string resourceName = "v2rayN.LIB." + new AssemblyName(args.Name).Name + ".dll";
        //        using (var stream = Assembly.GetExecutingAssembly().GetManifestResourceStream(resourceName))
        //        {
        //            if (stream == null)
        //            {
        //                return null;
        //            }
        //            byte[] assemblyData = new byte[stream.Length];
        //            stream.Read(assemblyData, 0, assemblyData.Length);
        //            return Assembly.Load(assemblyData);
        //        }
        //    }
        //    catch
        //    {
        //        return null;
        //    }
        //}

        /// <summary> 
        /// 检查是否已在运行
        /// </summary> 
        public static bool IsDuplicateInstance()
        {
            //string name = "v2rayN";

            string name = Utils.GetExePath(); // Allow different locations to run
            name = name.Replace("\\", "/"); // https://stackoverflow.com/questions/20714120/could-not-find-a-part-of-the-path-error-while-creating-mutex

            Global.mutexObj = new Mutex(false, name, out bool bCreatedNew);
            return !bCreatedNew;
        }

        static void Application_ThreadException(object sender, ThreadExceptionEventArgs e)
        {
            Utils.SaveLog("Application_ThreadException", e.Exception);
        }

        static void CurrentDomain_UnhandledException(object sender, UnhandledExceptionEventArgs e)
        {
            Utils.SaveLog("CurrentDomain_UnhandledException", (Exception)e.ExceptionObject);
        }
    }
}
