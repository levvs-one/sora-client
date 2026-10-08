import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc/service_api.dart' as api;
import 'package:retry/retry.dart';

import '../generated/sora/core/v1/core_control.pbgrpc.dart';
import 'pipe.dart';

/// API 1.4 is required for the local proxy endpoint used by the system proxy.
final apiVersion = ApiVersion(major: 1, minor: 5, minSupportedMinor: 5);

/// A gRPC channel to the core over a Unix socket or Windows named pipe, with
/// the Handshake authentication token.
class CoreLink {
  CoreLink._(this._channel, this.stub, this.token);

  final api.ClientChannel _channel;
  final CoreControlClient stub;
  final List<int> token;

  /// The installed service endpoint: Unix socket on Linux, named pipe on
  /// Windows. SORA_CORE_SOCKET overrides it for a manually started core using
  /// -socket.
  static String get socketPath =>
      Platform.environment['SORA_CORE_SOCKET'] ??
      (Platform.isWindows ? r'\\.\pipe\sora-core-v1' : '/run/sora/core.sock');

  /// Opens a core connection with increasing retry delays while the service
  /// starts or restarts after an update.
  static Future<CoreLink> open() {
    return const RetryOptions(
      maxAttempts: 1 << 30,
      maxDelay: Duration(seconds: 5),
    ).retry(_openOnce, retryIf: (e) => e is GrpcError && e.code != StatusCode.permissionDenied);
  }

  static Future<CoreLink> _openOnce() async {
    const options = ChannelOptions(credentials: ChannelCredentials.insecure());
    final api.ClientChannel channel = Platform.isWindows
        ? ClientTransportConnectorChannel(
            PipeConnector(socketPath, requireService: Platform.environment['SORA_CORE_SOCKET'] == null),
            options: options,
          )
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

/// A core or app failure identified by a message catalog key.
class CoreFailure implements Exception {
  const CoreFailure(this.key);

  /// A core catalog key, such as "core.engine.start_failed", or an app key
  /// under "app.".
  final String key;

  static const unavailable = CoreFailure('app.core_unavailable');

  /// Converts a request exception to a failure with a message catalog key.
  static CoreFailure from(Object error) {
    if (error is CoreFailure) return error;
    if (error is GrpcError) {
      // Transport errors from the core use "<code> <catalog key>".
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
