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
  static final _$getAbout = $grpc.ClientMethod<$0.GetAboutRequest, $0.GetAboutResponse>(
      '/sora.core.v1.CoreControl/GetAbout',
      ($0.GetAboutRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetAboutResponse.fromBuffer(value));
  static final _$getRoutingPresets = $grpc.ClientMethod<$0.GetRoutingPresetsRequest, $0.GetRoutingPresetsResponse>(
      '/sora.core.v1.CoreControl/GetRoutingPresets',
      ($0.GetRoutingPresetsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetRoutingPresetsResponse.fromBuffer(value));
  static final _$queryLogs = $grpc.ClientMethod<$0.QueryLogsRequest, $0.QueryLogsResponse>(
      '/sora.core.v1.CoreControl/QueryLogs',
      ($0.QueryLogsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.QueryLogsResponse.fromBuffer(value));
  static final _$watchLogs = $grpc.ClientMethod<$0.WatchLogsRequest, $0.LogEntry>(
      '/sora.core.v1.CoreControl/WatchLogs',
      ($0.WatchLogsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.LogEntry.fromBuffer(value));
  static final _$exportLogs = $grpc.ClientMethod<$0.ExportLogsRequest, $0.ExportLogsResponse>(
      '/sora.core.v1.CoreControl/ExportLogs',
      ($0.ExportLogsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ExportLogsResponse.fromBuffer(value));
  static final _$clearLogs = $grpc.ClientMethod<$0.ClearLogsRequest, $0.ClearLogsResponse>(
      '/sora.core.v1.CoreControl/ClearLogs',
      ($0.ClearLogsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ClearLogsResponse.fromBuffer(value));
  static final _$getLogSettings = $grpc.ClientMethod<$0.GetLogSettingsRequest, $0.GetLogSettingsResponse>(
      '/sora.core.v1.CoreControl/GetLogSettings',
      ($0.GetLogSettingsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.GetLogSettingsResponse.fromBuffer(value));
  static final _$setLogSettings = $grpc.ClientMethod<$0.SetLogSettingsRequest, $0.SetLogSettingsResponse>(
      '/sora.core.v1.CoreControl/SetLogSettings',
      ($0.SetLogSettingsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SetLogSettingsResponse.fromBuffer(value));
  static final _$listConnections = $grpc.ClientMethod<$0.ListConnectionsRequest, $0.ListConnectionsResponse>(
      '/sora.core.v1.CoreControl/ListConnections',
      ($0.ListConnectionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListConnectionsResponse.fromBuffer(value));
  static final _$closeConnection = $grpc.ClientMethod<$0.CloseConnectionRequest, $0.CloseConnectionResponse>(
      '/sora.core.v1.CoreControl/CloseConnection',
      ($0.CloseConnectionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.CloseConnectionResponse.fromBuffer(value));
  static final _$saveSubscription = $grpc.ClientMethod<$0.SaveSubscriptionRequest, $0.SaveSubscriptionResponse>(
      '/sora.core.v1.CoreControl/SaveSubscription',
      ($0.SaveSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SaveSubscriptionResponse.fromBuffer(value));
  static final _$listSubscriptions = $grpc.ClientMethod<$0.ListSubscriptionsRequest, $0.ListSubscriptionsResponse>(
      '/sora.core.v1.CoreControl/ListSubscriptions',
      ($0.ListSubscriptionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.ListSubscriptionsResponse.fromBuffer(value));
  static final _$deleteSubscription = $grpc.ClientMethod<$0.DeleteSubscriptionRequest, $0.DeleteSubscriptionResponse>(
      '/sora.core.v1.CoreControl/DeleteSubscription',
      ($0.DeleteSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.DeleteSubscriptionResponse.fromBuffer(value));
  static final _$refreshSubscription = $grpc.ClientMethod<$0.RefreshSubscriptionRequest, $0.RefreshSubscriptionResponse>(
      '/sora.core.v1.CoreControl/RefreshSubscription',
      ($0.RefreshSubscriptionRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.RefreshSubscriptionResponse.fromBuffer(value));
  static final _$watchSubscriptions = $grpc.ClientMethod<$0.WatchSubscriptionsRequest, $0.SubscriptionState>(
      '/sora.core.v1.CoreControl/WatchSubscriptions',
      ($0.WatchSubscriptionsRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.SubscriptionState.fromBuffer(value));
  static final _$putSecret = $grpc.ClientMethod<$0.PutSecretRequest, $0.PutSecretResponse>(
      '/sora.core.v1.CoreControl/PutSecret',
      ($0.PutSecretRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.PutSecretResponse.fromBuffer(value));
  static final _$deleteSecret = $grpc.ClientMethod<$0.DeleteSecretRequest, $0.DeleteSecretResponse>(
      '/sora.core.v1.CoreControl/DeleteSecret',
      ($0.DeleteSecretRequest value) => value.writeToBuffer(),
      ($core.List<$core.int> value) => $0.DeleteSecretResponse.fromBuffer(value));

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

  $grpc.ResponseFuture<$0.GetAboutResponse> getAbout($0.GetAboutRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getAbout, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetRoutingPresetsResponse> getRoutingPresets($0.GetRoutingPresetsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getRoutingPresets, request, options: options);
  }

  $grpc.ResponseFuture<$0.QueryLogsResponse> queryLogs($0.QueryLogsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$queryLogs, request, options: options);
  }

  $grpc.ResponseStream<$0.LogEntry> watchLogs($0.WatchLogsRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$watchLogs, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.ExportLogsResponse> exportLogs($0.ExportLogsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$exportLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.ClearLogsResponse> clearLogs($0.ClearLogsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$clearLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.GetLogSettingsResponse> getLogSettings($0.GetLogSettingsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$getLogSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.SetLogSettingsResponse> setLogSettings($0.SetLogSettingsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$setLogSettings, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListConnectionsResponse> listConnections($0.ListConnectionsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listConnections, request, options: options);
  }

  $grpc.ResponseFuture<$0.CloseConnectionResponse> closeConnection($0.CloseConnectionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$closeConnection, request, options: options);
  }

  $grpc.ResponseFuture<$0.SaveSubscriptionResponse> saveSubscription($0.SaveSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$saveSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$0.ListSubscriptionsResponse> listSubscriptions($0.ListSubscriptionsRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$listSubscriptions, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSubscriptionResponse> deleteSubscription($0.DeleteSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSubscription, request, options: options);
  }

  $grpc.ResponseFuture<$0.RefreshSubscriptionResponse> refreshSubscription($0.RefreshSubscriptionRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$refreshSubscription, request, options: options);
  }

  $grpc.ResponseStream<$0.SubscriptionState> watchSubscriptions($0.WatchSubscriptionsRequest request, {$grpc.CallOptions? options}) {
    return $createStreamingCall(_$watchSubscriptions, $async.Stream.fromIterable([request]), options: options);
  }

  $grpc.ResponseFuture<$0.PutSecretResponse> putSecret($0.PutSecretRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$putSecret, request, options: options);
  }

  $grpc.ResponseFuture<$0.DeleteSecretResponse> deleteSecret($0.DeleteSecretRequest request, {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$deleteSecret, request, options: options);
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
    $addMethod($grpc.ServiceMethod<$0.GetAboutRequest, $0.GetAboutResponse>(
        'GetAbout',
        getAbout_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetAboutRequest.fromBuffer(value),
        ($0.GetAboutResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetRoutingPresetsRequest, $0.GetRoutingPresetsResponse>(
        'GetRoutingPresets',
        getRoutingPresets_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetRoutingPresetsRequest.fromBuffer(value),
        ($0.GetRoutingPresetsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.QueryLogsRequest, $0.QueryLogsResponse>(
        'QueryLogs',
        queryLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.QueryLogsRequest.fromBuffer(value),
        ($0.QueryLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchLogsRequest, $0.LogEntry>(
        'WatchLogs',
        watchLogs_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchLogsRequest.fromBuffer(value),
        ($0.LogEntry value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ExportLogsRequest, $0.ExportLogsResponse>(
        'ExportLogs',
        exportLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ExportLogsRequest.fromBuffer(value),
        ($0.ExportLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ClearLogsRequest, $0.ClearLogsResponse>(
        'ClearLogs',
        clearLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ClearLogsRequest.fromBuffer(value),
        ($0.ClearLogsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.GetLogSettingsRequest, $0.GetLogSettingsResponse>(
        'GetLogSettings',
        getLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.GetLogSettingsRequest.fromBuffer(value),
        ($0.GetLogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SetLogSettingsRequest, $0.SetLogSettingsResponse>(
        'SetLogSettings',
        setLogSettings_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SetLogSettingsRequest.fromBuffer(value),
        ($0.SetLogSettingsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListConnectionsRequest, $0.ListConnectionsResponse>(
        'ListConnections',
        listConnections_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListConnectionsRequest.fromBuffer(value),
        ($0.ListConnectionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.CloseConnectionRequest, $0.CloseConnectionResponse>(
        'CloseConnection',
        closeConnection_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.CloseConnectionRequest.fromBuffer(value),
        ($0.CloseConnectionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.SaveSubscriptionRequest, $0.SaveSubscriptionResponse>(
        'SaveSubscription',
        saveSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.SaveSubscriptionRequest.fromBuffer(value),
        ($0.SaveSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.ListSubscriptionsRequest, $0.ListSubscriptionsResponse>(
        'ListSubscriptions',
        listSubscriptions_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.ListSubscriptionsRequest.fromBuffer(value),
        ($0.ListSubscriptionsResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSubscriptionRequest, $0.DeleteSubscriptionResponse>(
        'DeleteSubscription',
        deleteSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteSubscriptionRequest.fromBuffer(value),
        ($0.DeleteSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.RefreshSubscriptionRequest, $0.RefreshSubscriptionResponse>(
        'RefreshSubscription',
        refreshSubscription_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.RefreshSubscriptionRequest.fromBuffer(value),
        ($0.RefreshSubscriptionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.WatchSubscriptionsRequest, $0.SubscriptionState>(
        'WatchSubscriptions',
        watchSubscriptions_Pre,
        false,
        true,
        ($core.List<$core.int> value) => $0.WatchSubscriptionsRequest.fromBuffer(value),
        ($0.SubscriptionState value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.PutSecretRequest, $0.PutSecretResponse>(
        'PutSecret',
        putSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.PutSecretRequest.fromBuffer(value),
        ($0.PutSecretResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.DeleteSecretRequest, $0.DeleteSecretResponse>(
        'DeleteSecret',
        deleteSecret_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.DeleteSecretRequest.fromBuffer(value),
        ($0.DeleteSecretResponse value) => value.writeToBuffer()));
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

  $async.Future<$0.GetAboutResponse> getAbout_Pre($grpc.ServiceCall call, $async.Future<$0.GetAboutRequest> request) async {
    return getAbout(call, await request);
  }

  $async.Future<$0.GetRoutingPresetsResponse> getRoutingPresets_Pre($grpc.ServiceCall call, $async.Future<$0.GetRoutingPresetsRequest> request) async {
    return getRoutingPresets(call, await request);
  }

  $async.Future<$0.QueryLogsResponse> queryLogs_Pre($grpc.ServiceCall call, $async.Future<$0.QueryLogsRequest> request) async {
    return queryLogs(call, await request);
  }

  $async.Stream<$0.LogEntry> watchLogs_Pre($grpc.ServiceCall call, $async.Future<$0.WatchLogsRequest> request) async* {
    yield* watchLogs(call, await request);
  }

  $async.Future<$0.ExportLogsResponse> exportLogs_Pre($grpc.ServiceCall call, $async.Future<$0.ExportLogsRequest> request) async {
    return exportLogs(call, await request);
  }

  $async.Future<$0.ClearLogsResponse> clearLogs_Pre($grpc.ServiceCall call, $async.Future<$0.ClearLogsRequest> request) async {
    return clearLogs(call, await request);
  }

  $async.Future<$0.GetLogSettingsResponse> getLogSettings_Pre($grpc.ServiceCall call, $async.Future<$0.GetLogSettingsRequest> request) async {
    return getLogSettings(call, await request);
  }

  $async.Future<$0.SetLogSettingsResponse> setLogSettings_Pre($grpc.ServiceCall call, $async.Future<$0.SetLogSettingsRequest> request) async {
    return setLogSettings(call, await request);
  }

  $async.Future<$0.ListConnectionsResponse> listConnections_Pre($grpc.ServiceCall call, $async.Future<$0.ListConnectionsRequest> request) async {
    return listConnections(call, await request);
  }

  $async.Future<$0.CloseConnectionResponse> closeConnection_Pre($grpc.ServiceCall call, $async.Future<$0.CloseConnectionRequest> request) async {
    return closeConnection(call, await request);
  }

  $async.Future<$0.SaveSubscriptionResponse> saveSubscription_Pre($grpc.ServiceCall call, $async.Future<$0.SaveSubscriptionRequest> request) async {
    return saveSubscription(call, await request);
  }

  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions_Pre($grpc.ServiceCall call, $async.Future<$0.ListSubscriptionsRequest> request) async {
    return listSubscriptions(call, await request);
  }

  $async.Future<$0.DeleteSubscriptionResponse> deleteSubscription_Pre($grpc.ServiceCall call, $async.Future<$0.DeleteSubscriptionRequest> request) async {
    return deleteSubscription(call, await request);
  }

  $async.Future<$0.RefreshSubscriptionResponse> refreshSubscription_Pre($grpc.ServiceCall call, $async.Future<$0.RefreshSubscriptionRequest> request) async {
    return refreshSubscription(call, await request);
  }

  $async.Stream<$0.SubscriptionState> watchSubscriptions_Pre($grpc.ServiceCall call, $async.Future<$0.WatchSubscriptionsRequest> request) async* {
    yield* watchSubscriptions(call, await request);
  }

  $async.Future<$0.PutSecretResponse> putSecret_Pre($grpc.ServiceCall call, $async.Future<$0.PutSecretRequest> request) async {
    return putSecret(call, await request);
  }

  $async.Future<$0.DeleteSecretResponse> deleteSecret_Pre($grpc.ServiceCall call, $async.Future<$0.DeleteSecretRequest> request) async {
    return deleteSecret(call, await request);
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
  $async.Future<$0.GetAboutResponse> getAbout($grpc.ServiceCall call, $0.GetAboutRequest request);
  $async.Future<$0.GetRoutingPresetsResponse> getRoutingPresets($grpc.ServiceCall call, $0.GetRoutingPresetsRequest request);
  $async.Future<$0.QueryLogsResponse> queryLogs($grpc.ServiceCall call, $0.QueryLogsRequest request);
  $async.Stream<$0.LogEntry> watchLogs($grpc.ServiceCall call, $0.WatchLogsRequest request);
  $async.Future<$0.ExportLogsResponse> exportLogs($grpc.ServiceCall call, $0.ExportLogsRequest request);
  $async.Future<$0.ClearLogsResponse> clearLogs($grpc.ServiceCall call, $0.ClearLogsRequest request);
  $async.Future<$0.GetLogSettingsResponse> getLogSettings($grpc.ServiceCall call, $0.GetLogSettingsRequest request);
  $async.Future<$0.SetLogSettingsResponse> setLogSettings($grpc.ServiceCall call, $0.SetLogSettingsRequest request);
  $async.Future<$0.ListConnectionsResponse> listConnections($grpc.ServiceCall call, $0.ListConnectionsRequest request);
  $async.Future<$0.CloseConnectionResponse> closeConnection($grpc.ServiceCall call, $0.CloseConnectionRequest request);
  $async.Future<$0.SaveSubscriptionResponse> saveSubscription($grpc.ServiceCall call, $0.SaveSubscriptionRequest request);
  $async.Future<$0.ListSubscriptionsResponse> listSubscriptions($grpc.ServiceCall call, $0.ListSubscriptionsRequest request);
  $async.Future<$0.DeleteSubscriptionResponse> deleteSubscription($grpc.ServiceCall call, $0.DeleteSubscriptionRequest request);
  $async.Future<$0.RefreshSubscriptionResponse> refreshSubscription($grpc.ServiceCall call, $0.RefreshSubscriptionRequest request);
  $async.Stream<$0.SubscriptionState> watchSubscriptions($grpc.ServiceCall call, $0.WatchSubscriptionsRequest request);
  $async.Future<$0.PutSecretResponse> putSecret($grpc.ServiceCall call, $0.PutSecretRequest request);
  $async.Future<$0.DeleteSecretResponse> deleteSecret($grpc.ServiceCall call, $0.DeleteSecretRequest request);
}
