import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:app_links/app_links.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nativeapi/nativeapi.dart' show LaunchAtLogin;
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import '../../l10n/strings.dart';
import '../groups.dart';
import '../notifications.dart';
import '../sora.dart';
import '../updates.dart';
import '../ui/kit.dart';
import '../ui/servers.dart';
import '../ui/subscription_sheet.dart';
import 'links.dart';
import 'system_proxy.dart';

/// Manages the tray, window visibility, background notifications, system proxy,
/// import links and launch at login.
class Desktop with WindowListener {
  Desktop(this.sora, this.navigator);

  final Sora sora;

  /// Navigator used to display imported links.
  final GlobalKey<NavigatorState> navigator;

  final SystemProxy? _proxy = SystemProxy.forThisDesktop();

  /// Whether this desktop has a system proxy Sora can point at the core.
  bool get hasSystemProxy => _proxy != null;

  final _notifications = FlutterLocalNotificationsPlugin();
  final _links = AppLinks();
  final List<StreamSubscription<Object?>> _watches = [];

  tray.TrayIcon? _icon;
  String _iconName = '';
  String _menuKey = '';

  /// Tray availability: always true on Windows; on Linux, requires a panel
  /// owning StatusNotifierWatcher, which may appear after app startup.
  bool _trayShown = Platform.isWindows;
  DBusClient? _bus;

  /// Replaced tray menus retained briefly because a menu may still be open.
  final List<tray.Menu> _oldMenus = [];

  bool _visible = true;
  bool _focused = true;

  /// Tracks app shutdown; [_dropping] also requests session disconnection.
  bool _closing = false, _dropping = false;

  /// Serializes proxy writes so restoration cannot overtake a pending change.
  Future<void> _proxyWork = Future.value();

  /// Whether the core has responded in this run. Until then, preserve the proxy
  /// because an existing core session may still be active.
  bool _coreSeen = false;

  /// Last notification text for each subscription, used to suppress duplicates.
  final Map<String, String> _warned = {};

  /// Initializes desktop integration. [hidden] keeps a login launch in the tray
  /// until the window is opened.
  Future<void> start({required bool hidden}) async {
    _visible = !hidden;
    _focused = !hidden;
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
    _buildTray();
    if (Platform.isLinux) await _watchTrayHost();
    await _notifications.initialize(
      settings: InitializationSettings(
        linux: LinuxInitializationSettings(
          defaultActionName: _s.trayOpen,
          defaultIcon: AssetsLinuxIcon('assets/tray/on.png'),
        ),
        windows: const WindowsInitializationSettings(
          appName: 'Sora',
          appUserModelId: 'io.github.levvs_one.Sora',
          guid: '5f0c7f53-2b3e-4f21-9b44-6c1a8d3e7a10',
        ),
      ),
      onDidReceiveNotificationResponse: (_) => unawaited(show()),
    );
    syncLaunchAtLogin();
    sora.addListener(_changed);
    _watches
      ..add(sora.notices.listen(_notice))
      ..add(_links.stringLinkStream.listen(_open));
    _changed();
  }

  S get _s {
    final chosen = sora.settings.language;
    final locale = chosen == 'system' ? PlatformDispatcher.instance.locale : Locale(chosen);
    return lookupS(S.delegate.isSupported(locale) ? locale : const Locale('en'));
  }

  // Showing a hidden window does not guarantee focus; request both.

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowClose() {
    if (_closing) return;
    if (!sora.settings.closeToTray || !_trayShown) {
      // Without a tray, hiding would make the app inaccessible. Close the
      // window and leave the session running in the core.
      unawaited(quit(disconnect: _trayShown));
      return;
    }
    unawaited(windowManager.hide());
    _visible = false;
    if (!sora.settings.trayHintShown) {
      sora.settings.trayHintShown = true;
      unawaited(_tell(_s.noticeInTray, _s.noticeInTrayBody, always: true));
    }
  }

  @override
  void onWindowFocus() {
    _visible = true;
    _focused = true;
  }

  @override
  void onWindowBlur() => _focused = false;

  @override
  void onWindowMinimize() => _focused = false;

  /// Exits the app. By default, disconnects and restores the system proxy.
  /// Closing without a tray passes disconnect: false to preserve the core
  /// session.
  Future<void> quit({bool disconnect = true}) async {
    _closing = true;
    _dropping = disconnect;
    // An off session may still hold the kill switch after failure; disconnect
    // releases it.
    if (disconnect && sora.phase != Phase.offline) await sora.disconnect();
    await (_proxyWork = _proxyWork.then((_) => _syncProxy()).catchError((Object _) {}));
    for (final watch in _watches) {
      await watch.cancel();
    }
    sora.removeListener(_changed);
    await _bus?.close();
    _icon?.setVisible(false);
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  Future<void> launchUpdate(File installer) async {
    final path = installer.path;
    await Isolate.run(
      () => using((arena) {
        final initialized = CoInitializeEx(COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
        if (initialized.isError) throw const UpdateFailure(UpdateError.installation);
        try {
          final info = arena<SHELLEXECUTEINFO>();
          info.ref
            ..cbSize = sizeOf<SHELLEXECUTEINFO>()
            // SEE_MASK_NOASYNC and SEE_MASK_FLAG_NO_UI are absent from win32's
            // generated constants. Wait for handoff without a Shell error dialog.
            ..fMask = 0x00000100 | 0x00000400
            // Inno's unelevated loader must retain the original user's identity.
            ..lpVerb = 'open'.toPwstr(allocator: arena)
            ..lpFile = path.toPwstr(allocator: arena)
            ..lpParameters = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'.toPwstr(allocator: arena)
            ..nShow = SW_SHOWNORMAL;
          if (!ShellExecuteEx(info).value) throw const UpdateFailure(UpdateError.installation);
        } finally {
          CoUninitialize();
        }
      }),
    );
  }

  Future<void> restartAfterUpdate() async {
    // Wait for this process to release Flutter's shared libraries before loading
    // the newly installed ones. The watcher runs with the desktop user's UID.
    await Process.start('/bin/sh', [
      '-c',
      'while kill -0 "\$1" 2>/dev/null; do sleep 1; done; exec /usr/bin/sora',
      'sora-restart',
      '$pid',
    ], mode: ProcessStartMode.detached);
  }

  // Login launches stay hidden to avoid interrupting the desktop.

  /// Applies the launch-at-login setting, starting Sora in the tray.
  void syncLaunchAtLogin() {
    final login = LaunchAtLogin.createWithIdAndDisplayName('io.github.levvs_one.sora', 'Sora');
    if (login == null) return;
    login.setProgram(Platform.resolvedExecutable, ['--hidden']);
    if (sora.settings.launchAtLogin) {
      login.enable();
    } else if (login.isEnabled) {
      login.disable();
    }
  }

  // Linux panels may register their tray host after app startup.

  static const _watcher = 'org.kde.StatusNotifierWatcher';

  /// Watches Linux tray-host availability. Recreates the icon when a panel
  /// appears because registration happens only at icon creation.
  Future<void> _watchTrayHost() async {
    final bus = DBusClient.session();
    _bus = bus;
    try {
      _trayShown = await bus.nameHasOwner(_watcher);
    } on Object {
      // Without an accessible session bus, no tray host is available.
      _trayShown = false;
      return;
    }
    _watches.add(
      bus.nameOwnerChanged.where((e) => e.name == _watcher).listen((e) {
        final shown = (e.newOwner ?? '').isNotEmpty;
        if (shown && !_trayShown) {
          _icon?.dispose();
          _icon = null;
          _iconName = _menuKey = '';
          _buildTray();
          _updateTray();
        }
        _trayShown = shown;
      }),
    );
  }

  void _buildTray() {
    final icon = tray.TrayIcon.create();
    if (icon == null) return;
    // Reserve left-click for opening the window and right-click for the menu,
    // matching Windows tray behaviour and Linux panel menus.
    icon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
    icon.addListener((event) {
      if (event is tray.TrayIconClickedEvent || event is tray.TrayIconDoubleClickedEvent) unawaited(show());
    });
    icon.setVisible(true);
    _icon = icon;
  }

  void _changed() {
    _updateTray();
    _warnAboutSubscriptions();
    _proxyWork = _proxyWork.then((_) => _syncProxy()).catchError((Object _) {});
  }

  void _updateTray() {
    final icon = _icon;
    if (icon == null) return;
    final s = _s;
    final name = switch (sora.phase) {
      Phase.connected => 'on',
      Phase.connecting || Phase.reconnecting || Phase.disconnecting => 'connecting',
      _ => 'off',
    };
    if (name != _iconName) {
      icon.icon = tray.ImageAsset.fromAsset('assets/tray/$name.png');
      _iconName = name;
    }
    final state = _stateText(s);
    final server = sora.phase == Phase.connected || sora.phase == Phase.reconnecting ? _serverText(s) : null;
    icon.setTooltip(server == null ? s.trayTooltip(state) : s.trayTooltipServer(state, server));

    final entries = [for (final sub in sora.subscriptions) ...entriesOf(sub)];
    // Rebuilding an open menu closes it, so update only when its contents
    // change.
    final key = [
      sora.phase,
      sora.selected,
      sora.serverlessAvailable,
      sora.settings.tunnel,
      sora.settings.language,
      for (final e in entries) '${e.id}=${e.name}',
    ].join('|');
    if (key == _menuKey) return;
    _menuKey = key;
    final menu = _menu(s, state, server, entries);
    if (menu == null) return;
    icon.setContextMenu(menu);
    _oldMenus.add(menu);
    if (_oldMenus.length > 1) {
      final old = _oldMenus.removeAt(0);
      Future<void>.delayed(const Duration(seconds: 5), old.dispose);
    }
  }

  String _stateText(S s) => switch (sora.phase) {
    Phase.offline => s.coreMissing,
    Phase.off => s.stateOff,
    Phase.connecting => s.stateConnecting,
    Phase.connected => s.stateConnected,
    Phase.reconnecting => s.stateReconnecting,
    Phase.disconnecting => s.stateDisconnecting,
  };

  String _serverText(S s) => switch (sora.selected) {
    'auto' => s.serverAuto,
    'bypass' => s.serverBypass,
    final id => sora.nameOf(id),
  };

  tray.Menu? _menu(S s, String state, String? server, List<Entry> entries) {
    final menu = tray.Menu.create();
    if (menu == null) return null;
    tray.MenuItem? item(String label, {tray.MenuItemType type = tray.MenuItemType.normal, void Function()? onTap}) {
      final made = tray.MenuItem.createWithLabelAndType(label, type);
      if (made == null) return null;
      if (onTap == null && type != tray.MenuItemType.submenu) {
        made.isEnabled = false;
      } else if (onTap != null) {
        made.addListener((event) {
          if (event is tray.MenuItemClickedEvent) onTap();
        });
      }
      return made;
    }

    tray.MenuItem? choice(String label, {required bool checked, required int group, required void Function() onTap}) {
      final made = item(label, type: tray.MenuItemType.radio, onTap: onTap);
      made
        ?..radioGroup = group
        ..state = checked ? tray.MenuItemState.checked : tray.MenuItemState.unchecked;
      return made;
    }

    menu.addItem(item(server == null ? state : '$state: $server'));
    if (sora.phase == Phase.off) {
      menu.addItem(item(s.trayConnect, onTap: () => unawaited(sora.connect())));
    } else if (sora.phase != Phase.offline) {
      menu.addItem(item(s.trayDisconnect, onTap: () => unawaited(sora.disconnect())));
    }
    menu.addSeparator();

    final servers = tray.Menu.create();
    if (servers != null) {
      final selected = sora.selected;
      servers.addItem(
        choice(s.serverAuto, checked: selected == 'auto', group: 1, onTap: () => unawaited(sora.select('auto'))),
      );
      // Limit the tray list to fit on screen; the full list supports search and
      // latency checks in the window.
      for (final e in entries.take(40)) {
        servers.addItem(choice(e.name, checked: selected == e.id, group: 1, onTap: () => unawaited(sora.select(e.id))));
      }
      menu.addItem(item(s.trayServer, type: tray.MenuItemType.submenu)?..submenu = servers);
    }
    final modes = tray.Menu.create();
    if (modes != null) {
      final current = sora.selected == 'bypass' ? 'bypass' : sora.settings.tunnel;
      void mode(String value) => unawaited(
        sora.change((x) {
          if (value == 'bypass') {
            x.server = 'bypass';
            x.tunnel = 'tun';
          } else {
            if (x.server == 'bypass') x.server = 'auto';
            x.tunnel = value;
          }
        }),
      );
      for (final (value, label) in [
        ('tun', s.tunMode),
        ('proxy', s.tunnelProxy),
        if (sora.serverlessAvailable) ('bypass', s.serverBypass),
      ]) {
        modes.addItem(choice(label, checked: current == value, group: 2, onTap: () => mode(value)));
      }
      menu.addItem(item(s.modes, type: tray.MenuItemType.submenu)?..submenu = modes);
    }
    menu
      ..addSeparator()
      ..addItem(item(s.trayOpen, onTap: () => unawaited(show())))
      ..addItem(item(s.trayQuit, onTap: () => unawaited(quit())));
    return menu;
  }

  // Restore the proxy only after all pending writes complete.

  /// Sets the core proxy for active proxy-mode sessions; otherwise restores it,
  /// including after core loss or a crash, to avoid leaving an unusable proxy.
  Future<void> _syncProxy() async {
    final proxy = _proxy;
    if (proxy == null) return;
    if (sora.phase != Phase.offline) _coreSeen = true;
    if (sora.phase == Phase.offline && !_coreSeen && !_dropping) return;
    final local = sora.localProxy;
    final wanted =
        !_dropping &&
        sora.settings.tunnel == 'proxy' &&
        local != null &&
        (sora.phase == Phase.connected || sora.phase == Phase.reconnecting);
    final saved = sora.settings.proxySnapshot.isEmpty
        ? null
        : jsonDecode(sora.settings.proxySnapshot) as Map<String, dynamic>;
    if (wanted) {
      if (saved != null && saved['host'] == local.host && saved['port'] == local.port) return;
      // Persist the original proxy before changing it. Reuse any existing
      // snapshot so a crash does not overwrite the pre-Sora settings.
      final before = saved?['before'] as String? ?? await proxy.read();
      await sora.settings.saveProxySnapshot(jsonEncode({'before': before, 'host': local.host, 'port': local.port}));
      await proxy.point(local.host, local.port);
    } else if (saved != null) {
      // Restore only if the proxy still matches Sora's endpoint, preserving
      // subsequent changes by the user or another app.
      if (await proxy.pointsAt(saved['host'] as String, saved['port'] as int)) {
        await proxy.restore(saved['before'] as String);
      }
      await sora.settings.saveProxySnapshot('');
    }
  }

  // Focused windows already display events, so notices are suppressed.

  Future<void> _tell(
    String title,
    String body, {
    bool always = false,
    bool record = true,
    String action = '',
    String argument = '',
  }) async {
    if (record) {
      await sora.recordNotification(
        AppNotification(time: DateTime.now(), title: title, body: body, action: action, argument: argument),
      );
    }
    // Suppress duplicate notifications when the focused window already shows
    // the event.
    if (!sora.settings.notifications || (!always && _visible && _focused)) return;
    await _notifications.show(
      id: title.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        linux: LinuxNotificationDetails(),
        windows: WindowsNotificationDetails(),
      ),
    );
  }

  void _notice(Notice notice) {
    final entry = sora.notificationFor(notice);
    unawaited(_tell(entry.title, entry.body, record: false));
  }

  void _warnAboutSubscriptions() {
    final s = _s;
    final locale = Platform.localeName.replaceAll('_', '-');
    for (final sub in sora.subscriptions) {
      final warning = subscriptionWarning(s, sub, locale);
      final id = sub.settings.id;
      if (warning == null) {
        _warned.remove(id);
      } else if (_warned[id] != warning) {
        _warned[id] = warning;
        unawaited(_tell(s.noticeSubscription, warning, action: 'subscription', argument: id));
      }
    }
  }

  // Show the window before presenting an import prompt.

  Future<void> _open(String text) async {
    final link = parseImportLink(text);
    if (link == null) return;
    await show();
    final context = navigator.currentContext;
    if (context == null || !context.mounted) return;
    switch (link) {
      case AddSubscription(:final url, :final name):
        await showSubscriptionSheet(context, link: url.toString(), name: name);
      case SealedForHapp():
        final s = S.of(context);
        await confirm(context, question: s.importSealed, action: s.understood, destructive: false, cancellable: false);
    }
  }
}

/// Provides desktop integration to descendant screens. Absent when running
/// without a desktop, including tests.
class DesktopScope extends InheritedWidget {
  const DesktopScope({super.key, required this.desktop, required super.child});

  final Desktop desktop;

  static Desktop? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<DesktopScope>()?.desktop;

  @override
  bool updateShouldNotify(DesktopScope oldWidget) => desktop != oldWidget.desktop;
}
