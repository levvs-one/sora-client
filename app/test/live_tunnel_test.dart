// Carries real traffic through the installed core on Windows: a VLESS server
// on this machine, the tunnel and the system proxy in front of it, and the
// server's access log as the witness that the traffic went through it. Runs
// only when SORA_TUNNEL_LIVE names the server, as CI does after the install.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/desktop/system_proxy.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pbgrpc.dart';

void main() {
  final server = Platform.environment['SORA_TUNNEL_LIVE'];
  final log = Platform.environment['SORA_TUNNEL_LOG'] ?? '';
  final skip = server == null ? 'set SORA_TUNNEL_LIVE to a vless:// link of a local server' : false;

  late CoreLink link;
  late SessionPlan imported;

  setUpAll(() async {
    if (server == null) return;
    link = await CoreLink.open().timeout(const Duration(seconds: 30));
    final answer = await link.stub.parseImport(ParseImportRequest(apiVersion: apiVersion, payload: server.codeUnits));
    expect(answer.hasError(), isFalse, reason: answer.error.detailRedacted);
    imported = answer.sessionPlan;
  });

  tearDownAll(() async {
    if (server != null) await link.close();
  });

  /// Connects with the imported server in [mode] and reports how long the
  /// core took to say connected.
  Future<Duration> connect(TunnelMode mode) async {
    final out = imported.outbounds.single;
    final plan = SessionPlan(
      tunnelMode: mode,
      outbounds: [out],
      // The server is a program on this machine too: its own way out must not
      // go back into the tunnel that leads to it.
      routes: [RoutingRule(destination: 'process:xray.exe', outboundId: 'direct')],
      routing: RoutingOptions(preset: 'global', proxyTarget: out.id),
    );
    final clock = Stopwatch()..start();
    final answer = await link.stub.connect(
      ConnectRequest(apiVersion: apiVersion, sessionPlan: plan, controlAuthenticator: link.token),
    );
    expect(answer.hasError(), isFalse, reason: '${answer.error.userMessageKey} ${answer.error.detailRedacted}');
    for (var i = 0; i < 300; i++) {
      final status = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
      final value = status.status.connection.value;
      if (value == ConnectionStateValue.CONNECTION_STATE_VALUE_CONNECTED) return clock.elapsed;
      expect(value, isNot(ConnectionStateValue.CONNECTION_STATE_VALUE_FAILED));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    fail('the session did not come up in 30 seconds');
  }

  Future<void> disconnect() async {
    await link.stub.disconnect(DisconnectRequest(apiVersion: apiVersion, controlAuthenticator: link.token));
  }

  /// Whether the server's access log names [host], waiting a moment for it
  /// to be written.
  Future<bool> serverSaw(String host) async {
    for (var i = 0; i < 20; i++) {
      if (File(log).existsSync() && File(log).readAsStringSync().contains(host)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return false;
  }

  test(
    'the tunnel carries a program that knows nothing about proxies',
    () async {
      final took = await connect(TunnelMode.TUNNEL_MODE_SYSTEM);
      // ignore: avoid_print
      print('tunnel connected in ${took.inMilliseconds} ms');
      try {
        final curl = await Process.run('curl.exe', [
          '-s',
          '-o',
          'NUL',
          '-m',
          '20',
          '-w',
          '%{http_code}',
          'https://example.com/',
        ]);
        expect(curl.stdout, '200', reason: 'curl: ${curl.stderr}');
        expect(
          await serverSaw('example.com'),
          isTrue,
          reason: 'the server never saw the request: it went around the tunnel',
        );
      } finally {
        await disconnect();
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'the system proxy carries the programs that honour it, and is put back after',
    () async {
      final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      expect(about.about.hasLocalProxy(), isTrue);
      final local = about.about.localProxy;
      final proxy = SystemProxy.forThisDesktop()!;
      Future<String> setting() async =>
          (await Process.run('reg', [
                'query',
                r'HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings',
                '/v',
                'ProxyEnable',
              ])).stdout
              as String;
      final before = await setting();

      final took = await connect(TunnelMode.TUNNEL_MODE_APPLICATION);
      // ignore: avoid_print
      print('proxy mode connected in ${took.inMilliseconds} ms');
      final saved = await proxy.read();
      await proxy.point(local.host, local.port);
      try {
        expect(await setting(), contains('0x1'));
        expect(await proxy.pointsAt(local.host, local.port), isTrue);
        // .NET takes the system proxy of WinINet, as browsers do.
        final web = await Process.run('powershell.exe', [
          '-NoProfile',
          '-Command',
          '(Invoke-WebRequest -UseBasicParsing -TimeoutSec 20 https://example.org/).StatusCode',
        ]);
        expect((web.stdout as String).trim(), '200', reason: 'Invoke-WebRequest: ${web.stderr}');
        expect(
          await serverSaw('example.org'),
          isTrue,
          reason: 'the server never saw the request: the proxy was not used',
        );
      } finally {
        await proxy.restore(saved);
        await disconnect();
      }
      expect(await setting(), before, reason: 'the system proxy was not put back as it was');
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
