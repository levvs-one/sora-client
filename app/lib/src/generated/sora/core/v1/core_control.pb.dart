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

import '../../../google/protobuf/duration.pb.dart' as $2;
import '../../../google/protobuf/timestamp.pb.dart' as $1;
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
    $1.Timestamp? changedAt,
    $2.Duration? retryAfter,
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
    ..aOM<$1.Timestamp>(4, _omitFieldNames ? '' : 'changedAt', subBuilder: $1.Timestamp.create)
    ..aOM<$2.Duration>(5, _omitFieldNames ? '' : 'retryAfter', subBuilder: $2.Duration.create)
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
  $1.Timestamp get changedAt => $_getN(3);
  @$pb.TagNumber(4)
  set changedAt($1.Timestamp v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasChangedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearChangedAt() => clearField(4);
  @$pb.TagNumber(4)
  $1.Timestamp ensureChangedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.Duration get retryAfter => $_getN(4);
  @$pb.TagNumber(5)
  set retryAfter($2.Duration v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasRetryAfter() => $_has(4);
  @$pb.TagNumber(5)
  void clearRetryAfter() => clearField(5);
  @$pb.TagNumber(5)
  $2.Duration ensureRetryAfter() => $_ensure(4);
}

enum CoreEvent_Payload {
  stateChanged, 
  statsTick, 
  bypassStrategyChanged, 
  probeResult, 
  logBatch, 
  error, 
  notSet
}

class CoreEvent extends $pb.GeneratedMessage {
  factory CoreEvent({
    $fixnum.Int64? sequence,
    $core.String? sessionId,
    $1.Timestamp? emittedAt,
    StateChanged? stateChanged,
    StatsTick? statsTick,
    BypassStrategyChanged? bypassStrategyChanged,
    ProbeResult? probeResult,
    LogBatch? logBatch,
    SoraError? error,
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
    0 : CoreEvent_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CoreEvent', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..oo(0, [4, 5, 6, 7, 8, 9])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$1.Timestamp>(3, _omitFieldNames ? '' : 'emittedAt', subBuilder: $1.Timestamp.create)
    ..aOM<StateChanged>(4, _omitFieldNames ? '' : 'stateChanged', subBuilder: StateChanged.create)
    ..aOM<StatsTick>(5, _omitFieldNames ? '' : 'statsTick', subBuilder: StatsTick.create)
    ..aOM<BypassStrategyChanged>(6, _omitFieldNames ? '' : 'bypassStrategyChanged', subBuilder: BypassStrategyChanged.create)
    ..aOM<ProbeResult>(7, _omitFieldNames ? '' : 'probeResult', subBuilder: ProbeResult.create)
    ..aOM<LogBatch>(8, _omitFieldNames ? '' : 'logBatch', subBuilder: LogBatch.create)
    ..aOM<SoraError>(9, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
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
  $1.Timestamp get emittedAt => $_getN(2);
  @$pb.TagNumber(3)
  set emittedAt($1.Timestamp v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasEmittedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmittedAt() => clearField(3);
  @$pb.TagNumber(3)
  $1.Timestamp ensureEmittedAt() => $_ensure(2);

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
    return $result;
  }
  FetchSubscriptionRequest._() : super();
  factory FetchSubscriptionRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FetchSubscriptionRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'reference')
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
}

class FetchSubscriptionResponse extends $pb.GeneratedMessage {
  factory FetchSubscriptionResponse({
    $core.Iterable<OutboundSpec>? outbounds,
    SoraError? error,
  }) {
    final $result = create();
    if (outbounds != null) {
      $result.outbounds.addAll(outbounds);
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  FetchSubscriptionResponse._() : super();
  factory FetchSubscriptionResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory FetchSubscriptionResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..pc<OutboundSpec>(1, _omitFieldNames ? '' : 'outbounds', $pb.PbFieldType.PM, subBuilder: OutboundSpec.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
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
}

class ProbeServersRequest extends $pb.GeneratedMessage {
  factory ProbeServersRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.Iterable<Endpoint>? endpoints,
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
    return $result;
  }
  ProbeServersRequest._() : super();
  factory ProbeServersRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ProbeServersRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeServersRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.create)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..pc<Endpoint>(3, _omitFieldNames ? '' : 'endpoints', $pb.PbFieldType.PM, subBuilder: Endpoint.create)
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

  @$pb.TagNumber(3)
  $core.List<Endpoint> get endpoints => $_getList(2);
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
  }) {
    final $result = create();
    if (negotiatedVersion != null) {
      $result.negotiatedVersion = negotiatedVersion;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  HandshakeResponse._() : super();
  factory HandshakeResponse.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory HandshakeResponse.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'), createEmptyInstance: create)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'negotiatedVersion', subBuilder: ApiVersion.create)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.create)
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
}

class SoraError extends $pb.GeneratedMessage {
  factory SoraError({
    SoraErrorCode? code,
    $core.String? userMessageKey,
    $core.String? detailRedacted,
    $core.bool? retryable,
    $core.String? requestId,
    $2.Duration? retryAfter,
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
    ..aOM<$2.Duration>(6, _omitFieldNames ? '' : 'retryAfter', subBuilder: $2.Duration.create)
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
  $2.Duration get retryAfter => $_getN(5);
  @$pb.TagNumber(6)
  set retryAfter($2.Duration v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasRetryAfter() => $_has(5);
  @$pb.TagNumber(6)
  void clearRetryAfter() => clearField(6);
  @$pb.TagNumber(6)
  $2.Duration ensureRetryAfter() => $_ensure(5);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
