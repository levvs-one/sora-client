import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:sora/src/desktop/links.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:sora/src/settings.dart';
import 'package:sora/src/sora.dart';

void main() {
  group('import links', () {
    AddSubscription add(String text) => parseImportLink(text)! as AddSubscription;

    test('Sora and Happ links carry the subscription as it was pasted', () {
      expect(
        add('sora://add/https://sub.example.com/s/abc?flag=1').url.toString(),
        'https://sub.example.com/s/abc?flag=1',
      );
      expect(add('happ://add/https://sub.example.com/s/abc').url.host, 'sub.example.com');
      expect(add('happ://add/https%3A%2F%2Fsub.example.com%2Fs%2Fabc').url.path, '/s/abc');
      expect(add('HAPP://ADD/https://sub.example.com/x').url.path, '/x');
    });

    test('the links of other clients are read too, with their names', () {
      final v2 = add('v2rayn://install-config?url=https%3A%2F%2Fsub.example.com%2Fa');
      expect(v2.url.toString(), 'https://sub.example.com/a');
      final clash = add('clash://install-config?url=https%3A%2F%2Fsub.example.com%2Fb&name=Work');
      expect((clash.url.path, clash.name), ('/b', 'Work'));
      final hiddify = add('hiddify://import/https://sub.example.com/c#My%20VPN');
      expect((hiddify.url.path, hiddify.name), ('/c', 'My VPN'));
      final singbox = add('sing-box://import-remote-profile?url=https%3A%2F%2Fsub.example.com%2Fd#Home');
      expect((singbox.url.path, singbox.name), ('/d', 'Home'));
      expect(add('sora://add?url=https%3A%2F%2Fsub.example.com%2Fe&name=NL').name, 'NL');
    });

    test('a link Happ encrypted is recognised, not mistaken for a subscription', () {
      expect(parseImportLink('happ://crypt3/AbCdEf=='), isA<SealedForHapp>());
      expect(parseImportLink('happ://crypt/AbCdEf=='), isA<SealedForHapp>());
    });

    test('anything that is not a web subscription is refused', () {
      for (final text in [
        '',
        'https://sub.example.com/a',
        'sora://add/file:///etc/passwd',
        'sora://add/javascript:alert(1)',
        'happ://add/',
        'vless://uuid@host:443',
        'clash://install-config?name=x',
        'sora://open/https://sub.example.com',
      ]) {
        expect(parseImportLink(text), isNull, reason: text);
      }
    });
  });

  group('tunnel mode', () {
    setUp(() => SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty());

    test('all traffic is the tunnel; the system proxy mode asks for the local proxy', () async {
      final settings = await Settings.load();
      final servers = [OutboundSpec(id: 'a', displayName: 'A', protocol: 'vless')];
      expect(settings.tunnel, 'tun');
      expect(buildPlan(servers: servers, choice: 'a', settings: settings).tunnelMode, TunnelMode.TUNNEL_MODE_SYSTEM);
      settings.tunnel = 'proxy';
      expect(
        buildPlan(servers: servers, choice: 'a', settings: settings).tunnelMode,
        TunnelMode.TUNNEL_MODE_APPLICATION,
      );
    });

    test('a reset keeps the saved system proxy, so it can still be put back', () async {
      final settings = await Settings.load();
      settings
        ..proxySnapshot = '{"flags":1}'
        ..tunnel = 'proxy';
      await Future<void>.delayed(Duration.zero);
      await settings.reset();
      expect(settings.tunnel, 'tun');
      expect(settings.proxySnapshot, '{"flags":1}');
    });
  });
}
