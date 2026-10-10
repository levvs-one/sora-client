// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'strings.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get stateOff => 'Not connected';

  @override
  String get stateConnecting => 'Connecting';

  @override
  String get stateConnected => 'Connected';

  @override
  String get stateReconnecting => 'Reconnecting';

  @override
  String get stateDisconnecting => 'Disconnecting';

  @override
  String get stateFailed => 'Not connected';

  @override
  String get coreMissing => 'The Sora service is not responding';

  @override
  String get serverAuto => 'Fastest';

  @override
  String get serverBypass => 'No server';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get servers => 'Servers';

  @override
  String get settings => 'Settings';

  @override
  String get subscription => 'Subscription';

  @override
  String get subscriptionLink => 'Subscription link';

  @override
  String get add => 'Add';

  @override
  String get refresh => 'Update';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String deleteSubscription(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get routes => 'Routes';

  @override
  String get presetGlobal => 'Everything through VPN';

  @override
  String get presetRu => 'Russia direct';

  @override
  String get presetIr => 'Iran direct';

  @override
  String get presetCn => 'China direct';

  @override
  String get blockAds => 'Block ads';

  @override
  String get killSwitch => 'Internet only through VPN';

  @override
  String get engine => 'Engine';

  @override
  String get engineAuto => 'Auto';

  @override
  String get animations => 'Animations';

  @override
  String get logs => 'Log';

  @override
  String get about => 'About';

  @override
  String get logsAll => 'All';

  @override
  String get logsImportant => 'Important';

  @override
  String get logsErrors => 'Errors';

  @override
  String get search => 'Search';

  @override
  String get export => 'Save to file';

  @override
  String get clear => 'Clear';

  @override
  String get logsEmpty => 'Nothing here';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get notInstalled => 'Not installed';

  @override
  String get sourceCode => 'Source code';

  @override
  String get license => 'License';

  @override
  String usage(String used, String total) {
    return '$used of $total';
  }

  @override
  String until(String date) {
    return 'until $date';
  }

  @override
  String get expired => 'Expired';

  @override
  String milliseconds(int n) {
    return '$n ms';
  }

  @override
  String bytesB(String n) {
    return '$n B';
  }

  @override
  String bytesKB(String n) {
    return '$n KB';
  }

  @override
  String bytesMB(String n) {
    return '$n MB';
  }

  @override
  String bytesGB(String n) {
    return '$n GB';
  }

  @override
  String bytesTB(String n) {
    return '$n TB';
  }

  @override
  String get errGeneric => 'Something went wrong';

  @override
  String get errCore => 'The Sora service is not responding';

  @override
  String get errAuth => 'No access to the Sora service';

  @override
  String get errVersion => 'Update Sora: the app and the service are different versions';

  @override
  String get errBusy => 'Wait, the previous command is still running';

  @override
  String get errEngineMissing => 'No engine found for this server';

  @override
  String get errEngineStart => 'The engine did not start';

  @override
  String get errEngineStopped => 'The engine stopped';

  @override
  String get errTunnel => 'No permission to create the VPN connection';

  @override
  String get errServers => 'The server is configured with an error';

  @override
  String get errNetwork => 'Cannot reach the server';

  @override
  String get errTimeout => 'The server did not answer in time';

  @override
  String get errFirewall => 'Could not block the internet outside the VPN';

  @override
  String get errSubFetch => 'Could not load the subscription';

  @override
  String get errSubFormat => 'This is not a subscription link';

  @override
  String get errSubEmpty => 'The subscription has no servers';

  @override
  String get errSubDuplicate => 'This subscription is already added';

  @override
  String get errSubLimit => 'Too many subscriptions';

  @override
  String get errSubScheme => 'The link must start with https://';

  @override
  String get errSecretStore => 'Sora storage is damaged or unavailable';

  @override
  String get errNoServers => 'Add a subscription to connect';

  @override
  String get exportText => 'Text';

  @override
  String get connections => 'Connections';

  @override
  String get close => 'Close';

  @override
  String get chainDirect => 'Direct';

  @override
  String get chainBlocked => 'Blocked';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get sectionConnection => 'Connection';

  @override
  String get sectionNoServer => 'No server';

  @override
  String get sectionPing => 'Ping';

  @override
  String get sectionLog => 'Diagnostics';

  @override
  String get ipv6 => 'IPv6';

  @override
  String get dns => 'DNS';

  @override
  String get dnsAuto => 'Auto';

  @override
  String get dnsHint => 'Addresses, comma separated';

  @override
  String get fragment => 'TLS fragmentation';

  @override
  String get fragmentPackets => 'What to split';

  @override
  String get fragmentLength => 'Piece size';

  @override
  String get fragmentInterval => 'Pause between pieces';

  @override
  String get byDefault => 'Default';

  @override
  String get rangeHint => 'For example, 100-200';

  @override
  String get splitPos => 'Split positions';

  @override
  String get splitPosHint => 'For example, 1, midsld';

  @override
  String get disorder => 'Reorder pieces';

  @override
  String get tlsRecord => 'Split the TLS record';

  @override
  String get tlsRecordNo => 'No';

  @override
  String get tlsRecordSni => 'At the site name';

  @override
  String get tlsRecordFirst => 'After the first byte';

  @override
  String get hostCase => 'Change Host case';

  @override
  String get probeMethod => 'Method';

  @override
  String get probeAuto => 'Auto';

  @override
  String get probeEngine => 'Through the engine';

  @override
  String get probeConnect => 'Connection only';

  @override
  String get probeUrl => 'Test address';

  @override
  String get probeTimeout => 'Wait';

  @override
  String seconds(int n) {
    return '$n s';
  }

  @override
  String get subscriptions => 'Subscriptions';

  @override
  String get subscriptionSettings => 'Settings';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get autoUpdate => 'Update automatically';

  @override
  String get updateInterval => 'How often';

  @override
  String get intervalProvider => 'As the provider asks';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get updateNow => 'Update now';

  @override
  String get logLevel => 'What to record';

  @override
  String get levelDebug => 'Everything';

  @override
  String get levelInfo => 'Usual';

  @override
  String get levelWarning => 'Important';

  @override
  String get levelError => 'Errors only';

  @override
  String get recordDestinations => 'Record site addresses';

  @override
  String get reset => 'Reset settings';

  @override
  String get resetConfirm => 'Reset all settings?';

  @override
  String get resetAction => 'Reset';

  @override
  String get invalidValue => 'This value will not work';

  @override
  String get website => 'Subscription page';

  @override
  String get providerWebsite => 'Provider website';

  @override
  String get support => 'Support';

  @override
  String controlPortQuestion(String engine) {
    return '$engine is controlled through a port on this computer. Other programs will be able to tell that a VPN is on.';
  }

  @override
  String chooseEngine(String engine) {
    return 'Choose $engine';
  }

  @override
  String get rules => 'Custom rules';

  @override
  String get ruleAdd => 'New rule';

  @override
  String get ruleHint => 'Site, IP or program';

  @override
  String get ruleDirect => 'Direct';

  @override
  String get ruleProxy => 'Through VPN';

  @override
  String get ruleBlock => 'Block';

  @override
  String get failover => 'Switch on failure';

  @override
  String get connectOnStart => 'Connect on start';

  @override
  String expiresIn(String name, int days) {
    String _temp0 = intl.Intl.pluralLogic(days, locale: localeName, other: '# days', one: '# day', zero: 'a few hours');
    return '$name: the subscription ends in $_temp0';
  }

  @override
  String trafficLow(String name, String left) {
    return '$name: $left left';
  }

  @override
  String get ruleInvalid => 'This does not look like a site, an IP or a program';

  @override
  String groupOrdered(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# servers', one: '# server');
    return '$_temp0, in turn';
  }

  @override
  String groupBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '# servers', one: '# server');
    return '$_temp0, the fastest';
  }

  @override
  String get tunnelMode => 'Mode';

  @override
  String get tunnelTun => 'All traffic';

  @override
  String get tunnelProxy => 'System proxy';

  @override
  String get proxyAddress => 'Proxy address';

  @override
  String get copied => 'Copied';

  @override
  String get launchAtLogin => 'Start with the system';

  @override
  String get closeToTray => 'Keep in the tray when closed';

  @override
  String get notifications => 'Notifications';

  @override
  String get trayOpen => 'Open Sora';

  @override
  String get trayConnect => 'Connect';

  @override
  String get trayDisconnect => 'Disconnect';

  @override
  String get trayServer => 'Server';

  @override
  String get trayQuit => 'Quit Sora';

  @override
  String trayTooltip(String state) {
    return 'Sora: $state';
  }

  @override
  String trayTooltipServer(String state, String server) {
    return 'Sora: $state, $server';
  }

  @override
  String get noticeInTray => 'Sora is still in the tray';

  @override
  String get noticeInTrayBody => 'Quit from the menu of its icon';

  @override
  String get noticeLost => 'Connection lost';

  @override
  String get noticeLostBody => 'Sora is reconnecting';

  @override
  String get noticeRestored => 'Connected again';

  @override
  String get noticeFailed => 'Couldn\'t connect';

  @override
  String get noticeBackup => 'The main server didn\'t answer; the backup carries the traffic';

  @override
  String get noticeNext => 'The server didn\'t answer; the next one carries the traffic';

  @override
  String get noticeMainBack => 'The main server answers again and carries the traffic';

  @override
  String get noticeSubscription => 'Subscription';

  @override
  String get importTitle => 'Add this subscription?';

  @override
  String get importSealed =>
      'This link is encrypted for Happ, and only Happ can read it. Ask your provider for the plain subscription link.';

  @override
  String get understood => 'OK';

  @override
  String get noAnswer => 'no answer';

  @override
  String get home => 'Home';

  @override
  String get navRules => 'Rules';

  @override
  String get navConnections => 'Connections';

  @override
  String get navLogs => 'Logs';

  @override
  String get navAbout => 'About';

  @override
  String get sidebarToggle => 'Toggle sidebar';

  @override
  String get more => 'More';

  @override
  String get less => 'Less';

  @override
  String get currentServer => 'Current server';

  @override
  String get trafficDown => 'Downloaded';

  @override
  String get trafficUp => 'Uploaded';

  @override
  String perSecond(String value) {
    return '$value/s';
  }

  @override
  String activeRules(int count) {
    return 'Active rules: $count';
  }

  @override
  String get recentNotifications => 'Recent notifications';

  @override
  String get notificationsEmpty => 'Connection and subscription events will appear here';

  @override
  String get retryConnect => 'Retry connection';

  @override
  String get openLogs => 'Open logs';

  @override
  String get tourReplay => 'Show guide again';

  @override
  String tourStep(int step) {
    return 'Step $step of 5';
  }

  @override
  String get tourBack => 'Back';

  @override
  String get tourNext => 'Next';

  @override
  String get tourSkip => 'Skip';

  @override
  String get tourFinish => 'Done';

  @override
  String get tourAdd => 'Add your provider’s subscription link.';

  @override
  String get tourServer => 'Pick a server. “Fastest” selects one for you.';

  @override
  String get tourConnect => 'Click here to connect or disconnect.';

  @override
  String get tourMode => 'Choose a mode. Kill switch blocks internet if the VPN drops.';

  @override
  String get tourSettings => 'Open settings. You can replay this guide there.';

  @override
  String get chooseProgram => 'Choose a program';

  @override
  String get installedApps => 'Installed applications';

  @override
  String get runningProcesses => 'Running processes';

  @override
  String get programsFailed => 'Could not load applications';

  @override
  String get programsEmpty => 'No applications found. Try another name.';

  @override
  String get selectExe => 'Choose an .exe file';

  @override
  String get trafficUnavailable => 'Counters are not available yet';

  @override
  String get speedtest => 'Speed';

  @override
  String get speedtestCheck => 'Check speed';

  @override
  String get speedtestSearch => 'Find a service';

  @override
  String get speedtestEmpty => 'No matches. Change the search.';

  @override
  String get speedtestBackToList => 'Back to services';

  @override
  String get speedtestOpenBrowser => 'Open in browser';

  @override
  String get speedtestUnavailable => 'The embedded browser could not start. Open the service in your system browser.';

  @override
  String get speedtestPageFailed => 'The page could not load. Reload it or open the service in your system browser.';

  @override
  String get speedtestExternalFailed => 'The system browser could not open. Try again.';

  @override
  String get modes => 'Modes';

  @override
  String get proxyShort => 'Proxy';

  @override
  String get tunMode => 'All traffic (TUN)';

  @override
  String get checkUpdates => 'Check for updates';

  @override
  String get updates => 'App updates';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String get updateOpenAbout => 'View update';

  @override
  String updateNotes(String version) {
    return 'Changes in $version';
  }

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateChecking => 'Checking...';

  @override
  String get updateNoNotes => 'The release has no notes.';

  @override
  String get updateDropWarning =>
      'The VPN connection will drop for a few seconds while Sora and its core update. Continue?';

  @override
  String get updateWaitConnection => 'Wait for the VPN connection and core to become ready.';

  @override
  String get updateDownloading => 'Downloading and verifying files...';

  @override
  String get updateInstalling => 'Preparing the update or waiting for administrator authentication...';

  @override
  String get updateNetworkError => 'Could not download the update. Try again.';

  @override
  String get updateReleaseError => 'The release data or required files are missing or invalid.';

  @override
  String get updateChecksumError => 'The download does not match SHA256SUMS. Nothing was installed.';

  @override
  String get updateInstallError => 'The update did not finish. Authentication may have been cancelled.';

  @override
  String get updateUnsupported =>
      'This executable is not owned by a supported Sora package pair. Use the release installation instructions.';

  @override
  String get updateManual =>
      'Run this command in a terminal to install both verified packages, then reopen Sora. The files stay in the download directory. The VPN connection will drop.';

  @override
  String get updateCopyCommand => 'Copy command';

  @override
  String get updateChecksDisabled => 'Automatic checks are disabled in Settings.';

  @override
  String get updateInstalled => 'Update installed. Reopen Sora.';

  @override
  String get projectLinks => 'Project';

  @override
  String get githubReleases => 'Releases and downloads';

  @override
  String get telegramChannel => 'Telegram channel';

  @override
  String get licenses => 'Licenses';

  @override
  String get componentLicenses => 'Component licenses';

  @override
  String get appCopyright => '© 2026 levvs-one and contributors';

  @override
  String get collapseServers => 'Collapse servers';

  @override
  String get expandServers => 'Expand servers';

  @override
  String get hideDescription => 'Hide description';

  @override
  String get showDescription => 'Show description';

  @override
  String get pendingConnectionChanges => 'Reconnect to apply these changes.';

  @override
  String get reconnectNow => 'Apply and reconnect';

  @override
  String get bypassLimitations =>
      'This mode bypasses DPI only for HTTP and TLS, does not support UDP or change your IP. Use a VPN server for Discord voice, calls and blocked Telegram addresses.';

  @override
  String get errEngineUnsupported =>
      'The selected engine does not support this profile or settings. Choose Auto or a compatible engine.';

  @override
  String get errRestore => 'Connection cleanup was incomplete. Retry disconnecting; see the log for details.';

  @override
  String get errSessionEnded => 'This session has already ended. Refresh the connection state.';

  @override
  String get retryDisconnect => 'Retry disconnecting';

  @override
  String get tunStack => 'TUN stack';

  @override
  String get modesInfo => 'About modes';

  @override
  String get modesGuideTitle => 'Modes and engines';

  @override
  String get modesGuide =>
      'Choose Auto if you are unsure which engine your server needs. Sora checks the profile and settings before connecting. An engine cannot increase your plan’s bandwidth: performance depends on the server, route, protocol and network.\n\n## Modes\n\n### All traffic (TUN)\n\nSora creates a virtual network interface and routes application traffic through it, including TCP and UDP. Use this mode for Telegram, games and Discord voice. Rules can send specific sites or programs directly or block them. The network service needs permission and a server that supports the required protocol.\n\n### System proxy\n\nSora configures a local HTTP/SOCKS proxy. Applications that respect system proxy settings use it. Applications with their own network stack may connect directly; UDP and voice calls generally need TUN. This mode suits browsers and applications with proxy support.\n\n### No server\n\nOn Linux, Sora uses [zapret](https://github.com/bol-van/zapret) to split and reshape HTTP/TLS requests and bypass some DPI checks. Your IP stays the same and connections go directly to the website. Results depend on your provider and the blocking method.\n\nThe current integration uses tpws for HTTP and TLS over TCP. It does not bypass IP blocking or relay UDP, and cannot guarantee Telegram’s MTProto connections. Use a VPN server with TUN for Discord voice, Telegram calls and these kinds of restrictions.\n\n## Engines\n\n### Auto\n\nSora selects an installed engine that supports the entire connection plan: server protocols, transports, groups, fragmentation and mode. An incompatible manual choice is rejected before stopping the current connection. Choose Auto or another engine and apply the settings again.\n\n### sing-box\n\nNew Sora packages include [sing-box-lx](https://github.com/Leadaxe/sing-box-lx), a fork of [sing-box](https://github.com/SagerNet/sing-box), adding client-side XHTTP and VLESS Encryption. Sora recognizes the build and its capabilities. An upstream build without XHTTP does not gain this capability from its name alone.\n\nSupported protocols include VLESS, VMess, Trojan, Shadowsocks, Hysteria2, TUIC, AnyTLS, WireGuard and the AmneziaWG 1.x/2.x parameters Sora can import. Full Xray JSON profiles require Xray. New AWG 3.x fields cannot be imported yet. sing-box uses a password-protected local control port, which other applications on the computer can detect.\n\n### Xray\n\n[Xray-core](https://github.com/XTLS/Xray-core) supports VLESS, REALITY, XHTTP, VLESS Encryption and TLS fragmentation. It also runs complete provider Xray profiles while preserving their routing and groups. Such profiles cannot be automatically converted to another engine without changing their behavior.\n\nThe bundled Xray removed the setting that disables TLS certificate verification (`allowInsecure`). Auto selects sing-box or mihomo for ordinary servers requiring this setting. Selecting Xray manually reports incompatibility before stopping the current connection. Older full JSON profiles need an updated provider profile with a verifiable certificate or certificate pin.\n\n### mihomo\n\n[mihomo](https://github.com/MetaCubeX/mihomo) supports ordered fallback and load-balancing groups, XHTTP and AmneziaWG. Choose it when automatic failover to a backup server matters. Sora’s TLS fragmentation setting is unavailable with this engine.\n\n## Compatibility in Sora\n\n| Feature | sing-box-lx | Xray | mihomo |\n| --- | --- | --- | --- |\n| Linux TUN and TCP/UDP | Yes | Yes | Yes |\n| XHTTP | Yes | Yes | Yes |\n| VLESS Encryption | Yes | Yes | Yes |\n| Full Xray profile | No | Yes | No |\n| TUIC / AnyTLS | Both | No | TUIC |\n| TLS fragmentation | Yes | Yes | No |\n| AmneziaWG 1.x/2.x | Yes¹ | No | Yes |\n| Ordered fallback group | No | No² | Yes |\n\n¹ Profiles with J1/J2/J3/Itime use mihomo; these fields must never be silently discarded. ² For a group of complete Xray profiles, the app selects a backup profile. Support depends on the installed build; check its version in About.\n\n## TUN stack\n\nThe stack handles TCP and UDP inside the virtual interface. In the modes panel, Xray and mihomo offer gVisor, System, Mixed and MIPS. Each engine saves its own preference. System proxy and Serverless modes do not use this preference.\n\n- **Mixed** — TCP uses the system stack, while gVisor handles UDP. This is the default for mihomo.\n- **System** — uses the system stack. Try another option if network applications encounter problems.\n- **gVisor** — handles traffic in userspace.\n- **MIPS** — mihomo’s own IP stack, available in the bundled version 1.19.32.\n\nXray uses its built-in gVisor by default. System, Mixed and MIPS use mihomo as the TUN engine, forwarding TCP and UDP to Xray over an authenticated local SOCKS link. Xray retains the protocol, provider profile and routing. These three options require an installed mihomo.\n\nThe bridge runs a second process. In three idle measurements, it used about 32–36 MiB more physical memory than native Xray TUN. This does not measure download load: CPU and memory costs depend on connections. Keep gVisor unless you need another stack. sing-box has no stack selector. No stack guarantees better performance in every network. Choose a stack and select Apply and reconnect to try it in your network.\n\n## Applying settings\n\nMode, engine, server, DNS and rule selections are saved immediately. During an active connection, Sora prompts you to reconnect. Click Apply and reconnect to start the selected plan. Restarting an engine may interrupt current downloads and calls. Repeated clicks do not start parallel connections; disconnecting finishes the transition and releases the connection.\n\nInternet only through VPN blocks direct traffic when a tunnel drops. It affects the whole machine. An explicit disconnect removes Sora’s rules. If cleanup does not finish, retry disconnecting and open the log.\n\n## Project documentation\n\n- [sing-box-lx: configuration and support](https://github.com/Leadaxe/sing-box-lx/blob/lx/docs-lx/lx-config.md)\n- [sing-box documentation](https://sing-box.sagernet.org/)\n- [Xray documentation](https://xtls.github.io/)\n- [mihomo documentation](https://wiki.metacubex.one/)\n- [zapret: operation and limitations](https://github.com/bol-van/zapret/blob/master/docs/readme.md)\n';

  @override
  String get probeServers => 'Check servers';
}
