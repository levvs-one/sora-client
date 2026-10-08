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
  PipeConnector(this.path, {this.requireService = true});

  /// For example r"\\.\pipe\sora-core-v1".
  final String path;

  /// Whether the other end must be the Sora service, which runs as
  /// LocalSystem. Off only for a core started by hand on a path of its own.
  final bool requireService;

  final _done = Completer<void>();
  _Pipe? _pipe;

  @override
  Future<ClientTransportConnection> connect() async {
    final pipe = await _Pipe.open(path, requireService: requireService);
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

/// Read, write and attributes, the rights the service grants: GENERIC_WRITE
/// would also ask for the right to create instances of the pipe, which the
/// service gives nobody but itself.
const _pipeAccess = 0x0012018B;

final _serverProcessId = DynamicLibrary.open('kernel32.dll')
    .lookupFunction<Int32 Function(Pointer<Void>, Pointer<Uint32>), int Function(Pointer<Void>, Pointer<Uint32>)>(
      'GetNamedPipeServerProcessId',
    );

/// The security identifier of LocalSystem, S-1-5-18, as it sits in memory.
const _localSystem = [1, 1, 0, 0, 0, 0, 0, 5, 18, 0, 0, 0];

/// Whether the process at the other end of [pipe] runs as LocalSystem, as the
/// Sora service does.
bool _servedBySystem(HANDLE pipe) => using((arena) {
  final pid = arena<Uint32>();
  if (_serverProcessId(pipe.cast(), pid) == 0) return false;
  final process = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, false, pid.value).value;
  if (!process.isValid) return false;
  try {
    final token = arena<Pointer>();
    if (!OpenProcessToken(process, TOKEN_QUERY, token).value) return false;
    final tokenHandle = HANDLE(token.value);
    try {
      const size = 256;
      final info = arena<Uint8>(size);
      final returned = arena<Uint32>();
      if (!GetTokenInformation(tokenHandle, TokenUser, info, size, returned).value) return false;
      // TOKEN_USER starts with the pointer to the SID, which lies in the buffer.
      final sid = info.cast<Pointer<Uint8>>().value;
      for (final (i, byte) in _localSystem.indexed) {
        if (sid[i] != byte) return false;
      }
      return true;
    } finally {
      CloseHandle(tokenHandle);
    }
  } finally {
    CloseHandle(process);
  }
});

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

  static Future<_Pipe> open(String path, {required bool requireService}) async {
    final handle = await _create(path);
    // Anyone signed in could otherwise create a pipe of the same name before
    // the service does, and receive the app's requests and the system proxy
    // it would point at the answer.
    if (requireService && !_servedBySystem(HANDLE(Pointer.fromAddress(handle)))) {
      CloseHandle(HANDLE(Pointer.fromAddress(handle)));
      throw const GrpcError.unavailable('the core pipe is not served by the Sora service');
    }
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
        final result = CreateFile(name, _pipeAccess, FILE_SHARE_NONE, null, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, null);
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

/// NtReadFile and NtWriteFile answer with the status of the call itself, and
/// a call that waited leaves its status in the IO_STATUS_BLOCK, which is the
/// head of the OVERLAPPED. Nothing depends on GetLastError: read through the
/// win32 package in these isolates it was sometimes 0 for a read that was
/// only pending, and a working line was taken for a closed one.
typedef _NtIoNative = Int32 Function(
  Pointer<Void> file,
  Pointer<Void> event,
  Pointer<Void> apc,
  Pointer<Void> apcContext,
  Pointer<OVERLAPPED> status,
  Pointer<Uint8> buffer,
  Uint32 length,
  Pointer<Int64> offset,
  Pointer<Uint32> key,
);
typedef _NtIo = int Function(
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<Void>,
  Pointer<OVERLAPPED>,
  Pointer<Uint8>,
  int,
  Pointer<Int64>,
  Pointer<Uint32>,
);
final _ntdll = DynamicLibrary.open('ntdll.dll');
final _ntReadFile = _ntdll.lookupFunction<_NtIoNative, _NtIo>('NtReadFile');
final _ntWriteFile = _ntdll.lookupFunction<_NtIoNative, _NtIo>('NtWriteFile');
const _statusPending = 0x103;

/// Starts one read or write and waits for it. Answers the bytes it moved, or
/// null when the line is over: the core closed its end, or [_Pipe.close]
/// cancelled the call.
int? _transfer(_NtIo call, HANDLE file, HANDLE event, Pointer<OVERLAPPED> block, Pointer<Uint8> buffer, int length) {
  // A pipe has no position; the offset is there because the call takes one,
  // and it is the zeroed Offset fields of the OVERLAPPED.
  final offset = Pointer<Int64>.fromAddress(block.address + 16);
  var status = call(file.cast(), event.cast(), nullptr, nullptr, block, buffer, length, offset, nullptr);
  if (status == _statusPending) {
    // A wait that fails leaves the call running in the buffer and the block:
    // the line cannot be used again, so it is over.
    if (WaitForSingleObject(event, INFINITE).value != WAIT_OBJECT_0) return null;
    status = block.ref.Internal.toSigned(32);
  }
  // Errors and warnings have the high bit set.
  return status < 0 ? null : block.ref.InternalHigh;
}

/// Reads until the pipe closes, sending each chunk to the main isolate and a
/// null at the end.
void _readLoop((int, SendPort) args) {
  final (address, out) = args;
  final handle = HANDLE(Pointer.fromAddress(address));
  const size = 64 * 1024;
  final buffer = calloc<Uint8>(size);
  final overlapped = calloc<OVERLAPPED>();
  final event = CreateEvent(null, true, false, null).value;
  overlapped.ref.hEvent = event;
  try {
    // Without an event no call can be waited for: the line is over at once.
    while (event.isValid) {
      final read = _transfer(_ntReadFile, handle, event, overlapped, buffer, size);
      if (read == null) break;
      if (read == 0) continue;
      out.send(TransferableTypedData.fromList([Uint8List.fromList(buffer.asTypedList(read))]));
    }
  } finally {
    out.send(null);
    CloseHandle(event);
    calloc
      ..free(buffer)
      ..free(overlapped);
  }
}

/// Writes every chunk it receives, in order, until it receives null.
void _writeLoop((int, SendPort) args) {
  final (address, ready) = args;
  final handle = HANDLE(Pointer.fromAddress(address));
  final inbox = ReceivePort();
  ready.send(inbox.sendPort);
  final overlapped = calloc<OVERLAPPED>();
  final event = CreateEvent(null, true, false, null).value;
  overlapped.ref.hEvent = event;
  inbox.listen((message) {
    if (message is! TransferableTypedData || !event.isValid) {
      inbox.close();
      CloseHandle(event);
      calloc.free(overlapped);
      return;
    }
    final bytes = message.materialize().asUint8List();
    final buffer = calloc<Uint8>(bytes.length);
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      var sent = 0;
      while (sent < bytes.length) {
        final written = _transfer(_ntWriteFile, handle, event, overlapped, buffer + sent, bytes.length - sent);
        if (written == null) return;
        sent += written;
      }
    } finally {
      calloc.free(buffer);
    }
  });
}
