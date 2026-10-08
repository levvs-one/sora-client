#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <algorithm>

#include "app_links/app_links_plugin_c_api.h"
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // A link opened while Sora runs, from a browser or a messenger, goes to the
  // running window, which shows the import.
  if (SendAppLinkToInstance()) {
    return EXIT_SUCCESS;
  }

  // One window per session, as on Linux: a second start brings the open
  // window forward instead of starting another interface.
  HANDLE single = ::CreateMutexW(nullptr, TRUE, L"Local\\io.github.levvs_one.sora");
  if (single != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    if (HWND open = ::FindWindowW(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Sora")) {
      ::ShowWindow(open, SW_RESTORE);
      ::SetForegroundWindow(open);
    }
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  const bool start_hidden =
      std::find(command_line_arguments.begin(), command_line_arguments.end(),
                "--hidden") != command_line_arguments.end();
  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project, start_hidden);
  Win32Window::Point origin(10, 10);
  // Start with enough room for the server and connection panes.
  Win32Window::Size size(1120, 760);
  if (!window.Create(L"Sora", origin, size)) {
    return EXIT_FAILURE;
  }
  // The close button only hides the window, the app intercepts it; the
  // window is destroyed, and the app ends, when the person quits from the tray.
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
