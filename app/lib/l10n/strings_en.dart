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
}
