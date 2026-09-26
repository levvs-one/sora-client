//
//  Generated code. Do not modify.
//  source: sora/core/v1/core_control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'core_control.pb.dart' as $0;

export 'core_control.pb.dart';

@$pb.GrpcServiceName('sora.core.v1.CoreControl')
class CoreControlClient extends $grpc.Client {
  static final _$connect = $grpc.ClientMethod<$0.ConnectRequest, $0.ConnectResponse>(
      '/sora.core.v1.CoreControl/Connect',
      ($0.ConnectRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ConnectResponse.fromBuffer(value));
  static final _$disconnect = $grpc.ClientMethod<$0.DisconnectRequest, $0.DisconnectResponse>(
      '/sora.core.v1.CoreControl/Disconnect',
      ($0.DisconnectRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.DisconnectResponse.fromBuffer(value));
  static final _$getStatus = $grpc.ClientMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
      '/sora.core.v1.CoreControl/GetStatus',
      ($0.GetStatusRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetStatusResponse.fromBuffer(value));
  static final _$watchEvents = $grpc.ClientMethod<$0.WatchEventsRequest, $0.CoreEvent>(
      '/sora.core.v1.CoreControl/WatchEvents',
      ($0.WatchEventsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CoreEvent.fromBuffer(value));
  static final _$parseImport = $grpc.ClientMethod<$0.ParseImportRequest, $0.ParseImportResponse>(
      '/sora.core.v1.CoreControl/ParseImport',
      ($0.ParseImportRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ParseImportResponse.fromBuffer(value));
  static final _$fetchSubscription = $grpc.ClientMethod<$0.FetchSubscriptionRequest, $0.FetchSubscriptionResponse>(
      '/sora.core.v1.CoreControl/FetchSubscription',
      ($0.FetchSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.FetchSubscriptionResponse.fromBuffer(value));
  static final _$probeServers = $grpc.ClientMethod<$0.ProbeServersRequest, $0.ProbeResult>(
      '/sora.core.v1.CoreControl/ProbeServers',
      ($0.ProbeServersRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ProbeResult.fromBuffer(value));
  static final _$getStats = $grpc.ClientMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
      '/sora.core.v1.CoreControl/GetStats',
      ($0.GetStatsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetStatsResponse.fromBuffer(value));
  static final _$runDiagnostics = $grpc.ClientMethod<$0.RunDiagnosticsRequest, $0.RunDiagnosticsResponse>(
      '/sora.core.v1.CoreControl/RunDiagnostics',
      ($0.RunDiagnosticsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.RunDiagnosticsResponse.fromBuffer(value));
  static final _$exportDiagnostics = $grpc.ClientMethod<$0.ExportDiagnosticsRequest, $0.ExportDiagnosticsResponse>(
      '/sora.core.v1.CoreControl/ExportDiagnostics',
      ($0.ExportDiagnosticsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ExportDiagnosticsResponse.fromBuffer(value));
  static final _$setKillSwitch = $grpc.ClientMethod<$0.SetKillSwitchRequest, $0.SetKillSwitchResponse>(
      '/sora.core.v1.CoreControl/SetKillSwitch',
      ($0.SetKillSwitchRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SetKillSwitchResponse.fromBuffer(value));
  static final _$handshake = $grpc.ClientMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
      '/sora.core.v1.CoreControl/Handshake',
      ($0.HandshakeRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.HandshakeResponse.fromBuffer(value));

  CoreControlClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options,
        interceptors: interceptors);

  $grpc.ResponseFuture<$0.ConnectResponse> connect($0.ConnectRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$connect, request, options: options);
  }

  $grpc.ResponseFuture<$0.DisconnectResponse> disconnect($0.DisconnectRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$disconnect, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetStatusResponse> getStatus($0.GetStatusRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getStatus, request, options: options);
  }

  $grpc.ResponseStream<$0.CoreEvent> watchEvents($0.WatchEventsRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$watchEvents, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.ParseImportResponse> parseImport($0.ParseImportRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$parseImport, request, options: options);
  }

  $grpc.ResponseFuture<$0.FetchSubscriptionResponse> fetchSubscription($0.FetchSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$fetchSubscription, request, options: options);
  }

  $grpc.ResponseStream<$0.ProbeResult> probeServers($0.ProbeServersRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$probeServers, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.GetStatsResponse> getStats($0.GetStatsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getStats, request, options: options);
  }

  $grpc.ResponseFuture<$0.RunDiagnosticsResponse> runDiagnostics($0.RunDiagnosticsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$runDiagnostics, request, options: options);
  }

  $grpc.ResponseFuture<$0.ExportDiagnosticsResponse> exportDiagnostics($0.ExportDiagnosticsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$exportDiagnostics, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetKillSwitchResponse> setKillSwitch($0.SetKillSwitchRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setKillSwitch, request, options: options);
  }

  $grpc.ResponseFuture<$0.HandshakeResponse> handshake($0.HandshakeRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$handshake, request, options: options);
  }
}

@$pb.GrpcServiceName('sora.core.v1.CoreControl')
abstract class CoreControlServiceBase extends $grpc.Service {
  $core.String get $name => 'sora.core.v1.CoreControl';

  CoreControlServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.ConnectRequest, $0.ConnectResponse>(
        'Connect',
        connect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ConnectRequest.fromBuffer(value),
        ($0.ConnectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DisconnectRequest, $0.DisconnectResponse>(
        'Disconnect',
        disconnect_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DisconnectRequest.fromBuffer(value),
        ($0.DisconnectResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatusRequest, $0.GetStatusResponse>(
        'GetStatus',
        getStatus_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatusRequest.fromBuffer(value),
        ($0.GetStatusResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchEventsRequest, $0.CoreEvent>(
        'WatchEvents',
        watchEvents_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchEventsRequest.fromBuffer(value),
        ($0.CoreEvent value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ParseImportRequest, $0.ParseImportResponse>(
        'ParseImport',
        parseImport_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ParseImportRequest.fromBuffer(value),
        ($0.ParseImportResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.FetchSubscriptionRequest, $0.FetchSubscriptionResponse>(
        'FetchSubscription',
        fetchSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.FetchSubscriptionRequest.fromBuffer(value),
        ($0.FetchSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ProbeServersRequest, $0.ProbeResult>(
        'ProbeServers',
        probeServers_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.ProbeServersRequest.fromBuffer(value),
        ($0.ProbeResult value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetStatsRequest, $0.GetStatsResponse>(
        'GetStats',
        getStats_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetStatsRequest.fromBuffer(value),
        ($0.GetStatsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RunDiagnosticsRequest, $0.RunDiagnosticsResponse>(
        'RunDiagnostics',
        runDiagnostics_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RunDiagnosticsRequest.fromBuffer(value),
        ($0.RunDiagnosticsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportDiagnosticsRequest, $0.ExportDiagnosticsResponse>(
        'ExportDiagnostics',
        exportDiagnostics_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExportDiagnosticsRequest.fromBuffer(value),
        ($0.ExportDiagnosticsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetKillSwitchRequest, $0.SetKillSwitchResponse>(
        'SetKillSwitch',
        setKillSwitch_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetKillSwitchRequest.fromBuffer(value),
        ($0.SetKillSwitchResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.HandshakeRequest, $0.HandshakeResponse>(
        'Handshake',
        handshake_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.HandshakeRequest.fromBuffer(value),
        ($0.HandshakeResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.ConnectResponse> connect_Pre($grpc.ServiceCall call, $async.Future<$0.ConnectRequest> request) async {
    return connect(call, await request);
  }

  $async.Future<$0.DisconnectResponse> disconnect_Pre($grpc.ServiceCall call, $async.Future<$0.DisconnectRequest> request) async {
    return disconnect(call, await request);
  }

  $async.Future<$0.GetStatusResponse> getStatus_Pre($grpc.ServiceCall call, $async.Future<$0.GetStatusRequest> request) async {
    return getStatus(call, await request);
  }

  $async.Stream<$0.CoreEvent> watchEvents_Pre($grpc.ServiceCall call, $async.Future<$0.WatchEventsRequest> request) async* {
    yield* watchEvents(call, await request);
  }

  $async.Future<$0.ParseImportResponse> parseImport_Pre($grpc.ServiceCall call, $async.Future<$0.ParseImportRequest> request) async {
    return parseImport(call, await request);
  }

  $async.Future<$0.FetchSubscriptionResponse> fetchSubscription_Pre($grpc.ServiceCall call, $async.Future<$0.FetchSubscriptionRequest> request) async {
    return fetchSubscription(call, await request);
  }

  $async.Stream<$0.ProbeResult> probeServers_Pre($grpc.ServiceCall call, $async.Future<$0.ProbeServersRequest> request) async* {
    yield* probeServers(call, await request);
  }

  $async.Future<$0.GetStatsResponse> getStats_Pre($grpc.ServiceCall call, $async.Future<$0.GetStatsRequest> request) async {
    return getStats(call, await request);
  }

  $async.Future<$0.RunDiagnosticsResponse> runDiagnostics_Pre($grpc.ServiceCall call, $async.Future<$0.RunDiagnosticsRequest> request) async {
    return runDiagnostics(call, await request);
  }

  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics_Pre($grpc.ServiceCall call, $async.Future<$0.ExportDiagnosticsRequest> request) async {
    return exportDiagnostics(call, await request);
  }

  $async.Future<$0.SetKillSwitchResponse> setKillSwitch_Pre($grpc.ServiceCall call, $async.Future<$0.SetKillSwitchRequest> request) async {
    return setKillSwitch(call, await request);
  }

  $async.Future<$0.HandshakeResponse> handshake_Pre($grpc.ServiceCall call, $async.Future<$0.HandshakeRequest> request) async {
    return handshake(call, await request);
  }

  $async.Future<$0.ConnectResponse> connect($grpc.ServiceCall call, $0.ConnectRequest request);
  $async.Future<$0.DisconnectResponse> disconnect($grpc.ServiceCall call, $0.DisconnectRequest request);
  $async.Future<$0.GetStatusResponse> getStatus($grpc.ServiceCall call, $0.GetStatusRequest request);
  $async.Stream<$0.CoreEvent> watchEvents($grpc.ServiceCall call, $0.WatchEventsRequest request);
  $async.Future<$0.ParseImportResponse> parseImport($grpc.ServiceCall call, $0.ParseImportRequest request);
  $async.Future<$0.FetchSubscriptionResponse> fetchSubscription($grpc.ServiceCall call, $0.FetchSubscriptionRequest request);
  $async.Stream<$0.ProbeResult> probeServers($grpc.ServiceCall call, $0.ProbeServersRequest request);
  $async.Future<$0.GetStatsResponse> getStats($grpc.ServiceCall call, $0.GetStatsRequest request);
  $async.Future<$0.RunDiagnosticsResponse> runDiagnostics($grpc.ServiceCall call, $0.RunDiagnosticsRequest request);
  $async.Future<$0.ExportDiagnosticsResponse> exportDiagnostics($grpc.ServiceCall call, $0.ExportDiagnosticsRequest request);
  $async.Future<$0.SetKillSwitchResponse> setKillSwitch($grpc.ServiceCall call, $0.SetKillSwitchRequest request);
  $async.Future<$0.HandshakeResponse> handshake($grpc.ServiceCall call, $0.HandshakeRequest request);
}
