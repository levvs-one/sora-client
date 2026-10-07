import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:grpc/grpc.dart';
import 'package:http2/transport.dart';
import 'package:win32/win32.dart';

/// Carries gRPC to the core over its named pipe on Windows, where dart:io
/// has no pipes. The pipe is opened for overlapped I/O, so a read waiting for
/// the core never holds up a write: HTTP/2 talks both ways at once. Reading
/// and writing each wait on the system in an isolate of their own, so the
/// interface never does.
class PipeConnector implements ClientTransportConnector {
  PipeConnector(this.path);

  /// For example r"\\.\pipe\sora-core-v1".
  final String path;

  final _done = Completer<void>();
  _Pipe? _pipe;

  @override
  Future<ClientTransportConnection> connect() async {
    final pipe = await _Pipe.open(path);
    _pipe = pipe;
    unawaited(
      pipe.closed.whenComplete(() {
        if (!_done.isCompleted) _done.complete();
      }),
    );
    return ClientTransportConnection.viaStreams(pipe.incoming, pipe.outgoing);
  }

  @override
  Future<void> get done => _done.future;

  @override
  void shutdown() => unawaited(_pipe?.close());

  @override
  String get authority => 'localhost';
}

/// How long to wait for a pipe instance while all of them are busy: the core
/// opens a new one right after accepting a client.
const _busyRetries = 50;
const _busyPause = Duration(milliseconds: 40);

class _Pipe {
  _Pipe._(this._handle, this._reader, this._writer, this._writes, this.incoming);

  final int _handle;
  final Isolate _reader;
  final Isolate _writer;
  final SendPort _writes;
  final Stream<List<int>> incoming;
  final _outgoing = StreamController<List<int>>();
  final _closed = Completer<void>();
  bool _closing = false;

  StreamSink<List<int>> get outgoing => _outgoing.sink;
  Future<void> get closed => _closed.future;

  static Future<_Pipe> open(String path) async {
    final handle = await _create(path);
    final reads = ReceivePort();
    final writerReady = ReceivePort();
    final Isolate reader;
    final Isolate writer;
    try {
      reader = await Isolate.spawn(_readLoop, (handle, reads.sendPort));
      writer = await Isolate.spawn(_writeLoop, (handle, writerReady.sendPort));
    } catch (_) {
      CloseHandle(HANDLE(Pointer.fromAddress(handle)));
      reads.close();
      writerReady.close();
      rethrow;
    }
    final writes = await writerReady.first as SendPort;
    final incoming = StreamController<List<int>>();
    late final _Pipe pipe;
    reads.listen((message) {
      if (message is TransferableTypedData) {
        incoming.add(message.materialize().asUint8List());
      } else {
        // The core closed its end, or a read failed: the line is over.
        reads.close();
        unawaited(incoming.close());
        unawaited(pipe.close());
      }
    });
    pipe = _Pipe._(handle, reader, writer, writes, incoming.stream);
    pipe._outgoing.stream.listen(
      (chunk) => writes.send(TransferableTypedData.fromList([Uint8List.fromList(chunk)])),
      onDone: () => unawaited(pipe.close()),
    );
    return pipe;
  }

  /// Opens the client end, waiting while every instance is busy.
  static Future<int> _create(String path) async {
    final name = path.toPcwstr();
    try {
      for (var attempt = 0; ; attempt++) {
        final result = CreateFile(
          name,
          GENERIC_READ | GENERIC_WRITE,
          FILE_SHARE_NONE,
          null,
          OPEN_EXISTING,
          FILE_FLAG_OVERLAPPED,
          null,
        );
        if (result.value.isValid) return result.value.address;
        if (result.error != ERROR_PIPE_BUSY || attempt >= _busyRetries) {
          throw GrpcError.unavailable('the core pipe cannot be opened (error ${result.error})');
        }
        await Future<void>.delayed(_busyPause);
      }
    } finally {
      free(name);
    }
  }

  Future<void> close() async {
    if (_closing) return _closed.future;
    _closing = true;
    final handle = HANDLE(Pointer.fromAddress(_handle));
    // Pending reads and writes end with an error once cancelled, which lets
    // both isolates leave their loops before the handle goes away.
    CancelIoEx(handle, null);
    _writes.send(null);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _reader.kill(priority: Isolate.immediate);
    _writer.kill(priority: Isolate.immediate);
    CloseHandle(handle);
    unawaited(_outgoing.close());
    if (!_closed.isCompleted) _closed.complete();
  }
}

/// Reads until the pipe closes, sending each chunk to the main isolate and a
/// null at the end.
void _readLoop((int, SendPort) args) {
  final (address, out) = args;
  final handle = HANDLE(Pointer.fromAddress(address));
  const size = 64 * 1024;
  final buffer = calloc<Uint8>(size);
  final overlapped = calloc<OVERLAPPED>();
  final transferred = calloc<Uint32>();
  final event = CreateEvent(null, true, false, null).value;
  overlapped.ref.hEvent = event;
  try {
    while (true) {
      final read = ReadFile(handle, buffer, size, null, overlapped);
      if (!read.value && read.error != ERROR_IO_PENDING) break;
      final done = GetOverlappedResult(handle, overlapped, transferred, true);
      if (!done.value || transferred.value == 0) break;
      out.send(TransferableTypedData.fromList([Uint8List.fromList(buffer.asTypedList(transferred.value))]));
    }
  } finally {
    out.send(null);
    CloseHandle(event);
    calloc
      ..free(buffer)
      ..free(overlapped)
      ..free(transferred);
  }
}

/// Writes every chunk it receives, in order, until it receives null.
void _writeLoop((int, SendPort) args) {
  final (address, ready) = args;
  final handle = HANDLE(Pointer.fromAddress(address));
  final inbox = ReceivePort();
  ready.send(inbox.sendPort);
  final overlapped = calloc<OVERLAPPED>();
  final transferred = calloc<Uint32>();
  final event = CreateEvent(null, true, false, null).value;
  overlapped.ref.hEvent = event;
  inbox.listen((message) {
    if (message is! TransferableTypedData) {
      inbox.close();
      CloseHandle(event);
      calloc
        ..free(overlapped)
        ..free(transferred);
      return;
    }
    final bytes = message.materialize().asUint8List();
    final buffer = calloc<Uint8>(bytes.length);
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      var sent = 0;
      while (sent < bytes.length) {
        final write = WriteFile(handle, buffer + sent, bytes.length - sent, null, overlapped);
        if (!write.value && write.error != ERROR_IO_PENDING) return;
        if (!GetOverlappedResult(handle, overlapped, transferred, true).value) return;
        sent += transferred.value;
      }
    } finally {
      calloc.free(buffer);
    }
  });
}
