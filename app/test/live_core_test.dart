// Requires SORA_CORE_LIVE and an installed core, as configured in CI. Uses the
// Linux Unix socket or Windows named pipe to verify the service.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sora/src/core/link.dart';
import 'package:sora/src/generated/sora/core/v1/core_control.pb.dart';

void main() {
  final live = Platform.environment['SORA_CORE_LIVE'] != null;

  test('the interface reaches the core, is given the token and is answered', () async {
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
}
