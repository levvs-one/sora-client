//
//  Generated code. Do not modify.
//  source: sora/core/v1/core_control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import '../../../google/protobuf/duration.pb.dart' as $1;
import '../../../google/protobuf/timestamp.pb.dart' as $2;
import 'core_control.pbenum.dart';

export 'core_control.pbenum.dart';

class ApiVersion extends $pb.GeneratedMessage {
  factory ApiVersion({
    $core.int? major,
    $core.int? minor,
    $core.int? minSupportedMinor,
    $core.Iterable<$core.String>? capabilities,
  }) {
    final $result = create();
    if (major != null) {
      $result.major = major;
    }
    if (minor != null) {
      $result.minor = minor;
    }
    if (minSupportedMinor != null) {
      $result.minSupportedMinor = minSupportedMinor;
    }
    if (capabilities != null) {
      $result.capabilities.addAll(capabilities);
    }
    return $result;
  }
  ApiVersion._() : super();
  factory ApiVersion.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApiVersion.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApiVersion', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'major', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'minor', $pb.PbFieldType.OU3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'minSupportedMinor', $pb.PbFieldType.OU3)
    ..pPS(4, _omitFieldNames ? '' : 'capabilities')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApiVersion clone() => ApiVersion()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApiVersion copyWith(void Function(ApiVersion) updates) => super.copyWith((message) => updates(message as ApiVersion)) as ApiVersion;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApiVersion create() => ApiVersion._();
  ApiVersion createEmptyInstance() => create();
  static $pb.PbList<ApiVersion> createRepeated() => $pb.PbList<ApiVersion>();
  @$core.pragma('dart2js:noInline')
  static ApiVersion getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApiVersion>(create);
  static ApiVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get major => $_getIZ(0);
  @$pb.TagNumber(1)
  set major($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasMajor() => $_has(0);
  @$pb.TagNumber(1)
  void clearMajor() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get minor => $_getIZ(1);
  @$pb.TagNumber(2)
  set minor($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasMinor() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinor() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get minSupportedMinor => $_getIZ(2);
  @$pb.TagNumber(3)
  set minSupportedMinor($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMinSupportedMinor() => $_has(2);
  @$pb.TagNumber(3)
  void clearMinSupportedMinor() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.String> get capabilities => $_getList(3);
}

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
    SessionPlan? sessionPlan,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (sessionPlan != null) {
      $result.sessionPlan = sessionPlan;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  ConnectRequest._() : super();
  factory ConnectRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOM<SessionPlan>(4, _omitFieldNames ? '' : 'sessionPlan', subBuilder: SessionPlan.create)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectRequest clone() => ConnectRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) => super.copyWith((message) => updates(message as ConnectRequest)) as ConnectRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectRequest create() => ConnectRequest._();
  ConnectRequest createEmptyInstance() => create();
  static $pb.PbList<ConnectRequest> createRepeated() => $pb.PbList<ConnectRequest>();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(create);
  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  SessionPlan get sessionPlan => $_getN(3);
  @$pb.TagNumber(4)
  set sessionPlan(SessionPlan v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasSessionPlan() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionPlan() => clearField(4);
  @$pb.TagNumber(4)
  SessionPlan ensureSessionPlan() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get controlAuthenticator => $_getN(4);
  @$pb.TagNumber(5)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasControlAuthenticator() => $_has(4);
  @$pb.TagNumber(5)
  void clearControlAuthenticator() => clearField(5);
}

class ConnectResponse extends $pb.GeneratedMessage {
  factory ConnectResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final $result = create();
    if (status != null) {
      $result.status = status;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ConnectResponse._() : super();
  factory ConnectResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectResponse clone() => ConnectResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectResponse copyWith(void Function(ConnectResponse) updates) => super.copyWith((message) => updates(message as ConnectResponse)) as ConnectResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectResponse create() => ConnectResponse._();
  ConnectResponse createEmptyInstance() => create();
  static $pb.PbList<ConnectResponse> createRepeated() => $pb.PbList<ConnectResponse>();
  @$core.pragma('dart2js:noInline')
  static ConnectResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectResponse>(create);
  static ConnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class DisconnectRequest extends $pb.GeneratedMessage {
  factory DisconnectRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  DisconnectRequest._() : super();
  factory DisconnectRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DisconnectRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DisconnectRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DisconnectRequest clone() => DisconnectRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DisconnectRequest copyWith(void Function(DisconnectRequest) updates) => super.copyWith((message) => updates(message as DisconnectRequest)) as DisconnectRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisconnectRequest create() => DisconnectRequest._();
  DisconnectRequest createEmptyInstance() => create();
  static $pb.PbList<DisconnectRequest> createRepeated() => $pb.PbList<DisconnectRequest>();
  @$core.pragma('dart2js:noInline')
  static DisconnectRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisconnectRequest>(create);
  static DisconnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get controlAuthenticator => $_getN(3);
  @$pb.TagNumber(4)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasControlAuthenticator() => $_has(3);
  @$pb.TagNumber(4)
  void clearControlAuthenticator() => clearField(4);
}

class DisconnectResponse extends $pb.GeneratedMessage {
  factory DisconnectResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final $result = create();
    if (status != null) {
      $result.status = status;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  DisconnectResponse._() : super();
  factory DisconnectResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DisconnectResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DisconnectResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DisconnectResponse clone() => DisconnectResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DisconnectResponse copyWith(void Function(DisconnectResponse) updates) => super.copyWith((message) => updates(message as DisconnectResponse)) as DisconnectResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DisconnectResponse create() => DisconnectResponse._();
  DisconnectResponse createEmptyInstance() => create();
  static $pb.PbList<DisconnectResponse> createRepeated() => $pb.PbList<DisconnectResponse>();
  @$core.pragma('dart2js:noInline')
  static DisconnectResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisconnectResponse>(create);
  static DisconnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  GetStatusRequest._() : super();
  factory GetStatusRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatusRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStatusRequest clone() => GetStatusRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) => super.copyWith((message) => updates(message as GetStatusRequest)) as GetStatusRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusRequest create() => GetStatusRequest._();
  GetStatusRequest createEmptyInstance() => create();
  static $pb.PbList<GetStatusRequest> createRepeated() => $pb.PbList<GetStatusRequest>();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(create);
  static GetStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final $result = create();
    if (status != null) {
      $result.status = status;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetStatusResponse._() : super();
  factory GetStatusResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatusResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStatusResponse clone() => GetStatusResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) => super.copyWith((message) => updates(message as GetStatusResponse)) as GetStatusResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatusResponse create() => GetStatusResponse._();
  GetStatusResponse createEmptyInstance() => create();
  static $pb.PbList<GetStatusResponse> createRepeated() => $pb.PbList<GetStatusResponse>();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusResponse>(create);
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class WatchEventsRequest extends $pb.GeneratedMessage {
  factory WatchEventsRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
    $fixnum.Int64? afterSequence,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (afterSequence != null) {
      $result.afterSequence = afterSequence;
    }
    return $result;
  }
  WatchEventsRequest._() : super();
  factory WatchEventsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WatchEventsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchEventsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'afterSequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WatchEventsRequest clone() => WatchEventsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WatchEventsRequest copyWith(void Function(WatchEventsRequest) updates) => super.copyWith((message) => updates(message as WatchEventsRequest)) as WatchEventsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchEventsRequest create() => WatchEventsRequest._();
  WatchEventsRequest createEmptyInstance() => create();
  static $pb.PbList<WatchEventsRequest> createRepeated() => $pb.PbList<WatchEventsRequest>();
  @$core.pragma('dart2js:noInline')
  static WatchEventsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchEventsRequest>(create);
  static WatchEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get afterSequence => $_getI64(2);
  @$pb.TagNumber(3)
  set afterSequence($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAfterSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterSequence() => clearField(3);
}

class SessionPlan extends $pb.GeneratedMessage {
  factory SessionPlan({
    TunnelMode? tunnelMode,
    $core.Iterable<OutboundSpec>? outbounds,
    $core.Iterable<RoutingRule>? routes,
    DnsPolicy? dnsPolicy,
    BypassSettings? bypassSettings,
    $core.String? sessionIdentity,
    AntiCensorship? antiCensorship,
    $core.Iterable<$core.String>? engines,
    $core.bool? networkControlAllowed,
    LocalProxy? localProxy,
    $core.Iterable<GroupSpec>? groups,
    RoutingOptions? routing,
  }) {
    final $result = create();
    if (tunnelMode != null) {
      $result.tunnelMode = tunnelMode;
    }
    if (outbounds != null) {
      $result.outbounds.addAll(outbounds);
    }
    if (routes != null) {
      $result.routes.addAll(routes);
    }
    if (dnsPolicy != null) {
      $result.dnsPolicy = dnsPolicy;
    }
    if (bypassSettings != null) {
      $result.bypassSettings = bypassSettings;
    }
    if (sessionIdentity != null) {
      $result.sessionIdentity = sessionIdentity;
    }
    if (antiCensorship != null) {
      $result.antiCensorship = antiCensorship;
    }
    if (engines != null) {
      $result.engines.addAll(engines);
    }
    if (networkControlAllowed != null) {
      $result.networkControlAllowed = networkControlAllowed;
    }
    if (localProxy != null) {
      $result.localProxy = localProxy;
    }
    if (groups != null) {
      $result.groups.addAll(groups);
    }
    if (routing != null) {
      $result.routing = routing;
    }
    return $result;
  }
  SessionPlan._() : super();
  factory SessionPlan.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SessionPlan.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SessionPlan', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<TunnelMode>(1, _omitFieldNames ? '' : 'tunnelMode', $pb.PbFieldType.OE, defaultOrMaker: TunnelMode.TUNNEL_MODE_UNSPECIFIED, valueOf: TunnelMode.valueOf, enumValues: TunnelMode.values)
    ..pc<OutboundSpec>(2, _omitFieldNames ? '' : 'outbounds', $pb.PbFieldType.PM, subBuilder: OutboundSpec.create)
    ..pc<RoutingRule>(3, _omitFieldNames ? '' : 'routes', $pb.PbFieldType.PM, subBuilder: RoutingRule.create)
    ..aOM<DnsPolicy>(4, _omitFieldNames ? '' : 'dnsPolicy', subBuilder: DnsPolicy.create)
    ..aOM<BypassSettings>(5, _omitFieldNames ? '' : 'bypassSettings', subBuilder: BypassSettings.create)
    ..aOS(6, _omitFieldNames ? '' : 'sessionIdentity')
    ..aOM<AntiCensorship>(7, _omitFieldNames ? '' : 'antiCensorship', subBuilder: AntiCensorship.create)
    ..pPS(8, _omitFieldNames ? '' : 'engines')
    ..aOB(9, _omitFieldNames ? '' : 'networkControlAllowed')
    ..aOM<LocalProxy>(10, _omitFieldNames ? '' : 'localProxy', subBuilder: LocalProxy.create)
    ..pc<GroupSpec>(11, _omitFieldNames ? '' : 'groups', $pb.PbFieldType.PM, subBuilder: GroupSpec.create)
    ..aOM<RoutingOptions>(12, _omitFieldNames ? '' : 'routing', subBuilder: RoutingOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SessionPlan clone() => SessionPlan()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SessionPlan copyWith(void Function(SessionPlan) updates) => super.copyWith((message) => updates(message as SessionPlan)) as SessionPlan;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionPlan create() => SessionPlan._();
  SessionPlan createEmptyInstance() => create();
  static $pb.PbList<SessionPlan> createRepeated() => $pb.PbList<SessionPlan>();
  @$core.pragma('dart2js:noInline')
  static SessionPlan getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionPlan>(create);
  static SessionPlan? _defaultInstance;

  @$pb.TagNumber(1)
  TunnelMode get tunnelMode => $_getN(0);
  @$pb.TagNumber(1)
  set tunnelMode(TunnelMode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTunnelMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearTunnelMode() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<OutboundSpec> get outbounds => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<RoutingRule> get routes => $_getList(2);

  @$pb.TagNumber(4)
  DnsPolicy get dnsPolicy => $_getN(3);
  @$pb.TagNumber(4)
  set dnsPolicy(DnsPolicy v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasDnsPolicy() => $_has(3);
  @$pb.TagNumber(4)
  void clearDnsPolicy() => clearField(4);
  @$pb.TagNumber(4)
  DnsPolicy ensureDnsPolicy() => $_ensure(3);

  @$pb.TagNumber(5)
  BypassSettings get bypassSettings => $_getN(4);
  @$pb.TagNumber(5)
  set bypassSettings(BypassSettings v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasBypassSettings() => $_has(4);
  @$pb.TagNumber(5)
  void clearBypassSettings() => clearField(5);
  @$pb.TagNumber(5)
  BypassSettings ensureBypassSettings() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get sessionIdentity => $_getSZ(5);
  @$pb.TagNumber(6)
  set sessionIdentity($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSessionIdentity() => $_has(5);
  @$pb.TagNumber(6)
  void clearSessionIdentity() => clearField(6);

  /// Since 1.3. Switches that change how connections look on the wire.
  @$pb.TagNumber(7)
  AntiCensorship get antiCensorship => $_getN(6);
  @$pb.TagNumber(7)
  set antiCensorship(AntiCensorship v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasAntiCensorship() => $_has(6);
  @$pb.TagNumber(7)
  void clearAntiCensorship() => clearField(7);
  @$pb.TagNumber(7)
  AntiCensorship ensureAntiCensorship() => $_ensure(6);

  /// Since 1.3. Engine preference for this session, best first: "sing-box",
  /// "xray", "mihomo". The core runs the first one that carries the whole
  /// plan. Empty uses the core default; a single entry pins that engine.
  @$pb.TagNumber(8)
  $core.List<$core.String> get engines => $_getList(7);

  /// Since 1.3. Lets an engine controlled over a loopback port carry this
  /// session. Off by default: a port scan finds a loopback controller, so only
  /// an engine controlled through a unix socket or a named pipe is chosen.
  @$pb.TagNumber(9)
  $core.bool get networkControlAllowed => $_getBF(8);
  @$pb.TagNumber(9)
  set networkControlAllowed($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasNetworkControlAllowed() => $_has(8);
  @$pb.TagNumber(9)
  void clearNetworkControlAllowed() => clearField(9);

  /// Since 1.3. The loopback HTTP and SOCKS5 listener. The system proxy mode
  /// always opens it, without a login; in tun mode it exists only when enabled.
  @$pb.TagNumber(10)
  LocalProxy get localProxy => $_getN(9);
  @$pb.TagNumber(10)
  set localProxy(LocalProxy v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasLocalProxy() => $_has(9);
  @$pb.TagNumber(10)
  void clearLocalProxy() => clearField(10);
  @$pb.TagNumber(10)
  LocalProxy ensureLocalProxy() => $_ensure(9);

  /// Since 1.3. Groups the user picks a server in, or the core picks one for
  /// them. A rule, a group member and the routing target may name a group.
  @$pb.TagNumber(11)
  $core.List<GroupSpec> get groups => $_getList(10);

  /// Since 1.3. A routing preset applied after the routes above.
  @$pb.TagNumber(12)
  RoutingOptions get routing => $_getN(11);
  @$pb.TagNumber(12)
  set routing(RoutingOptions v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasRouting() => $_has(11);
  @$pb.TagNumber(12)
  void clearRouting() => clearField(12);
  @$pb.TagNumber(12)
  RoutingOptions ensureRouting() => $_ensure(11);
}

/// GroupSpec is one group of outbounds.
class GroupSpec extends $pb.GeneratedMessage {
  factory GroupSpec({
    $core.String? name,
    GroupType? type,
    $core.Iterable<$core.String>? members,
    $core.String? testUrl,
    $1.Duration? testInterval,
    $core.int? toleranceMs,
  }) {
    final $result = create();
    if (name != null) {
      $result.name = name;
    }
    if (type != null) {
      $result.type = type;
    }
    if (members != null) {
      $result.members.addAll(members);
    }
    if (testUrl != null) {
      $result.testUrl = testUrl;
    }
    if (testInterval != null) {
      $result.testInterval = testInterval;
    }
    if (toleranceMs != null) {
      $result.toleranceMs = toleranceMs;
    }
    return $result;
  }
  GroupSpec._() : super();
  factory GroupSpec.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupSpec', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..e<GroupType>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: GroupType.GROUP_TYPE_UNSPECIFIED, valueOf: GroupType.valueOf, enumValues: GroupType.values)
    ..pPS(3, _omitFieldNames ? '' : 'members')
    ..aOS(4, _omitFieldNames ? '' : 'testUrl')
    ..aOM<$1.Duration>(5, _omitFieldNames ? '' : 'testInterval', subBuilder: $1.Duration.create)
    ..a<$core.int>(6, _omitFieldNames ? '' : 'toleranceMs', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupSpec clone() => GroupSpec()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupSpec copyWith(void Function(GroupSpec) updates) => super.copyWith((message) => updates(message as GroupSpec)) as GroupSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupSpec create() => GroupSpec._();
  GroupSpec createEmptyInstance() => create();
  static $pb.PbList<GroupSpec> createRepeated() => $pb.PbList<GroupSpec>();
  @$core.pragma('dart2js:noInline')
  static GroupSpec getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupSpec>(create);
  static GroupSpec? _defaultInstance;

  /// Unique among the groups and different from every outbound id.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => clearField(1);

  @$pb.TagNumber(2)
  GroupType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(GroupType v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  /// Outbound ids or names of other groups, in display order.
  @$pb.TagNumber(3)
  $core.List<$core.String> get members => $_getList(2);

  /// How automatic groups measure their members; empty uses the core default.
  @$pb.TagNumber(4)
  $core.String get testUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set testUrl($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTestUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearTestUrl() => clearField(4);

  @$pb.TagNumber(5)
  $1.Duration get testInterval => $_getN(4);
  @$pb.TagNumber(5)
  set testInterval($1.Duration v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasTestInterval() => $_has(4);
  @$pb.TagNumber(5)
  void clearTestInterval() => clearField(5);
  @$pb.TagNumber(5)
  $1.Duration ensureTestInterval() => $_ensure(4);

  /// url-test switches only when another member is faster by this much.
  @$pb.TagNumber(6)
  $core.int get toleranceMs => $_getIZ(5);
  @$pb.TagNumber(6)
  set toleranceMs($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasToleranceMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearToleranceMs() => clearField(6);
}

/// RoutingOptions apply a preset after the routes of the plan; see
/// GetRoutingPresets for what each preset sends direct.
class RoutingOptions extends $pb.GeneratedMessage {
  factory RoutingOptions({
    $core.String? preset,
    $core.String? proxyTarget,
    $core.bool? blockAds,
  }) {
    final $result = create();
    if (preset != null) {
      $result.preset = preset;
    }
    if (proxyTarget != null) {
      $result.proxyTarget = proxyTarget;
    }
    if (blockAds != null) {
      $result.blockAds = blockAds;
    }
    return $result;
  }
  RoutingOptions._() : super();
  factory RoutingOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RoutingOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'preset')
    ..aOS(2, _omitFieldNames ? '' : 'proxyTarget')
    ..aOB(3, _omitFieldNames ? '' : 'blockAds')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RoutingOptions clone() => RoutingOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RoutingOptions copyWith(void Function(RoutingOptions) updates) => super.copyWith((message) => updates(message as RoutingOptions)) as RoutingOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoutingOptions create() => RoutingOptions._();
  RoutingOptions createEmptyInstance() => create();
  static $pb.PbList<RoutingOptions> createRepeated() => $pb.PbList<RoutingOptions>();
  @$core.pragma('dart2js:noInline')
  static RoutingOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingOptions>(create);
  static RoutingOptions? _defaultInstance;

  /// A preset id from GetRoutingPresets; empty applies none.
  @$pb.TagNumber(1)
  $core.String get preset => $_getSZ(0);
  @$pb.TagNumber(1)
  set preset($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => clearField(1);

  /// The outbound or group everything the routes and the preset leave goes to.
  @$pb.TagNumber(2)
  $core.String get proxyTarget => $_getSZ(1);
  @$pb.TagNumber(2)
  set proxyTarget($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasProxyTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearProxyTarget() => clearField(2);

  /// Rejects advertising and tracking domains before anything else.
  @$pb.TagNumber(3)
  $core.bool get blockAds => $_getBF(2);
  @$pb.TagNumber(3)
  set blockAds($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBlockAds() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlockAds() => clearField(3);
}

/// LocalProxy is a listener other applications on the machine can use. Any of
/// them can reach it, send traffic through the tunnel and learn the server
/// address, so it is closed unless asked for, and a login is recommended.
class LocalProxy extends $pb.GeneratedMessage {
  factory LocalProxy({
    $core.bool? enabled,
    $core.String? username,
    $core.String? password,
  }) {
    final $result = create();
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (username != null) {
      $result.username = username;
    }
    if (password != null) {
      $result.password = password;
    }
    return $result;
  }
  LocalProxy._() : super();
  factory LocalProxy.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LocalProxy.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocalProxy', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LocalProxy clone() => LocalProxy()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LocalProxy copyWith(void Function(LocalProxy) updates) => super.copyWith((message) => updates(message as LocalProxy)) as LocalProxy;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LocalProxy create() => LocalProxy._();
  LocalProxy createEmptyInstance() => create();
  static $pb.PbList<LocalProxy> createRepeated() => $pb.PbList<LocalProxy>();
  @$core.pragma('dart2js:noInline')
  static LocalProxy getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocalProxy>(create);
  static LocalProxy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => clearField(3);
}

/// AntiCensorship holds the per-session defences against DPI.
class AntiCensorship extends $pb.GeneratedMessage {
  factory AntiCensorship({
    $core.bool? tlsFragment,
    $core.String? fragmentPackets,
    $core.String? fragmentLength,
    $core.String? fragmentInterval,
  }) {
    final $result = create();
    if (tlsFragment != null) {
      $result.tlsFragment = tlsFragment;
    }
    if (fragmentPackets != null) {
      $result.fragmentPackets = fragmentPackets;
    }
    if (fragmentLength != null) {
      $result.fragmentLength = fragmentLength;
    }
    if (fragmentInterval != null) {
      $result.fragmentInterval = fragmentInterval;
    }
    return $result;
  }
  AntiCensorship._() : super();
  factory AntiCensorship.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory AntiCensorship.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AntiCensorship', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'tlsFragment')
    ..aOS(2, _omitFieldNames ? '' : 'fragmentPackets')
    ..aOS(3, _omitFieldNames ? '' : 'fragmentLength')
    ..aOS(4, _omitFieldNames ? '' : 'fragmentInterval')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  AntiCensorship clone() => AntiCensorship()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  AntiCensorship copyWith(void Function(AntiCensorship) updates) => super.copyWith((message) => updates(message as AntiCensorship)) as AntiCensorship;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AntiCensorship create() => AntiCensorship._();
  AntiCensorship createEmptyInstance() => create();
  static $pb.PbList<AntiCensorship> createRepeated() => $pb.PbList<AntiCensorship>();
  @$core.pragma('dart2js:noInline')
  static AntiCensorship getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AntiCensorship>(create);
  static AntiCensorship? _defaultInstance;

  /// Splits the TLS ClientHello of proxy connections into several TCP segments.
  @$pb.TagNumber(1)
  $core.bool get tlsFragment => $_getBF(0);
  @$pb.TagNumber(1)
  set tlsFragment($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTlsFragment() => $_has(0);
  @$pb.TagNumber(1)
  void clearTlsFragment() => clearField(1);

  /// Xray grammar: "tlshello" or a segment range such as "1-3". Empty means "tlshello".
  @$pb.TagNumber(2)
  $core.String get fragmentPackets => $_getSZ(1);
  @$pb.TagNumber(2)
  set fragmentPackets($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFragmentPackets() => $_has(1);
  @$pb.TagNumber(2)
  void clearFragmentPackets() => clearField(2);

  /// Segment length range in bytes, for example "100-200".
  @$pb.TagNumber(3)
  $core.String get fragmentLength => $_getSZ(2);
  @$pb.TagNumber(3)
  set fragmentLength($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasFragmentLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearFragmentLength() => clearField(3);

  /// Pause range between segments in milliseconds, for example "10-20".
  @$pb.TagNumber(4)
  $core.String get fragmentInterval => $_getSZ(3);
  @$pb.TagNumber(4)
  set fragmentInterval($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFragmentInterval() => $_has(3);
  @$pb.TagNumber(4)
  void clearFragmentInterval() => clearField(4);
}

class OutboundSpec extends $pb.GeneratedMessage {
  factory OutboundSpec({
    $core.String? id,
    $core.String? displayName,
    $core.String? protocol,
    $core.String? transport,
    $core.String? security,
    Endpoint? endpoint,
    CredentialsRef? credentials,
    BypassStrategy? bypass,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (displayName != null) {
      $result.displayName = displayName;
    }
    if (protocol != null) {
      $result.protocol = protocol;
    }
    if (transport != null) {
      $result.transport = transport;
    }
    if (security != null) {
      $result.security = security;
    }
    if (endpoint != null) {
      $result.endpoint = endpoint;
    }
    if (credentials != null) {
      $result.credentials = credentials;
    }
    if (bypass != null) {
      $result.bypass = bypass;
    }
    return $result;
  }
  OutboundSpec._() : super();
  factory OutboundSpec.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory OutboundSpec.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundSpec', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'protocol')
    ..aOS(4, _omitFieldNames ? '' : 'transport')
    ..aOS(5, _omitFieldNames ? '' : 'security')
    ..aOM<Endpoint>(6, _omitFieldNames ? '' : 'endpoint', subBuilder: Endpoint.create)
    ..aOM<CredentialsRef>(7, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.create)
    ..aOM<BypassStrategy>(8, _omitFieldNames ? '' : 'bypass', subBuilder: BypassStrategy.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  OutboundSpec clone() => OutboundSpec()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  OutboundSpec copyWith(void Function(OutboundSpec) updates) => super.copyWith((message) => updates(message as OutboundSpec)) as OutboundSpec;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static OutboundSpec create() => OutboundSpec._();
  OutboundSpec createEmptyInstance() => create();
  static $pb.PbList<OutboundSpec> createRepeated() => $pb.PbList<OutboundSpec>();
  @$core.pragma('dart2js:noInline')
  static OutboundSpec getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutboundSpec>(create);
  static OutboundSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get protocol => $_getSZ(2);
  @$pb.TagNumber(3)
  set protocol($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasProtocol() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocol() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get transport => $_getSZ(3);
  @$pb.TagNumber(4)
  set transport($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTransport() => $_has(3);
  @$pb.TagNumber(4)
  void clearTransport() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get security => $_getSZ(4);
  @$pb.TagNumber(5)
  set security($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSecurity() => $_has(4);
  @$pb.TagNumber(5)
  void clearSecurity() => clearField(5);

  @$pb.TagNumber(6)
  Endpoint get endpoint => $_getN(5);
  @$pb.TagNumber(6)
  set endpoint(Endpoint v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasEndpoint() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndpoint() => clearField(6);
  @$pb.TagNumber(6)
  Endpoint ensureEndpoint() => $_ensure(5);

  @$pb.TagNumber(7)
  CredentialsRef get credentials => $_getN(6);
  @$pb.TagNumber(7)
  set credentials(CredentialsRef v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasCredentials() => $_has(6);
  @$pb.TagNumber(7)
  void clearCredentials() => clearField(7);
  @$pb.TagNumber(7)
  CredentialsRef ensureCredentials() => $_ensure(6);

  /// Since 1.3. For protocol "bypass": sites reached directly with the
  /// handshake reshaped by zapret against DPI; no endpoint, no credentials.
  @$pb.TagNumber(8)
  BypassStrategy get bypass => $_getN(7);
  @$pb.TagNumber(8)
  set bypass(BypassStrategy v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasBypass() => $_has(7);
  @$pb.TagNumber(8)
  void clearBypass() => clearField(8);
  @$pb.TagNumber(8)
  BypassStrategy ensureBypass() => $_ensure(7);
}

class Endpoint extends $pb.GeneratedMessage {
  factory Endpoint({
    $core.String? host,
    $core.int? port,
  }) {
    final $result = create();
    if (host != null) {
      $result.host = host;
    }
    if (port != null) {
      $result.port = port;
    }
    return $result;
  }
  Endpoint._() : super();
  factory Endpoint.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Endpoint.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Endpoint', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'port', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Endpoint clone() => Endpoint()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Endpoint copyWith(void Function(Endpoint) updates) => super.copyWith((message) => updates(message as Endpoint)) as Endpoint;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Endpoint create() => Endpoint._();
  Endpoint createEmptyInstance() => create();
  static $pb.PbList<Endpoint> createRepeated() => $pb.PbList<Endpoint>();
  @$core.pragma('dart2js:noInline')
  static Endpoint getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Endpoint>(create);
  static Endpoint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => clearField(2);
}

class CredentialsRef extends $pb.GeneratedMessage {
  factory CredentialsRef({
    $core.String? reference,
  }) {
    final $result = create();
    if (reference != null) {
      $result.reference = reference;
    }
    return $result;
  }
  CredentialsRef._() : super();
  factory CredentialsRef.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CredentialsRef.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CredentialsRef', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'reference')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CredentialsRef clone() => CredentialsRef()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CredentialsRef copyWith(void Function(CredentialsRef) updates) => super.copyWith((message) => updates(message as CredentialsRef)) as CredentialsRef;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CredentialsRef create() => CredentialsRef._();
  CredentialsRef createEmptyInstance() => create();
  static $pb.PbList<CredentialsRef> createRepeated() => $pb.PbList<CredentialsRef>();
  @$core.pragma('dart2js:noInline')
  static CredentialsRef getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CredentialsRef>(create);
  static CredentialsRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reference => $_getSZ(0);
  @$pb.TagNumber(1)
  set reference($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => clearField(1);
}

class RoutingRule extends $pb.GeneratedMessage {
  factory RoutingRule({
    $core.String? destination,
    $core.String? outboundId,
  }) {
    final $result = create();
    if (destination != null) {
      $result.destination = destination;
    }
    if (outboundId != null) {
      $result.outboundId = outboundId;
    }
    return $result;
  }
  RoutingRule._() : super();
  factory RoutingRule.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RoutingRule.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingRule', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'destination')
    ..aOS(2, _omitFieldNames ? '' : 'outboundId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RoutingRule clone() => RoutingRule()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RoutingRule copyWith(void Function(RoutingRule) updates) => super.copyWith((message) => updates(message as RoutingRule)) as RoutingRule;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoutingRule create() => RoutingRule._();
  RoutingRule createEmptyInstance() => create();
  static $pb.PbList<RoutingRule> createRepeated() => $pb.PbList<RoutingRule>();
  @$core.pragma('dart2js:noInline')
  static RoutingRule getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingRule>(create);
  static RoutingRule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get destination => $_getSZ(0);
  @$pb.TagNumber(1)
  set destination($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearDestination() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get outboundId => $_getSZ(1);
  @$pb.TagNumber(2)
  set outboundId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOutboundId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutboundId() => clearField(2);
}

class DnsPolicy extends $pb.GeneratedMessage {
  factory DnsPolicy({
    $core.Iterable<$core.String>? servers,
    $core.bool? blockPrivate,
  }) {
    final $result = create();
    if (servers != null) {
      $result.servers.addAll(servers);
    }
    if (blockPrivate != null) {
      $result.blockPrivate = blockPrivate;
    }
    return $result;
  }
  DnsPolicy._() : super();
  factory DnsPolicy.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DnsPolicy.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DnsPolicy', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'servers')
    ..aOB(2, _omitFieldNames ? '' : 'blockPrivate')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DnsPolicy clone() => DnsPolicy()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DnsPolicy copyWith(void Function(DnsPolicy) updates) => super.copyWith((message) => updates(message as DnsPolicy)) as DnsPolicy;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DnsPolicy create() => DnsPolicy._();
  DnsPolicy createEmptyInstance() => create();
  static $pb.PbList<DnsPolicy> createRepeated() => $pb.PbList<DnsPolicy>();
  @$core.pragma('dart2js:noInline')
  static DnsPolicy getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DnsPolicy>(create);
  static DnsPolicy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get servers => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get blockPrivate => $_getBF(1);
  @$pb.TagNumber(2)
  set blockPrivate($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBlockPrivate() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlockPrivate() => clearField(2);
}

class BypassSettings extends $pb.GeneratedMessage {
  factory BypassSettings({
    $core.bool? enabled,
    $core.Iterable<$core.String>? rules,
  }) {
    final $result = create();
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (rules != null) {
      $result.rules.addAll(rules);
    }
    return $result;
  }
  BypassSettings._() : super();
  factory BypassSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BypassSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..pPS(2, _omitFieldNames ? '' : 'rules')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BypassSettings clone() => BypassSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BypassSettings copyWith(void Function(BypassSettings) updates) => super.copyWith((message) => updates(message as BypassSettings)) as BypassSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BypassSettings create() => BypassSettings._();
  BypassSettings createEmptyInstance() => create();
  static $pb.PbList<BypassSettings> createRepeated() => $pb.PbList<BypassSettings>();
  @$core.pragma('dart2js:noInline')
  static BypassSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BypassSettings>(create);
  static BypassSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get rules => $_getList(1);
}

class SessionStatus extends $pb.GeneratedMessage {
  factory SessionStatus({
    ConnectionState? connection,
    ApiVersion? negotiatedVersion,
  }) {
    final $result = create();
    if (connection != null) {
      $result.connection = connection;
    }
    if (negotiatedVersion != null) {
      $result.negotiatedVersion = negotiatedVersion;
    }
    return $result;
  }
  SessionStatus._() : super();
  factory SessionStatus.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SessionStatus.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SessionStatus', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ConnectionState>(1, _omitFieldNames ? '' : 'connection', subBuilder: ConnectionState.create)
    ..aOM<ApiVersion>(2, _omitFieldNames ? '' : 'negotiatedVersion', subBuilder: ApiVersion.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SessionStatus clone() => SessionStatus()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SessionStatus copyWith(void Function(SessionStatus) updates) => super.copyWith((message) => updates(message as SessionStatus)) as SessionStatus;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SessionStatus create() => SessionStatus._();
  SessionStatus createEmptyInstance() => create();
  static $pb.PbList<SessionStatus> createRepeated() => $pb.PbList<SessionStatus>();
  @$core.pragma('dart2js:noInline')
  static SessionStatus getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionStatus>(create);
  static SessionStatus? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionState get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(ConnectionState v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => clearField(1);
  @$pb.TagNumber(1)
  ConnectionState ensureConnection() => $_ensure(0);

  @$pb.TagNumber(2)
  ApiVersion get negotiatedVersion => $_getN(1);
  @$pb.TagNumber(2)
  set negotiatedVersion(ApiVersion v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasNegotiatedVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearNegotiatedVersion() => clearField(2);
  @$pb.TagNumber(2)
  ApiVersion ensureNegotiatedVersion() => $_ensure(1);
}

class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  GetStatsRequest._() : super();
  factory GetStatsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStatsRequest clone() => GetStatsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) => super.copyWith((message) => updates(message as GetStatsRequest)) as GetStatsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsRequest create() => GetStatsRequest._();
  GetStatsRequest createEmptyInstance() => create();
  static $pb.PbList<GetStatsRequest> createRepeated() => $pb.PbList<GetStatsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(create);
  static GetStatsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);
}

class GetStatsResponse extends $pb.GeneratedMessage {
  factory GetStatsResponse({
    StatsTick? stats,
    SoraError? error,
  }) {
    final $result = create();
    if (stats != null) {
      $result.stats = stats;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetStatsResponse._() : super();
  factory GetStatsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetStatsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<StatsTick>(1, _omitFieldNames ? '' : 'stats', subBuilder: StatsTick.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetStatsResponse clone() => GetStatsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetStatsResponse copyWith(void Function(GetStatsResponse) updates) => super.copyWith((message) => updates(message as GetStatsResponse)) as GetStatsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetStatsResponse create() => GetStatsResponse._();
  GetStatsResponse createEmptyInstance() => create();
  static $pb.PbList<GetStatsResponse> createRepeated() => $pb.PbList<GetStatsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetStatsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsResponse>(create);
  static GetStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  StatsTick get stats => $_getN(0);
  @$pb.TagNumber(1)
  set stats(StatsTick v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasStats() => $_has(0);
  @$pb.TagNumber(1)
  void clearStats() => clearField(1);
  @$pb.TagNumber(1)
  StatsTick ensureStats() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class ConnectionState extends $pb.GeneratedMessage {
  factory ConnectionState({
    ConnectionStateValue? value,
    $core.String? sessionId,
    SoraErrorCode? reason,
    $2.Timestamp? changedAt,
    $1.Duration? retryAfter,
  }) {
    final $result = create();
    if (value != null) {
      $result.value = value;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    if (changedAt != null) {
      $result.changedAt = changedAt;
    }
    if (retryAfter != null) {
      $result.retryAfter = retryAfter;
    }
    return $result;
  }
  ConnectionState._() : super();
  factory ConnectionState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ConnectionState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectionState', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<ConnectionStateValue>(1, _omitFieldNames ? '' : 'value', $pb.PbFieldType.OE, defaultOrMaker: ConnectionStateValue.CONNECTION_STATE_VALUE_UNSPECIFIED, valueOf: ConnectionStateValue.valueOf, enumValues: ConnectionStateValue.values)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..e<SoraErrorCode>(3, _omitFieldNames ? '' : 'reason', $pb.PbFieldType.OE, defaultOrMaker: SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED, valueOf: SoraErrorCode.valueOf, enumValues: SoraErrorCode.values)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'changedAt', subBuilder: $2.Timestamp.create)
    ..aOM<$1.Duration>(5, _omitFieldNames ? '' : 'retryAfter', subBuilder: $1.Duration.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ConnectionState clone() => ConnectionState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ConnectionState copyWith(void Function(ConnectionState) updates) => super.copyWith((message) => updates(message as ConnectionState)) as ConnectionState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ConnectionState create() => ConnectionState._();
  ConnectionState createEmptyInstance() => create();
  static $pb.PbList<ConnectionState> createRepeated() => $pb.PbList<ConnectionState>();
  @$core.pragma('dart2js:noInline')
  static ConnectionState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectionState>(create);
  static ConnectionState? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionStateValue get value => $_getN(0);
  @$pb.TagNumber(1)
  set value(ConnectionStateValue v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);

  @$pb.TagNumber(3)
  SoraErrorCode get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason(SoraErrorCode v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get changedAt => $_getN(3);
  @$pb.TagNumber(4)
  set changedAt($2.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasChangedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearChangedAt() => clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureChangedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.Duration get retryAfter => $_getN(4);
  @$pb.TagNumber(5)
  set retryAfter($1.Duration v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRetryAfter() => $_has(4);
  @$pb.TagNumber(5)
  void clearRetryAfter() => clearField(5);
  @$pb.TagNumber(5)
  $1.Duration ensureRetryAfter() => $_ensure(4);
}

enum CoreEvent_Payload {
  stateChanged, 
  statsTick, 
  bypassStrategyChanged, 
  probeResult, 
  logBatch, 
  error, 
  killSwitchChanged, 
  notSet
}

class CoreEvent extends $pb.GeneratedMessage {
  factory CoreEvent({
    $fixnum.Int64? sequence,
    $core.String? sessionId,
    $2.Timestamp? emittedAt,
    StateChanged? stateChanged,
    StatsTick? statsTick,
    BypassStrategyChanged? bypassStrategyChanged,
    ProbeResult? probeResult,
    LogBatch? logBatch,
    SoraError? error,
    KillSwitchChanged? killSwitchChanged,
  }) {
    final $result = create();
    if (sequence != null) {
      $result.sequence = sequence;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (emittedAt != null) {
      $result.emittedAt = emittedAt;
    }
    if (stateChanged != null) {
      $result.stateChanged = stateChanged;
    }
    if (statsTick != null) {
      $result.statsTick = statsTick;
    }
    if (bypassStrategyChanged != null) {
      $result.bypassStrategyChanged = bypassStrategyChanged;
    }
    if (probeResult != null) {
      $result.probeResult = probeResult;
    }
    if (logBatch != null) {
      $result.logBatch = logBatch;
    }
    if (error != null) {
      $result.error = error;
    }
    if (killSwitchChanged != null) {
      $result.killSwitchChanged = killSwitchChanged;
    }
    return $result;
  }
  CoreEvent._() : super();
  factory CoreEvent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CoreEvent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, CoreEvent_Payload> _CoreEvent_PayloadByTag = {
    4 : CoreEvent_Payload.stateChanged,
    5 : CoreEvent_Payload.statsTick,
    6 : CoreEvent_Payload.bypassStrategyChanged,
    7 : CoreEvent_Payload.probeResult,
    8 : CoreEvent_Payload.logBatch,
    9 : CoreEvent_Payload.error,
    10 : CoreEvent_Payload.killSwitchChanged,
    0 : CoreEvent_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CoreEvent', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..oo(0, [4, 5, 6, 7, 8, 9, 10])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'emittedAt', subBuilder: $2.Timestamp.create)
    ..aOM<StateChanged>(4, _omitFieldNames ? '' : 'stateChanged', subBuilder: StateChanged.create)
    ..aOM<StatsTick>(5, _omitFieldNames ? '' : 'statsTick', subBuilder: StatsTick.create)
    ..aOM<BypassStrategyChanged>(6, _omitFieldNames ? '' : 'bypassStrategyChanged', subBuilder: BypassStrategyChanged.create)
    ..aOM<ProbeResult>(7, _omitFieldNames ? '' : 'probeResult', subBuilder: ProbeResult.create)
    ..aOM<LogBatch>(8, _omitFieldNames ? '' : 'logBatch', subBuilder: LogBatch.create)
    ..aOM<SoraError>(9, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..aOM<KillSwitchChanged>(10, _omitFieldNames ? '' : 'killSwitchChanged', subBuilder: KillSwitchChanged.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CoreEvent clone() => CoreEvent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CoreEvent copyWith(void Function(CoreEvent) updates) => super.copyWith((message) => updates(message as CoreEvent)) as CoreEvent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CoreEvent create() => CoreEvent._();
  CoreEvent createEmptyInstance() => create();
  static $pb.PbList<CoreEvent> createRepeated() => $pb.PbList<CoreEvent>();
  @$core.pragma('dart2js:noInline')
  static CoreEvent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoreEvent>(create);
  static CoreEvent? _defaultInstance;

  CoreEvent_Payload whichPayload() => _CoreEvent_PayloadByTag[$_whichOneof(0)]!;
  void clearPayload() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => clearField(2);

  @$pb.TagNumber(3)
  $2.Timestamp get emittedAt => $_getN(2);
  @$pb.TagNumber(3)
  set emittedAt($2.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmittedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmittedAt() => clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureEmittedAt() => $_ensure(2);

  @$pb.TagNumber(4)
  StateChanged get stateChanged => $_getN(3);
  @$pb.TagNumber(4)
  set stateChanged(StateChanged v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasStateChanged() => $_has(3);
  @$pb.TagNumber(4)
  void clearStateChanged() => clearField(4);
  @$pb.TagNumber(4)
  StateChanged ensureStateChanged() => $_ensure(3);

  @$pb.TagNumber(5)
  StatsTick get statsTick => $_getN(4);
  @$pb.TagNumber(5)
  set statsTick(StatsTick v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasStatsTick() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatsTick() => clearField(5);
  @$pb.TagNumber(5)
  StatsTick ensureStatsTick() => $_ensure(4);

  @$pb.TagNumber(6)
  BypassStrategyChanged get bypassStrategyChanged => $_getN(5);
  @$pb.TagNumber(6)
  set bypassStrategyChanged(BypassStrategyChanged v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasBypassStrategyChanged() => $_has(5);
  @$pb.TagNumber(6)
  void clearBypassStrategyChanged() => clearField(6);
  @$pb.TagNumber(6)
  BypassStrategyChanged ensureBypassStrategyChanged() => $_ensure(5);

  @$pb.TagNumber(7)
  ProbeResult get probeResult => $_getN(6);
  @$pb.TagNumber(7)
  set probeResult(ProbeResult v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasProbeResult() => $_has(6);
  @$pb.TagNumber(7)
  void clearProbeResult() => clearField(7);
  @$pb.TagNumber(7)
  ProbeResult ensureProbeResult() => $_ensure(6);

  @$pb.TagNumber(8)
  LogBatch get logBatch => $_getN(7);
  @$pb.TagNumber(8)
  set logBatch(LogBatch v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasLogBatch() => $_has(7);
  @$pb.TagNumber(8)
  void clearLogBatch() => clearField(8);
  @$pb.TagNumber(8)
  LogBatch ensureLogBatch() => $_ensure(7);

  @$pb.TagNumber(9)
  SoraError get error => $_getN(8);
  @$pb.TagNumber(9)
  set error(SoraError v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasError() => $_has(8);
  @$pb.TagNumber(9)
  void clearError() => clearField(9);
  @$pb.TagNumber(9)
  SoraError ensureError() => $_ensure(8);

  @$pb.TagNumber(10)
  KillSwitchChanged get killSwitchChanged => $_getN(9);
  @$pb.TagNumber(10)
  set killSwitchChanged(KillSwitchChanged v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasKillSwitchChanged() => $_has(9);
  @$pb.TagNumber(10)
  void clearKillSwitchChanged() => clearField(10);
  @$pb.TagNumber(10)
  KillSwitchChanged ensureKillSwitchChanged() => $_ensure(9);
}

class StateChanged extends $pb.GeneratedMessage {
  factory StateChanged({
    ConnectionState? state,
  }) {
    final $result = create();
    if (state != null) {
      $result.state = state;
    }
    return $result;
  }
  StateChanged._() : super();
  factory StateChanged.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StateChanged.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StateChanged', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ConnectionState>(1, _omitFieldNames ? '' : 'state', subBuilder: ConnectionState.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StateChanged clone() => StateChanged()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StateChanged copyWith(void Function(StateChanged) updates) => super.copyWith((message) => updates(message as StateChanged)) as StateChanged;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StateChanged create() => StateChanged._();
  StateChanged createEmptyInstance() => create();
  static $pb.PbList<StateChanged> createRepeated() => $pb.PbList<StateChanged>();
  @$core.pragma('dart2js:noInline')
  static StateChanged getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StateChanged>(create);
  static StateChanged? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ConnectionState v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => clearField(1);
  @$pb.TagNumber(1)
  ConnectionState ensureState() => $_ensure(0);
}

class StatsTick extends $pb.GeneratedMessage {
  factory StatsTick({
    $fixnum.Int64? bytesUp,
    $fixnum.Int64? bytesDown,
    $fixnum.Int64? activeConnections,
  }) {
    final $result = create();
    if (bytesUp != null) {
      $result.bytesUp = bytesUp;
    }
    if (bytesDown != null) {
      $result.bytesDown = bytesDown;
    }
    if (activeConnections != null) {
      $result.activeConnections = activeConnections;
    }
    return $result;
  }
  StatsTick._() : super();
  factory StatsTick.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory StatsTick.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatsTick', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'bytesUp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytesDown', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'activeConnections', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  StatsTick clone() => StatsTick()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  StatsTick copyWith(void Function(StatsTick) updates) => super.copyWith((message) => updates(message as StatsTick)) as StatsTick;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StatsTick create() => StatsTick._();
  StatsTick createEmptyInstance() => create();
  static $pb.PbList<StatsTick> createRepeated() => $pb.PbList<StatsTick>();
  @$core.pragma('dart2js:noInline')
  static StatsTick getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatsTick>(create);
  static StatsTick? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesUp => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesUp($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBytesUp() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesUp() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesDown => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesDown($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBytesDown() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesDown() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get activeConnections => $_getI64(2);
  @$pb.TagNumber(3)
  set activeConnections($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasActiveConnections() => $_has(2);
  @$pb.TagNumber(3)
  void clearActiveConnections() => clearField(3);
}

class BypassStrategyChanged extends $pb.GeneratedMessage {
  factory BypassStrategyChanged({
    $core.String? strategy,
  }) {
    final $result = create();
    if (strategy != null) {
      $result.strategy = strategy;
    }
    return $result;
  }
  BypassStrategyChanged._() : super();
  factory BypassStrategyChanged.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BypassStrategyChanged.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassStrategyChanged', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'strategy')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BypassStrategyChanged clone() => BypassStrategyChanged()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BypassStrategyChanged copyWith(void Function(BypassStrategyChanged) updates) => super.copyWith((message) => updates(message as BypassStrategyChanged)) as BypassStrategyChanged;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BypassStrategyChanged create() => BypassStrategyChanged._();
  BypassStrategyChanged createEmptyInstance() => create();
  static $pb.PbList<BypassStrategyChanged> createRepeated() => $pb.PbList<BypassStrategyChanged>();
  @$core.pragma('dart2js:noInline')
  static BypassStrategyChanged getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BypassStrategyChanged>(create);
  static BypassStrategyChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get strategy => $_getSZ(0);
  @$pb.TagNumber(1)
  set strategy($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasStrategy() => $_has(0);
  @$pb.TagNumber(1)
  void clearStrategy() => clearField(1);
}

class ProbeResult extends $pb.GeneratedMessage {
  factory ProbeResult({
    $core.String? serverId,
    $core.bool? reachable,
    $core.int? latencyMs,
    SoraError? error,
    $core.String? method,
    $core.String? engine,
  }) {
    final $result = create();
    if (serverId != null) {
      $result.serverId = serverId;
    }
    if (reachable != null) {
      $result.reachable = reachable;
    }
    if (latencyMs != null) {
      $result.latencyMs = latencyMs;
    }
    if (error != null) {
      $result.error = error;
    }
    if (method != null) {
      $result.method = method;
    }
    if (engine != null) {
      $result.engine = engine;
    }
    return $result;
  }
  ProbeResult._() : super();
  factory ProbeResult.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProbeResult.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOB(2, _omitFieldNames ? '' : 'reachable')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'latencyMs', $pb.PbFieldType.OU3)
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..aOS(5, _omitFieldNames ? '' : 'method')
    ..aOS(6, _omitFieldNames ? '' : 'engine')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProbeResult clone() => ProbeResult()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProbeResult copyWith(void Function(ProbeResult) updates) => super.copyWith((message) => updates(message as ProbeResult)) as ProbeResult;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProbeResult create() => ProbeResult._();
  ProbeResult createEmptyInstance() => create();
  static $pb.PbList<ProbeResult> createRepeated() => $pb.PbList<ProbeResult>();
  @$core.pragma('dart2js:noInline')
  static ProbeResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeResult>(create);
  static ProbeResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get reachable => $_getBF(1);
  @$pb.TagNumber(2)
  set reachable($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReachable() => $_has(1);
  @$pb.TagNumber(2)
  void clearReachable() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get latencyMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set latencyMs($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasLatencyMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatencyMs() => clearField(3);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);

  /// Since 1.3. How the value was measured: "engine" is a real request through
  /// the server, "connect" only a TCP connection to it.
  @$pb.TagNumber(5)
  $core.String get method => $_getSZ(4);
  @$pb.TagNumber(5)
  set method($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMethod() => $_has(4);
  @$pb.TagNumber(5)
  void clearMethod() => clearField(5);

  /// Since 1.3. The engine that carried an "engine" measurement.
  @$pb.TagNumber(6)
  $core.String get engine => $_getSZ(5);
  @$pb.TagNumber(6)
  set engine($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasEngine() => $_has(5);
  @$pb.TagNumber(6)
  void clearEngine() => clearField(6);
}

class LogBatch extends $pb.GeneratedMessage {
  factory LogBatch({
    $core.Iterable<$core.String>? lines,
  }) {
    final $result = create();
    if (lines != null) {
      $result.lines.addAll(lines);
    }
    return $result;
  }
  LogBatch._() : super();
  factory LogBatch.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogBatch.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogBatch', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'lines')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogBatch clone() => LogBatch()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogBatch copyWith(void Function(LogBatch) updates) => super.copyWith((message) => updates(message as LogBatch)) as LogBatch;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogBatch create() => LogBatch._();
  LogBatch createEmptyInstance() => create();
  static $pb.PbList<LogBatch> createRepeated() => $pb.PbList<LogBatch>();
  @$core.pragma('dart2js:noInline')
  static LogBatch getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogBatch>(create);
  static LogBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get lines => $_getList(0);
}

/// KillSwitchChanged reports the state of the kill switch of a session. Enforced
/// is separate from enabled on purpose: on a platform that cannot block traffic at
/// the packet filter the core still records the request, and the interface has to
/// be able to show a switch that is on but not blocking rather than a switch that
/// protects the user when it does not.
class KillSwitchChanged extends $pb.GeneratedMessage {
  factory KillSwitchChanged({
    $core.bool? enabled,
    $core.bool? enforced,
  }) {
    final $result = create();
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (enforced != null) {
      $result.enforced = enforced;
    }
    return $result;
  }
  KillSwitchChanged._() : super();
  factory KillSwitchChanged.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory KillSwitchChanged.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'KillSwitchChanged', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'enforced')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  KillSwitchChanged clone() => KillSwitchChanged()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  KillSwitchChanged copyWith(void Function(KillSwitchChanged) updates) => super.copyWith((message) => updates(message as KillSwitchChanged)) as KillSwitchChanged;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static KillSwitchChanged create() => KillSwitchChanged._();
  KillSwitchChanged createEmptyInstance() => create();
  static $pb.PbList<KillSwitchChanged> createRepeated() => $pb.PbList<KillSwitchChanged>();
  @$core.pragma('dart2js:noInline')
  static KillSwitchChanged getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KillSwitchChanged>(create);
  static KillSwitchChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enforced => $_getBF(1);
  @$pb.TagNumber(2)
  set enforced($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEnforced() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnforced() => clearField(2);
}

class ParseImportRequest extends $pb.GeneratedMessage {
  factory ParseImportRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.List<$core.int>? payload,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (payload != null) {
      $result.payload = payload;
    }
    return $result;
  }
  ParseImportRequest._() : super();
  factory ParseImportRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseImportRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseImportRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseImportRequest clone() => ParseImportRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseImportRequest copyWith(void Function(ParseImportRequest) updates) => super.copyWith((message) => updates(message as ParseImportRequest)) as ParseImportRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseImportRequest create() => ParseImportRequest._();
  ParseImportRequest createEmptyInstance() => create();
  static $pb.PbList<ParseImportRequest> createRepeated() => $pb.PbList<ParseImportRequest>();
  @$core.pragma('dart2js:noInline')
  static ParseImportRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseImportRequest>(create);
  static ParseImportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get payload => $_getN(2);
  @$pb.TagNumber(3)
  set payload($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => clearField(3);
}

class ParseImportResponse extends $pb.GeneratedMessage {
  factory ParseImportResponse({
    SessionPlan? sessionPlan,
    SoraError? error,
  }) {
    final $result = create();
    if (sessionPlan != null) {
      $result.sessionPlan = sessionPlan;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ParseImportResponse._() : super();
  factory ParseImportResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ParseImportResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseImportResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SessionPlan>(1, _omitFieldNames ? '' : 'sessionPlan', subBuilder: SessionPlan.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ParseImportResponse clone() => ParseImportResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ParseImportResponse copyWith(void Function(ParseImportResponse) updates) => super.copyWith((message) => updates(message as ParseImportResponse)) as ParseImportResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ParseImportResponse create() => ParseImportResponse._();
  ParseImportResponse createEmptyInstance() => create();
  static $pb.PbList<ParseImportResponse> createRepeated() => $pb.PbList<ParseImportResponse>();
  @$core.pragma('dart2js:noInline')
  static ParseImportResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseImportResponse>(create);
  static ParseImportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionPlan get sessionPlan => $_getN(0);
  @$pb.TagNumber(1)
  set sessionPlan(SessionPlan v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSessionPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionPlan() => clearField(1);
  @$pb.TagNumber(1)
  SessionPlan ensureSessionPlan() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class FetchSubscriptionRequest extends $pb.GeneratedMessage {
  factory FetchSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? reference,
    $core.String? userAgent,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (reference != null) {
      $result.reference = reference;
    }
    if (userAgent != null) {
      $result.userAgent = userAgent;
    }
    return $result;
  }
  FetchSubscriptionRequest._() : super();
  factory FetchSubscriptionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FetchSubscriptionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'reference')
    ..aOS(4, _omitFieldNames ? '' : 'userAgent')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FetchSubscriptionRequest clone() => FetchSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FetchSubscriptionRequest copyWith(void Function(FetchSubscriptionRequest) updates) => super.copyWith((message) => updates(message as FetchSubscriptionRequest)) as FetchSubscriptionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionRequest create() => FetchSubscriptionRequest._();
  FetchSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<FetchSubscriptionRequest> createRepeated() => $pb.PbList<FetchSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FetchSubscriptionRequest>(create);
  static FetchSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get reference => $_getSZ(2);
  @$pb.TagNumber(3)
  set reference($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasReference() => $_has(2);
  @$pb.TagNumber(3)
  void clearReference() => clearField(3);

  /// Since 1.3. Replaces the default User-Agent for this subscription: panels
  /// choose the format of their answer by it. Printable ASCII, at most 256 bytes.
  @$pb.TagNumber(4)
  $core.String get userAgent => $_getSZ(3);
  @$pb.TagNumber(4)
  set userAgent($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUserAgent() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserAgent() => clearField(4);
}

class FetchSubscriptionResponse extends $pb.GeneratedMessage {
  factory FetchSubscriptionResponse({
    $core.Iterable<OutboundSpec>? outbounds,
    SoraError? error,
    SubscriptionInfo? info,
  }) {
    final $result = create();
    if (outbounds != null) {
      $result.outbounds.addAll(outbounds);
    }
    if (error != null) {
      $result.error = error;
    }
    if (info != null) {
      $result.info = info;
    }
    return $result;
  }
  FetchSubscriptionResponse._() : super();
  factory FetchSubscriptionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FetchSubscriptionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<OutboundSpec>(1, _omitFieldNames ? '' : 'outbounds', $pb.PbFieldType.PM, subBuilder: OutboundSpec.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..aOM<SubscriptionInfo>(3, _omitFieldNames ? '' : 'info', subBuilder: SubscriptionInfo.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  FetchSubscriptionResponse clone() => FetchSubscriptionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  FetchSubscriptionResponse copyWith(void Function(FetchSubscriptionResponse) updates) => super.copyWith((message) => updates(message as FetchSubscriptionResponse)) as FetchSubscriptionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionResponse create() => FetchSubscriptionResponse._();
  FetchSubscriptionResponse createEmptyInstance() => create();
  static $pb.PbList<FetchSubscriptionResponse> createRepeated() => $pb.PbList<FetchSubscriptionResponse>();
  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<FetchSubscriptionResponse>(create);
  static FetchSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<OutboundSpec> get outbounds => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);

  /// Since 1.3. What the provider said about the subscription.
  @$pb.TagNumber(3)
  SubscriptionInfo get info => $_getN(2);
  @$pb.TagNumber(3)
  set info(SubscriptionInfo v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearInfo() => clearField(3);
  @$pb.TagNumber(3)
  SubscriptionInfo ensureInfo() => $_ensure(2);
}

/// SubscriptionInfo is read from the panel headers (profile-title,
/// profile-update-interval, subscription-userinfo, profile-web-page-url,
/// support-url, announce) or from "#key: value" lines at the top of the body.
class SubscriptionInfo extends $pb.GeneratedMessage {
  factory SubscriptionInfo({
    $core.String? title,
    $1.Duration? updateInterval,
    $core.bool? hasUsage,
    $fixnum.Int64? uploadBytes,
    $fixnum.Int64? downloadBytes,
    $fixnum.Int64? totalBytes,
    $2.Timestamp? expire,
    $core.String? webPageUrl,
    $core.String? supportUrl,
    $core.String? announce,
  }) {
    final $result = create();
    if (title != null) {
      $result.title = title;
    }
    if (updateInterval != null) {
      $result.updateInterval = updateInterval;
    }
    if (hasUsage != null) {
      $result.hasUsage = hasUsage;
    }
    if (uploadBytes != null) {
      $result.uploadBytes = uploadBytes;
    }
    if (downloadBytes != null) {
      $result.downloadBytes = downloadBytes;
    }
    if (totalBytes != null) {
      $result.totalBytes = totalBytes;
    }
    if (expire != null) {
      $result.expire = expire;
    }
    if (webPageUrl != null) {
      $result.webPageUrl = webPageUrl;
    }
    if (supportUrl != null) {
      $result.supportUrl = supportUrl;
    }
    if (announce != null) {
      $result.announce = announce;
    }
    return $result;
  }
  SubscriptionInfo._() : super();
  factory SubscriptionInfo.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SubscriptionInfo.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionInfo', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOM<$1.Duration>(2, _omitFieldNames ? '' : 'updateInterval', subBuilder: $1.Duration.create)
    ..aOB(3, _omitFieldNames ? '' : 'hasUsage')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'uploadBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'downloadBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'expire', subBuilder: $2.Timestamp.create)
    ..aOS(8, _omitFieldNames ? '' : 'webPageUrl')
    ..aOS(9, _omitFieldNames ? '' : 'supportUrl')
    ..aOS(10, _omitFieldNames ? '' : 'announce')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SubscriptionInfo clone() => SubscriptionInfo()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SubscriptionInfo copyWith(void Function(SubscriptionInfo) updates) => super.copyWith((message) => updates(message as SubscriptionInfo)) as SubscriptionInfo;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo create() => SubscriptionInfo._();
  SubscriptionInfo createEmptyInstance() => create();
  static $pb.PbList<SubscriptionInfo> createRepeated() => $pb.PbList<SubscriptionInfo>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionInfo>(create);
  static SubscriptionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => clearField(1);

  /// How often the provider asks to be fetched; unset when it did not say.
  @$pb.TagNumber(2)
  $1.Duration get updateInterval => $_getN(1);
  @$pb.TagNumber(2)
  set updateInterval($1.Duration v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasUpdateInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateInterval() => clearField(2);
  @$pb.TagNumber(2)
  $1.Duration ensureUpdateInterval() => $_ensure(1);

  /// Whether the provider sent traffic figures at all.
  @$pb.TagNumber(3)
  $core.bool get hasUsage => $_getBF(2);
  @$pb.TagNumber(3)
  set hasUsage($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHasUsage() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasUsage() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get uploadBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set uploadBytes($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUploadBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploadBytes() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get downloadBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set downloadBytes($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasDownloadBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearDownloadBytes() => clearField(5);

  /// Zero means unlimited.
  @$pb.TagNumber(6)
  $fixnum.Int64 get totalBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set totalBytes($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasTotalBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalBytes() => clearField(6);

  /// Unset when the subscription does not expire.
  @$pb.TagNumber(7)
  $2.Timestamp get expire => $_getN(6);
  @$pb.TagNumber(7)
  set expire($2.Timestamp v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasExpire() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpire() => clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureExpire() => $_ensure(6);

  /// https, http or tg links only.
  @$pb.TagNumber(8)
  $core.String get webPageUrl => $_getSZ(7);
  @$pb.TagNumber(8)
  set webPageUrl($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasWebPageUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearWebPageUrl() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get supportUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set supportUrl($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasSupportUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearSupportUrl() => clearField(9);

  @$pb.TagNumber(10)
  $core.String get announce => $_getSZ(9);
  @$pb.TagNumber(10)
  set announce($core.String v) { $_setString(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasAnnounce() => $_has(9);
  @$pb.TagNumber(10)
  void clearAnnounce() => clearField(10);
}

class ProbeServersRequest extends $pb.GeneratedMessage {
  factory ProbeServersRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.Iterable<Endpoint>? endpoints,
    $core.Iterable<OutboundSpec>? outbounds,
    ProbeOptions? options,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (endpoints != null) {
      $result.endpoints.addAll(endpoints);
    }
    if (outbounds != null) {
      $result.outbounds.addAll(outbounds);
    }
    if (options != null) {
      $result.options = options;
    }
    return $result;
  }
  ProbeServersRequest._() : super();
  factory ProbeServersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProbeServersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeServersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..pc<Endpoint>(3, _omitFieldNames ? '' : 'endpoints', $pb.PbFieldType.PM, subBuilder: Endpoint.create)
    ..pc<OutboundSpec>(4, _omitFieldNames ? '' : 'outbounds', $pb.PbFieldType.PM, subBuilder: OutboundSpec.create)
    ..aOM<ProbeOptions>(5, _omitFieldNames ? '' : 'options', subBuilder: ProbeOptions.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProbeServersRequest clone() => ProbeServersRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProbeServersRequest copyWith(void Function(ProbeServersRequest) updates) => super.copyWith((message) => updates(message as ProbeServersRequest)) as ProbeServersRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProbeServersRequest create() => ProbeServersRequest._();
  ProbeServersRequest createEmptyInstance() => create();
  static $pb.PbList<ProbeServersRequest> createRepeated() => $pb.PbList<ProbeServersRequest>();
  @$core.pragma('dart2js:noInline')
  static ProbeServersRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeServersRequest>(create);
  static ProbeServersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  /// Measured with a TCP connection only.
  @$pb.TagNumber(3)
  $core.List<Endpoint> get endpoints => $_getList(2);

  /// Since 1.3. Measured as the options say; results carry the outbound id.
  @$pb.TagNumber(4)
  $core.List<OutboundSpec> get outbounds => $_getList(3);

  @$pb.TagNumber(5)
  ProbeOptions get options => $_getN(4);
  @$pb.TagNumber(5)
  set options(ProbeOptions v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearOptions() => clearField(5);
  @$pb.TagNumber(5)
  ProbeOptions ensureOptions() => $_ensure(4);
}

/// ProbeOptions controls a latency measurement. Zero values take the core
/// defaults.
class ProbeOptions extends $pb.GeneratedMessage {
  factory ProbeOptions({
    ProbeMethod? method,
    $core.String? url,
    $core.int? timeoutMs,
    $core.int? concurrency,
    $core.Iterable<$core.String>? engines,
  }) {
    final $result = create();
    if (method != null) {
      $result.method = method;
    }
    if (url != null) {
      $result.url = url;
    }
    if (timeoutMs != null) {
      $result.timeoutMs = timeoutMs;
    }
    if (concurrency != null) {
      $result.concurrency = concurrency;
    }
    if (engines != null) {
      $result.engines.addAll(engines);
    }
    return $result;
  }
  ProbeOptions._() : super();
  factory ProbeOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProbeOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<ProbeMethod>(1, _omitFieldNames ? '' : 'method', $pb.PbFieldType.OE, defaultOrMaker: ProbeMethod.PROBE_METHOD_UNSPECIFIED, valueOf: ProbeMethod.valueOf, enumValues: ProbeMethod.values)
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'timeoutMs', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'concurrency', $pb.PbFieldType.OU3)
    ..pPS(5, _omitFieldNames ? '' : 'engines')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ProbeOptions clone() => ProbeOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ProbeOptions copyWith(void Function(ProbeOptions) updates) => super.copyWith((message) => updates(message as ProbeOptions)) as ProbeOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ProbeOptions create() => ProbeOptions._();
  ProbeOptions createEmptyInstance() => create();
  static $pb.PbList<ProbeOptions> createRepeated() => $pb.PbList<ProbeOptions>();
  @$core.pragma('dart2js:noInline')
  static ProbeOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeOptions>(create);
  static ProbeOptions? _defaultInstance;

  @$pb.TagNumber(1)
  ProbeMethod get method => $_getN(0);
  @$pb.TagNumber(1)
  set method(ProbeMethod v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => clearField(1);

  /// The URL requested through each server; it should answer 204 or 200.
  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => clearField(2);

  @$pb.TagNumber(3)
  $core.int get timeoutMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeoutMs($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTimeoutMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeoutMs() => clearField(3);

  /// How many servers are measured at once.
  @$pb.TagNumber(4)
  $core.int get concurrency => $_getIZ(3);
  @$pb.TagNumber(4)
  set concurrency($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasConcurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearConcurrency() => clearField(4);

  /// Engine preference for the measurement, as in SessionPlan.engines.
  @$pb.TagNumber(5)
  $core.List<$core.String> get engines => $_getList(4);
}

class RunDiagnosticsRequest extends $pb.GeneratedMessage {
  factory RunDiagnosticsRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  RunDiagnosticsRequest._() : super();
  factory RunDiagnosticsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RunDiagnosticsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RunDiagnosticsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RunDiagnosticsRequest clone() => RunDiagnosticsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RunDiagnosticsRequest copyWith(void Function(RunDiagnosticsRequest) updates) => super.copyWith((message) => updates(message as RunDiagnosticsRequest)) as RunDiagnosticsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsRequest create() => RunDiagnosticsRequest._();
  RunDiagnosticsRequest createEmptyInstance() => create();
  static $pb.PbList<RunDiagnosticsRequest> createRepeated() => $pb.PbList<RunDiagnosticsRequest>();
  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RunDiagnosticsRequest>(create);
  static RunDiagnosticsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);
}

class RunDiagnosticsResponse extends $pb.GeneratedMessage {
  factory RunDiagnosticsResponse({
    DiagnosticReport? report,
    SoraError? error,
  }) {
    final $result = create();
    if (report != null) {
      $result.report = report;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  RunDiagnosticsResponse._() : super();
  factory RunDiagnosticsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RunDiagnosticsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RunDiagnosticsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<DiagnosticReport>(1, _omitFieldNames ? '' : 'report', subBuilder: DiagnosticReport.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RunDiagnosticsResponse clone() => RunDiagnosticsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RunDiagnosticsResponse copyWith(void Function(RunDiagnosticsResponse) updates) => super.copyWith((message) => updates(message as RunDiagnosticsResponse)) as RunDiagnosticsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsResponse create() => RunDiagnosticsResponse._();
  RunDiagnosticsResponse createEmptyInstance() => create();
  static $pb.PbList<RunDiagnosticsResponse> createRepeated() => $pb.PbList<RunDiagnosticsResponse>();
  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RunDiagnosticsResponse>(create);
  static RunDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DiagnosticReport get report => $_getN(0);
  @$pb.TagNumber(1)
  set report(DiagnosticReport v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasReport() => $_has(0);
  @$pb.TagNumber(1)
  void clearReport() => clearField(1);
  @$pb.TagNumber(1)
  DiagnosticReport ensureReport() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class ExportDiagnosticsRequest extends $pb.GeneratedMessage {
  factory ExportDiagnosticsRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  ExportDiagnosticsRequest._() : super();
  factory ExportDiagnosticsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportDiagnosticsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportDiagnosticsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportDiagnosticsRequest clone() => ExportDiagnosticsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportDiagnosticsRequest copyWith(void Function(ExportDiagnosticsRequest) updates) => super.copyWith((message) => updates(message as ExportDiagnosticsRequest)) as ExportDiagnosticsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsRequest create() => ExportDiagnosticsRequest._();
  ExportDiagnosticsRequest createEmptyInstance() => create();
  static $pb.PbList<ExportDiagnosticsRequest> createRepeated() => $pb.PbList<ExportDiagnosticsRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportDiagnosticsRequest>(create);
  static ExportDiagnosticsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);
}

class ExportDiagnosticsResponse extends $pb.GeneratedMessage {
  factory ExportDiagnosticsResponse({
    $core.List<$core.int>? archive,
    SoraError? error,
  }) {
    final $result = create();
    if (archive != null) {
      $result.archive = archive;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ExportDiagnosticsResponse._() : super();
  factory ExportDiagnosticsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportDiagnosticsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportDiagnosticsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'archive', $pb.PbFieldType.OY)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportDiagnosticsResponse clone() => ExportDiagnosticsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportDiagnosticsResponse copyWith(void Function(ExportDiagnosticsResponse) updates) => super.copyWith((message) => updates(message as ExportDiagnosticsResponse)) as ExportDiagnosticsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsResponse create() => ExportDiagnosticsResponse._();
  ExportDiagnosticsResponse createEmptyInstance() => create();
  static $pb.PbList<ExportDiagnosticsResponse> createRepeated() => $pb.PbList<ExportDiagnosticsResponse>();
  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportDiagnosticsResponse>(create);
  static ExportDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get archive => $_getN(0);
  @$pb.TagNumber(1)
  set archive($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasArchive() => $_has(0);
  @$pb.TagNumber(1)
  void clearArchive() => clearField(1);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class SetKillSwitchRequest extends $pb.GeneratedMessage {
  factory SetKillSwitchRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
    $core.bool? enabled,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (enabled != null) {
      $result.enabled = enabled;
    }
    return $result;
  }
  SetKillSwitchRequest._() : super();
  factory SetKillSwitchRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetKillSwitchRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetKillSwitchRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetKillSwitchRequest clone() => SetKillSwitchRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetKillSwitchRequest copyWith(void Function(SetKillSwitchRequest) updates) => super.copyWith((message) => updates(message as SetKillSwitchRequest)) as SetKillSwitchRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetKillSwitchRequest create() => SetKillSwitchRequest._();
  SetKillSwitchRequest createEmptyInstance() => create();
  static $pb.PbList<SetKillSwitchRequest> createRepeated() => $pb.PbList<SetKillSwitchRequest>();
  @$core.pragma('dart2js:noInline')
  static SetKillSwitchRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetKillSwitchRequest>(create);
  static SetKillSwitchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => clearField(4);
}

class SetKillSwitchResponse extends $pb.GeneratedMessage {
  factory SetKillSwitchResponse({
    $core.bool? enabled,
    SoraError? error,
  }) {
    final $result = create();
    if (enabled != null) {
      $result.enabled = enabled;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  SetKillSwitchResponse._() : super();
  factory SetKillSwitchResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetKillSwitchResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetKillSwitchResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetKillSwitchResponse clone() => SetKillSwitchResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetKillSwitchResponse copyWith(void Function(SetKillSwitchResponse) updates) => super.copyWith((message) => updates(message as SetKillSwitchResponse)) as SetKillSwitchResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetKillSwitchResponse create() => SetKillSwitchResponse._();
  SetKillSwitchResponse createEmptyInstance() => create();
  static $pb.PbList<SetKillSwitchResponse> createRepeated() => $pb.PbList<SetKillSwitchResponse>();
  @$core.pragma('dart2js:noInline')
  static SetKillSwitchResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetKillSwitchResponse>(create);
  static SetKillSwitchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => clearField(1);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class DiagnosticReport extends $pb.GeneratedMessage {
  factory DiagnosticReport({
    $core.Iterable<$core.String>? lines,
  }) {
    final $result = create();
    if (lines != null) {
      $result.lines.addAll(lines);
    }
    return $result;
  }
  DiagnosticReport._() : super();
  factory DiagnosticReport.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DiagnosticReport.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DiagnosticReport', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'lines')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DiagnosticReport clone() => DiagnosticReport()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DiagnosticReport copyWith(void Function(DiagnosticReport) updates) => super.copyWith((message) => updates(message as DiagnosticReport)) as DiagnosticReport;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DiagnosticReport create() => DiagnosticReport._();
  DiagnosticReport createEmptyInstance() => create();
  static $pb.PbList<DiagnosticReport> createRepeated() => $pb.PbList<DiagnosticReport>();
  @$core.pragma('dart2js:noInline')
  static DiagnosticReport getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiagnosticReport>(create);
  static DiagnosticReport? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get lines => $_getList(0);
}

class HandshakeRequest extends $pb.GeneratedMessage {
  factory HandshakeRequest({
    ApiVersion? clientVersion,
  }) {
    final $result = create();
    if (clientVersion != null) {
      $result.clientVersion = clientVersion;
    }
    return $result;
  }
  HandshakeRequest._() : super();
  factory HandshakeRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HandshakeRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'clientVersion', subBuilder: ApiVersion.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HandshakeRequest clone() => HandshakeRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HandshakeRequest copyWith(void Function(HandshakeRequest) updates) => super.copyWith((message) => updates(message as HandshakeRequest)) as HandshakeRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeRequest create() => HandshakeRequest._();
  HandshakeRequest createEmptyInstance() => create();
  static $pb.PbList<HandshakeRequest> createRepeated() => $pb.PbList<HandshakeRequest>();
  @$core.pragma('dart2js:noInline')
  static HandshakeRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeRequest>(create);
  static HandshakeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get clientVersion => $_getN(0);
  @$pb.TagNumber(1)
  set clientVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasClientVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureClientVersion() => $_ensure(0);
}

class HandshakeResponse extends $pb.GeneratedMessage {
  factory HandshakeResponse({
    ApiVersion? negotiatedVersion,
    SoraError? error,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (negotiatedVersion != null) {
      $result.negotiatedVersion = negotiatedVersion;
    }
    if (error != null) {
      $result.error = error;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  HandshakeResponse._() : super();
  factory HandshakeResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HandshakeResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'negotiatedVersion', subBuilder: ApiVersion.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  HandshakeResponse clone() => HandshakeResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  HandshakeResponse copyWith(void Function(HandshakeResponse) updates) => super.copyWith((message) => updates(message as HandshakeResponse)) as HandshakeResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static HandshakeResponse create() => HandshakeResponse._();
  HandshakeResponse createEmptyInstance() => create();
  static $pb.PbList<HandshakeResponse> createRepeated() => $pb.PbList<HandshakeResponse>();
  @$core.pragma('dart2js:noInline')
  static HandshakeResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeResponse>(create);
  static HandshakeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get negotiatedVersion => $_getN(0);
  @$pb.TagNumber(1)
  set negotiatedVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasNegotiatedVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearNegotiatedVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureNegotiatedVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);

  /// Since 1.3. The token the other calls present. The transport admits only
  /// the core's own account, the service group and the person in the active
  /// local session, so whoever reaches Handshake may hold it; a system
  /// installation keeps the token file where that person cannot read it.
  @$pb.TagNumber(3)
  $core.List<$core.int> get controlAuthenticator => $_getN(2);
  @$pb.TagNumber(3)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasControlAuthenticator() => $_has(2);
  @$pb.TagNumber(3)
  void clearControlAuthenticator() => clearField(3);
}

/// PutSecretRequest hands one piece of credential material to the core. The
/// interface keeps the material only until the call is confirmed; the core keeps
/// it encrypted at rest and hands it back only to a plan that names it.
class PutSecretRequest extends $pb.GeneratedMessage {
  factory PutSecretRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    CredentialsRef? credentials,
    $core.List<$core.int>? material,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (credentials != null) {
      $result.credentials = credentials;
    }
    if (material != null) {
      $result.material = material;
    }
    return $result;
  }
  PutSecretRequest._() : super();
  factory PutSecretRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PutSecretRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PutSecretRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<CredentialsRef>(3, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.create)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'material', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PutSecretRequest clone() => PutSecretRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PutSecretRequest copyWith(void Function(PutSecretRequest) updates) => super.copyWith((message) => updates(message as PutSecretRequest)) as PutSecretRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PutSecretRequest create() => PutSecretRequest._();
  PutSecretRequest createEmptyInstance() => create();
  static $pb.PbList<PutSecretRequest> createRepeated() => $pb.PbList<PutSecretRequest>();
  @$core.pragma('dart2js:noInline')
  static PutSecretRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PutSecretRequest>(create);
  static PutSecretRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  CredentialsRef get credentials => $_getN(2);
  @$pb.TagNumber(3)
  set credentials(CredentialsRef v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasCredentials() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredentials() => clearField(3);
  @$pb.TagNumber(3)
  CredentialsRef ensureCredentials() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get material => $_getN(3);
  @$pb.TagNumber(4)
  set material($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMaterial() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaterial() => clearField(4);
}

class PutSecretResponse extends $pb.GeneratedMessage {
  factory PutSecretResponse({
    CredentialsRef? credentials,
    SoraError? error,
  }) {
    final $result = create();
    if (credentials != null) {
      $result.credentials = credentials;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  PutSecretResponse._() : super();
  factory PutSecretResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PutSecretResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PutSecretResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<CredentialsRef>(1, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PutSecretResponse clone() => PutSecretResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PutSecretResponse copyWith(void Function(PutSecretResponse) updates) => super.copyWith((message) => updates(message as PutSecretResponse)) as PutSecretResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PutSecretResponse create() => PutSecretResponse._();
  PutSecretResponse createEmptyInstance() => create();
  static $pb.PbList<PutSecretResponse> createRepeated() => $pb.PbList<PutSecretResponse>();
  @$core.pragma('dart2js:noInline')
  static PutSecretResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PutSecretResponse>(create);
  static PutSecretResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CredentialsRef get credentials => $_getN(0);
  @$pb.TagNumber(1)
  set credentials(CredentialsRef v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCredentials() => $_has(0);
  @$pb.TagNumber(1)
  void clearCredentials() => clearField(1);
  @$pb.TagNumber(1)
  CredentialsRef ensureCredentials() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// DeleteSecretRequest removes stored material. It is safe to call for a
/// reference that holds nothing, so a cleanup path may run twice.
class DeleteSecretRequest extends $pb.GeneratedMessage {
  factory DeleteSecretRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    CredentialsRef? credentials,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (credentials != null) {
      $result.credentials = credentials;
    }
    return $result;
  }
  DeleteSecretRequest._() : super();
  factory DeleteSecretRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSecretRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSecretRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<CredentialsRef>(3, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSecretRequest clone() => DeleteSecretRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSecretRequest copyWith(void Function(DeleteSecretRequest) updates) => super.copyWith((message) => updates(message as DeleteSecretRequest)) as DeleteSecretRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSecretRequest create() => DeleteSecretRequest._();
  DeleteSecretRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSecretRequest> createRepeated() => $pb.PbList<DeleteSecretRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSecretRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSecretRequest>(create);
  static DeleteSecretRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => clearField(2);

  @$pb.TagNumber(3)
  CredentialsRef get credentials => $_getN(2);
  @$pb.TagNumber(3)
  set credentials(CredentialsRef v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasCredentials() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredentials() => clearField(3);
  @$pb.TagNumber(3)
  CredentialsRef ensureCredentials() => $_ensure(2);
}

class DeleteSecretResponse extends $pb.GeneratedMessage {
  factory DeleteSecretResponse({
    SoraError? error,
  }) {
    final $result = create();
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  DeleteSecretResponse._() : super();
  factory DeleteSecretResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSecretResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSecretResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSecretResponse clone() => DeleteSecretResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSecretResponse copyWith(void Function(DeleteSecretResponse) updates) => super.copyWith((message) => updates(message as DeleteSecretResponse)) as DeleteSecretResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSecretResponse create() => DeleteSecretResponse._();
  DeleteSecretResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteSecretResponse> createRepeated() => $pb.PbList<DeleteSecretResponse>();
  @$core.pragma('dart2js:noInline')
  static DeleteSecretResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSecretResponse>(create);
  static DeleteSecretResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => clearField(1);
  @$pb.TagNumber(1)
  SoraError ensureError() => $_ensure(0);
}

class SoraError extends $pb.GeneratedMessage {
  factory SoraError({
    SoraErrorCode? code,
    $core.String? userMessageKey,
    $core.String? detailRedacted,
    $core.bool? retryable,
    $core.String? requestId,
    $1.Duration? retryAfter,
  }) {
    final $result = create();
    if (code != null) {
      $result.code = code;
    }
    if (userMessageKey != null) {
      $result.userMessageKey = userMessageKey;
    }
    if (detailRedacted != null) {
      $result.detailRedacted = detailRedacted;
    }
    if (retryable != null) {
      $result.retryable = retryable;
    }
    if (requestId != null) {
      $result.requestId = requestId;
    }
    if (retryAfter != null) {
      $result.retryAfter = retryAfter;
    }
    return $result;
  }
  SoraError._() : super();
  factory SoraError.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SoraError.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SoraError', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<SoraErrorCode>(1, _omitFieldNames ? '' : 'code', $pb.PbFieldType.OE, defaultOrMaker: SoraErrorCode.SORA_ERROR_CODE_UNSPECIFIED, valueOf: SoraErrorCode.valueOf, enumValues: SoraErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'userMessageKey')
    ..aOS(3, _omitFieldNames ? '' : 'detailRedacted')
    ..aOB(4, _omitFieldNames ? '' : 'retryable')
    ..aOS(5, _omitFieldNames ? '' : 'requestId')
    ..aOM<$1.Duration>(6, _omitFieldNames ? '' : 'retryAfter', subBuilder: $1.Duration.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SoraError clone() => SoraError()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SoraError copyWith(void Function(SoraError) updates) => super.copyWith((message) => updates(message as SoraError)) as SoraError;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SoraError create() => SoraError._();
  SoraError createEmptyInstance() => create();
  static $pb.PbList<SoraError> createRepeated() => $pb.PbList<SoraError>();
  @$core.pragma('dart2js:noInline')
  static SoraError getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SoraError>(create);
  static SoraError? _defaultInstance;

  @$pb.TagNumber(1)
  SoraErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(SoraErrorCode v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get userMessageKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set userMessageKey($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserMessageKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserMessageKey() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get detailRedacted => $_getSZ(2);
  @$pb.TagNumber(3)
  set detailRedacted($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDetailRedacted() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetailRedacted() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get retryable => $_getBF(3);
  @$pb.TagNumber(4)
  set retryable($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRetryable() => $_has(3);
  @$pb.TagNumber(4)
  void clearRetryable() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get requestId => $_getSZ(4);
  @$pb.TagNumber(5)
  set requestId($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasRequestId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestId() => clearField(5);

  @$pb.TagNumber(6)
  $1.Duration get retryAfter => $_getN(5);
  @$pb.TagNumber(6)
  set retryAfter($1.Duration v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasRetryAfter() => $_has(5);
  @$pb.TagNumber(6)
  void clearRetryAfter() => clearField(6);
  @$pb.TagNumber(6)
  $1.Duration ensureRetryAfter() => $_ensure(5);
}

/// LogEntry is one record. The message is masked of credentials, and of the
/// destinations a person visits unless LogSettings.record_destinations is on.
class LogEntry extends $pb.GeneratedMessage {
  factory LogEntry({
    $fixnum.Int64? sequence,
    $2.Timestamp? time,
    LogLevel? level,
    $core.String? source,
    $core.String? message,
    $core.int? repeat,
  }) {
    final $result = create();
    if (sequence != null) {
      $result.sequence = sequence;
    }
    if (time != null) {
      $result.time = time;
    }
    if (level != null) {
      $result.level = level;
    }
    if (source != null) {
      $result.source = source;
    }
    if (message != null) {
      $result.message = message;
    }
    if (repeat != null) {
      $result.repeat = repeat;
    }
    return $result;
  }
  LogEntry._() : super();
  factory LogEntry.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogEntry.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogEntry', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(2, _omitFieldNames ? '' : 'time', subBuilder: $2.Timestamp.create)
    ..e<LogLevel>(3, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.LOG_LEVEL_UNSPECIFIED, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..a<$core.int>(6, _omitFieldNames ? '' : 'repeat', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogEntry clone() => LogEntry()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogEntry copyWith(void Function(LogEntry) updates) => super.copyWith((message) => updates(message as LogEntry)) as LogEntry;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogEntry create() => LogEntry._();
  LogEntry createEmptyInstance() => create();
  static $pb.PbList<LogEntry> createRepeated() => $pb.PbList<LogEntry>();
  @$core.pragma('dart2js:noInline')
  static LogEntry getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogEntry>(create);
  static LogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => clearField(1);

  @$pb.TagNumber(2)
  $2.Timestamp get time => $_getN(1);
  @$pb.TagNumber(2)
  set time($2.Timestamp v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => clearField(2);
  @$pb.TagNumber(2)
  $2.Timestamp ensureTime() => $_ensure(1);

  @$pb.TagNumber(3)
  LogLevel get level => $_getN(2);
  @$pb.TagNumber(3)
  set level(LogLevel v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => clearField(3);

  /// "core" for the service itself, otherwise the engine: sing-box, xray, mihomo.
  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => clearField(5);

  /// Identical consecutive messages fold into one entry; a watcher receives the
  /// entry again with the same sequence and a higher repeat.
  @$pb.TagNumber(6)
  $core.int get repeat => $_getIZ(5);
  @$pb.TagNumber(6)
  set repeat($core.int v) { $_setUnsignedInt32(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasRepeat() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepeat() => clearField(6);
}

/// LogFilter selects entries; unset fields select everything.
class LogFilter extends $pb.GeneratedMessage {
  factory LogFilter({
    LogLevel? minLevel,
    $core.Iterable<$core.String>? sources,
    $core.String? contains,
    $core.String? pattern,
    $2.Timestamp? since,
    $2.Timestamp? until,
  }) {
    final $result = create();
    if (minLevel != null) {
      $result.minLevel = minLevel;
    }
    if (sources != null) {
      $result.sources.addAll(sources);
    }
    if (contains != null) {
      $result.contains = contains;
    }
    if (pattern != null) {
      $result.pattern = pattern;
    }
    if (since != null) {
      $result.since = since;
    }
    if (until != null) {
      $result.until = until;
    }
    return $result;
  }
  LogFilter._() : super();
  factory LogFilter.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogFilter.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogFilter', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'minLevel', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.LOG_LEVEL_UNSPECIFIED, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..pPS(2, _omitFieldNames ? '' : 'sources')
    ..aOS(3, _omitFieldNames ? '' : 'contains')
    ..aOS(4, _omitFieldNames ? '' : 'pattern')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'since', subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'until', subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogFilter clone() => LogFilter()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogFilter copyWith(void Function(LogFilter) updates) => super.copyWith((message) => updates(message as LogFilter)) as LogFilter;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogFilter create() => LogFilter._();
  LogFilter createEmptyInstance() => create();
  static $pb.PbList<LogFilter> createRepeated() => $pb.PbList<LogFilter>();
  @$core.pragma('dart2js:noInline')
  static LogFilter getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogFilter>(create);
  static LogFilter? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get minLevel => $_getN(0);
  @$pb.TagNumber(1)
  set minLevel(LogLevel v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasMinLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinLevel() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.String> get sources => $_getList(1);

  /// Case-insensitive substring of the message.
  @$pb.TagNumber(3)
  $core.String get contains => $_getSZ(2);
  @$pb.TagNumber(3)
  set contains($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasContains() => $_has(2);
  @$pb.TagNumber(3)
  void clearContains() => clearField(3);

  /// Case-insensitive regular expression (RE2), at most 512 bytes.
  @$pb.TagNumber(4)
  $core.String get pattern => $_getSZ(3);
  @$pb.TagNumber(4)
  set pattern($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPattern() => $_has(3);
  @$pb.TagNumber(4)
  void clearPattern() => clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get since => $_getN(4);
  @$pb.TagNumber(5)
  set since($2.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasSince() => $_has(4);
  @$pb.TagNumber(5)
  void clearSince() => clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureSince() => $_ensure(4);

  @$pb.TagNumber(6)
  $2.Timestamp get until => $_getN(5);
  @$pb.TagNumber(6)
  set until($2.Timestamp v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasUntil() => $_has(5);
  @$pb.TagNumber(6)
  void clearUntil() => clearField(6);
  @$pb.TagNumber(6)
  $2.Timestamp ensureUntil() => $_ensure(5);
}

class QueryLogsRequest extends $pb.GeneratedMessage {
  factory QueryLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogFilter? filter,
    $fixnum.Int64? beforeSequence,
    $core.int? limit,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (filter != null) {
      $result.filter = filter;
    }
    if (beforeSequence != null) {
      $result.beforeSequence = beforeSequence;
    }
    if (limit != null) {
      $result.limit = limit;
    }
    return $result;
  }
  QueryLogsRequest._() : super();
  factory QueryLogsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryLogsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'QueryLogsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.create)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'beforeSequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'limit', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryLogsRequest clone() => QueryLogsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryLogsRequest copyWith(void Function(QueryLogsRequest) updates) => super.copyWith((message) => updates(message as QueryLogsRequest)) as QueryLogsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryLogsRequest create() => QueryLogsRequest._();
  QueryLogsRequest createEmptyInstance() => create();
  static $pb.PbList<QueryLogsRequest> createRepeated() => $pb.PbList<QueryLogsRequest>();
  @$core.pragma('dart2js:noInline')
  static QueryLogsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryLogsRequest>(create);
  static QueryLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  /// Entries older than this sequence; 0 starts at the newest.
  @$pb.TagNumber(4)
  $fixnum.Int64 get beforeSequence => $_getI64(3);
  @$pb.TagNumber(4)
  set beforeSequence($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBeforeSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearBeforeSequence() => clearField(4);

  /// At most 1000; 0 means 1000.
  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int v) { $_setUnsignedInt32(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => clearField(5);
}

class QueryLogsResponse extends $pb.GeneratedMessage {
  factory QueryLogsResponse({
    $core.Iterable<LogEntry>? entries,
    $fixnum.Int64? beforeSequence,
    LogStats? stats,
    SoraError? error,
  }) {
    final $result = create();
    if (entries != null) {
      $result.entries.addAll(entries);
    }
    if (beforeSequence != null) {
      $result.beforeSequence = beforeSequence;
    }
    if (stats != null) {
      $result.stats = stats;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  QueryLogsResponse._() : super();
  factory QueryLogsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory QueryLogsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'QueryLogsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<LogEntry>(1, _omitFieldNames ? '' : 'entries', $pb.PbFieldType.PM, subBuilder: LogEntry.create)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'beforeSequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<LogStats>(3, _omitFieldNames ? '' : 'stats', subBuilder: LogStats.create)
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  QueryLogsResponse clone() => QueryLogsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  QueryLogsResponse copyWith(void Function(QueryLogsResponse) updates) => super.copyWith((message) => updates(message as QueryLogsResponse)) as QueryLogsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QueryLogsResponse create() => QueryLogsResponse._();
  QueryLogsResponse createEmptyInstance() => create();
  static $pb.PbList<QueryLogsResponse> createRepeated() => $pb.PbList<QueryLogsResponse>();
  @$core.pragma('dart2js:noInline')
  static QueryLogsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryLogsResponse>(create);
  static QueryLogsResponse? _defaultInstance;

  /// Newest first.
  @$pb.TagNumber(1)
  $core.List<LogEntry> get entries => $_getList(0);

  /// Cursor of the next, older page; 0 when there is none.
  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeSequence => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeSequence($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBeforeSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeSequence() => clearField(2);

  @$pb.TagNumber(3)
  LogStats get stats => $_getN(2);
  @$pb.TagNumber(3)
  set stats(LogStats v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasStats() => $_has(2);
  @$pb.TagNumber(3)
  void clearStats() => clearField(3);
  @$pb.TagNumber(3)
  LogStats ensureStats() => $_ensure(2);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);
}

/// LogStats describe the whole record, not only what the filter matched.
class LogStats extends $pb.GeneratedMessage {
  factory LogStats({
    $core.Iterable<LogLevelCount>? byLevel,
    $core.Iterable<LogSourceCount>? bySource,
    $fixnum.Int64? total,
    $fixnum.Int64? bytes,
    $fixnum.Int64? maxBytes,
    $fixnum.Int64? dropped,
  }) {
    final $result = create();
    if (byLevel != null) {
      $result.byLevel.addAll(byLevel);
    }
    if (bySource != null) {
      $result.bySource.addAll(bySource);
    }
    if (total != null) {
      $result.total = total;
    }
    if (bytes != null) {
      $result.bytes = bytes;
    }
    if (maxBytes != null) {
      $result.maxBytes = maxBytes;
    }
    if (dropped != null) {
      $result.dropped = dropped;
    }
    return $result;
  }
  LogStats._() : super();
  factory LogStats.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogStats.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogStats', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<LogLevelCount>(1, _omitFieldNames ? '' : 'byLevel', $pb.PbFieldType.PM, subBuilder: LogLevelCount.create)
    ..pc<LogSourceCount>(2, _omitFieldNames ? '' : 'bySource', $pb.PbFieldType.PM, subBuilder: LogSourceCount.create)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'maxBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'dropped', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogStats clone() => LogStats()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogStats copyWith(void Function(LogStats) updates) => super.copyWith((message) => updates(message as LogStats)) as LogStats;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogStats create() => LogStats._();
  LogStats createEmptyInstance() => create();
  static $pb.PbList<LogStats> createRepeated() => $pb.PbList<LogStats>();
  @$core.pragma('dart2js:noInline')
  static LogStats getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogStats>(create);
  static LogStats? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<LogLevelCount> get byLevel => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<LogSourceCount> get bySource => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set bytes($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearBytes() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get maxBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set maxBytes($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasMaxBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxBytes() => clearField(5);

  /// Entries the bounds evicted since the core started.
  @$pb.TagNumber(6)
  $fixnum.Int64 get dropped => $_getI64(5);
  @$pb.TagNumber(6)
  set dropped($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDropped() => $_has(5);
  @$pb.TagNumber(6)
  void clearDropped() => clearField(6);
}

class LogLevelCount extends $pb.GeneratedMessage {
  factory LogLevelCount({
    LogLevel? level,
    $fixnum.Int64? count,
  }) {
    final $result = create();
    if (level != null) {
      $result.level = level;
    }
    if (count != null) {
      $result.count = count;
    }
    return $result;
  }
  LogLevelCount._() : super();
  factory LogLevelCount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogLevelCount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogLevelCount', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'level', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.LOG_LEVEL_UNSPECIFIED, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogLevelCount clone() => LogLevelCount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogLevelCount copyWith(void Function(LogLevelCount) updates) => super.copyWith((message) => updates(message as LogLevelCount)) as LogLevelCount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogLevelCount create() => LogLevelCount._();
  LogLevelCount createEmptyInstance() => create();
  static $pb.PbList<LogLevelCount> createRepeated() => $pb.PbList<LogLevelCount>();
  @$core.pragma('dart2js:noInline')
  static LogLevelCount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogLevelCount>(create);
  static LogLevelCount? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get level => $_getN(0);
  @$pb.TagNumber(1)
  set level(LogLevel v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => clearField(2);
}

class LogSourceCount extends $pb.GeneratedMessage {
  factory LogSourceCount({
    $core.String? source,
    $fixnum.Int64? count,
  }) {
    final $result = create();
    if (source != null) {
      $result.source = source;
    }
    if (count != null) {
      $result.count = count;
    }
    return $result;
  }
  LogSourceCount._() : super();
  factory LogSourceCount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogSourceCount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogSourceCount', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'source')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogSourceCount clone() => LogSourceCount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogSourceCount copyWith(void Function(LogSourceCount) updates) => super.copyWith((message) => updates(message as LogSourceCount)) as LogSourceCount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogSourceCount create() => LogSourceCount._();
  LogSourceCount createEmptyInstance() => create();
  static $pb.PbList<LogSourceCount> createRepeated() => $pb.PbList<LogSourceCount>();
  @$core.pragma('dart2js:noInline')
  static LogSourceCount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogSourceCount>(create);
  static LogSourceCount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get source => $_getSZ(0);
  @$pb.TagNumber(1)
  set source($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => clearField(2);
}

class WatchLogsRequest extends $pb.GeneratedMessage {
  factory WatchLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogFilter? filter,
    $fixnum.Int64? afterSequence,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (filter != null) {
      $result.filter = filter;
    }
    if (afterSequence != null) {
      $result.afterSequence = afterSequence;
    }
    return $result;
  }
  WatchLogsRequest._() : super();
  factory WatchLogsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WatchLogsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchLogsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.create)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'afterSequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WatchLogsRequest clone() => WatchLogsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WatchLogsRequest copyWith(void Function(WatchLogsRequest) updates) => super.copyWith((message) => updates(message as WatchLogsRequest)) as WatchLogsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchLogsRequest create() => WatchLogsRequest._();
  WatchLogsRequest createEmptyInstance() => create();
  static $pb.PbList<WatchLogsRequest> createRepeated() => $pb.PbList<WatchLogsRequest>();
  @$core.pragma('dart2js:noInline')
  static WatchLogsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchLogsRequest>(create);
  static WatchLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  /// Replays the matching entries after this sequence, then follows.
  @$pb.TagNumber(4)
  $fixnum.Int64 get afterSequence => $_getI64(3);
  @$pb.TagNumber(4)
  set afterSequence($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasAfterSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearAfterSequence() => clearField(4);
}

class ExportLogsRequest extends $pb.GeneratedMessage {
  factory ExportLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogFilter? filter,
    LogExportFormat? format,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (filter != null) {
      $result.filter = filter;
    }
    if (format != null) {
      $result.format = format;
    }
    return $result;
  }
  ExportLogsRequest._() : super();
  factory ExportLogsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportLogsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportLogsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.create)
    ..e<LogExportFormat>(4, _omitFieldNames ? '' : 'format', $pb.PbFieldType.OE, defaultOrMaker: LogExportFormat.LOG_EXPORT_FORMAT_UNSPECIFIED, valueOf: LogExportFormat.valueOf, enumValues: LogExportFormat.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportLogsRequest clone() => ExportLogsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportLogsRequest copyWith(void Function(ExportLogsRequest) updates) => super.copyWith((message) => updates(message as ExportLogsRequest)) as ExportLogsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportLogsRequest create() => ExportLogsRequest._();
  ExportLogsRequest createEmptyInstance() => create();
  static $pb.PbList<ExportLogsRequest> createRepeated() => $pb.PbList<ExportLogsRequest>();
  @$core.pragma('dart2js:noInline')
  static ExportLogsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportLogsRequest>(create);
  static ExportLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  @$pb.TagNumber(4)
  LogExportFormat get format => $_getN(3);
  @$pb.TagNumber(4)
  set format(LogExportFormat v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => clearField(4);
}

class ExportLogsResponse extends $pb.GeneratedMessage {
  factory ExportLogsResponse({
    $core.List<$core.int>? data,
    $core.String? fileName,
    $core.String? mediaType,
    SoraError? error,
  }) {
    final $result = create();
    if (data != null) {
      $result.data = data;
    }
    if (fileName != null) {
      $result.fileName = fileName;
    }
    if (mediaType != null) {
      $result.mediaType = mediaType;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ExportLogsResponse._() : super();
  factory ExportLogsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ExportLogsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportLogsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'fileName')
    ..aOS(3, _omitFieldNames ? '' : 'mediaType')
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ExportLogsResponse clone() => ExportLogsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ExportLogsResponse copyWith(void Function(ExportLogsResponse) updates) => super.copyWith((message) => updates(message as ExportLogsResponse)) as ExportLogsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ExportLogsResponse create() => ExportLogsResponse._();
  ExportLogsResponse createEmptyInstance() => create();
  static $pb.PbList<ExportLogsResponse> createRepeated() => $pb.PbList<ExportLogsResponse>();
  @$core.pragma('dart2js:noInline')
  static ExportLogsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportLogsResponse>(create);
  static ExportLogsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get fileName => $_getSZ(1);
  @$pb.TagNumber(2)
  set fileName($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFileName() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileName() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get mediaType => $_getSZ(2);
  @$pb.TagNumber(3)
  set mediaType($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMediaType() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaType() => clearField(3);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);
}

class ClearLogsRequest extends $pb.GeneratedMessage {
  factory ClearLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  ClearLogsRequest._() : super();
  factory ClearLogsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClearLogsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClearLogsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClearLogsRequest clone() => ClearLogsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClearLogsRequest copyWith(void Function(ClearLogsRequest) updates) => super.copyWith((message) => updates(message as ClearLogsRequest)) as ClearLogsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClearLogsRequest create() => ClearLogsRequest._();
  ClearLogsRequest createEmptyInstance() => create();
  static $pb.PbList<ClearLogsRequest> createRepeated() => $pb.PbList<ClearLogsRequest>();
  @$core.pragma('dart2js:noInline')
  static ClearLogsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearLogsRequest>(create);
  static ClearLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);
}

class ClearLogsResponse extends $pb.GeneratedMessage {
  factory ClearLogsResponse({
    SoraError? error,
  }) {
    final $result = create();
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ClearLogsResponse._() : super();
  factory ClearLogsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClearLogsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClearLogsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClearLogsResponse clone() => ClearLogsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClearLogsResponse copyWith(void Function(ClearLogsResponse) updates) => super.copyWith((message) => updates(message as ClearLogsResponse)) as ClearLogsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClearLogsResponse create() => ClearLogsResponse._();
  ClearLogsResponse createEmptyInstance() => create();
  static $pb.PbList<ClearLogsResponse> createRepeated() => $pb.PbList<ClearLogsResponse>();
  @$core.pragma('dart2js:noInline')
  static ClearLogsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearLogsResponse>(create);
  static ClearLogsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => clearField(1);
  @$pb.TagNumber(1)
  SoraError ensureError() => $_ensure(0);
}

/// LogSettings change at runtime and apply to the next entry.
class LogSettings extends $pb.GeneratedMessage {
  factory LogSettings({
    LogLevel? captureLevel,
    $core.bool? recordDestinations,
    $core.int? maxEntries,
    $core.int? maxBytes,
  }) {
    final $result = create();
    if (captureLevel != null) {
      $result.captureLevel = captureLevel;
    }
    if (recordDestinations != null) {
      $result.recordDestinations = recordDestinations;
    }
    if (maxEntries != null) {
      $result.maxEntries = maxEntries;
    }
    if (maxBytes != null) {
      $result.maxBytes = maxBytes;
    }
    return $result;
  }
  LogSettings._() : super();
  factory LogSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory LogSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..e<LogLevel>(1, _omitFieldNames ? '' : 'captureLevel', $pb.PbFieldType.OE, defaultOrMaker: LogLevel.LOG_LEVEL_UNSPECIFIED, valueOf: LogLevel.valueOf, enumValues: LogLevel.values)
    ..aOB(2, _omitFieldNames ? '' : 'recordDestinations')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'maxEntries', $pb.PbFieldType.OU3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'maxBytes', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  LogSettings clone() => LogSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  LogSettings copyWith(void Function(LogSettings) updates) => super.copyWith((message) => updates(message as LogSettings)) as LogSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogSettings create() => LogSettings._();
  LogSettings createEmptyInstance() => create();
  static $pb.PbList<LogSettings> createRepeated() => $pb.PbList<LogSettings>();
  @$core.pragma('dart2js:noInline')
  static LogSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogSettings>(create);
  static LogSettings? _defaultInstance;

  /// Entries below it are dropped before they are stored. Engines run at debug
  /// level, so a change takes effect at once, without a reconnect.
  @$pb.TagNumber(1)
  LogLevel get captureLevel => $_getN(0);
  @$pb.TagNumber(1)
  set captureLevel(LogLevel v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasCaptureLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaptureLevel() => clearField(1);

  /// Keeps the hosts and addresses of visited sites in engine messages.
  @$pb.TagNumber(2)
  $core.bool get recordDestinations => $_getBF(1);
  @$pb.TagNumber(2)
  set recordDestinations($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRecordDestinations() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecordDestinations() => clearField(2);

  /// Bounds of the record; 0 keeps the core default.
  @$pb.TagNumber(3)
  $core.int get maxEntries => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxEntries($core.int v) { $_setUnsignedInt32(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMaxEntries() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxEntries() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxBytes => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxBytes($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMaxBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxBytes() => clearField(4);
}

class GetLogSettingsRequest extends $pb.GeneratedMessage {
  factory GetLogSettingsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  GetLogSettingsRequest._() : super();
  factory GetLogSettingsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetLogSettingsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLogSettingsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetLogSettingsRequest clone() => GetLogSettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetLogSettingsRequest copyWith(void Function(GetLogSettingsRequest) updates) => super.copyWith((message) => updates(message as GetLogSettingsRequest)) as GetLogSettingsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLogSettingsRequest create() => GetLogSettingsRequest._();
  GetLogSettingsRequest createEmptyInstance() => create();
  static $pb.PbList<GetLogSettingsRequest> createRepeated() => $pb.PbList<GetLogSettingsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetLogSettingsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLogSettingsRequest>(create);
  static GetLogSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);
}

class GetLogSettingsResponse extends $pb.GeneratedMessage {
  factory GetLogSettingsResponse({
    LogSettings? settings,
    SoraError? error,
  }) {
    final $result = create();
    if (settings != null) {
      $result.settings = settings;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetLogSettingsResponse._() : super();
  factory GetLogSettingsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetLogSettingsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLogSettingsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<LogSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetLogSettingsResponse clone() => GetLogSettingsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetLogSettingsResponse copyWith(void Function(GetLogSettingsResponse) updates) => super.copyWith((message) => updates(message as GetLogSettingsResponse)) as GetLogSettingsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetLogSettingsResponse create() => GetLogSettingsResponse._();
  GetLogSettingsResponse createEmptyInstance() => create();
  static $pb.PbList<GetLogSettingsResponse> createRepeated() => $pb.PbList<GetLogSettingsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetLogSettingsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetLogSettingsResponse>(create);
  static GetLogSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(LogSettings v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => clearField(1);
  @$pb.TagNumber(1)
  LogSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class SetLogSettingsRequest extends $pb.GeneratedMessage {
  factory SetLogSettingsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogSettings? settings,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (settings != null) {
      $result.settings = settings;
    }
    return $result;
  }
  SetLogSettingsRequest._() : super();
  factory SetLogSettingsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetLogSettingsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetLogSettingsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogSettings>(3, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetLogSettingsRequest clone() => SetLogSettingsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetLogSettingsRequest copyWith(void Function(SetLogSettingsRequest) updates) => super.copyWith((message) => updates(message as SetLogSettingsRequest)) as SetLogSettingsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetLogSettingsRequest create() => SetLogSettingsRequest._();
  SetLogSettingsRequest createEmptyInstance() => create();
  static $pb.PbList<SetLogSettingsRequest> createRepeated() => $pb.PbList<SetLogSettingsRequest>();
  @$core.pragma('dart2js:noInline')
  static SetLogSettingsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetLogSettingsRequest>(create);
  static SetLogSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  LogSettings get settings => $_getN(2);
  @$pb.TagNumber(3)
  set settings(LogSettings v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSettings() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettings() => clearField(3);
  @$pb.TagNumber(3)
  LogSettings ensureSettings() => $_ensure(2);
}

class SetLogSettingsResponse extends $pb.GeneratedMessage {
  factory SetLogSettingsResponse({
    LogSettings? settings,
    SoraError? error,
  }) {
    final $result = create();
    if (settings != null) {
      $result.settings = settings;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  SetLogSettingsResponse._() : super();
  factory SetLogSettingsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SetLogSettingsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetLogSettingsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<LogSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SetLogSettingsResponse clone() => SetLogSettingsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SetLogSettingsResponse copyWith(void Function(SetLogSettingsResponse) updates) => super.copyWith((message) => updates(message as SetLogSettingsResponse)) as SetLogSettingsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SetLogSettingsResponse create() => SetLogSettingsResponse._();
  SetLogSettingsResponse createEmptyInstance() => create();
  static $pb.PbList<SetLogSettingsResponse> createRepeated() => $pb.PbList<SetLogSettingsResponse>();
  @$core.pragma('dart2js:noInline')
  static SetLogSettingsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SetLogSettingsResponse>(create);
  static SetLogSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(LogSettings v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => clearField(1);
  @$pb.TagNumber(1)
  LogSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// Connection is one live connection of the session.
class Connection extends $pb.GeneratedMessage {
  factory Connection({
    $core.String? id,
    $core.String? network,
    $core.String? host,
    $core.int? port,
    $core.String? process,
    $core.String? rule,
    $core.Iterable<$core.String>? chain,
    $fixnum.Int64? upload,
    $fixnum.Int64? download,
    $2.Timestamp? start,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (network != null) {
      $result.network = network;
    }
    if (host != null) {
      $result.host = host;
    }
    if (port != null) {
      $result.port = port;
    }
    if (process != null) {
      $result.process = process;
    }
    if (rule != null) {
      $result.rule = rule;
    }
    if (chain != null) {
      $result.chain.addAll(chain);
    }
    if (upload != null) {
      $result.upload = upload;
    }
    if (download != null) {
      $result.download = download;
    }
    if (start != null) {
      $result.start = start;
    }
    return $result;
  }
  Connection._() : super();
  factory Connection.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Connection.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Connection', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'network')
    ..aOS(3, _omitFieldNames ? '' : 'host')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'port', $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'process')
    ..aOS(6, _omitFieldNames ? '' : 'rule')
    ..pPS(7, _omitFieldNames ? '' : 'chain')
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'upload', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'download', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(10, _omitFieldNames ? '' : 'start', subBuilder: $2.Timestamp.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Connection clone() => Connection()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Connection copyWith(void Function(Connection) updates) => super.copyWith((message) => updates(message as Connection)) as Connection;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Connection create() => Connection._();
  Connection createEmptyInstance() => create();
  static $pb.PbList<Connection> createRepeated() => $pb.PbList<Connection>();
  @$core.pragma('dart2js:noInline')
  static Connection getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Connection>(create);
  static Connection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// tcp or udp.
  @$pb.TagNumber(2)
  $core.String get network => $_getSZ(1);
  @$pb.TagNumber(2)
  set network($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasNetwork() => $_has(1);
  @$pb.TagNumber(2)
  void clearNetwork() => clearField(2);

  /// What the application asked for: a name where one was seen, else an address.
  @$pb.TagNumber(3)
  $core.String get host => $_getSZ(2);
  @$pb.TagNumber(3)
  set host($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasHost() => $_has(2);
  @$pb.TagNumber(3)
  void clearHost() => clearField(3);

  @$pb.TagNumber(4)
  $core.int get port => $_getIZ(3);
  @$pb.TagNumber(4)
  set port($core.int v) { $_setUnsignedInt32(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearPort() => clearField(4);

  @$pb.TagNumber(5)
  $core.String get process => $_getSZ(4);
  @$pb.TagNumber(5)
  set process($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasProcess() => $_has(4);
  @$pb.TagNumber(5)
  void clearProcess() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get rule => $_getSZ(5);
  @$pb.TagNumber(6)
  set rule($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasRule() => $_has(5);
  @$pb.TagNumber(6)
  void clearRule() => clearField(6);

  /// From the group the rule chose to the outbound that carried it.
  @$pb.TagNumber(7)
  $core.List<$core.String> get chain => $_getList(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get upload => $_getI64(7);
  @$pb.TagNumber(8)
  set upload($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasUpload() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpload() => clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get download => $_getI64(8);
  @$pb.TagNumber(9)
  set download($fixnum.Int64 v) { $_setInt64(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDownload() => $_has(8);
  @$pb.TagNumber(9)
  void clearDownload() => clearField(9);

  @$pb.TagNumber(10)
  $2.Timestamp get start => $_getN(9);
  @$pb.TagNumber(10)
  set start($2.Timestamp v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasStart() => $_has(9);
  @$pb.TagNumber(10)
  void clearStart() => clearField(10);
  @$pb.TagNumber(10)
  $2.Timestamp ensureStart() => $_ensure(9);
}

class ListConnectionsRequest extends $pb.GeneratedMessage {
  factory ListConnectionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? sessionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    return $result;
  }
  ListConnectionsRequest._() : super();
  factory ListConnectionsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListConnectionsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListConnectionsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ListConnectionsRequest clone() => ListConnectionsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ListConnectionsRequest copyWith(void Function(ListConnectionsRequest) updates) => super.copyWith((message) => updates(message as ListConnectionsRequest)) as ListConnectionsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest create() => ListConnectionsRequest._();
  ListConnectionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListConnectionsRequest> createRepeated() => $pb.PbList<ListConnectionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListConnectionsRequest>(create);
  static ListConnectionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);
}

class ListConnectionsResponse extends $pb.GeneratedMessage {
  factory ListConnectionsResponse({
    $core.Iterable<Connection>? connections,
    SoraError? error,
  }) {
    final $result = create();
    if (connections != null) {
      $result.connections.addAll(connections);
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ListConnectionsResponse._() : super();
  factory ListConnectionsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListConnectionsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListConnectionsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<Connection>(1, _omitFieldNames ? '' : 'connections', $pb.PbFieldType.PM, subBuilder: Connection.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ListConnectionsResponse clone() => ListConnectionsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ListConnectionsResponse copyWith(void Function(ListConnectionsResponse) updates) => super.copyWith((message) => updates(message as ListConnectionsResponse)) as ListConnectionsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse create() => ListConnectionsResponse._();
  ListConnectionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListConnectionsResponse> createRepeated() => $pb.PbList<ListConnectionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListConnectionsResponse>(create);
  static ListConnectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Connection> get connections => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class CloseConnectionRequest extends $pb.GeneratedMessage {
  factory CloseConnectionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? sessionId,
    $core.String? connectionId,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (sessionId != null) {
      $result.sessionId = sessionId;
    }
    if (connectionId != null) {
      $result.connectionId = connectionId;
    }
    return $result;
  }
  CloseConnectionRequest._() : super();
  factory CloseConnectionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CloseConnectionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CloseConnectionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOS(4, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CloseConnectionRequest clone() => CloseConnectionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CloseConnectionRequest copyWith(void Function(CloseConnectionRequest) updates) => super.copyWith((message) => updates(message as CloseConnectionRequest)) as CloseConnectionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseConnectionRequest create() => CloseConnectionRequest._();
  CloseConnectionRequest createEmptyInstance() => create();
  static $pb.PbList<CloseConnectionRequest> createRepeated() => $pb.PbList<CloseConnectionRequest>();
  @$core.pragma('dart2js:noInline')
  static CloseConnectionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CloseConnectionRequest>(create);
  static CloseConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get connectionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set connectionId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasConnectionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectionId() => clearField(4);
}

class CloseConnectionResponse extends $pb.GeneratedMessage {
  factory CloseConnectionResponse({
    SoraError? error,
  }) {
    final $result = create();
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  CloseConnectionResponse._() : super();
  factory CloseConnectionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory CloseConnectionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CloseConnectionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  CloseConnectionResponse clone() => CloseConnectionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  CloseConnectionResponse copyWith(void Function(CloseConnectionResponse) updates) => super.copyWith((message) => updates(message as CloseConnectionResponse)) as CloseConnectionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloseConnectionResponse create() => CloseConnectionResponse._();
  CloseConnectionResponse createEmptyInstance() => create();
  static $pb.PbList<CloseConnectionResponse> createRepeated() => $pb.PbList<CloseConnectionResponse>();
  @$core.pragma('dart2js:noInline')
  static CloseConnectionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CloseConnectionResponse>(create);
  static CloseConnectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => clearField(1);
  @$pb.TagNumber(1)
  SoraError ensureError() => $_ensure(0);
}

/// SubscriptionSettings are what the user chooses for one subscription.
class SubscriptionSettings extends $pb.GeneratedMessage {
  factory SubscriptionSettings({
    $core.String? id,
    $core.String? url,
    $core.String? name,
    $core.String? userAgent,
    $core.bool? autoUpdate,
    $1.Duration? updateInterval,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (url != null) {
      $result.url = url;
    }
    if (name != null) {
      $result.name = name;
    }
    if (userAgent != null) {
      $result.userAgent = userAgent;
    }
    if (autoUpdate != null) {
      $result.autoUpdate = autoUpdate;
    }
    if (updateInterval != null) {
      $result.updateInterval = updateInterval;
    }
    return $result;
  }
  SubscriptionSettings._() : super();
  factory SubscriptionSettings.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SubscriptionSettings.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionSettings', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'userAgent')
    ..aOB(5, _omitFieldNames ? '' : 'autoUpdate')
    ..aOM<$1.Duration>(6, _omitFieldNames ? '' : 'updateInterval', subBuilder: $1.Duration.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SubscriptionSettings clone() => SubscriptionSettings()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SubscriptionSettings copyWith(void Function(SubscriptionSettings) updates) => super.copyWith((message) => updates(message as SubscriptionSettings)) as SubscriptionSettings;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionSettings create() => SubscriptionSettings._();
  SubscriptionSettings createEmptyInstance() => create();
  static $pb.PbList<SubscriptionSettings> createRepeated() => $pb.PbList<SubscriptionSettings>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionSettings getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionSettings>(create);
  static SubscriptionSettings? _defaultInstance;

  /// Empty on the first save; the core assigns one and answers with it.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// The https link. Required on the first save; empty on a later save keeps
  /// the stored link.
  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => clearField(2);

  /// Overrides the provider title in the list; empty shows the provider title.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => clearField(3);

  /// Empty sends the Sora User-Agent.
  @$pb.TagNumber(4)
  $core.String get userAgent => $_getSZ(3);
  @$pb.TagNumber(4)
  set userAgent($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasUserAgent() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserAgent() => clearField(4);

  @$pb.TagNumber(5)
  $core.bool get autoUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set autoUpdate($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAutoUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoUpdate() => clearField(5);

  /// Overrides the interval the provider asks for; unset follows the provider,
  /// and 24 hours when the provider did not say. At least one hour.
  @$pb.TagNumber(6)
  $1.Duration get updateInterval => $_getN(5);
  @$pb.TagNumber(6)
  set updateInterval($1.Duration v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasUpdateInterval() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdateInterval() => clearField(6);
  @$pb.TagNumber(6)
  $1.Duration ensureUpdateInterval() => $_ensure(5);
}

/// SubscriptionState is a subscription as the core holds it.
class SubscriptionState extends $pb.GeneratedMessage {
  factory SubscriptionState({
    SubscriptionSettings? settings,
    SubscriptionInfo? info,
    $core.Iterable<OutboundSpec>? outbounds,
    $2.Timestamp? lastUpdate,
    $2.Timestamp? nextUpdate,
    SoraError? lastError,
    $core.bool? updating,
    $core.bool? deleted,
    $core.String? displayName,
  }) {
    final $result = create();
    if (settings != null) {
      $result.settings = settings;
    }
    if (info != null) {
      $result.info = info;
    }
    if (outbounds != null) {
      $result.outbounds.addAll(outbounds);
    }
    if (lastUpdate != null) {
      $result.lastUpdate = lastUpdate;
    }
    if (nextUpdate != null) {
      $result.nextUpdate = nextUpdate;
    }
    if (lastError != null) {
      $result.lastError = lastError;
    }
    if (updating != null) {
      $result.updating = updating;
    }
    if (deleted != null) {
      $result.deleted = deleted;
    }
    if (displayName != null) {
      $result.displayName = displayName;
    }
    return $result;
  }
  SubscriptionState._() : super();
  factory SubscriptionState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SubscriptionState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionState', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SubscriptionSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: SubscriptionSettings.create)
    ..aOM<SubscriptionInfo>(2, _omitFieldNames ? '' : 'info', subBuilder: SubscriptionInfo.create)
    ..pc<OutboundSpec>(3, _omitFieldNames ? '' : 'outbounds', $pb.PbFieldType.PM, subBuilder: OutboundSpec.create)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'lastUpdate', subBuilder: $2.Timestamp.create)
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'nextUpdate', subBuilder: $2.Timestamp.create)
    ..aOM<SoraError>(6, _omitFieldNames ? '' : 'lastError', subBuilder: SoraError.create)
    ..aOB(7, _omitFieldNames ? '' : 'updating')
    ..aOB(8, _omitFieldNames ? '' : 'deleted')
    ..aOS(9, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SubscriptionState clone() => SubscriptionState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SubscriptionState copyWith(void Function(SubscriptionState) updates) => super.copyWith((message) => updates(message as SubscriptionState)) as SubscriptionState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SubscriptionState create() => SubscriptionState._();
  SubscriptionState createEmptyInstance() => create();
  static $pb.PbList<SubscriptionState> createRepeated() => $pb.PbList<SubscriptionState>();
  @$core.pragma('dart2js:noInline')
  static SubscriptionState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionState>(create);
  static SubscriptionState? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(SubscriptionSettings v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => clearField(1);
  @$pb.TagNumber(1)
  SubscriptionSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SubscriptionInfo get info => $_getN(1);
  @$pb.TagNumber(2)
  set info(SubscriptionInfo v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearInfo() => clearField(2);
  @$pb.TagNumber(2)
  SubscriptionInfo ensureInfo() => $_ensure(1);

  @$pb.TagNumber(3)
  $core.List<OutboundSpec> get outbounds => $_getList(2);

  @$pb.TagNumber(4)
  $2.Timestamp get lastUpdate => $_getN(3);
  @$pb.TagNumber(4)
  set lastUpdate($2.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasLastUpdate() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastUpdate() => clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureLastUpdate() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.Timestamp get nextUpdate => $_getN(4);
  @$pb.TagNumber(5)
  set nextUpdate($2.Timestamp v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasNextUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearNextUpdate() => clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureNextUpdate() => $_ensure(4);

  /// The failure of the last attempt; unset after a success.
  @$pb.TagNumber(6)
  SoraError get lastError => $_getN(5);
  @$pb.TagNumber(6)
  set lastError(SoraError v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasLastError() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastError() => clearField(6);
  @$pb.TagNumber(6)
  SoraError ensureLastError() => $_ensure(5);

  /// Whether a fetch is running right now.
  @$pb.TagNumber(7)
  $core.bool get updating => $_getBF(6);
  @$pb.TagNumber(7)
  set updating($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasUpdating() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdating() => clearField(7);

  /// Set on a watched state when the subscription was deleted.
  @$pb.TagNumber(8)
  $core.bool get deleted => $_getBF(7);
  @$pb.TagNumber(8)
  set deleted($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasDeleted() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeleted() => clearField(8);

  /// What the list shows: the user's name, else the provider's title, else the
  /// file name the provider sent, else the host of the link. Never empty.
  @$pb.TagNumber(9)
  $core.String get displayName => $_getSZ(8);
  @$pb.TagNumber(9)
  set displayName($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasDisplayName() => $_has(8);
  @$pb.TagNumber(9)
  void clearDisplayName() => clearField(9);
}

class SaveSubscriptionRequest extends $pb.GeneratedMessage {
  factory SaveSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    SubscriptionSettings? settings,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (settings != null) {
      $result.settings = settings;
    }
    return $result;
  }
  SaveSubscriptionRequest._() : super();
  factory SaveSubscriptionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SaveSubscriptionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveSubscriptionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<SubscriptionSettings>(3, _omitFieldNames ? '' : 'settings', subBuilder: SubscriptionSettings.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SaveSubscriptionRequest clone() => SaveSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SaveSubscriptionRequest copyWith(void Function(SaveSubscriptionRequest) updates) => super.copyWith((message) => updates(message as SaveSubscriptionRequest)) as SaveSubscriptionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionRequest create() => SaveSubscriptionRequest._();
  SaveSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<SaveSubscriptionRequest> createRepeated() => $pb.PbList<SaveSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SaveSubscriptionRequest>(create);
  static SaveSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  SubscriptionSettings get settings => $_getN(2);
  @$pb.TagNumber(3)
  set settings(SubscriptionSettings v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasSettings() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettings() => clearField(3);
  @$pb.TagNumber(3)
  SubscriptionSettings ensureSettings() => $_ensure(2);
}

class SaveSubscriptionResponse extends $pb.GeneratedMessage {
  factory SaveSubscriptionResponse({
    SubscriptionState? state,
    SoraError? error,
  }) {
    final $result = create();
    if (state != null) {
      $result.state = state;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  SaveSubscriptionResponse._() : super();
  factory SaveSubscriptionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory SaveSubscriptionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveSubscriptionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SubscriptionState>(1, _omitFieldNames ? '' : 'state', subBuilder: SubscriptionState.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  SaveSubscriptionResponse clone() => SaveSubscriptionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  SaveSubscriptionResponse copyWith(void Function(SaveSubscriptionResponse) updates) => super.copyWith((message) => updates(message as SaveSubscriptionResponse)) as SaveSubscriptionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionResponse create() => SaveSubscriptionResponse._();
  SaveSubscriptionResponse createEmptyInstance() => create();
  static $pb.PbList<SaveSubscriptionResponse> createRepeated() => $pb.PbList<SaveSubscriptionResponse>();
  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SaveSubscriptionResponse>(create);
  static SaveSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(SubscriptionState v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => clearField(1);
  @$pb.TagNumber(1)
  SubscriptionState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class ListSubscriptionsRequest extends $pb.GeneratedMessage {
  factory ListSubscriptionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  ListSubscriptionsRequest._() : super();
  factory ListSubscriptionsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListSubscriptionsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSubscriptionsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ListSubscriptionsRequest clone() => ListSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ListSubscriptionsRequest copyWith(void Function(ListSubscriptionsRequest) updates) => super.copyWith((message) => updates(message as ListSubscriptionsRequest)) as ListSubscriptionsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest create() => ListSubscriptionsRequest._();
  ListSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<ListSubscriptionsRequest> createRepeated() => $pb.PbList<ListSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsRequest>(create);
  static ListSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);
}

class ListSubscriptionsResponse extends $pb.GeneratedMessage {
  factory ListSubscriptionsResponse({
    $core.Iterable<SubscriptionState>? subscriptions,
    SoraError? error,
  }) {
    final $result = create();
    if (subscriptions != null) {
      $result.subscriptions.addAll(subscriptions);
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  ListSubscriptionsResponse._() : super();
  factory ListSubscriptionsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ListSubscriptionsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSubscriptionsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<SubscriptionState>(1, _omitFieldNames ? '' : 'subscriptions', $pb.PbFieldType.PM, subBuilder: SubscriptionState.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ListSubscriptionsResponse clone() => ListSubscriptionsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ListSubscriptionsResponse copyWith(void Function(ListSubscriptionsResponse) updates) => super.copyWith((message) => updates(message as ListSubscriptionsResponse)) as ListSubscriptionsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse create() => ListSubscriptionsResponse._();
  ListSubscriptionsResponse createEmptyInstance() => create();
  static $pb.PbList<ListSubscriptionsResponse> createRepeated() => $pb.PbList<ListSubscriptionsResponse>();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsResponse>(create);
  static ListSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<SubscriptionState> get subscriptions => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class DeleteSubscriptionRequest extends $pb.GeneratedMessage {
  factory DeleteSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  DeleteSubscriptionRequest._() : super();
  factory DeleteSubscriptionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSubscriptionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSubscriptionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSubscriptionRequest clone() => DeleteSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSubscriptionRequest copyWith(void Function(DeleteSubscriptionRequest) updates) => super.copyWith((message) => updates(message as DeleteSubscriptionRequest)) as DeleteSubscriptionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionRequest create() => DeleteSubscriptionRequest._();
  DeleteSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<DeleteSubscriptionRequest> createRepeated() => $pb.PbList<DeleteSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSubscriptionRequest>(create);
  static DeleteSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);
}

class DeleteSubscriptionResponse extends $pb.GeneratedMessage {
  factory DeleteSubscriptionResponse({
    SoraError? error,
  }) {
    final $result = create();
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  DeleteSubscriptionResponse._() : super();
  factory DeleteSubscriptionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DeleteSubscriptionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSubscriptionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DeleteSubscriptionResponse clone() => DeleteSubscriptionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DeleteSubscriptionResponse copyWith(void Function(DeleteSubscriptionResponse) updates) => super.copyWith((message) => updates(message as DeleteSubscriptionResponse)) as DeleteSubscriptionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionResponse create() => DeleteSubscriptionResponse._();
  DeleteSubscriptionResponse createEmptyInstance() => create();
  static $pb.PbList<DeleteSubscriptionResponse> createRepeated() => $pb.PbList<DeleteSubscriptionResponse>();
  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSubscriptionResponse>(create);
  static DeleteSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => clearField(1);
  @$pb.TagNumber(1)
  SoraError ensureError() => $_ensure(0);
}

class RefreshSubscriptionRequest extends $pb.GeneratedMessage {
  factory RefreshSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    if (id != null) {
      $result.id = id;
    }
    return $result;
  }
  RefreshSubscriptionRequest._() : super();
  factory RefreshSubscriptionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshSubscriptionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RefreshSubscriptionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshSubscriptionRequest clone() => RefreshSubscriptionRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshSubscriptionRequest copyWith(void Function(RefreshSubscriptionRequest) updates) => super.copyWith((message) => updates(message as RefreshSubscriptionRequest)) as RefreshSubscriptionRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionRequest create() => RefreshSubscriptionRequest._();
  RefreshSubscriptionRequest createEmptyInstance() => create();
  static $pb.PbList<RefreshSubscriptionRequest> createRepeated() => $pb.PbList<RefreshSubscriptionRequest>();
  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshSubscriptionRequest>(create);
  static RefreshSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => clearField(3);
}

class RefreshSubscriptionResponse extends $pb.GeneratedMessage {
  factory RefreshSubscriptionResponse({
    SubscriptionState? state,
    SoraError? error,
  }) {
    final $result = create();
    if (state != null) {
      $result.state = state;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  RefreshSubscriptionResponse._() : super();
  factory RefreshSubscriptionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RefreshSubscriptionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RefreshSubscriptionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<SubscriptionState>(1, _omitFieldNames ? '' : 'state', subBuilder: SubscriptionState.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RefreshSubscriptionResponse clone() => RefreshSubscriptionResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RefreshSubscriptionResponse copyWith(void Function(RefreshSubscriptionResponse) updates) => super.copyWith((message) => updates(message as RefreshSubscriptionResponse)) as RefreshSubscriptionResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionResponse create() => RefreshSubscriptionResponse._();
  RefreshSubscriptionResponse createEmptyInstance() => create();
  static $pb.PbList<RefreshSubscriptionResponse> createRepeated() => $pb.PbList<RefreshSubscriptionResponse>();
  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RefreshSubscriptionResponse>(create);
  static RefreshSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(SubscriptionState v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => clearField(1);
  @$pb.TagNumber(1)
  SubscriptionState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class WatchSubscriptionsRequest extends $pb.GeneratedMessage {
  factory WatchSubscriptionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    if (controlAuthenticator != null) {
      $result.controlAuthenticator = controlAuthenticator;
    }
    return $result;
  }
  WatchSubscriptionsRequest._() : super();
  factory WatchSubscriptionsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory WatchSubscriptionsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchSubscriptionsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  WatchSubscriptionsRequest clone() => WatchSubscriptionsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  WatchSubscriptionsRequest copyWith(void Function(WatchSubscriptionsRequest) updates) => super.copyWith((message) => updates(message as WatchSubscriptionsRequest)) as WatchSubscriptionsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WatchSubscriptionsRequest create() => WatchSubscriptionsRequest._();
  WatchSubscriptionsRequest createEmptyInstance() => create();
  static $pb.PbList<WatchSubscriptionsRequest> createRepeated() => $pb.PbList<WatchSubscriptionsRequest>();
  @$core.pragma('dart2js:noInline')
  static WatchSubscriptionsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchSubscriptionsRequest>(create);
  static WatchSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => clearField(2);
}

class GetAboutRequest extends $pb.GeneratedMessage {
  factory GetAboutRequest({
    ApiVersion? apiVersion,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    return $result;
  }
  GetAboutRequest._() : super();
  factory GetAboutRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAboutRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAboutRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAboutRequest clone() => GetAboutRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAboutRequest copyWith(void Function(GetAboutRequest) updates) => super.copyWith((message) => updates(message as GetAboutRequest)) as GetAboutRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAboutRequest create() => GetAboutRequest._();
  GetAboutRequest createEmptyInstance() => create();
  static $pb.PbList<GetAboutRequest> createRepeated() => $pb.PbList<GetAboutRequest>();
  @$core.pragma('dart2js:noInline')
  static GetAboutRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAboutRequest>(create);
  static GetAboutRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);
}

class GetAboutResponse extends $pb.GeneratedMessage {
  factory GetAboutResponse({
    About? about,
    SoraError? error,
  }) {
    final $result = create();
    if (about != null) {
      $result.about = about;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetAboutResponse._() : super();
  factory GetAboutResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetAboutResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAboutResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<About>(1, _omitFieldNames ? '' : 'about', subBuilder: About.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetAboutResponse clone() => GetAboutResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetAboutResponse copyWith(void Function(GetAboutResponse) updates) => super.copyWith((message) => updates(message as GetAboutResponse)) as GetAboutResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetAboutResponse create() => GetAboutResponse._();
  GetAboutResponse createEmptyInstance() => create();
  static $pb.PbList<GetAboutResponse> createRepeated() => $pb.PbList<GetAboutResponse>();
  @$core.pragma('dart2js:noInline')
  static GetAboutResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAboutResponse>(create);
  static GetAboutResponse? _defaultInstance;

  @$pb.TagNumber(1)
  About get about => $_getN(0);
  @$pb.TagNumber(1)
  set about(About v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasAbout() => $_has(0);
  @$pb.TagNumber(1)
  void clearAbout() => clearField(1);
  @$pb.TagNumber(1)
  About ensureAbout() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// About describes the running core.
class About extends $pb.GeneratedMessage {
  factory About({
    $core.String? coreVersion,
    $core.String? commit,
    $2.Timestamp? commitTime,
    ApiVersion? contract,
    $core.String? platform,
    $core.String? goVersion,
    $core.Iterable<EngineBuild>? engines,
    $core.String? license,
    $core.String? sourceUrl,
  }) {
    final $result = create();
    if (coreVersion != null) {
      $result.coreVersion = coreVersion;
    }
    if (commit != null) {
      $result.commit = commit;
    }
    if (commitTime != null) {
      $result.commitTime = commitTime;
    }
    if (contract != null) {
      $result.contract = contract;
    }
    if (platform != null) {
      $result.platform = platform;
    }
    if (goVersion != null) {
      $result.goVersion = goVersion;
    }
    if (engines != null) {
      $result.engines.addAll(engines);
    }
    if (license != null) {
      $result.license = license;
    }
    if (sourceUrl != null) {
      $result.sourceUrl = sourceUrl;
    }
    return $result;
  }
  About._() : super();
  factory About.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory About.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'About', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'coreVersion')
    ..aOS(2, _omitFieldNames ? '' : 'commit')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'commitTime', subBuilder: $2.Timestamp.create)
    ..aOM<ApiVersion>(4, _omitFieldNames ? '' : 'contract', subBuilder: ApiVersion.create)
    ..aOS(5, _omitFieldNames ? '' : 'platform')
    ..aOS(6, _omitFieldNames ? '' : 'goVersion')
    ..pc<EngineBuild>(7, _omitFieldNames ? '' : 'engines', $pb.PbFieldType.PM, subBuilder: EngineBuild.create)
    ..aOS(8, _omitFieldNames ? '' : 'license')
    ..aOS(9, _omitFieldNames ? '' : 'sourceUrl')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  About clone() => About()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  About copyWith(void Function(About) updates) => super.copyWith((message) => updates(message as About)) as About;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static About create() => About._();
  About createEmptyInstance() => create();
  static $pb.PbList<About> createRepeated() => $pb.PbList<About>();
  @$core.pragma('dart2js:noInline')
  static About getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<About>(create);
  static About? _defaultInstance;

  /// The release version, or "dev" for a build that was not stamped.
  @$pb.TagNumber(1)
  $core.String get coreVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set coreVersion($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCoreVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreVersion() => clearField(1);

  /// The commit the core was built from and when, where the build recorded it.
  @$pb.TagNumber(2)
  $core.String get commit => $_getSZ(1);
  @$pb.TagNumber(2)
  set commit($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => clearField(2);

  @$pb.TagNumber(3)
  $2.Timestamp get commitTime => $_getN(2);
  @$pb.TagNumber(3)
  set commitTime($2.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasCommitTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommitTime() => clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureCommitTime() => $_ensure(2);

  /// The contract the core serves.
  @$pb.TagNumber(4)
  ApiVersion get contract => $_getN(3);
  @$pb.TagNumber(4)
  set contract(ApiVersion v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasContract() => $_has(3);
  @$pb.TagNumber(4)
  void clearContract() => clearField(4);
  @$pb.TagNumber(4)
  ApiVersion ensureContract() => $_ensure(3);

  /// For example "linux/amd64".
  @$pb.TagNumber(5)
  $core.String get platform => $_getSZ(4);
  @$pb.TagNumber(5)
  set platform($core.String v) { $_setString(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlatform() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get goVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set goVersion($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasGoVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearGoVersion() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<EngineBuild> get engines => $_getList(6);

  /// SPDX identifier.
  @$pb.TagNumber(8)
  $core.String get license => $_getSZ(7);
  @$pb.TagNumber(8)
  set license($core.String v) { $_setString(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasLicense() => $_has(7);
  @$pb.TagNumber(8)
  void clearLicense() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get sourceUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set sourceUrl($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasSourceUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearSourceUrl() => clearField(9);
}

/// EngineBuild is one engine as this machine has it.
class EngineBuild extends $pb.GeneratedMessage {
  factory EngineBuild({
    $core.String? kind,
    $core.bool? installed,
    $core.String? version,
  }) {
    final $result = create();
    if (kind != null) {
      $result.kind = kind;
    }
    if (installed != null) {
      $result.installed = installed;
    }
    if (version != null) {
      $result.version = version;
    }
    return $result;
  }
  EngineBuild._() : super();
  factory EngineBuild.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EngineBuild.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EngineBuild', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOB(2, _omitFieldNames ? '' : 'installed')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EngineBuild clone() => EngineBuild()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EngineBuild copyWith(void Function(EngineBuild) updates) => super.copyWith((message) => updates(message as EngineBuild)) as EngineBuild;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EngineBuild create() => EngineBuild._();
  EngineBuild createEmptyInstance() => create();
  static $pb.PbList<EngineBuild> createRepeated() => $pb.PbList<EngineBuild>();
  @$core.pragma('dart2js:noInline')
  static EngineBuild getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EngineBuild>(create);
  static EngineBuild? _defaultInstance;

  /// sing-box, xray or mihomo.
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get installed => $_getBF(1);
  @$pb.TagNumber(2)
  set installed($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInstalled() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstalled() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => clearField(3);
}

class GetRoutingPresetsRequest extends $pb.GeneratedMessage {
  factory GetRoutingPresetsRequest({
    ApiVersion? apiVersion,
  }) {
    final $result = create();
    if (apiVersion != null) {
      $result.apiVersion = apiVersion;
    }
    return $result;
  }
  GetRoutingPresetsRequest._() : super();
  factory GetRoutingPresetsRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetRoutingPresetsRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetRoutingPresetsRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetRoutingPresetsRequest clone() => GetRoutingPresetsRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetRoutingPresetsRequest copyWith(void Function(GetRoutingPresetsRequest) updates) => super.copyWith((message) => updates(message as GetRoutingPresetsRequest)) as GetRoutingPresetsRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsRequest create() => GetRoutingPresetsRequest._();
  GetRoutingPresetsRequest createEmptyInstance() => create();
  static $pb.PbList<GetRoutingPresetsRequest> createRepeated() => $pb.PbList<GetRoutingPresetsRequest>();
  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRoutingPresetsRequest>(create);
  static GetRoutingPresetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);
}

class GetRoutingPresetsResponse extends $pb.GeneratedMessage {
  factory GetRoutingPresetsResponse({
    $core.Iterable<RoutingPreset>? presets,
    SoraError? error,
  }) {
    final $result = create();
    if (presets != null) {
      $result.presets.addAll(presets);
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  GetRoutingPresetsResponse._() : super();
  factory GetRoutingPresetsResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GetRoutingPresetsResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetRoutingPresetsResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<RoutingPreset>(1, _omitFieldNames ? '' : 'presets', $pb.PbFieldType.PM, subBuilder: RoutingPreset.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GetRoutingPresetsResponse clone() => GetRoutingPresetsResponse()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GetRoutingPresetsResponse copyWith(void Function(GetRoutingPresetsResponse) updates) => super.copyWith((message) => updates(message as GetRoutingPresetsResponse)) as GetRoutingPresetsResponse;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsResponse create() => GetRoutingPresetsResponse._();
  GetRoutingPresetsResponse createEmptyInstance() => create();
  static $pb.PbList<GetRoutingPresetsResponse> createRepeated() => $pb.PbList<GetRoutingPresetsResponse>();
  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetRoutingPresetsResponse>(create);
  static GetRoutingPresetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<RoutingPreset> get presets => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// RoutingPreset is one preset; the interface names it by id in its own words.
class RoutingPreset extends $pb.GeneratedMessage {
  factory RoutingPreset({
    $core.String? id,
    $core.Iterable<$core.String>? direct,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (direct != null) {
      $result.direct.addAll(direct);
    }
    return $result;
  }
  RoutingPreset._() : super();
  factory RoutingPreset.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory RoutingPreset.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingPreset', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPS(2, _omitFieldNames ? '' : 'direct')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  RoutingPreset clone() => RoutingPreset()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  RoutingPreset copyWith(void Function(RoutingPreset) updates) => super.copyWith((message) => updates(message as RoutingPreset)) as RoutingPreset;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RoutingPreset create() => RoutingPreset._();
  RoutingPreset createEmptyInstance() => create();
  static $pb.PbList<RoutingPreset> createRepeated() => $pb.PbList<RoutingPreset>();
  @$core.pragma('dart2js:noInline')
  static RoutingPreset getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingPreset>(create);
  static RoutingPreset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  /// Destinations sent direct, in the destination form of RoutingRule, for
  /// example "geosite:category-ru" or "geoip:ru".
  @$pb.TagNumber(2)
  $core.List<$core.String> get direct => $_getList(1);
}

/// BypassStrategy is how zapret reshapes a handshake. Positions are a number
/// of bytes, negative from the end, or a marker (method, host, endhost, sld,
/// midsld, endsld, sniext) with an optional +N or -N.
class BypassStrategy extends $pb.GeneratedMessage {
  factory BypassStrategy({
    $core.Iterable<$core.String>? splitPos,
    $core.bool? disorder,
    $core.bool? oob,
    $core.String? tlsRecord,
    $core.bool? hostCase,
    $core.bool? domainCase,
    $core.bool? methodEol,
  }) {
    final $result = create();
    if (splitPos != null) {
      $result.splitPos.addAll(splitPos);
    }
    if (disorder != null) {
      $result.disorder = disorder;
    }
    if (oob != null) {
      $result.oob = oob;
    }
    if (tlsRecord != null) {
      $result.tlsRecord = tlsRecord;
    }
    if (hostCase != null) {
      $result.hostCase = hostCase;
    }
    if (domainCase != null) {
      $result.domainCase = domainCase;
    }
    if (methodEol != null) {
      $result.methodEol = methodEol;
    }
    return $result;
  }
  BypassStrategy._() : super();
  factory BypassStrategy.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory BypassStrategy.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassStrategy', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'splitPos')
    ..aOB(2, _omitFieldNames ? '' : 'disorder')
    ..aOB(3, _omitFieldNames ? '' : 'oob')
    ..aOS(4, _omitFieldNames ? '' : 'tlsRecord')
    ..aOB(5, _omitFieldNames ? '' : 'hostCase')
    ..aOB(6, _omitFieldNames ? '' : 'domainCase')
    ..aOB(7, _omitFieldNames ? '' : 'methodEol')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  BypassStrategy clone() => BypassStrategy()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  BypassStrategy copyWith(void Function(BypassStrategy) updates) => super.copyWith((message) => updates(message as BypassStrategy)) as BypassStrategy;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BypassStrategy create() => BypassStrategy._();
  BypassStrategy createEmptyInstance() => create();
  static $pb.PbList<BypassStrategy> createRepeated() => $pb.PbList<BypassStrategy>();
  @$core.pragma('dart2js:noInline')
  static BypassStrategy getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BypassStrategy>(create);
  static BypassStrategy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.String> get splitPos => $_getList(0);

  /// Sends the second part of a split first.
  @$pb.TagNumber(2)
  $core.bool get disorder => $_getBF(1);
  @$pb.TagNumber(2)
  set disorder($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasDisorder() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisorder() => clearField(2);

  /// Sends an out-of-band byte with the split.
  @$pb.TagNumber(3)
  $core.bool get oob => $_getBF(2);
  @$pb.TagNumber(3)
  set oob($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasOob() => $_has(2);
  @$pb.TagNumber(3)
  void clearOob() => clearField(3);

  /// Splits the TLS ClientHello into two records at this position.
  @$pb.TagNumber(4)
  $core.String get tlsRecord => $_getSZ(3);
  @$pb.TagNumber(4)
  set tlsRecord($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasTlsRecord() => $_has(3);
  @$pb.TagNumber(4)
  void clearTlsRecord() => clearField(4);

  /// Reshape plain HTTP requests.
  @$pb.TagNumber(5)
  $core.bool get hostCase => $_getBF(4);
  @$pb.TagNumber(5)
  set hostCase($core.bool v) { $_setBool(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasHostCase() => $_has(4);
  @$pb.TagNumber(5)
  void clearHostCase() => clearField(5);

  @$pb.TagNumber(6)
  $core.bool get domainCase => $_getBF(5);
  @$pb.TagNumber(6)
  set domainCase($core.bool v) { $_setBool(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasDomainCase() => $_has(5);
  @$pb.TagNumber(6)
  void clearDomainCase() => clearField(6);

  @$pb.TagNumber(7)
  $core.bool get methodEol => $_getBF(6);
  @$pb.TagNumber(7)
  set methodEol($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMethodEol() => $_has(6);
  @$pb.TagNumber(7)
  void clearMethodEol() => clearField(7);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
