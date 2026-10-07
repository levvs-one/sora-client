import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc/service_api.dart' as api;
import 'package:retry/retry.dart';

import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import 'pipe.dart';

/// The contract this interface speaks: 1.4, and nothing older, because the
/// address of the local proxy the system proxy points at arrived in it.
final apiVersion = ApiVersion(major: 1, minor: 4, minSupportedMinor: 4);

/// An open line to the core: the channel over its unix socket and the token
/// the core handed over in Handshake.
class CoreLink {
  CoreLink._(this._channel, this.stub, this.token);

  final api.ClientChannel _channel;
  final CoreControlClient stub;
  final List<int> token;

  /// Where a system installation listens: a unix socket on Linux, a named
  /// pipe on Windows. SORA_CORE_SOCKET points at a core run by hand with
  /// -socket.
  static String get socketPath =>
      Platform.environment['SORA_CORE_SOCKET'] ??
      (Platform.isWindows ? r'\\.\pipe\sora-core-v1' : '/run/sora/core.sock');

  /// Opens the line, trying again with a growing pause until the core answers:
  /// the service may still be starting, or may be restarting after an update.
  static Future<CoreLink> open() {
    return const RetryOptions(
      maxAttempts: 1 << 30,
      maxDelay: Duration(seconds: 5),
    ).retry(_openOnce, retryIf: (e) => e is GrpcError && e.code != StatusCode.permissionDenied);
  }

  static Future<CoreLink> _openOnce() async {
    const options = ChannelOptions(credentials: ChannelCredentials.insecure());
    final api.ClientChannel channel = Platform.isWindows
        ? ClientTransportConnectorChannel(PipeConnector(socketPath), options: options)
        : ClientChannel(InternetAddress(socketPath, type: InternetAddressType.unix), port: 0, options: options);
    try {
      final stub = CoreControlClient(channel);
      final answer = await stub.handshake(
        HandshakeRequest(clientVersion: apiVersion),
        options: CallOptions(timeout: const Duration(seconds: 5)),
      );
      if (answer.hasError()) throw CoreFailure(answer.error.userMessageKey);
      return CoreLink._(channel, stub, answer.controlAuthenticator);
    } catch (_) {
      await channel.shutdown();
      rethrow;
    }
  }

  Future<void> close() => _channel.shutdown();
}

/// A failure the core reported, named by the key of its message catalog.
class CoreFailure implements Exception {
  const CoreFailure(this.key);

  /// The key of the core catalog, for example "core.engine.start_failed", or
  /// one of the interface's own keys under "app.".
  final String key;

  static const unavailable = CoreFailure('app.core_unavailable');

  /// Turns whatever a call threw into a failure with a catalog key.
  static CoreFailure from(Object error) {
    if (error is CoreFailure) return error;
    if (error is GrpcError) {
      // The core answers in-transport refusals as "<code> <catalog key>".
      final key = (error.message ?? '').split(' ').last;
      if (key.startsWith('core.')) return CoreFailure(key);
      return switch (error.code) {
        StatusCode.unavailable || StatusCode.deadlineExceeded || StatusCode.cancelled => unavailable,
        StatusCode.unauthenticated || StatusCode.permissionDenied => const CoreFailure('core.auth.unauthenticated'),
        _ => const CoreFailure('core.internal.unexpected'),
      };
    }
    return const CoreFailure('core.internal.unexpected');
  }

  @override
  String toString() => key;
}
