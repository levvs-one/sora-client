// Requires SORA_CORE_LIVE and an installed core, as configured in CI. Uses the
// Linux Unix socket or Windows named pipe to verify the service.
import 'dart:io';
import 'dart:ffi';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/core/pipe.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';
import 'package:grpc/grpc.dart' show CallOptions;

void main() {
  final live = Platform.environment['SORA_CORE_LIVE'] != null;

  test('the Windows connector reports closure separately for every connection', () async {
    final connector = PipeConnector(CoreLink.socketPath);
    try {
      for (var reopen = 0; reopen < 20; reopen++) {
        await connector.connect().timeout(const Duration(seconds: 5));
        var closed = false;
        final done = connector.done;
        unawaited(done.then((_) => closed = true));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(closed, isFalse, reason: 'an earlier pipe closure must not close a fresh transport');
        connector.shutdown();
        await done.timeout(const Duration(seconds: 5));
      }
    } finally {
      connector.shutdown();
    }
  }, skip: live && Platform.isWindows ? false : 'requires the installed Windows service');

  test('the interface reaches the core, is given the token and is answered', () async {
    if (Platform.isWindows && Platform.environment['SORA_CORE_UNELEVATED'] != null) {
      final isAdmin = DynamicLibrary.open('shell32.dll')
          .lookupFunction<Int32 Function(), int Function()>('IsUserAnAdmin');
      expect(isAdmin(), 0, reason: 'the client must run without administrator rights');
    }
    final link = await CoreLink.open().timeout(const Duration(seconds: 30));
    try {
      expect(link.token, hasLength(32), reason: 'Handshake hands over the token');
      final about = await link.stub.getAbout(GetAboutRequest(apiVersion: apiVersion));
      expect(about.hasError(), isFalse);
      final installed = {
        for (final e in about.about.engines)
          if (e.installed) e.kind,
      };
      expect(installed, containsAll(Platform.environment['SORA_CORE_ENGINES']?.split(',') ?? const <String>[]));
      // An authenticated request verifies that the Handshake token is accepted.
      final subs = await link.stub.listSubscriptions(
        ListSubscriptionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token),
      );
      expect(subs.hasError(), isFalse);
      final status = await link.stub.getStatus(GetStatusRequest(apiVersion: apiVersion));
      expect(status.status.connection.value, isNot(ConnectionStateValue.CONNECTION_STATE_VALUE_UNSPECIFIED));
    } finally {
      await link.close();
    }
  }, skip: live ? false : 'set SORA_CORE_LIVE to run against a running core');

  test('concurrent watches and repeated requests keep the service connection alive', () async {
    for (var reopen = 0; reopen < 3; reopen++) {
      final link = await CoreLink.open().timeout(const Duration(seconds: 15));
      final errors = <Object>[];
      final latest = await link.stub.queryLogs(
        QueryLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, limit: 1),
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );
      final watches = <StreamSubscription<Object>>[
        link.stub
            .watchSubscriptions(WatchSubscriptionsRequest(apiVersion: apiVersion, controlAuthenticator: link.token))
            .listen((_) {}, onError: errors.add),
        link.stub
            .watchLogs(
              WatchLogsRequest(
                apiVersion: apiVersion,
                controlAuthenticator: link.token,
                afterSequence: latest.entries.firstOrNull?.sequence,
              ),
            )
            .listen((_) {}, onError: errors.add),
      ];
      try {
        for (var batch = 0; batch < 30; batch++) {
          final answers = await Future.wait(
            List.generate(
              8,
              (_) => link.stub.queryLogs(
                QueryLogsRequest(apiVersion: apiVersion, controlAuthenticator: link.token, limit: 500),
                options: CallOptions(timeout: const Duration(seconds: 5)),
              ),
            ),
          );
          expect(answers.every((a) => !a.hasError()), isTrue);
          expect(errors, isEmpty);
          await Future<void>.delayed(const Duration(milliseconds: 30));
        }
      } finally {
        for (final watch in watches) {
          await watch.cancel();
        }
        await link.close().timeout(const Duration(seconds: 5));
      }
    }
  }, skip: live ? false : 'set SORA_CORE_LIVE to run against a running core');
}
