import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:app_links/app_links.dart';
import 'package:dbus/dbus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:nativeapi/nativeapi.dart' show LaunchAtLogin;
import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart';

import '../../l10n/strings.dart';
import '../groups.dart';
import '../sora.dart';
import '../ui/kit.dart';
import '../ui/servers.dart';
import '../ui/subscription_sheet.dart';
import 'links.dart';
import 'system_proxy.dart';

/// Sora on the desktop: the tray icon and its menu, the window that hides
/// instead of closing, notices of what happened out of sight, the system
/// proxy of the proxy mode, links opened from a browser, and the start with
/// the system.
class Desktop with WindowListener {
  Desktop(this.sora, this.navigator);

  final Sora sora;

  /// Where the import of an opened link is shown.
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

  /// Whether something shows tray icons. Windows always has a tray; on Linux
  /// it is the panel that owns the StatusNotifierWatcher name, and a panel
  /// may have none, or start after Sora does at sign-in.
  bool _trayShown = Platform.isWindows;
  DBusClient? _bus;

  /// Menus the tray showed earlier, released a moment after they are
  /// replaced: one may still be open when the next one is set.
  final List<tray.Menu> _oldMenus = [];

  bool _visible = true;
  bool _focused = true;

  /// Set once Sora is ending; [_dropping] when the connection ends with it.
  bool _closing = false, _dropping = false;

  /// Changes of the system proxy, one after another: a restore must never
  /// overtake a change still being written.
  Future<void> _proxyWork = Future.value();

  /// The core answered at least once in this run. Before that, a session in
  /// the proxy mode may still be running in it, and its proxy is left alone.
  bool _coreSeen = false;

  /// The warning each subscription was last announced with.
  final Map<String, String> _warned = {};

  /// Sets everything up. [hidden] is a start at sign-in, which stays in the
  /// tray until the person opens the window.
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

  // The window.

  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onWindowClose() {
    if (_closing) return;
    if (!sora.settings.closeToTray || !_trayShown) {
      // Without a tray there is nowhere to hide to: the window closes, and
      // the connection stays with the core until Sora is opened again.
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

  /// Ends Sora. Quitting from the tray takes the connection down with it and
  /// puts the system proxy back, so nothing is left running that the person
  /// cannot see; closing a window that has no tray to hide in leaves the
  /// connection to the core.
  Future<void> quit({bool disconnect = true}) async {
    _closing = true;
    _dropping = disconnect;
    // Off may still be a failed session that keeps its kill switch on: the
    // core is asked to end it all the same.
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

  // The start with the system.

  /// Makes the system start Sora, in the tray, when the setting says so.
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

  // The tray.

  static const _watcher = 'org.kde.StatusNotifierWatcher';

  /// Follows the panel that shows tray icons. The icon registers with it once,
  /// when it is made, so a panel that comes later gets the icon made again.
  Future<void> _watchTrayHost() async {
    final bus = DBusClient.session();
    _bus = bus;
    try {
      _trayShown = await bus.nameHasOwner(_watcher);
    } on Object {
      // No session bus, or it refused: no panel can show an icon either.
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
    // A left click opens the window, as people expect of a tray icon on
    // Windows; the menu is on the right click, and on the panels of Linux.
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
    // The menu is built again only when something in it changed: rebuilding
    // a menu the person may have open would close it under their pointer.
    final key = [
      sora.phase,
      sora.selected,
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
      if (onTap == null) {
        made.isEnabled = false;
      } else {
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
      // A long list belongs in the window, where it can be searched and
      // measured; the tray keeps what fits on a screen.
      for (final e in entries.take(40)) {
        servers.addItem(choice(e.name, checked: selected == e.id, group: 1, onTap: () => unawaited(sora.select(e.id))));
      }
      servers.addItem(
        choice(s.serverBypass, checked: selected == 'bypass', group: 1, onTap: () => unawaited(sora.select('bypass'))),
      );
      menu.addItem(item(s.trayServer, type: tray.MenuItemType.submenu, onTap: () {})?..submenu = servers);
    }
    final modes = tray.Menu.create();
    if (modes != null) {
      void mode(String value) => unawaited(sora.change((x) => x.tunnel = value));
      modes
        ..addItem(choice(s.tunnelTun, checked: sora.settings.tunnel == 'tun', group: 2, onTap: () => mode('tun')))
        ..addItem(
          choice(s.tunnelProxy, checked: sora.settings.tunnel == 'proxy', group: 2, onTap: () => mode('proxy')),
        );
      menu.addItem(item(s.tunnelMode, type: tray.MenuItemType.submenu, onTap: () {})?..submenu = modes);
    }
    menu
      ..addSeparator()
      ..addItem(item(s.trayOpen, onTap: () => unawaited(show())))
      ..addItem(item(s.trayQuit, onTap: () => unawaited(quit())));
    return menu;
  }

  // The system proxy.

  /// Points the system proxy at the core while a session runs in the proxy
  /// mode, and puts the old one back otherwise, also when the core is gone,
  /// since a proxy pointing at a dead port cuts the person off. A snapshot
  /// left by a crash is put back too.
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
      // What was there is kept before anything changes. A proxy already
      // pointed at the core, by this run or one that ended without putting
      // it back, keeps the snapshot of what came before Sora.
      final before = saved?['before'] as String? ?? await proxy.read();
      await sora.settings.saveProxySnapshot(jsonEncode({'before': before, 'host': local.host, 'port': local.port}));
      await proxy.point(local.host, local.port);
    } else if (saved != null) {
      // Only what Sora set is put back: a proxy the person or another
      // program chose since is theirs to keep.
      if (await proxy.pointsAt(saved['host'] as String, saved['port'] as int)) {
        await proxy.restore(saved['before'] as String);
      }
      await sora.settings.saveProxySnapshot('');
    }
  }

  // Notices.

  Future<void> _tell(String title, String body, {bool always = false}) async {
    // What happens in front of the person needs no notice: the window shows
    // it already.
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
    final s = _s;
    unawaited(switch (notice) {
      ConnectionLost() => _tell(s.noticeLost, s.noticeLostBody),
      ConnectionRestored() => _tell(s.noticeRestored, _serverText(s)),
      ConnectionFailed(:final failure) => _tell(s.noticeFailed, describe(s, failure)),
      ServerSwitched(:final entry, :final backup) => _tell(entry, backup ? s.noticeBackup : s.noticeNext),
    });
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
        unawaited(_tell(s.noticeSubscription, warning));
      }
    }
  }

  // Links.

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

/// Hands [Desktop] to the screens that set what it does; absent where Sora
/// runs without a desktop, as in tests.
class DesktopScope extends InheritedWidget {
  const DesktopScope({super.key, required this.desktop, required super.child});

  final Desktop desktop;

  static Desktop? maybeOf(BuildContext context) => context.getInheritedWidgetOfExactType<DesktopScope>()?.desktop;

  @override
  bool updateShouldNotify(DesktopScope oldWidget) => desktop != oldWidget.desktop;
}
