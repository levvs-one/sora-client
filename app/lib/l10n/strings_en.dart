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
  String get website => 'Provider website';

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
}
