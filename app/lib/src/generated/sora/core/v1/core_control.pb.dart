// This is a generated file - do not edit.
//
// Generated from sora/core/v1/core_control.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;
import 'package:protobuf/well_known_types/google/protobuf/duration.pb.dart' as $1;
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart' as $2;

import 'core_control.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'core_control.pbenum.dart';

class ApiVersion extends $pb.GeneratedMessage {
  factory ApiVersion({
    $core.int? major,
    $core.int? minor,
    $core.int? minSupportedMinor,
    $core.Iterable<$core.String>? capabilities,
  }) {
    final result = ApiVersion._();
    if (major != null) result.major = major;
    if (minor != null) result.minor = minor;
    if (minSupportedMinor != null) result.minSupportedMinor = minSupportedMinor;
    if (capabilities != null) result.capabilities.addAll(capabilities);
    return result;
  }

  ApiVersion._();

  factory ApiVersion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApiVersion()..mergeFromBuffer(data, registry);
  factory ApiVersion.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ApiVersion()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApiVersion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ApiVersion.$_createMessage)
    ..aI(1, _omitFieldNames ? '' : 'major', fieldType: $pb.PbFieldType.OU3)
    ..aI(2, _omitFieldNames ? '' : 'minor', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'minSupportedMinor', fieldType: $pb.PbFieldType.OU3)
    ..pPS(4, _omitFieldNames ? '' : 'capabilities')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiVersion clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ApiVersion copyWith(void Function(ApiVersion) updates) =>
      super.copyWith((message) => updates(message as ApiVersion)) as ApiVersion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ApiVersion() / ApiVersion.new instead')
  static ApiVersion create() => ApiVersion._();
  static $pb.GeneratedMessage $_createMessage() => ApiVersion._();
  @$core.override
  ApiVersion createEmptyInstance() => ApiVersion._();
  @$core.pragma('dart2js:noInline')
  static ApiVersion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApiVersion>(ApiVersion.$_createMessage);
  static ApiVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get major => $_getIZ(0);
  @$pb.TagNumber(1)
  set major($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMajor() => $_has(0);
  @$pb.TagNumber(1)
  void clearMajor() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get minor => $_getIZ(1);
  @$pb.TagNumber(2)
  set minor($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMinor() => $_has(1);
  @$pb.TagNumber(2)
  void clearMinor() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get minSupportedMinor => $_getIZ(2);
  @$pb.TagNumber(3)
  set minSupportedMinor($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMinSupportedMinor() => $_has(2);
  @$pb.TagNumber(3)
  void clearMinSupportedMinor() => $_clearField(3);

  @$pb.TagNumber(4)
  $pb.PbList<$core.String> get capabilities => $_getList(3);
}

class ConnectRequest extends $pb.GeneratedMessage {
  factory ConnectRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
    SessionPlan? sessionPlan,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = ConnectRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (sessionId != null) result.sessionId = sessionId;
    if (sessionPlan != null) result.sessionPlan = sessionPlan;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  ConnectRequest._();

  factory ConnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromBuffer(data, registry);
  factory ConnectRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ConnectRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOM<SessionPlan>(4, _omitFieldNames ? '' : 'sessionPlan', subBuilder: SessionPlan.$_createMessage)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectRequest copyWith(void Function(ConnectRequest) updates) =>
      super.copyWith((message) => updates(message as ConnectRequest)) as ConnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectRequest() / ConnectRequest.new instead')
  static ConnectRequest create() => ConnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => ConnectRequest._();
  @$core.override
  ConnectRequest createEmptyInstance() => ConnectRequest._();
  @$core.pragma('dart2js:noInline')
  static ConnectRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectRequest>(ConnectRequest.$_createMessage);
  static ConnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  SessionPlan get sessionPlan => $_getN(3);
  @$pb.TagNumber(4)
  set sessionPlan(SessionPlan value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasSessionPlan() => $_has(3);
  @$pb.TagNumber(4)
  void clearSessionPlan() => $_clearField(4);
  @$pb.TagNumber(4)
  SessionPlan ensureSessionPlan() => $_ensure(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get controlAuthenticator => $_getN(4);
  @$pb.TagNumber(5)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasControlAuthenticator() => $_has(4);
  @$pb.TagNumber(5)
  void clearControlAuthenticator() => $_clearField(5);
}

class ConnectResponse extends $pb.GeneratedMessage {
  factory ConnectResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final result = ConnectResponse._();
    if (status != null) result.status = status;
    if (error != null) result.error = error;
    return result;
  }

  ConnectResponse._();

  factory ConnectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectResponse()..mergeFromBuffer(data, registry);
  factory ConnectResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ConnectResponse.$_createMessage)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectResponse copyWith(void Function(ConnectResponse) updates) =>
      super.copyWith((message) => updates(message as ConnectResponse)) as ConnectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectResponse() / ConnectResponse.new instead')
  static ConnectResponse create() => ConnectResponse._();
  static $pb.GeneratedMessage $_createMessage() => ConnectResponse._();
  @$core.override
  ConnectResponse createEmptyInstance() => ConnectResponse._();
  @$core.pragma('dart2js:noInline')
  static ConnectResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectResponse>(ConnectResponse.$_createMessage);
  static ConnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = DisconnectRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (sessionId != null) result.sessionId = sessionId;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  DisconnectRequest._();

  factory DisconnectRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisconnectRequest()..mergeFromBuffer(data, registry);
  factory DisconnectRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisconnectRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DisconnectRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DisconnectRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectRequest copyWith(void Function(DisconnectRequest) updates) =>
      super.copyWith((message) => updates(message as DisconnectRequest)) as DisconnectRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisconnectRequest() / DisconnectRequest.new instead')
  static DisconnectRequest create() => DisconnectRequest._();
  static $pb.GeneratedMessage $_createMessage() => DisconnectRequest._();
  @$core.override
  DisconnectRequest createEmptyInstance() => DisconnectRequest._();
  @$core.pragma('dart2js:noInline')
  static DisconnectRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisconnectRequest>(DisconnectRequest.$_createMessage);
  static DisconnectRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get controlAuthenticator => $_getN(3);
  @$pb.TagNumber(4)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasControlAuthenticator() => $_has(3);
  @$pb.TagNumber(4)
  void clearControlAuthenticator() => $_clearField(4);
}

class DisconnectResponse extends $pb.GeneratedMessage {
  factory DisconnectResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final result = DisconnectResponse._();
    if (status != null) result.status = status;
    if (error != null) result.error = error;
    return result;
  }

  DisconnectResponse._();

  factory DisconnectResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisconnectResponse()..mergeFromBuffer(data, registry);
  factory DisconnectResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DisconnectResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DisconnectResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DisconnectResponse.$_createMessage)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DisconnectResponse copyWith(void Function(DisconnectResponse) updates) =>
      super.copyWith((message) => updates(message as DisconnectResponse)) as DisconnectResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DisconnectResponse() / DisconnectResponse.new instead')
  static DisconnectResponse create() => DisconnectResponse._();
  static $pb.GeneratedMessage $_createMessage() => DisconnectResponse._();
  @$core.override
  DisconnectResponse createEmptyInstance() => DisconnectResponse._();
  @$core.pragma('dart2js:noInline')
  static DisconnectResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DisconnectResponse>(DisconnectResponse.$_createMessage);
  static DisconnectResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class GetStatusRequest extends $pb.GeneratedMessage {
  factory GetStatusRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
  }) {
    final result = GetStatusRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetStatusRequest._();

  factory GetStatusRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromBuffer(data, registry);
  factory GetStatusRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetStatusRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusRequest copyWith(void Function(GetStatusRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatusRequest)) as GetStatusRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatusRequest() / GetStatusRequest.new instead')
  static GetStatusRequest create() => GetStatusRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatusRequest._();
  @$core.override
  GetStatusRequest createEmptyInstance() => GetStatusRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatusRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusRequest>(GetStatusRequest.$_createMessage);
  static GetStatusRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);
}

class GetStatusResponse extends $pb.GeneratedMessage {
  factory GetStatusResponse({
    SessionStatus? status,
    SoraError? error,
  }) {
    final result = GetStatusResponse._();
    if (status != null) result.status = status;
    if (error != null) result.error = error;
    return result;
  }

  GetStatusResponse._();

  factory GetStatusResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusResponse()..mergeFromBuffer(data, registry);
  factory GetStatusResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatusResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatusResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetStatusResponse.$_createMessage)
    ..aOM<SessionStatus>(1, _omitFieldNames ? '' : 'status', subBuilder: SessionStatus.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatusResponse copyWith(void Function(GetStatusResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatusResponse)) as GetStatusResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatusResponse() / GetStatusResponse.new instead')
  static GetStatusResponse create() => GetStatusResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStatusResponse._();
  @$core.override
  GetStatusResponse createEmptyInstance() => GetStatusResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStatusResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatusResponse>(GetStatusResponse.$_createMessage);
  static GetStatusResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionStatus get status => $_getN(0);
  @$pb.TagNumber(1)
  set status(SessionStatus value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStatus() => $_has(0);
  @$pb.TagNumber(1)
  void clearStatus() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionStatus ensureStatus() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class WatchEventsRequest extends $pb.GeneratedMessage {
  factory WatchEventsRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
    $fixnum.Int64? afterSequence,
  }) {
    final result = WatchEventsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (sessionId != null) result.sessionId = sessionId;
    if (afterSequence != null) result.afterSequence = afterSequence;
    return result;
  }

  WatchEventsRequest._();

  factory WatchEventsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchEventsRequest()..mergeFromBuffer(data, registry);
  factory WatchEventsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchEventsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchEventsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: WatchEventsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'afterSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchEventsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchEventsRequest copyWith(void Function(WatchEventsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchEventsRequest)) as WatchEventsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchEventsRequest() / WatchEventsRequest.new instead')
  static WatchEventsRequest create() => WatchEventsRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchEventsRequest._();
  @$core.override
  WatchEventsRequest createEmptyInstance() => WatchEventsRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchEventsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchEventsRequest>(WatchEventsRequest.$_createMessage);
  static WatchEventsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get afterSequence => $_getI64(2);
  @$pb.TagNumber(3)
  set afterSequence($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAfterSequence() => $_has(2);
  @$pb.TagNumber(3)
  void clearAfterSequence() => $_clearField(3);
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
    final result = SessionPlan._();
    if (tunnelMode != null) result.tunnelMode = tunnelMode;
    if (outbounds != null) result.outbounds.addAll(outbounds);
    if (routes != null) result.routes.addAll(routes);
    if (dnsPolicy != null) result.dnsPolicy = dnsPolicy;
    if (bypassSettings != null) result.bypassSettings = bypassSettings;
    if (sessionIdentity != null) result.sessionIdentity = sessionIdentity;
    if (antiCensorship != null) result.antiCensorship = antiCensorship;
    if (engines != null) result.engines.addAll(engines);
    if (networkControlAllowed != null) result.networkControlAllowed = networkControlAllowed;
    if (localProxy != null) result.localProxy = localProxy;
    if (groups != null) result.groups.addAll(groups);
    if (routing != null) result.routing = routing;
    return result;
  }

  SessionPlan._();

  factory SessionPlan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionPlan()..mergeFromBuffer(data, registry);
  factory SessionPlan.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionPlan()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SessionPlan',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SessionPlan.$_createMessage)
    ..aE<TunnelMode>(1, _omitFieldNames ? '' : 'tunnelMode', enumValues: TunnelMode.values)
    ..pPM<OutboundSpec>(2, _omitFieldNames ? '' : 'outbounds', subBuilder: OutboundSpec.$_createMessage)
    ..pPM<RoutingRule>(3, _omitFieldNames ? '' : 'routes', subBuilder: RoutingRule.$_createMessage)
    ..aOM<DnsPolicy>(4, _omitFieldNames ? '' : 'dnsPolicy', subBuilder: DnsPolicy.$_createMessage)
    ..aOM<BypassSettings>(5, _omitFieldNames ? '' : 'bypassSettings', subBuilder: BypassSettings.$_createMessage)
    ..aOS(6, _omitFieldNames ? '' : 'sessionIdentity')
    ..aOM<AntiCensorship>(7, _omitFieldNames ? '' : 'antiCensorship', subBuilder: AntiCensorship.$_createMessage)
    ..pPS(8, _omitFieldNames ? '' : 'engines')
    ..aOB(9, _omitFieldNames ? '' : 'networkControlAllowed')
    ..aOM<LocalProxy>(10, _omitFieldNames ? '' : 'localProxy', subBuilder: LocalProxy.$_createMessage)
    ..pPM<GroupSpec>(11, _omitFieldNames ? '' : 'groups', subBuilder: GroupSpec.$_createMessage)
    ..aOM<RoutingOptions>(12, _omitFieldNames ? '' : 'routing', subBuilder: RoutingOptions.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionPlan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionPlan copyWith(void Function(SessionPlan) updates) =>
      super.copyWith((message) => updates(message as SessionPlan)) as SessionPlan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionPlan() / SessionPlan.new instead')
  static SessionPlan create() => SessionPlan._();
  static $pb.GeneratedMessage $_createMessage() => SessionPlan._();
  @$core.override
  SessionPlan createEmptyInstance() => SessionPlan._();
  @$core.pragma('dart2js:noInline')
  static SessionPlan getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionPlan>(SessionPlan.$_createMessage);
  static SessionPlan? _defaultInstance;

  @$pb.TagNumber(1)
  TunnelMode get tunnelMode => $_getN(0);
  @$pb.TagNumber(1)
  set tunnelMode(TunnelMode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTunnelMode() => $_has(0);
  @$pb.TagNumber(1)
  void clearTunnelMode() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<OutboundSpec> get outbounds => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<RoutingRule> get routes => $_getList(2);

  @$pb.TagNumber(4)
  DnsPolicy get dnsPolicy => $_getN(3);
  @$pb.TagNumber(4)
  set dnsPolicy(DnsPolicy value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasDnsPolicy() => $_has(3);
  @$pb.TagNumber(4)
  void clearDnsPolicy() => $_clearField(4);
  @$pb.TagNumber(4)
  DnsPolicy ensureDnsPolicy() => $_ensure(3);

  @$pb.TagNumber(5)
  BypassSettings get bypassSettings => $_getN(4);
  @$pb.TagNumber(5)
  set bypassSettings(BypassSettings value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasBypassSettings() => $_has(4);
  @$pb.TagNumber(5)
  void clearBypassSettings() => $_clearField(5);
  @$pb.TagNumber(5)
  BypassSettings ensureBypassSettings() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.String get sessionIdentity => $_getSZ(5);
  @$pb.TagNumber(6)
  set sessionIdentity($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSessionIdentity() => $_has(5);
  @$pb.TagNumber(6)
  void clearSessionIdentity() => $_clearField(6);

  /// Since 1.3. Switches that change how connections look on the wire.
  @$pb.TagNumber(7)
  AntiCensorship get antiCensorship => $_getN(6);
  @$pb.TagNumber(7)
  set antiCensorship(AntiCensorship value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasAntiCensorship() => $_has(6);
  @$pb.TagNumber(7)
  void clearAntiCensorship() => $_clearField(7);
  @$pb.TagNumber(7)
  AntiCensorship ensureAntiCensorship() => $_ensure(6);

  /// Since 1.3. Engine preference for this session, best first: "sing-box",
  /// "xray", "mihomo". The core runs the first one that carries the whole
  /// plan. Empty uses the core default; a single entry pins that engine.
  @$pb.TagNumber(8)
  $pb.PbList<$core.String> get engines => $_getList(7);

  /// Since 1.3. Lets an engine controlled over a loopback port carry this
  /// session. Off by default: a port scan finds a loopback controller, so only
  /// an engine controlled through a unix socket or a named pipe is chosen.
  @$pb.TagNumber(9)
  $core.bool get networkControlAllowed => $_getBF(8);
  @$pb.TagNumber(9)
  set networkControlAllowed($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasNetworkControlAllowed() => $_has(8);
  @$pb.TagNumber(9)
  void clearNetworkControlAllowed() => $_clearField(9);

  /// Since 1.3. The loopback HTTP and SOCKS5 listener. The system proxy mode
  /// always opens it, without a login; in tun mode it exists only when enabled.
  @$pb.TagNumber(10)
  LocalProxy get localProxy => $_getN(9);
  @$pb.TagNumber(10)
  set localProxy(LocalProxy value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasLocalProxy() => $_has(9);
  @$pb.TagNumber(10)
  void clearLocalProxy() => $_clearField(10);
  @$pb.TagNumber(10)
  LocalProxy ensureLocalProxy() => $_ensure(9);

  /// Since 1.3. Groups the user picks a server in, or the core picks one for
  /// them. A rule, a group member and the routing target may name a group.
  @$pb.TagNumber(11)
  $pb.PbList<GroupSpec> get groups => $_getList(10);

  /// Since 1.3. A routing preset applied after the routes above.
  @$pb.TagNumber(12)
  RoutingOptions get routing => $_getN(11);
  @$pb.TagNumber(12)
  set routing(RoutingOptions value) => $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasRouting() => $_has(11);
  @$pb.TagNumber(12)
  void clearRouting() => $_clearField(12);
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
    final result = GroupSpec._();
    if (name != null) result.name = name;
    if (type != null) result.type = type;
    if (members != null) result.members.addAll(members);
    if (testUrl != null) result.testUrl = testUrl;
    if (testInterval != null) result.testInterval = testInterval;
    if (toleranceMs != null) result.toleranceMs = toleranceMs;
    return result;
  }

  GroupSpec._();

  factory GroupSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupSpec()..mergeFromBuffer(data, registry);
  factory GroupSpec.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GroupSpec()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GroupSpec.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'name')
    ..aE<GroupType>(2, _omitFieldNames ? '' : 'type', enumValues: GroupType.values)
    ..pPS(3, _omitFieldNames ? '' : 'members')
    ..aOS(4, _omitFieldNames ? '' : 'testUrl')
    ..aOM<$1.Duration>(5, _omitFieldNames ? '' : 'testInterval', subBuilder: $1.Duration.$_createMessage)
    ..aI(6, _omitFieldNames ? '' : 'toleranceMs', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupSpec copyWith(void Function(GroupSpec) updates) =>
      super.copyWith((message) => updates(message as GroupSpec)) as GroupSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GroupSpec() / GroupSpec.new instead')
  static GroupSpec create() => GroupSpec._();
  static $pb.GeneratedMessage $_createMessage() => GroupSpec._();
  @$core.override
  GroupSpec createEmptyInstance() => GroupSpec._();
  @$core.pragma('dart2js:noInline')
  static GroupSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupSpec>(GroupSpec.$_createMessage);
  static GroupSpec? _defaultInstance;

  /// Unique among the groups and different from every outbound id.
  @$pb.TagNumber(1)
  $core.String get name => $_getSZ(0);
  @$pb.TagNumber(1)
  set name($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasName() => $_has(0);
  @$pb.TagNumber(1)
  void clearName() => $_clearField(1);

  @$pb.TagNumber(2)
  GroupType get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(GroupType value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  /// Outbound ids or names of other groups, in display order.
  @$pb.TagNumber(3)
  $pb.PbList<$core.String> get members => $_getList(2);

  /// How automatic groups measure their members; empty uses the core default.
  @$pb.TagNumber(4)
  $core.String get testUrl => $_getSZ(3);
  @$pb.TagNumber(4)
  set testUrl($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTestUrl() => $_has(3);
  @$pb.TagNumber(4)
  void clearTestUrl() => $_clearField(4);

  @$pb.TagNumber(5)
  $1.Duration get testInterval => $_getN(4);
  @$pb.TagNumber(5)
  set testInterval($1.Duration value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasTestInterval() => $_has(4);
  @$pb.TagNumber(5)
  void clearTestInterval() => $_clearField(5);
  @$pb.TagNumber(5)
  $1.Duration ensureTestInterval() => $_ensure(4);

  /// url-test switches only when another member is faster by this much.
  @$pb.TagNumber(6)
  $core.int get toleranceMs => $_getIZ(5);
  @$pb.TagNumber(6)
  set toleranceMs($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasToleranceMs() => $_has(5);
  @$pb.TagNumber(6)
  void clearToleranceMs() => $_clearField(6);
}

/// RoutingOptions apply a preset after the routes of the plan; see
/// GetRoutingPresets for what each preset sends direct.
class RoutingOptions extends $pb.GeneratedMessage {
  factory RoutingOptions({
    $core.String? preset,
    $core.String? proxyTarget,
    $core.bool? blockAds,
  }) {
    final result = RoutingOptions._();
    if (preset != null) result.preset = preset;
    if (proxyTarget != null) result.proxyTarget = proxyTarget;
    if (blockAds != null) result.blockAds = blockAds;
    return result;
  }

  RoutingOptions._();

  factory RoutingOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingOptions()..mergeFromBuffer(data, registry);
  factory RoutingOptions.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RoutingOptions.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'preset')
    ..aOS(2, _omitFieldNames ? '' : 'proxyTarget')
    ..aOB(3, _omitFieldNames ? '' : 'blockAds')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingOptions copyWith(void Function(RoutingOptions) updates) =>
      super.copyWith((message) => updates(message as RoutingOptions)) as RoutingOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoutingOptions() / RoutingOptions.new instead')
  static RoutingOptions create() => RoutingOptions._();
  static $pb.GeneratedMessage $_createMessage() => RoutingOptions._();
  @$core.override
  RoutingOptions createEmptyInstance() => RoutingOptions._();
  @$core.pragma('dart2js:noInline')
  static RoutingOptions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingOptions>(RoutingOptions.$_createMessage);
  static RoutingOptions? _defaultInstance;

  /// A preset id from GetRoutingPresets; empty applies none.
  @$pb.TagNumber(1)
  $core.String get preset => $_getSZ(0);
  @$pb.TagNumber(1)
  set preset($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPreset() => $_has(0);
  @$pb.TagNumber(1)
  void clearPreset() => $_clearField(1);

  /// The outbound or group everything the routes and the preset leave goes to.
  @$pb.TagNumber(2)
  $core.String get proxyTarget => $_getSZ(1);
  @$pb.TagNumber(2)
  set proxyTarget($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasProxyTarget() => $_has(1);
  @$pb.TagNumber(2)
  void clearProxyTarget() => $_clearField(2);

  /// Rejects advertising and tracking domains before anything else.
  @$pb.TagNumber(3)
  $core.bool get blockAds => $_getBF(2);
  @$pb.TagNumber(3)
  set blockAds($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBlockAds() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlockAds() => $_clearField(3);
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
    final result = LocalProxy._();
    if (enabled != null) result.enabled = enabled;
    if (username != null) result.username = username;
    if (password != null) result.password = password;
    return result;
  }

  LocalProxy._();

  factory LocalProxy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalProxy()..mergeFromBuffer(data, registry);
  factory LocalProxy.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LocalProxy()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LocalProxy',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LocalProxy.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..aOS(3, _omitFieldNames ? '' : 'password')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalProxy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LocalProxy copyWith(void Function(LocalProxy) updates) =>
      super.copyWith((message) => updates(message as LocalProxy)) as LocalProxy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LocalProxy() / LocalProxy.new instead')
  static LocalProxy create() => LocalProxy._();
  static $pb.GeneratedMessage $_createMessage() => LocalProxy._();
  @$core.override
  LocalProxy createEmptyInstance() => LocalProxy._();
  @$core.pragma('dart2js:noInline')
  static LocalProxy getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LocalProxy>(LocalProxy.$_createMessage);
  static LocalProxy? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get password => $_getSZ(2);
  @$pb.TagNumber(3)
  set password($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPassword() => $_has(2);
  @$pb.TagNumber(3)
  void clearPassword() => $_clearField(3);
}

/// AntiCensorship holds the per-session defences against DPI.
class AntiCensorship extends $pb.GeneratedMessage {
  factory AntiCensorship({
    $core.bool? tlsFragment,
    $core.String? fragmentPackets,
    $core.String? fragmentLength,
    $core.String? fragmentInterval,
  }) {
    final result = AntiCensorship._();
    if (tlsFragment != null) result.tlsFragment = tlsFragment;
    if (fragmentPackets != null) result.fragmentPackets = fragmentPackets;
    if (fragmentLength != null) result.fragmentLength = fragmentLength;
    if (fragmentInterval != null) result.fragmentInterval = fragmentInterval;
    return result;
  }

  AntiCensorship._();

  factory AntiCensorship.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AntiCensorship()..mergeFromBuffer(data, registry);
  factory AntiCensorship.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      AntiCensorship()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'AntiCensorship',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: AntiCensorship.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'tlsFragment')
    ..aOS(2, _omitFieldNames ? '' : 'fragmentPackets')
    ..aOS(3, _omitFieldNames ? '' : 'fragmentLength')
    ..aOS(4, _omitFieldNames ? '' : 'fragmentInterval')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AntiCensorship clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AntiCensorship copyWith(void Function(AntiCensorship) updates) =>
      super.copyWith((message) => updates(message as AntiCensorship)) as AntiCensorship;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use AntiCensorship() / AntiCensorship.new instead')
  static AntiCensorship create() => AntiCensorship._();
  static $pb.GeneratedMessage $_createMessage() => AntiCensorship._();
  @$core.override
  AntiCensorship createEmptyInstance() => AntiCensorship._();
  @$core.pragma('dart2js:noInline')
  static AntiCensorship getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<AntiCensorship>(AntiCensorship.$_createMessage);
  static AntiCensorship? _defaultInstance;

  /// Splits the TLS ClientHello of proxy connections into several TCP segments.
  @$pb.TagNumber(1)
  $core.bool get tlsFragment => $_getBF(0);
  @$pb.TagNumber(1)
  set tlsFragment($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTlsFragment() => $_has(0);
  @$pb.TagNumber(1)
  void clearTlsFragment() => $_clearField(1);

  /// Xray grammar: "tlshello" or a segment range such as "1-3". Empty means "tlshello".
  @$pb.TagNumber(2)
  $core.String get fragmentPackets => $_getSZ(1);
  @$pb.TagNumber(2)
  set fragmentPackets($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFragmentPackets() => $_has(1);
  @$pb.TagNumber(2)
  void clearFragmentPackets() => $_clearField(2);

  /// Segment length range in bytes, for example "100-200".
  @$pb.TagNumber(3)
  $core.String get fragmentLength => $_getSZ(2);
  @$pb.TagNumber(3)
  set fragmentLength($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasFragmentLength() => $_has(2);
  @$pb.TagNumber(3)
  void clearFragmentLength() => $_clearField(3);

  /// Pause range between segments in milliseconds, for example "10-20".
  @$pb.TagNumber(4)
  $core.String get fragmentInterval => $_getSZ(3);
  @$pb.TagNumber(4)
  set fragmentInterval($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasFragmentInterval() => $_has(3);
  @$pb.TagNumber(4)
  void clearFragmentInterval() => $_clearField(4);
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
    final result = OutboundSpec._();
    if (id != null) result.id = id;
    if (displayName != null) result.displayName = displayName;
    if (protocol != null) result.protocol = protocol;
    if (transport != null) result.transport = transport;
    if (security != null) result.security = security;
    if (endpoint != null) result.endpoint = endpoint;
    if (credentials != null) result.credentials = credentials;
    if (bypass != null) result.bypass = bypass;
    return result;
  }

  OutboundSpec._();

  factory OutboundSpec.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OutboundSpec()..mergeFromBuffer(data, registry);
  factory OutboundSpec.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      OutboundSpec()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'OutboundSpec',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: OutboundSpec.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..aOS(3, _omitFieldNames ? '' : 'protocol')
    ..aOS(4, _omitFieldNames ? '' : 'transport')
    ..aOS(5, _omitFieldNames ? '' : 'security')
    ..aOM<Endpoint>(6, _omitFieldNames ? '' : 'endpoint', subBuilder: Endpoint.$_createMessage)
    ..aOM<CredentialsRef>(7, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.$_createMessage)
    ..aOM<BypassStrategy>(8, _omitFieldNames ? '' : 'bypass', subBuilder: BypassStrategy.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutboundSpec clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  OutboundSpec copyWith(void Function(OutboundSpec) updates) =>
      super.copyWith((message) => updates(message as OutboundSpec)) as OutboundSpec;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use OutboundSpec() / OutboundSpec.new instead')
  static OutboundSpec create() => OutboundSpec._();
  static $pb.GeneratedMessage $_createMessage() => OutboundSpec._();
  @$core.override
  OutboundSpec createEmptyInstance() => OutboundSpec._();
  @$core.pragma('dart2js:noInline')
  static OutboundSpec getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<OutboundSpec>(OutboundSpec.$_createMessage);
  static OutboundSpec? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get protocol => $_getSZ(2);
  @$pb.TagNumber(3)
  set protocol($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasProtocol() => $_has(2);
  @$pb.TagNumber(3)
  void clearProtocol() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get transport => $_getSZ(3);
  @$pb.TagNumber(4)
  set transport($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTransport() => $_has(3);
  @$pb.TagNumber(4)
  void clearTransport() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get security => $_getSZ(4);
  @$pb.TagNumber(5)
  set security($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSecurity() => $_has(4);
  @$pb.TagNumber(5)
  void clearSecurity() => $_clearField(5);

  @$pb.TagNumber(6)
  Endpoint get endpoint => $_getN(5);
  @$pb.TagNumber(6)
  set endpoint(Endpoint value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasEndpoint() => $_has(5);
  @$pb.TagNumber(6)
  void clearEndpoint() => $_clearField(6);
  @$pb.TagNumber(6)
  Endpoint ensureEndpoint() => $_ensure(5);

  @$pb.TagNumber(7)
  CredentialsRef get credentials => $_getN(6);
  @$pb.TagNumber(7)
  set credentials(CredentialsRef value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasCredentials() => $_has(6);
  @$pb.TagNumber(7)
  void clearCredentials() => $_clearField(7);
  @$pb.TagNumber(7)
  CredentialsRef ensureCredentials() => $_ensure(6);

  /// Since 1.3. For protocol "bypass": sites reached directly with the
  /// handshake reshaped by zapret against DPI; no endpoint, no credentials.
  @$pb.TagNumber(8)
  BypassStrategy get bypass => $_getN(7);
  @$pb.TagNumber(8)
  set bypass(BypassStrategy value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasBypass() => $_has(7);
  @$pb.TagNumber(8)
  void clearBypass() => $_clearField(8);
  @$pb.TagNumber(8)
  BypassStrategy ensureBypass() => $_ensure(7);
}

class Endpoint extends $pb.GeneratedMessage {
  factory Endpoint({
    $core.String? host,
    $core.int? port,
  }) {
    final result = Endpoint._();
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    return result;
  }

  Endpoint._();

  factory Endpoint.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Endpoint()..mergeFromBuffer(data, registry);
  factory Endpoint.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Endpoint()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Endpoint',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: Endpoint.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'host')
    ..aI(2, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Endpoint clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Endpoint copyWith(void Function(Endpoint) updates) =>
      super.copyWith((message) => updates(message as Endpoint)) as Endpoint;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Endpoint() / Endpoint.new instead')
  static Endpoint create() => Endpoint._();
  static $pb.GeneratedMessage $_createMessage() => Endpoint._();
  @$core.override
  Endpoint createEmptyInstance() => Endpoint._();
  @$core.pragma('dart2js:noInline')
  static Endpoint getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Endpoint>(Endpoint.$_createMessage);
  static Endpoint? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get host => $_getSZ(0);
  @$pb.TagNumber(1)
  set host($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasHost() => $_has(0);
  @$pb.TagNumber(1)
  void clearHost() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get port => $_getIZ(1);
  @$pb.TagNumber(2)
  set port($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPort() => $_has(1);
  @$pb.TagNumber(2)
  void clearPort() => $_clearField(2);
}

class CredentialsRef extends $pb.GeneratedMessage {
  factory CredentialsRef({
    $core.String? reference,
  }) {
    final result = CredentialsRef._();
    if (reference != null) result.reference = reference;
    return result;
  }

  CredentialsRef._();

  factory CredentialsRef.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CredentialsRef()..mergeFromBuffer(data, registry);
  factory CredentialsRef.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CredentialsRef()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CredentialsRef',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: CredentialsRef.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'reference')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialsRef clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CredentialsRef copyWith(void Function(CredentialsRef) updates) =>
      super.copyWith((message) => updates(message as CredentialsRef)) as CredentialsRef;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CredentialsRef() / CredentialsRef.new instead')
  static CredentialsRef create() => CredentialsRef._();
  static $pb.GeneratedMessage $_createMessage() => CredentialsRef._();
  @$core.override
  CredentialsRef createEmptyInstance() => CredentialsRef._();
  @$core.pragma('dart2js:noInline')
  static CredentialsRef getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CredentialsRef>(CredentialsRef.$_createMessage);
  static CredentialsRef? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get reference => $_getSZ(0);
  @$pb.TagNumber(1)
  set reference($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasReference() => $_has(0);
  @$pb.TagNumber(1)
  void clearReference() => $_clearField(1);
}

class RoutingRule extends $pb.GeneratedMessage {
  factory RoutingRule({
    $core.String? destination,
    $core.String? outboundId,
  }) {
    final result = RoutingRule._();
    if (destination != null) result.destination = destination;
    if (outboundId != null) result.outboundId = outboundId;
    return result;
  }

  RoutingRule._();

  factory RoutingRule.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingRule()..mergeFromBuffer(data, registry);
  factory RoutingRule.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingRule()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingRule',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RoutingRule.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'destination')
    ..aOS(2, _omitFieldNames ? '' : 'outboundId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingRule clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingRule copyWith(void Function(RoutingRule) updates) =>
      super.copyWith((message) => updates(message as RoutingRule)) as RoutingRule;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoutingRule() / RoutingRule.new instead')
  static RoutingRule create() => RoutingRule._();
  static $pb.GeneratedMessage $_createMessage() => RoutingRule._();
  @$core.override
  RoutingRule createEmptyInstance() => RoutingRule._();
  @$core.pragma('dart2js:noInline')
  static RoutingRule getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingRule>(RoutingRule.$_createMessage);
  static RoutingRule? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get destination => $_getSZ(0);
  @$pb.TagNumber(1)
  set destination($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDestination() => $_has(0);
  @$pb.TagNumber(1)
  void clearDestination() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get outboundId => $_getSZ(1);
  @$pb.TagNumber(2)
  set outboundId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOutboundId() => $_has(1);
  @$pb.TagNumber(2)
  void clearOutboundId() => $_clearField(2);
}

/// DnsPolicy names the resolvers of the session. A tun session that names none
/// uses DNS over HTTPS to 1.1.1.1 and 8.8.8.8, since the adapter carries every
/// lookup of the machine.
class DnsPolicy extends $pb.GeneratedMessage {
  factory DnsPolicy({
    $core.Iterable<$core.String>? servers,
    $core.bool? blockPrivate,
  }) {
    final result = DnsPolicy._();
    if (servers != null) result.servers.addAll(servers);
    if (blockPrivate != null) result.blockPrivate = blockPrivate;
    return result;
  }

  DnsPolicy._();

  factory DnsPolicy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DnsPolicy()..mergeFromBuffer(data, registry);
  factory DnsPolicy.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DnsPolicy()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DnsPolicy',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DnsPolicy.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'servers')
    ..aOB(2, _omitFieldNames ? '' : 'blockPrivate')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DnsPolicy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DnsPolicy copyWith(void Function(DnsPolicy) updates) =>
      super.copyWith((message) => updates(message as DnsPolicy)) as DnsPolicy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DnsPolicy() / DnsPolicy.new instead')
  static DnsPolicy create() => DnsPolicy._();
  static $pb.GeneratedMessage $_createMessage() => DnsPolicy._();
  @$core.override
  DnsPolicy createEmptyInstance() => DnsPolicy._();
  @$core.pragma('dart2js:noInline')
  static DnsPolicy getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DnsPolicy>(DnsPolicy.$_createMessage);
  static DnsPolicy? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get servers => $_getList(0);

  @$pb.TagNumber(2)
  $core.bool get blockPrivate => $_getBF(1);
  @$pb.TagNumber(2)
  set blockPrivate($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBlockPrivate() => $_has(1);
  @$pb.TagNumber(2)
  void clearBlockPrivate() => $_clearField(2);
}

class BypassSettings extends $pb.GeneratedMessage {
  factory BypassSettings({
    $core.bool? enabled,
    $core.Iterable<$core.String>? rules,
  }) {
    final result = BypassSettings._();
    if (enabled != null) result.enabled = enabled;
    if (rules != null) result.rules.addAll(rules);
    return result;
  }

  BypassSettings._();

  factory BypassSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassSettings()..mergeFromBuffer(data, registry);
  factory BypassSettings.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassSettings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: BypassSettings.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..pPS(2, _omitFieldNames ? '' : 'rules')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassSettings copyWith(void Function(BypassSettings) updates) =>
      super.copyWith((message) => updates(message as BypassSettings)) as BypassSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BypassSettings() / BypassSettings.new instead')
  static BypassSettings create() => BypassSettings._();
  static $pb.GeneratedMessage $_createMessage() => BypassSettings._();
  @$core.override
  BypassSettings createEmptyInstance() => BypassSettings._();
  @$core.pragma('dart2js:noInline')
  static BypassSettings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BypassSettings>(BypassSettings.$_createMessage);
  static BypassSettings? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get rules => $_getList(1);
}

class SessionStatus extends $pb.GeneratedMessage {
  factory SessionStatus({
    ConnectionState? connection,
    ApiVersion? negotiatedVersion,
  }) {
    final result = SessionStatus._();
    if (connection != null) result.connection = connection;
    if (negotiatedVersion != null) result.negotiatedVersion = negotiatedVersion;
    return result;
  }

  SessionStatus._();

  factory SessionStatus.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionStatus()..mergeFromBuffer(data, registry);
  factory SessionStatus.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SessionStatus()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SessionStatus',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SessionStatus.$_createMessage)
    ..aOM<ConnectionState>(1, _omitFieldNames ? '' : 'connection', subBuilder: ConnectionState.$_createMessage)
    ..aOM<ApiVersion>(2, _omitFieldNames ? '' : 'negotiatedVersion', subBuilder: ApiVersion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionStatus clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SessionStatus copyWith(void Function(SessionStatus) updates) =>
      super.copyWith((message) => updates(message as SessionStatus)) as SessionStatus;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SessionStatus() / SessionStatus.new instead')
  static SessionStatus create() => SessionStatus._();
  static $pb.GeneratedMessage $_createMessage() => SessionStatus._();
  @$core.override
  SessionStatus createEmptyInstance() => SessionStatus._();
  @$core.pragma('dart2js:noInline')
  static SessionStatus getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SessionStatus>(SessionStatus.$_createMessage);
  static SessionStatus? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionState get connection => $_getN(0);
  @$pb.TagNumber(1)
  set connection(ConnectionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasConnection() => $_has(0);
  @$pb.TagNumber(1)
  void clearConnection() => $_clearField(1);
  @$pb.TagNumber(1)
  ConnectionState ensureConnection() => $_ensure(0);

  @$pb.TagNumber(2)
  ApiVersion get negotiatedVersion => $_getN(1);
  @$pb.TagNumber(2)
  set negotiatedVersion(ApiVersion value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasNegotiatedVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearNegotiatedVersion() => $_clearField(2);
  @$pb.TagNumber(2)
  ApiVersion ensureNegotiatedVersion() => $_ensure(1);
}

class GetStatsRequest extends $pb.GeneratedMessage {
  factory GetStatsRequest({
    ApiVersion? apiVersion,
    $core.String? sessionId,
  }) {
    final result = GetStatsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  GetStatsRequest._();

  factory GetStatsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromBuffer(data, registry);
  factory GetStatsRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetStatsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsRequest copyWith(void Function(GetStatsRequest) updates) =>
      super.copyWith((message) => updates(message as GetStatsRequest)) as GetStatsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatsRequest() / GetStatsRequest.new instead')
  static GetStatsRequest create() => GetStatsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetStatsRequest._();
  @$core.override
  GetStatsRequest createEmptyInstance() => GetStatsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetStatsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsRequest>(GetStatsRequest.$_createMessage);
  static GetStatsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);
}

class GetStatsResponse extends $pb.GeneratedMessage {
  factory GetStatsResponse({
    StatsTick? stats,
    SoraError? error,
  }) {
    final result = GetStatsResponse._();
    if (stats != null) result.stats = stats;
    if (error != null) result.error = error;
    return result;
  }

  GetStatsResponse._();

  factory GetStatsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsResponse()..mergeFromBuffer(data, registry);
  factory GetStatsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetStatsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetStatsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetStatsResponse.$_createMessage)
    ..aOM<StatsTick>(1, _omitFieldNames ? '' : 'stats', subBuilder: StatsTick.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetStatsResponse copyWith(void Function(GetStatsResponse) updates) =>
      super.copyWith((message) => updates(message as GetStatsResponse)) as GetStatsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetStatsResponse() / GetStatsResponse.new instead')
  static GetStatsResponse create() => GetStatsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetStatsResponse._();
  @$core.override
  GetStatsResponse createEmptyInstance() => GetStatsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetStatsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetStatsResponse>(GetStatsResponse.$_createMessage);
  static GetStatsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  StatsTick get stats => $_getN(0);
  @$pb.TagNumber(1)
  set stats(StatsTick value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasStats() => $_has(0);
  @$pb.TagNumber(1)
  void clearStats() => $_clearField(1);
  @$pb.TagNumber(1)
  StatsTick ensureStats() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = ConnectionState._();
    if (value != null) result.value = value;
    if (sessionId != null) result.sessionId = sessionId;
    if (reason != null) result.reason = reason;
    if (changedAt != null) result.changedAt = changedAt;
    if (retryAfter != null) result.retryAfter = retryAfter;
    return result;
  }

  ConnectionState._();

  factory ConnectionState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionState()..mergeFromBuffer(data, registry);
  factory ConnectionState.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ConnectionState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ConnectionState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ConnectionState.$_createMessage)
    ..aE<ConnectionStateValue>(1, _omitFieldNames ? '' : 'value', enumValues: ConnectionStateValue.values)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aE<SoraErrorCode>(3, _omitFieldNames ? '' : 'reason', enumValues: SoraErrorCode.values)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'changedAt', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<$1.Duration>(5, _omitFieldNames ? '' : 'retryAfter', subBuilder: $1.Duration.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ConnectionState copyWith(void Function(ConnectionState) updates) =>
      super.copyWith((message) => updates(message as ConnectionState)) as ConnectionState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ConnectionState() / ConnectionState.new instead')
  static ConnectionState create() => ConnectionState._();
  static $pb.GeneratedMessage $_createMessage() => ConnectionState._();
  @$core.override
  ConnectionState createEmptyInstance() => ConnectionState._();
  @$core.pragma('dart2js:noInline')
  static ConnectionState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ConnectionState>(ConnectionState.$_createMessage);
  static ConnectionState? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionStateValue get value => $_getN(0);
  @$pb.TagNumber(1)
  set value(ConnectionStateValue value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasValue() => $_has(0);
  @$pb.TagNumber(1)
  void clearValue() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  SoraErrorCode get reason => $_getN(2);
  @$pb.TagNumber(3)
  set reason(SoraErrorCode value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasReason() => $_has(2);
  @$pb.TagNumber(3)
  void clearReason() => $_clearField(3);

  @$pb.TagNumber(4)
  $2.Timestamp get changedAt => $_getN(3);
  @$pb.TagNumber(4)
  set changedAt($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasChangedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearChangedAt() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureChangedAt() => $_ensure(3);

  @$pb.TagNumber(5)
  $1.Duration get retryAfter => $_getN(4);
  @$pb.TagNumber(5)
  set retryAfter($1.Duration value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasRetryAfter() => $_has(4);
  @$pb.TagNumber(5)
  void clearRetryAfter() => $_clearField(5);
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
    final result = CoreEvent._();
    if (sequence != null) result.sequence = sequence;
    if (sessionId != null) result.sessionId = sessionId;
    if (emittedAt != null) result.emittedAt = emittedAt;
    if (stateChanged != null) result.stateChanged = stateChanged;
    if (statsTick != null) result.statsTick = statsTick;
    if (bypassStrategyChanged != null) result.bypassStrategyChanged = bypassStrategyChanged;
    if (probeResult != null) result.probeResult = probeResult;
    if (logBatch != null) result.logBatch = logBatch;
    if (error != null) result.error = error;
    if (killSwitchChanged != null) result.killSwitchChanged = killSwitchChanged;
    return result;
  }

  CoreEvent._();

  factory CoreEvent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CoreEvent()..mergeFromBuffer(data, registry);
  factory CoreEvent.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CoreEvent()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, CoreEvent_Payload> _CoreEvent_PayloadByTag = {
    4: CoreEvent_Payload.stateChanged,
    5: CoreEvent_Payload.statsTick,
    6: CoreEvent_Payload.bypassStrategyChanged,
    7: CoreEvent_Payload.probeResult,
    8: CoreEvent_Payload.logBatch,
    9: CoreEvent_Payload.error,
    10: CoreEvent_Payload.killSwitchChanged,
    0: CoreEvent_Payload.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CoreEvent',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: CoreEvent.$_createMessage)
    ..oo(0, [4, 5, 6, 7, 8, 9, 10])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOS(2, _omitFieldNames ? '' : 'sessionId')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'emittedAt', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<StateChanged>(4, _omitFieldNames ? '' : 'stateChanged', subBuilder: StateChanged.$_createMessage)
    ..aOM<StatsTick>(5, _omitFieldNames ? '' : 'statsTick', subBuilder: StatsTick.$_createMessage)
    ..aOM<BypassStrategyChanged>(6, _omitFieldNames ? '' : 'bypassStrategyChanged',
        subBuilder: BypassStrategyChanged.$_createMessage)
    ..aOM<ProbeResult>(7, _omitFieldNames ? '' : 'probeResult', subBuilder: ProbeResult.$_createMessage)
    ..aOM<LogBatch>(8, _omitFieldNames ? '' : 'logBatch', subBuilder: LogBatch.$_createMessage)
    ..aOM<SoraError>(9, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..aOM<KillSwitchChanged>(10, _omitFieldNames ? '' : 'killSwitchChanged',
        subBuilder: KillSwitchChanged.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CoreEvent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CoreEvent copyWith(void Function(CoreEvent) updates) =>
      super.copyWith((message) => updates(message as CoreEvent)) as CoreEvent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CoreEvent() / CoreEvent.new instead')
  static CoreEvent create() => CoreEvent._();
  static $pb.GeneratedMessage $_createMessage() => CoreEvent._();
  @$core.override
  CoreEvent createEmptyInstance() => CoreEvent._();
  @$core.pragma('dart2js:noInline')
  static CoreEvent getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<CoreEvent>(CoreEvent.$_createMessage);
  static CoreEvent? _defaultInstance;

  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  CoreEvent_Payload whichPayload() => _CoreEvent_PayloadByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  void clearPayload() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get sessionId => $_getSZ(1);
  @$pb.TagNumber(2)
  set sessionId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSessionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSessionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $2.Timestamp get emittedAt => $_getN(2);
  @$pb.TagNumber(3)
  set emittedAt($2.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasEmittedAt() => $_has(2);
  @$pb.TagNumber(3)
  void clearEmittedAt() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureEmittedAt() => $_ensure(2);

  @$pb.TagNumber(4)
  StateChanged get stateChanged => $_getN(3);
  @$pb.TagNumber(4)
  set stateChanged(StateChanged value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasStateChanged() => $_has(3);
  @$pb.TagNumber(4)
  void clearStateChanged() => $_clearField(4);
  @$pb.TagNumber(4)
  StateChanged ensureStateChanged() => $_ensure(3);

  @$pb.TagNumber(5)
  StatsTick get statsTick => $_getN(4);
  @$pb.TagNumber(5)
  set statsTick(StatsTick value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasStatsTick() => $_has(4);
  @$pb.TagNumber(5)
  void clearStatsTick() => $_clearField(5);
  @$pb.TagNumber(5)
  StatsTick ensureStatsTick() => $_ensure(4);

  @$pb.TagNumber(6)
  BypassStrategyChanged get bypassStrategyChanged => $_getN(5);
  @$pb.TagNumber(6)
  set bypassStrategyChanged(BypassStrategyChanged value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasBypassStrategyChanged() => $_has(5);
  @$pb.TagNumber(6)
  void clearBypassStrategyChanged() => $_clearField(6);
  @$pb.TagNumber(6)
  BypassStrategyChanged ensureBypassStrategyChanged() => $_ensure(5);

  @$pb.TagNumber(7)
  ProbeResult get probeResult => $_getN(6);
  @$pb.TagNumber(7)
  set probeResult(ProbeResult value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasProbeResult() => $_has(6);
  @$pb.TagNumber(7)
  void clearProbeResult() => $_clearField(7);
  @$pb.TagNumber(7)
  ProbeResult ensureProbeResult() => $_ensure(6);

  @$pb.TagNumber(8)
  LogBatch get logBatch => $_getN(7);
  @$pb.TagNumber(8)
  set logBatch(LogBatch value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasLogBatch() => $_has(7);
  @$pb.TagNumber(8)
  void clearLogBatch() => $_clearField(8);
  @$pb.TagNumber(8)
  LogBatch ensureLogBatch() => $_ensure(7);

  @$pb.TagNumber(9)
  SoraError get error => $_getN(8);
  @$pb.TagNumber(9)
  set error(SoraError value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasError() => $_has(8);
  @$pb.TagNumber(9)
  void clearError() => $_clearField(9);
  @$pb.TagNumber(9)
  SoraError ensureError() => $_ensure(8);

  @$pb.TagNumber(10)
  KillSwitchChanged get killSwitchChanged => $_getN(9);
  @$pb.TagNumber(10)
  set killSwitchChanged(KillSwitchChanged value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasKillSwitchChanged() => $_has(9);
  @$pb.TagNumber(10)
  void clearKillSwitchChanged() => $_clearField(10);
  @$pb.TagNumber(10)
  KillSwitchChanged ensureKillSwitchChanged() => $_ensure(9);
}

class StateChanged extends $pb.GeneratedMessage {
  factory StateChanged({
    ConnectionState? state,
  }) {
    final result = StateChanged._();
    if (state != null) result.state = state;
    return result;
  }

  StateChanged._();

  factory StateChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateChanged()..mergeFromBuffer(data, registry);
  factory StateChanged.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StateChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StateChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: StateChanged.$_createMessage)
    ..aOM<ConnectionState>(1, _omitFieldNames ? '' : 'state', subBuilder: ConnectionState.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StateChanged copyWith(void Function(StateChanged) updates) =>
      super.copyWith((message) => updates(message as StateChanged)) as StateChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StateChanged() / StateChanged.new instead')
  static StateChanged create() => StateChanged._();
  static $pb.GeneratedMessage $_createMessage() => StateChanged._();
  @$core.override
  StateChanged createEmptyInstance() => StateChanged._();
  @$core.pragma('dart2js:noInline')
  static StateChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StateChanged>(StateChanged.$_createMessage);
  static StateChanged? _defaultInstance;

  @$pb.TagNumber(1)
  ConnectionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(ConnectionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  ConnectionState ensureState() => $_ensure(0);
}

class StatsTick extends $pb.GeneratedMessage {
  factory StatsTick({
    $fixnum.Int64? bytesUp,
    $fixnum.Int64? bytesDown,
    $fixnum.Int64? activeConnections,
  }) {
    final result = StatsTick._();
    if (bytesUp != null) result.bytesUp = bytesUp;
    if (bytesDown != null) result.bytesDown = bytesDown;
    if (activeConnections != null) result.activeConnections = activeConnections;
    return result;
  }

  StatsTick._();

  factory StatsTick.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatsTick()..mergeFromBuffer(data, registry);
  factory StatsTick.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      StatsTick()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StatsTick',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: StatsTick.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'bytesUp', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'bytesDown', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'activeConnections', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatsTick clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StatsTick copyWith(void Function(StatsTick) updates) =>
      super.copyWith((message) => updates(message as StatsTick)) as StatsTick;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use StatsTick() / StatsTick.new instead')
  static StatsTick create() => StatsTick._();
  static $pb.GeneratedMessage $_createMessage() => StatsTick._();
  @$core.override
  StatsTick createEmptyInstance() => StatsTick._();
  @$core.pragma('dart2js:noInline')
  static StatsTick getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StatsTick>(StatsTick.$_createMessage);
  static StatsTick? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get bytesUp => $_getI64(0);
  @$pb.TagNumber(1)
  set bytesUp($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBytesUp() => $_has(0);
  @$pb.TagNumber(1)
  void clearBytesUp() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get bytesDown => $_getI64(1);
  @$pb.TagNumber(2)
  set bytesDown($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBytesDown() => $_has(1);
  @$pb.TagNumber(2)
  void clearBytesDown() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get activeConnections => $_getI64(2);
  @$pb.TagNumber(3)
  set activeConnections($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasActiveConnections() => $_has(2);
  @$pb.TagNumber(3)
  void clearActiveConnections() => $_clearField(3);
}

class BypassStrategyChanged extends $pb.GeneratedMessage {
  factory BypassStrategyChanged({
    $core.String? strategy,
  }) {
    final result = BypassStrategyChanged._();
    if (strategy != null) result.strategy = strategy;
    return result;
  }

  BypassStrategyChanged._();

  factory BypassStrategyChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassStrategyChanged()..mergeFromBuffer(data, registry);
  factory BypassStrategyChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassStrategyChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassStrategyChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: BypassStrategyChanged.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'strategy')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassStrategyChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassStrategyChanged copyWith(void Function(BypassStrategyChanged) updates) =>
      super.copyWith((message) => updates(message as BypassStrategyChanged)) as BypassStrategyChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BypassStrategyChanged() / BypassStrategyChanged.new instead')
  static BypassStrategyChanged create() => BypassStrategyChanged._();
  static $pb.GeneratedMessage $_createMessage() => BypassStrategyChanged._();
  @$core.override
  BypassStrategyChanged createEmptyInstance() => BypassStrategyChanged._();
  @$core.pragma('dart2js:noInline')
  static BypassStrategyChanged getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<BypassStrategyChanged>(BypassStrategyChanged.$_createMessage);
  static BypassStrategyChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get strategy => $_getSZ(0);
  @$pb.TagNumber(1)
  set strategy($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasStrategy() => $_has(0);
  @$pb.TagNumber(1)
  void clearStrategy() => $_clearField(1);
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
    final result = ProbeResult._();
    if (serverId != null) result.serverId = serverId;
    if (reachable != null) result.reachable = reachable;
    if (latencyMs != null) result.latencyMs = latencyMs;
    if (error != null) result.error = error;
    if (method != null) result.method = method;
    if (engine != null) result.engine = engine;
    return result;
  }

  ProbeResult._();

  factory ProbeResult.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeResult()..mergeFromBuffer(data, registry);
  factory ProbeResult.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeResult()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeResult',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ProbeResult.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'serverId')
    ..aOB(2, _omitFieldNames ? '' : 'reachable')
    ..aI(3, _omitFieldNames ? '' : 'latencyMs', fieldType: $pb.PbFieldType.OU3)
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'method')
    ..aOS(6, _omitFieldNames ? '' : 'engine')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeResult clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeResult copyWith(void Function(ProbeResult) updates) =>
      super.copyWith((message) => updates(message as ProbeResult)) as ProbeResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProbeResult() / ProbeResult.new instead')
  static ProbeResult create() => ProbeResult._();
  static $pb.GeneratedMessage $_createMessage() => ProbeResult._();
  @$core.override
  ProbeResult createEmptyInstance() => ProbeResult._();
  @$core.pragma('dart2js:noInline')
  static ProbeResult getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeResult>(ProbeResult.$_createMessage);
  static ProbeResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get serverId => $_getSZ(0);
  @$pb.TagNumber(1)
  set serverId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasServerId() => $_has(0);
  @$pb.TagNumber(1)
  void clearServerId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get reachable => $_getBF(1);
  @$pb.TagNumber(2)
  set reachable($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasReachable() => $_has(1);
  @$pb.TagNumber(2)
  void clearReachable() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get latencyMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set latencyMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasLatencyMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearLatencyMs() => $_clearField(3);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);

  /// Since 1.3. How the value was measured: "engine" is a real request through
  /// the server, "connect" only a TCP connection to it.
  @$pb.TagNumber(5)
  $core.String get method => $_getSZ(4);
  @$pb.TagNumber(5)
  set method($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMethod() => $_has(4);
  @$pb.TagNumber(5)
  void clearMethod() => $_clearField(5);

  /// Since 1.3. The engine that carried an "engine" measurement.
  @$pb.TagNumber(6)
  $core.String get engine => $_getSZ(5);
  @$pb.TagNumber(6)
  set engine($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasEngine() => $_has(5);
  @$pb.TagNumber(6)
  void clearEngine() => $_clearField(6);
}

class LogBatch extends $pb.GeneratedMessage {
  factory LogBatch({
    $core.Iterable<$core.String>? lines,
  }) {
    final result = LogBatch._();
    if (lines != null) result.lines.addAll(lines);
    return result;
  }

  LogBatch._();

  factory LogBatch.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogBatch()..mergeFromBuffer(data, registry);
  factory LogBatch.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogBatch()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogBatch',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogBatch.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'lines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogBatch clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogBatch copyWith(void Function(LogBatch) updates) =>
      super.copyWith((message) => updates(message as LogBatch)) as LogBatch;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogBatch() / LogBatch.new instead')
  static LogBatch create() => LogBatch._();
  static $pb.GeneratedMessage $_createMessage() => LogBatch._();
  @$core.override
  LogBatch createEmptyInstance() => LogBatch._();
  @$core.pragma('dart2js:noInline')
  static LogBatch getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogBatch>(LogBatch.$_createMessage);
  static LogBatch? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get lines => $_getList(0);
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
    final result = KillSwitchChanged._();
    if (enabled != null) result.enabled = enabled;
    if (enforced != null) result.enforced = enforced;
    return result;
  }

  KillSwitchChanged._();

  factory KillSwitchChanged.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KillSwitchChanged()..mergeFromBuffer(data, registry);
  factory KillSwitchChanged.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      KillSwitchChanged()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'KillSwitchChanged',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: KillSwitchChanged.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOB(2, _omitFieldNames ? '' : 'enforced')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KillSwitchChanged clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  KillSwitchChanged copyWith(void Function(KillSwitchChanged) updates) =>
      super.copyWith((message) => updates(message as KillSwitchChanged)) as KillSwitchChanged;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use KillSwitchChanged() / KillSwitchChanged.new instead')
  static KillSwitchChanged create() => KillSwitchChanged._();
  static $pb.GeneratedMessage $_createMessage() => KillSwitchChanged._();
  @$core.override
  KillSwitchChanged createEmptyInstance() => KillSwitchChanged._();
  @$core.pragma('dart2js:noInline')
  static KillSwitchChanged getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<KillSwitchChanged>(KillSwitchChanged.$_createMessage);
  static KillSwitchChanged? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get enforced => $_getBF(1);
  @$pb.TagNumber(2)
  set enforced($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEnforced() => $_has(1);
  @$pb.TagNumber(2)
  void clearEnforced() => $_clearField(2);
}

class ParseImportRequest extends $pb.GeneratedMessage {
  factory ParseImportRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.List<$core.int>? payload,
  }) {
    final result = ParseImportRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (payload != null) result.payload = payload;
    return result;
  }

  ParseImportRequest._();

  factory ParseImportRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ParseImportRequest()..mergeFromBuffer(data, registry);
  factory ParseImportRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ParseImportRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseImportRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ParseImportRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseImportRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseImportRequest copyWith(void Function(ParseImportRequest) updates) =>
      super.copyWith((message) => updates(message as ParseImportRequest)) as ParseImportRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ParseImportRequest() / ParseImportRequest.new instead')
  static ParseImportRequest create() => ParseImportRequest._();
  static $pb.GeneratedMessage $_createMessage() => ParseImportRequest._();
  @$core.override
  ParseImportRequest createEmptyInstance() => ParseImportRequest._();
  @$core.pragma('dart2js:noInline')
  static ParseImportRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseImportRequest>(ParseImportRequest.$_createMessage);
  static ParseImportRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get payload => $_getN(2);
  @$pb.TagNumber(3)
  set payload($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField(3);
}

class ParseImportResponse extends $pb.GeneratedMessage {
  factory ParseImportResponse({
    SessionPlan? sessionPlan,
    SoraError? error,
  }) {
    final result = ParseImportResponse._();
    if (sessionPlan != null) result.sessionPlan = sessionPlan;
    if (error != null) result.error = error;
    return result;
  }

  ParseImportResponse._();

  factory ParseImportResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ParseImportResponse()..mergeFromBuffer(data, registry);
  factory ParseImportResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ParseImportResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ParseImportResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ParseImportResponse.$_createMessage)
    ..aOM<SessionPlan>(1, _omitFieldNames ? '' : 'sessionPlan', subBuilder: SessionPlan.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseImportResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ParseImportResponse copyWith(void Function(ParseImportResponse) updates) =>
      super.copyWith((message) => updates(message as ParseImportResponse)) as ParseImportResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ParseImportResponse() / ParseImportResponse.new instead')
  static ParseImportResponse create() => ParseImportResponse._();
  static $pb.GeneratedMessage $_createMessage() => ParseImportResponse._();
  @$core.override
  ParseImportResponse createEmptyInstance() => ParseImportResponse._();
  @$core.pragma('dart2js:noInline')
  static ParseImportResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ParseImportResponse>(ParseImportResponse.$_createMessage);
  static ParseImportResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SessionPlan get sessionPlan => $_getN(0);
  @$pb.TagNumber(1)
  set sessionPlan(SessionPlan value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSessionPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearSessionPlan() => $_clearField(1);
  @$pb.TagNumber(1)
  SessionPlan ensureSessionPlan() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = FetchSubscriptionRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (reference != null) result.reference = reference;
    if (userAgent != null) result.userAgent = userAgent;
    return result;
  }

  FetchSubscriptionRequest._();

  factory FetchSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchSubscriptionRequest()..mergeFromBuffer(data, registry);
  factory FetchSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchSubscriptionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: FetchSubscriptionRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'reference')
    ..aOS(4, _omitFieldNames ? '' : 'userAgent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSubscriptionRequest copyWith(void Function(FetchSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as FetchSubscriptionRequest)) as FetchSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FetchSubscriptionRequest() / FetchSubscriptionRequest.new instead')
  static FetchSubscriptionRequest create() => FetchSubscriptionRequest._();
  static $pb.GeneratedMessage $_createMessage() => FetchSubscriptionRequest._();
  @$core.override
  FetchSubscriptionRequest createEmptyInstance() => FetchSubscriptionRequest._();
  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchSubscriptionRequest>(FetchSubscriptionRequest.$_createMessage);
  static FetchSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get reference => $_getSZ(2);
  @$pb.TagNumber(3)
  set reference($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasReference() => $_has(2);
  @$pb.TagNumber(3)
  void clearReference() => $_clearField(3);

  /// Since 1.3. Replaces the default User-Agent for this subscription: panels
  /// choose the format of their answer by it. Printable ASCII, at most 256 bytes.
  @$pb.TagNumber(4)
  $core.String get userAgent => $_getSZ(3);
  @$pb.TagNumber(4)
  set userAgent($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserAgent() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserAgent() => $_clearField(4);
}

class FetchSubscriptionResponse extends $pb.GeneratedMessage {
  factory FetchSubscriptionResponse({
    $core.Iterable<OutboundSpec>? outbounds,
    SoraError? error,
    SubscriptionInfo? info,
  }) {
    final result = FetchSubscriptionResponse._();
    if (outbounds != null) result.outbounds.addAll(outbounds);
    if (error != null) result.error = error;
    if (info != null) result.info = info;
    return result;
  }

  FetchSubscriptionResponse._();

  factory FetchSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchSubscriptionResponse()..mergeFromBuffer(data, registry);
  factory FetchSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      FetchSubscriptionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'FetchSubscriptionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: FetchSubscriptionResponse.$_createMessage)
    ..pPM<OutboundSpec>(1, _omitFieldNames ? '' : 'outbounds', subBuilder: OutboundSpec.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..aOM<SubscriptionInfo>(3, _omitFieldNames ? '' : 'info', subBuilder: SubscriptionInfo.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSubscriptionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  FetchSubscriptionResponse copyWith(void Function(FetchSubscriptionResponse) updates) =>
      super.copyWith((message) => updates(message as FetchSubscriptionResponse)) as FetchSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use FetchSubscriptionResponse() / FetchSubscriptionResponse.new instead')
  static FetchSubscriptionResponse create() => FetchSubscriptionResponse._();
  static $pb.GeneratedMessage $_createMessage() => FetchSubscriptionResponse._();
  @$core.override
  FetchSubscriptionResponse createEmptyInstance() => FetchSubscriptionResponse._();
  @$core.pragma('dart2js:noInline')
  static FetchSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<FetchSubscriptionResponse>(FetchSubscriptionResponse.$_createMessage);
  static FetchSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<OutboundSpec> get outbounds => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);

  /// Since 1.3. What the provider said about the subscription.
  @$pb.TagNumber(3)
  SubscriptionInfo get info => $_getN(2);
  @$pb.TagNumber(3)
  set info(SubscriptionInfo value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearInfo() => $_clearField(3);
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
    final result = SubscriptionInfo._();
    if (title != null) result.title = title;
    if (updateInterval != null) result.updateInterval = updateInterval;
    if (hasUsage != null) result.hasUsage = hasUsage;
    if (uploadBytes != null) result.uploadBytes = uploadBytes;
    if (downloadBytes != null) result.downloadBytes = downloadBytes;
    if (totalBytes != null) result.totalBytes = totalBytes;
    if (expire != null) result.expire = expire;
    if (webPageUrl != null) result.webPageUrl = webPageUrl;
    if (supportUrl != null) result.supportUrl = supportUrl;
    if (announce != null) result.announce = announce;
    return result;
  }

  SubscriptionInfo._();

  factory SubscriptionInfo.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionInfo()..mergeFromBuffer(data, registry);
  factory SubscriptionInfo.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionInfo()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionInfo',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SubscriptionInfo.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'title')
    ..aOM<$1.Duration>(2, _omitFieldNames ? '' : 'updateInterval', subBuilder: $1.Duration.$_createMessage)
    ..aOB(3, _omitFieldNames ? '' : 'hasUsage')
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'uploadBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'downloadBytes', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'totalBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(7, _omitFieldNames ? '' : 'expire', subBuilder: $2.Timestamp.$_createMessage)
    ..aOS(8, _omitFieldNames ? '' : 'webPageUrl')
    ..aOS(9, _omitFieldNames ? '' : 'supportUrl')
    ..aOS(10, _omitFieldNames ? '' : 'announce')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionInfo clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionInfo copyWith(void Function(SubscriptionInfo) updates) =>
      super.copyWith((message) => updates(message as SubscriptionInfo)) as SubscriptionInfo;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscriptionInfo() / SubscriptionInfo.new instead')
  static SubscriptionInfo create() => SubscriptionInfo._();
  static $pb.GeneratedMessage $_createMessage() => SubscriptionInfo._();
  @$core.override
  SubscriptionInfo createEmptyInstance() => SubscriptionInfo._();
  @$core.pragma('dart2js:noInline')
  static SubscriptionInfo getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionInfo>(SubscriptionInfo.$_createMessage);
  static SubscriptionInfo? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get title => $_getSZ(0);
  @$pb.TagNumber(1)
  set title($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTitle() => $_has(0);
  @$pb.TagNumber(1)
  void clearTitle() => $_clearField(1);

  /// How often the provider asks to be fetched; unset when it did not say.
  @$pb.TagNumber(2)
  $1.Duration get updateInterval => $_getN(1);
  @$pb.TagNumber(2)
  set updateInterval($1.Duration value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUpdateInterval() => $_has(1);
  @$pb.TagNumber(2)
  void clearUpdateInterval() => $_clearField(2);
  @$pb.TagNumber(2)
  $1.Duration ensureUpdateInterval() => $_ensure(1);

  /// Whether the provider sent traffic figures at all.
  @$pb.TagNumber(3)
  $core.bool get hasUsage => $_getBF(2);
  @$pb.TagNumber(3)
  set hasUsage($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHasUsage() => $_has(2);
  @$pb.TagNumber(3)
  void clearHasUsage() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get uploadBytes => $_getI64(3);
  @$pb.TagNumber(4)
  set uploadBytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUploadBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploadBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get downloadBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set downloadBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDownloadBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearDownloadBytes() => $_clearField(5);

  /// Zero means unlimited.
  @$pb.TagNumber(6)
  $fixnum.Int64 get totalBytes => $_getI64(5);
  @$pb.TagNumber(6)
  set totalBytes($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasTotalBytes() => $_has(5);
  @$pb.TagNumber(6)
  void clearTotalBytes() => $_clearField(6);

  /// Unset when the subscription does not expire.
  @$pb.TagNumber(7)
  $2.Timestamp get expire => $_getN(6);
  @$pb.TagNumber(7)
  set expire($2.Timestamp value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasExpire() => $_has(6);
  @$pb.TagNumber(7)
  void clearExpire() => $_clearField(7);
  @$pb.TagNumber(7)
  $2.Timestamp ensureExpire() => $_ensure(6);

  /// https, http or tg links only.
  @$pb.TagNumber(8)
  $core.String get webPageUrl => $_getSZ(7);
  @$pb.TagNumber(8)
  set webPageUrl($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasWebPageUrl() => $_has(7);
  @$pb.TagNumber(8)
  void clearWebPageUrl() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get supportUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set supportUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSupportUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearSupportUrl() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.String get announce => $_getSZ(9);
  @$pb.TagNumber(10)
  set announce($core.String value) => $_setString(9, value);
  @$pb.TagNumber(10)
  $core.bool hasAnnounce() => $_has(9);
  @$pb.TagNumber(10)
  void clearAnnounce() => $_clearField(10);
}

class ProbeServersRequest extends $pb.GeneratedMessage {
  factory ProbeServersRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.Iterable<Endpoint>? endpoints,
    $core.Iterable<OutboundSpec>? outbounds,
    ProbeOptions? options,
  }) {
    final result = ProbeServersRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (endpoints != null) result.endpoints.addAll(endpoints);
    if (outbounds != null) result.outbounds.addAll(outbounds);
    if (options != null) result.options = options;
    return result;
  }

  ProbeServersRequest._();

  factory ProbeServersRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeServersRequest()..mergeFromBuffer(data, registry);
  factory ProbeServersRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeServersRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeServersRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ProbeServersRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..pPM<Endpoint>(3, _omitFieldNames ? '' : 'endpoints', subBuilder: Endpoint.$_createMessage)
    ..pPM<OutboundSpec>(4, _omitFieldNames ? '' : 'outbounds', subBuilder: OutboundSpec.$_createMessage)
    ..aOM<ProbeOptions>(5, _omitFieldNames ? '' : 'options', subBuilder: ProbeOptions.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeServersRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeServersRequest copyWith(void Function(ProbeServersRequest) updates) =>
      super.copyWith((message) => updates(message as ProbeServersRequest)) as ProbeServersRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProbeServersRequest() / ProbeServersRequest.new instead')
  static ProbeServersRequest create() => ProbeServersRequest._();
  static $pb.GeneratedMessage $_createMessage() => ProbeServersRequest._();
  @$core.override
  ProbeServersRequest createEmptyInstance() => ProbeServersRequest._();
  @$core.pragma('dart2js:noInline')
  static ProbeServersRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeServersRequest>(ProbeServersRequest.$_createMessage);
  static ProbeServersRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  /// Measured with a TCP connection only.
  @$pb.TagNumber(3)
  $pb.PbList<Endpoint> get endpoints => $_getList(2);

  /// Since 1.3. Measured as the options say; results carry the outbound id.
  @$pb.TagNumber(4)
  $pb.PbList<OutboundSpec> get outbounds => $_getList(3);

  @$pb.TagNumber(5)
  ProbeOptions get options => $_getN(4);
  @$pb.TagNumber(5)
  set options(ProbeOptions value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasOptions() => $_has(4);
  @$pb.TagNumber(5)
  void clearOptions() => $_clearField(5);
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
    final result = ProbeOptions._();
    if (method != null) result.method = method;
    if (url != null) result.url = url;
    if (timeoutMs != null) result.timeoutMs = timeoutMs;
    if (concurrency != null) result.concurrency = concurrency;
    if (engines != null) result.engines.addAll(engines);
    return result;
  }

  ProbeOptions._();

  factory ProbeOptions.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeOptions()..mergeFromBuffer(data, registry);
  factory ProbeOptions.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ProbeOptions()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ProbeOptions',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ProbeOptions.$_createMessage)
    ..aE<ProbeMethod>(1, _omitFieldNames ? '' : 'method', enumValues: ProbeMethod.values)
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..aI(3, _omitFieldNames ? '' : 'timeoutMs', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'concurrency', fieldType: $pb.PbFieldType.OU3)
    ..pPS(5, _omitFieldNames ? '' : 'engines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeOptions clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ProbeOptions copyWith(void Function(ProbeOptions) updates) =>
      super.copyWith((message) => updates(message as ProbeOptions)) as ProbeOptions;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ProbeOptions() / ProbeOptions.new instead')
  static ProbeOptions create() => ProbeOptions._();
  static $pb.GeneratedMessage $_createMessage() => ProbeOptions._();
  @$core.override
  ProbeOptions createEmptyInstance() => ProbeOptions._();
  @$core.pragma('dart2js:noInline')
  static ProbeOptions getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ProbeOptions>(ProbeOptions.$_createMessage);
  static ProbeOptions? _defaultInstance;

  @$pb.TagNumber(1)
  ProbeMethod get method => $_getN(0);
  @$pb.TagNumber(1)
  set method(ProbeMethod value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMethod() => $_has(0);
  @$pb.TagNumber(1)
  void clearMethod() => $_clearField(1);

  /// The URL requested through each server; it should answer 204 or 200.
  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get timeoutMs => $_getIZ(2);
  @$pb.TagNumber(3)
  set timeoutMs($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTimeoutMs() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimeoutMs() => $_clearField(3);

  /// How many servers are measured at once.
  @$pb.TagNumber(4)
  $core.int get concurrency => $_getIZ(3);
  @$pb.TagNumber(4)
  set concurrency($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConcurrency() => $_has(3);
  @$pb.TagNumber(4)
  void clearConcurrency() => $_clearField(4);

  /// Engine preference for the measurement, as in SessionPlan.engines.
  @$pb.TagNumber(5)
  $pb.PbList<$core.String> get engines => $_getList(4);
}

class RunDiagnosticsRequest extends $pb.GeneratedMessage {
  factory RunDiagnosticsRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
  }) {
    final result = RunDiagnosticsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  RunDiagnosticsRequest._();

  factory RunDiagnosticsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunDiagnosticsRequest()..mergeFromBuffer(data, registry);
  factory RunDiagnosticsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunDiagnosticsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RunDiagnosticsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RunDiagnosticsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunDiagnosticsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunDiagnosticsRequest copyWith(void Function(RunDiagnosticsRequest) updates) =>
      super.copyWith((message) => updates(message as RunDiagnosticsRequest)) as RunDiagnosticsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunDiagnosticsRequest() / RunDiagnosticsRequest.new instead')
  static RunDiagnosticsRequest create() => RunDiagnosticsRequest._();
  static $pb.GeneratedMessage $_createMessage() => RunDiagnosticsRequest._();
  @$core.override
  RunDiagnosticsRequest createEmptyInstance() => RunDiagnosticsRequest._();
  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunDiagnosticsRequest>(RunDiagnosticsRequest.$_createMessage);
  static RunDiagnosticsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);
}

class RunDiagnosticsResponse extends $pb.GeneratedMessage {
  factory RunDiagnosticsResponse({
    DiagnosticReport? report,
    SoraError? error,
  }) {
    final result = RunDiagnosticsResponse._();
    if (report != null) result.report = report;
    if (error != null) result.error = error;
    return result;
  }

  RunDiagnosticsResponse._();

  factory RunDiagnosticsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunDiagnosticsResponse()..mergeFromBuffer(data, registry);
  factory RunDiagnosticsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RunDiagnosticsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RunDiagnosticsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RunDiagnosticsResponse.$_createMessage)
    ..aOM<DiagnosticReport>(1, _omitFieldNames ? '' : 'report', subBuilder: DiagnosticReport.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunDiagnosticsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RunDiagnosticsResponse copyWith(void Function(RunDiagnosticsResponse) updates) =>
      super.copyWith((message) => updates(message as RunDiagnosticsResponse)) as RunDiagnosticsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RunDiagnosticsResponse() / RunDiagnosticsResponse.new instead')
  static RunDiagnosticsResponse create() => RunDiagnosticsResponse._();
  static $pb.GeneratedMessage $_createMessage() => RunDiagnosticsResponse._();
  @$core.override
  RunDiagnosticsResponse createEmptyInstance() => RunDiagnosticsResponse._();
  @$core.pragma('dart2js:noInline')
  static RunDiagnosticsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RunDiagnosticsResponse>(RunDiagnosticsResponse.$_createMessage);
  static RunDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  DiagnosticReport get report => $_getN(0);
  @$pb.TagNumber(1)
  set report(DiagnosticReport value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasReport() => $_has(0);
  @$pb.TagNumber(1)
  void clearReport() => $_clearField(1);
  @$pb.TagNumber(1)
  DiagnosticReport ensureReport() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class ExportDiagnosticsRequest extends $pb.GeneratedMessage {
  factory ExportDiagnosticsRequest({
    ApiVersion? apiVersion,
    $core.String? requestId,
    $core.String? sessionId,
  }) {
    final result = ExportDiagnosticsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ExportDiagnosticsRequest._();

  factory ExportDiagnosticsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportDiagnosticsRequest()..mergeFromBuffer(data, registry);
  factory ExportDiagnosticsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportDiagnosticsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportDiagnosticsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ExportDiagnosticsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportDiagnosticsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportDiagnosticsRequest copyWith(void Function(ExportDiagnosticsRequest) updates) =>
      super.copyWith((message) => updates(message as ExportDiagnosticsRequest)) as ExportDiagnosticsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExportDiagnosticsRequest() / ExportDiagnosticsRequest.new instead')
  static ExportDiagnosticsRequest create() => ExportDiagnosticsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExportDiagnosticsRequest._();
  @$core.override
  ExportDiagnosticsRequest createEmptyInstance() => ExportDiagnosticsRequest._();
  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportDiagnosticsRequest>(ExportDiagnosticsRequest.$_createMessage);
  static ExportDiagnosticsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);
}

class ExportDiagnosticsResponse extends $pb.GeneratedMessage {
  factory ExportDiagnosticsResponse({
    $core.List<$core.int>? archive,
    SoraError? error,
  }) {
    final result = ExportDiagnosticsResponse._();
    if (archive != null) result.archive = archive;
    if (error != null) result.error = error;
    return result;
  }

  ExportDiagnosticsResponse._();

  factory ExportDiagnosticsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportDiagnosticsResponse()..mergeFromBuffer(data, registry);
  factory ExportDiagnosticsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportDiagnosticsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportDiagnosticsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ExportDiagnosticsResponse.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'archive', $pb.PbFieldType.OY)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportDiagnosticsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportDiagnosticsResponse copyWith(void Function(ExportDiagnosticsResponse) updates) =>
      super.copyWith((message) => updates(message as ExportDiagnosticsResponse)) as ExportDiagnosticsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExportDiagnosticsResponse() / ExportDiagnosticsResponse.new instead')
  static ExportDiagnosticsResponse create() => ExportDiagnosticsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ExportDiagnosticsResponse._();
  @$core.override
  ExportDiagnosticsResponse createEmptyInstance() => ExportDiagnosticsResponse._();
  @$core.pragma('dart2js:noInline')
  static ExportDiagnosticsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ExportDiagnosticsResponse>(ExportDiagnosticsResponse.$_createMessage);
  static ExportDiagnosticsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get archive => $_getN(0);
  @$pb.TagNumber(1)
  set archive($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasArchive() => $_has(0);
  @$pb.TagNumber(1)
  void clearArchive() => $_clearField(1);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = SetKillSwitchRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (sessionId != null) result.sessionId = sessionId;
    if (enabled != null) result.enabled = enabled;
    return result;
  }

  SetKillSwitchRequest._();

  factory SetKillSwitchRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetKillSwitchRequest()..mergeFromBuffer(data, registry);
  factory SetKillSwitchRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetKillSwitchRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetKillSwitchRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SetKillSwitchRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOB(4, _omitFieldNames ? '' : 'enabled')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetKillSwitchRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetKillSwitchRequest copyWith(void Function(SetKillSwitchRequest) updates) =>
      super.copyWith((message) => updates(message as SetKillSwitchRequest)) as SetKillSwitchRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetKillSwitchRequest() / SetKillSwitchRequest.new instead')
  static SetKillSwitchRequest create() => SetKillSwitchRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetKillSwitchRequest._();
  @$core.override
  SetKillSwitchRequest createEmptyInstance() => SetKillSwitchRequest._();
  @$core.pragma('dart2js:noInline')
  static SetKillSwitchRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetKillSwitchRequest>(SetKillSwitchRequest.$_createMessage);
  static SetKillSwitchRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get enabled => $_getBF(3);
  @$pb.TagNumber(4)
  set enabled($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasEnabled() => $_has(3);
  @$pb.TagNumber(4)
  void clearEnabled() => $_clearField(4);
}

class SetKillSwitchResponse extends $pb.GeneratedMessage {
  factory SetKillSwitchResponse({
    $core.bool? enabled,
    SoraError? error,
  }) {
    final result = SetKillSwitchResponse._();
    if (enabled != null) result.enabled = enabled;
    if (error != null) result.error = error;
    return result;
  }

  SetKillSwitchResponse._();

  factory SetKillSwitchResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetKillSwitchResponse()..mergeFromBuffer(data, registry);
  factory SetKillSwitchResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetKillSwitchResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetKillSwitchResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SetKillSwitchResponse.$_createMessage)
    ..aOB(1, _omitFieldNames ? '' : 'enabled')
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetKillSwitchResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetKillSwitchResponse copyWith(void Function(SetKillSwitchResponse) updates) =>
      super.copyWith((message) => updates(message as SetKillSwitchResponse)) as SetKillSwitchResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetKillSwitchResponse() / SetKillSwitchResponse.new instead')
  static SetKillSwitchResponse create() => SetKillSwitchResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetKillSwitchResponse._();
  @$core.override
  SetKillSwitchResponse createEmptyInstance() => SetKillSwitchResponse._();
  @$core.pragma('dart2js:noInline')
  static SetKillSwitchResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetKillSwitchResponse>(SetKillSwitchResponse.$_createMessage);
  static SetKillSwitchResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get enabled => $_getBF(0);
  @$pb.TagNumber(1)
  set enabled($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEnabled() => $_has(0);
  @$pb.TagNumber(1)
  void clearEnabled() => $_clearField(1);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class DiagnosticReport extends $pb.GeneratedMessage {
  factory DiagnosticReport({
    $core.Iterable<$core.String>? lines,
  }) {
    final result = DiagnosticReport._();
    if (lines != null) result.lines.addAll(lines);
    return result;
  }

  DiagnosticReport._();

  factory DiagnosticReport.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiagnosticReport()..mergeFromBuffer(data, registry);
  factory DiagnosticReport.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DiagnosticReport()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DiagnosticReport',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DiagnosticReport.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'lines')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticReport clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DiagnosticReport copyWith(void Function(DiagnosticReport) updates) =>
      super.copyWith((message) => updates(message as DiagnosticReport)) as DiagnosticReport;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DiagnosticReport() / DiagnosticReport.new instead')
  static DiagnosticReport create() => DiagnosticReport._();
  static $pb.GeneratedMessage $_createMessage() => DiagnosticReport._();
  @$core.override
  DiagnosticReport createEmptyInstance() => DiagnosticReport._();
  @$core.pragma('dart2js:noInline')
  static DiagnosticReport getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DiagnosticReport>(DiagnosticReport.$_createMessage);
  static DiagnosticReport? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get lines => $_getList(0);
}

class HandshakeRequest extends $pb.GeneratedMessage {
  factory HandshakeRequest({
    ApiVersion? clientVersion,
  }) {
    final result = HandshakeRequest._();
    if (clientVersion != null) result.clientVersion = clientVersion;
    return result;
  }

  HandshakeRequest._();

  factory HandshakeRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeRequest()..mergeFromBuffer(data, registry);
  factory HandshakeRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: HandshakeRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'clientVersion', subBuilder: ApiVersion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeRequest copyWith(void Function(HandshakeRequest) updates) =>
      super.copyWith((message) => updates(message as HandshakeRequest)) as HandshakeRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HandshakeRequest() / HandshakeRequest.new instead')
  static HandshakeRequest create() => HandshakeRequest._();
  static $pb.GeneratedMessage $_createMessage() => HandshakeRequest._();
  @$core.override
  HandshakeRequest createEmptyInstance() => HandshakeRequest._();
  @$core.pragma('dart2js:noInline')
  static HandshakeRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeRequest>(HandshakeRequest.$_createMessage);
  static HandshakeRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get clientVersion => $_getN(0);
  @$pb.TagNumber(1)
  set clientVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasClientVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearClientVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureClientVersion() => $_ensure(0);
}

class HandshakeResponse extends $pb.GeneratedMessage {
  factory HandshakeResponse({
    ApiVersion? negotiatedVersion,
    SoraError? error,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = HandshakeResponse._();
    if (negotiatedVersion != null) result.negotiatedVersion = negotiatedVersion;
    if (error != null) result.error = error;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  HandshakeResponse._();

  factory HandshakeResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeResponse()..mergeFromBuffer(data, registry);
  factory HandshakeResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      HandshakeResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'HandshakeResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: HandshakeResponse.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'negotiatedVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  HandshakeResponse copyWith(void Function(HandshakeResponse) updates) =>
      super.copyWith((message) => updates(message as HandshakeResponse)) as HandshakeResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use HandshakeResponse() / HandshakeResponse.new instead')
  static HandshakeResponse create() => HandshakeResponse._();
  static $pb.GeneratedMessage $_createMessage() => HandshakeResponse._();
  @$core.override
  HandshakeResponse createEmptyInstance() => HandshakeResponse._();
  @$core.pragma('dart2js:noInline')
  static HandshakeResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<HandshakeResponse>(HandshakeResponse.$_createMessage);
  static HandshakeResponse? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get negotiatedVersion => $_getN(0);
  @$pb.TagNumber(1)
  set negotiatedVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasNegotiatedVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearNegotiatedVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureNegotiatedVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);

  /// Since 1.3. The token the other calls present. The transport admits only
  /// the core's own account, the service group and the person in the active
  /// local session, so whoever reaches Handshake may hold it; a system
  /// installation keeps the token file where that person cannot read it.
  @$pb.TagNumber(3)
  $core.List<$core.int> get controlAuthenticator => $_getN(2);
  @$pb.TagNumber(3)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasControlAuthenticator() => $_has(2);
  @$pb.TagNumber(3)
  void clearControlAuthenticator() => $_clearField(3);
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
    final result = PutSecretRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (credentials != null) result.credentials = credentials;
    if (material != null) result.material = material;
    return result;
  }

  PutSecretRequest._();

  factory PutSecretRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutSecretRequest()..mergeFromBuffer(data, registry);
  factory PutSecretRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutSecretRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PutSecretRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: PutSecretRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<CredentialsRef>(3, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.$_createMessage)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'material', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutSecretRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutSecretRequest copyWith(void Function(PutSecretRequest) updates) =>
      super.copyWith((message) => updates(message as PutSecretRequest)) as PutSecretRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PutSecretRequest() / PutSecretRequest.new instead')
  static PutSecretRequest create() => PutSecretRequest._();
  static $pb.GeneratedMessage $_createMessage() => PutSecretRequest._();
  @$core.override
  PutSecretRequest createEmptyInstance() => PutSecretRequest._();
  @$core.pragma('dart2js:noInline')
  static PutSecretRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PutSecretRequest>(PutSecretRequest.$_createMessage);
  static PutSecretRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  CredentialsRef get credentials => $_getN(2);
  @$pb.TagNumber(3)
  set credentials(CredentialsRef value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCredentials() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredentials() => $_clearField(3);
  @$pb.TagNumber(3)
  CredentialsRef ensureCredentials() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get material => $_getN(3);
  @$pb.TagNumber(4)
  set material($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaterial() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaterial() => $_clearField(4);
}

class PutSecretResponse extends $pb.GeneratedMessage {
  factory PutSecretResponse({
    CredentialsRef? credentials,
    SoraError? error,
  }) {
    final result = PutSecretResponse._();
    if (credentials != null) result.credentials = credentials;
    if (error != null) result.error = error;
    return result;
  }

  PutSecretResponse._();

  factory PutSecretResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutSecretResponse()..mergeFromBuffer(data, registry);
  factory PutSecretResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      PutSecretResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PutSecretResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: PutSecretResponse.$_createMessage)
    ..aOM<CredentialsRef>(1, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutSecretResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PutSecretResponse copyWith(void Function(PutSecretResponse) updates) =>
      super.copyWith((message) => updates(message as PutSecretResponse)) as PutSecretResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use PutSecretResponse() / PutSecretResponse.new instead')
  static PutSecretResponse create() => PutSecretResponse._();
  static $pb.GeneratedMessage $_createMessage() => PutSecretResponse._();
  @$core.override
  PutSecretResponse createEmptyInstance() => PutSecretResponse._();
  @$core.pragma('dart2js:noInline')
  static PutSecretResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PutSecretResponse>(PutSecretResponse.$_createMessage);
  static PutSecretResponse? _defaultInstance;

  @$pb.TagNumber(1)
  CredentialsRef get credentials => $_getN(0);
  @$pb.TagNumber(1)
  set credentials(CredentialsRef value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCredentials() => $_has(0);
  @$pb.TagNumber(1)
  void clearCredentials() => $_clearField(1);
  @$pb.TagNumber(1)
  CredentialsRef ensureCredentials() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = DeleteSecretRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (requestId != null) result.requestId = requestId;
    if (credentials != null) result.credentials = credentials;
    return result;
  }

  DeleteSecretRequest._();

  factory DeleteSecretRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSecretRequest()..mergeFromBuffer(data, registry);
  factory DeleteSecretRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSecretRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSecretRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DeleteSecretRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..aOS(2, _omitFieldNames ? '' : 'requestId')
    ..aOM<CredentialsRef>(3, _omitFieldNames ? '' : 'credentials', subBuilder: CredentialsRef.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSecretRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSecretRequest copyWith(void Function(DeleteSecretRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSecretRequest)) as DeleteSecretRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteSecretRequest() / DeleteSecretRequest.new instead')
  static DeleteSecretRequest create() => DeleteSecretRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteSecretRequest._();
  @$core.override
  DeleteSecretRequest createEmptyInstance() => DeleteSecretRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteSecretRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DeleteSecretRequest>(DeleteSecretRequest.$_createMessage);
  static DeleteSecretRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.String get requestId => $_getSZ(1);
  @$pb.TagNumber(2)
  set requestId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRequestId() => $_has(1);
  @$pb.TagNumber(2)
  void clearRequestId() => $_clearField(2);

  @$pb.TagNumber(3)
  CredentialsRef get credentials => $_getN(2);
  @$pb.TagNumber(3)
  set credentials(CredentialsRef value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCredentials() => $_has(2);
  @$pb.TagNumber(3)
  void clearCredentials() => $_clearField(3);
  @$pb.TagNumber(3)
  CredentialsRef ensureCredentials() => $_ensure(2);
}

class DeleteSecretResponse extends $pb.GeneratedMessage {
  factory DeleteSecretResponse({
    SoraError? error,
  }) {
    final result = DeleteSecretResponse._();
    if (error != null) result.error = error;
    return result;
  }

  DeleteSecretResponse._();

  factory DeleteSecretResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSecretResponse()..mergeFromBuffer(data, registry);
  factory DeleteSecretResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSecretResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSecretResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DeleteSecretResponse.$_createMessage)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSecretResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSecretResponse copyWith(void Function(DeleteSecretResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteSecretResponse)) as DeleteSecretResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteSecretResponse() / DeleteSecretResponse.new instead')
  static DeleteSecretResponse create() => DeleteSecretResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteSecretResponse._();
  @$core.override
  DeleteSecretResponse createEmptyInstance() => DeleteSecretResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteSecretResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSecretResponse>(DeleteSecretResponse.$_createMessage);
  static DeleteSecretResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
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
    final result = SoraError._();
    if (code != null) result.code = code;
    if (userMessageKey != null) result.userMessageKey = userMessageKey;
    if (detailRedacted != null) result.detailRedacted = detailRedacted;
    if (retryable != null) result.retryable = retryable;
    if (requestId != null) result.requestId = requestId;
    if (retryAfter != null) result.retryAfter = retryAfter;
    return result;
  }

  SoraError._();

  factory SoraError.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SoraError()..mergeFromBuffer(data, registry);
  factory SoraError.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SoraError()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SoraError',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SoraError.$_createMessage)
    ..aE<SoraErrorCode>(1, _omitFieldNames ? '' : 'code', enumValues: SoraErrorCode.values)
    ..aOS(2, _omitFieldNames ? '' : 'userMessageKey')
    ..aOS(3, _omitFieldNames ? '' : 'detailRedacted')
    ..aOB(4, _omitFieldNames ? '' : 'retryable')
    ..aOS(5, _omitFieldNames ? '' : 'requestId')
    ..aOM<$1.Duration>(6, _omitFieldNames ? '' : 'retryAfter', subBuilder: $1.Duration.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoraError clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SoraError copyWith(void Function(SoraError) updates) =>
      super.copyWith((message) => updates(message as SoraError)) as SoraError;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SoraError() / SoraError.new instead')
  static SoraError create() => SoraError._();
  static $pb.GeneratedMessage $_createMessage() => SoraError._();
  @$core.override
  SoraError createEmptyInstance() => SoraError._();
  @$core.pragma('dart2js:noInline')
  static SoraError getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SoraError>(SoraError.$_createMessage);
  static SoraError? _defaultInstance;

  @$pb.TagNumber(1)
  SoraErrorCode get code => $_getN(0);
  @$pb.TagNumber(1)
  set code(SoraErrorCode value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCode() => $_has(0);
  @$pb.TagNumber(1)
  void clearCode() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get userMessageKey => $_getSZ(1);
  @$pb.TagNumber(2)
  set userMessageKey($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserMessageKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserMessageKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get detailRedacted => $_getSZ(2);
  @$pb.TagNumber(3)
  set detailRedacted($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDetailRedacted() => $_has(2);
  @$pb.TagNumber(3)
  void clearDetailRedacted() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get retryable => $_getBF(3);
  @$pb.TagNumber(4)
  set retryable($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRetryable() => $_has(3);
  @$pb.TagNumber(4)
  void clearRetryable() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get requestId => $_getSZ(4);
  @$pb.TagNumber(5)
  set requestId($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRequestId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRequestId() => $_clearField(5);

  @$pb.TagNumber(6)
  $1.Duration get retryAfter => $_getN(5);
  @$pb.TagNumber(6)
  set retryAfter($1.Duration value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasRetryAfter() => $_has(5);
  @$pb.TagNumber(6)
  void clearRetryAfter() => $_clearField(6);
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
    final result = LogEntry._();
    if (sequence != null) result.sequence = sequence;
    if (time != null) result.time = time;
    if (level != null) result.level = level;
    if (source != null) result.source = source;
    if (message != null) result.message = message;
    if (repeat != null) result.repeat = repeat;
    return result;
  }

  LogEntry._();

  factory LogEntry.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromBuffer(data, registry);
  factory LogEntry.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogEntry()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogEntry',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogEntry.$_createMessage)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'sequence', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(2, _omitFieldNames ? '' : 'time', subBuilder: $2.Timestamp.$_createMessage)
    ..aE<LogLevel>(3, _omitFieldNames ? '' : 'level', enumValues: LogLevel.values)
    ..aOS(4, _omitFieldNames ? '' : 'source')
    ..aOS(5, _omitFieldNames ? '' : 'message')
    ..aI(6, _omitFieldNames ? '' : 'repeat', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogEntry copyWith(void Function(LogEntry) updates) =>
      super.copyWith((message) => updates(message as LogEntry)) as LogEntry;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogEntry() / LogEntry.new instead')
  static LogEntry create() => LogEntry._();
  static $pb.GeneratedMessage $_createMessage() => LogEntry._();
  @$core.override
  LogEntry createEmptyInstance() => LogEntry._();
  @$core.pragma('dart2js:noInline')
  static LogEntry getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogEntry>(LogEntry.$_createMessage);
  static LogEntry? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get sequence => $_getI64(0);
  @$pb.TagNumber(1)
  set sequence($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSequence() => $_has(0);
  @$pb.TagNumber(1)
  void clearSequence() => $_clearField(1);

  @$pb.TagNumber(2)
  $2.Timestamp get time => $_getN(1);
  @$pb.TagNumber(2)
  set time($2.Timestamp value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTime() => $_has(1);
  @$pb.TagNumber(2)
  void clearTime() => $_clearField(2);
  @$pb.TagNumber(2)
  $2.Timestamp ensureTime() => $_ensure(1);

  @$pb.TagNumber(3)
  LogLevel get level => $_getN(2);
  @$pb.TagNumber(3)
  set level(LogLevel value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasLevel() => $_has(2);
  @$pb.TagNumber(3)
  void clearLevel() => $_clearField(3);

  /// "core" for the service itself, otherwise the engine: sing-box, xray, mihomo.
  @$pb.TagNumber(4)
  $core.String get source => $_getSZ(3);
  @$pb.TagNumber(4)
  set source($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSource() => $_has(3);
  @$pb.TagNumber(4)
  void clearSource() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get message => $_getSZ(4);
  @$pb.TagNumber(5)
  set message($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMessage() => $_has(4);
  @$pb.TagNumber(5)
  void clearMessage() => $_clearField(5);

  /// Identical consecutive messages fold into one entry; a watcher receives the
  /// entry again with the same sequence and a higher repeat.
  @$pb.TagNumber(6)
  $core.int get repeat => $_getIZ(5);
  @$pb.TagNumber(6)
  set repeat($core.int value) => $_setUnsignedInt32(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRepeat() => $_has(5);
  @$pb.TagNumber(6)
  void clearRepeat() => $_clearField(6);
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
    final result = LogFilter._();
    if (minLevel != null) result.minLevel = minLevel;
    if (sources != null) result.sources.addAll(sources);
    if (contains != null) result.contains = contains;
    if (pattern != null) result.pattern = pattern;
    if (since != null) result.since = since;
    if (until != null) result.until = until;
    return result;
  }

  LogFilter._();

  factory LogFilter.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogFilter()..mergeFromBuffer(data, registry);
  factory LogFilter.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogFilter()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogFilter',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogFilter.$_createMessage)
    ..aE<LogLevel>(1, _omitFieldNames ? '' : 'minLevel', enumValues: LogLevel.values)
    ..pPS(2, _omitFieldNames ? '' : 'sources')
    ..aOS(3, _omitFieldNames ? '' : 'contains')
    ..aOS(4, _omitFieldNames ? '' : 'pattern')
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'since', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<$2.Timestamp>(6, _omitFieldNames ? '' : 'until', subBuilder: $2.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogFilter clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogFilter copyWith(void Function(LogFilter) updates) =>
      super.copyWith((message) => updates(message as LogFilter)) as LogFilter;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogFilter() / LogFilter.new instead')
  static LogFilter create() => LogFilter._();
  static $pb.GeneratedMessage $_createMessage() => LogFilter._();
  @$core.override
  LogFilter createEmptyInstance() => LogFilter._();
  @$core.pragma('dart2js:noInline')
  static LogFilter getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogFilter>(LogFilter.$_createMessage);
  static LogFilter? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get minLevel => $_getN(0);
  @$pb.TagNumber(1)
  set minLevel(LogLevel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasMinLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearMinLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get sources => $_getList(1);

  /// Case-insensitive substring of the message.
  @$pb.TagNumber(3)
  $core.String get contains => $_getSZ(2);
  @$pb.TagNumber(3)
  set contains($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasContains() => $_has(2);
  @$pb.TagNumber(3)
  void clearContains() => $_clearField(3);

  /// Case-insensitive regular expression (RE2), at most 512 bytes.
  @$pb.TagNumber(4)
  $core.String get pattern => $_getSZ(3);
  @$pb.TagNumber(4)
  set pattern($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPattern() => $_has(3);
  @$pb.TagNumber(4)
  void clearPattern() => $_clearField(4);

  @$pb.TagNumber(5)
  $2.Timestamp get since => $_getN(4);
  @$pb.TagNumber(5)
  set since($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasSince() => $_has(4);
  @$pb.TagNumber(5)
  void clearSince() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureSince() => $_ensure(4);

  @$pb.TagNumber(6)
  $2.Timestamp get until => $_getN(5);
  @$pb.TagNumber(6)
  set until($2.Timestamp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUntil() => $_has(5);
  @$pb.TagNumber(6)
  void clearUntil() => $_clearField(6);
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
    final result = QueryLogsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (filter != null) result.filter = filter;
    if (beforeSequence != null) result.beforeSequence = beforeSequence;
    if (limit != null) result.limit = limit;
    return result;
  }

  QueryLogsRequest._();

  factory QueryLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryLogsRequest()..mergeFromBuffer(data, registry);
  factory QueryLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryLogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'QueryLogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: QueryLogsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.$_createMessage)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'beforeSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aI(5, _omitFieldNames ? '' : 'limit', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryLogsRequest copyWith(void Function(QueryLogsRequest) updates) =>
      super.copyWith((message) => updates(message as QueryLogsRequest)) as QueryLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QueryLogsRequest() / QueryLogsRequest.new instead')
  static QueryLogsRequest create() => QueryLogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => QueryLogsRequest._();
  @$core.override
  QueryLogsRequest createEmptyInstance() => QueryLogsRequest._();
  @$core.pragma('dart2js:noInline')
  static QueryLogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryLogsRequest>(QueryLogsRequest.$_createMessage);
  static QueryLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  /// Entries older than this sequence; 0 starts at the newest.
  @$pb.TagNumber(4)
  $fixnum.Int64 get beforeSequence => $_getI64(3);
  @$pb.TagNumber(4)
  set beforeSequence($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBeforeSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearBeforeSequence() => $_clearField(4);

  /// At most 1000; 0 means 1000.
  @$pb.TagNumber(5)
  $core.int get limit => $_getIZ(4);
  @$pb.TagNumber(5)
  set limit($core.int value) => $_setUnsignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasLimit() => $_has(4);
  @$pb.TagNumber(5)
  void clearLimit() => $_clearField(5);
}

class QueryLogsResponse extends $pb.GeneratedMessage {
  factory QueryLogsResponse({
    $core.Iterable<LogEntry>? entries,
    $fixnum.Int64? beforeSequence,
    LogStats? stats,
    SoraError? error,
  }) {
    final result = QueryLogsResponse._();
    if (entries != null) result.entries.addAll(entries);
    if (beforeSequence != null) result.beforeSequence = beforeSequence;
    if (stats != null) result.stats = stats;
    if (error != null) result.error = error;
    return result;
  }

  QueryLogsResponse._();

  factory QueryLogsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryLogsResponse()..mergeFromBuffer(data, registry);
  factory QueryLogsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      QueryLogsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'QueryLogsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: QueryLogsResponse.$_createMessage)
    ..pPM<LogEntry>(1, _omitFieldNames ? '' : 'entries', subBuilder: LogEntry.$_createMessage)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'beforeSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<LogStats>(3, _omitFieldNames ? '' : 'stats', subBuilder: LogStats.$_createMessage)
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryLogsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QueryLogsResponse copyWith(void Function(QueryLogsResponse) updates) =>
      super.copyWith((message) => updates(message as QueryLogsResponse)) as QueryLogsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use QueryLogsResponse() / QueryLogsResponse.new instead')
  static QueryLogsResponse create() => QueryLogsResponse._();
  static $pb.GeneratedMessage $_createMessage() => QueryLogsResponse._();
  @$core.override
  QueryLogsResponse createEmptyInstance() => QueryLogsResponse._();
  @$core.pragma('dart2js:noInline')
  static QueryLogsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<QueryLogsResponse>(QueryLogsResponse.$_createMessage);
  static QueryLogsResponse? _defaultInstance;

  /// Newest first.
  @$pb.TagNumber(1)
  $pb.PbList<LogEntry> get entries => $_getList(0);

  /// Cursor of the next, older page; 0 when there is none.
  @$pb.TagNumber(2)
  $fixnum.Int64 get beforeSequence => $_getI64(1);
  @$pb.TagNumber(2)
  set beforeSequence($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBeforeSequence() => $_has(1);
  @$pb.TagNumber(2)
  void clearBeforeSequence() => $_clearField(2);

  @$pb.TagNumber(3)
  LogStats get stats => $_getN(2);
  @$pb.TagNumber(3)
  set stats(LogStats value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasStats() => $_has(2);
  @$pb.TagNumber(3)
  void clearStats() => $_clearField(3);
  @$pb.TagNumber(3)
  LogStats ensureStats() => $_ensure(2);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
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
    final result = LogStats._();
    if (byLevel != null) result.byLevel.addAll(byLevel);
    if (bySource != null) result.bySource.addAll(bySource);
    if (total != null) result.total = total;
    if (bytes != null) result.bytes = bytes;
    if (maxBytes != null) result.maxBytes = maxBytes;
    if (dropped != null) result.dropped = dropped;
    return result;
  }

  LogStats._();

  factory LogStats.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogStats()..mergeFromBuffer(data, registry);
  factory LogStats.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogStats()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogStats',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogStats.$_createMessage)
    ..pPM<LogLevelCount>(1, _omitFieldNames ? '' : 'byLevel', subBuilder: LogLevelCount.$_createMessage)
    ..pPM<LogSourceCount>(2, _omitFieldNames ? '' : 'bySource', subBuilder: LogSourceCount.$_createMessage)
    ..a<$fixnum.Int64>(3, _omitFieldNames ? '' : 'total', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'bytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(5, _omitFieldNames ? '' : 'maxBytes', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(6, _omitFieldNames ? '' : 'dropped', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogStats clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogStats copyWith(void Function(LogStats) updates) =>
      super.copyWith((message) => updates(message as LogStats)) as LogStats;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogStats() / LogStats.new instead')
  static LogStats create() => LogStats._();
  static $pb.GeneratedMessage $_createMessage() => LogStats._();
  @$core.override
  LogStats createEmptyInstance() => LogStats._();
  @$core.pragma('dart2js:noInline')
  static LogStats getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogStats>(LogStats.$_createMessage);
  static LogStats? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<LogLevelCount> get byLevel => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<LogSourceCount> get bySource => $_getList(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get total => $_getI64(2);
  @$pb.TagNumber(3)
  set total($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasTotal() => $_has(2);
  @$pb.TagNumber(3)
  void clearTotal() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get bytes => $_getI64(3);
  @$pb.TagNumber(4)
  set bytes($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearBytes() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get maxBytes => $_getI64(4);
  @$pb.TagNumber(5)
  set maxBytes($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasMaxBytes() => $_has(4);
  @$pb.TagNumber(5)
  void clearMaxBytes() => $_clearField(5);

  /// Entries the bounds evicted since the core started.
  @$pb.TagNumber(6)
  $fixnum.Int64 get dropped => $_getI64(5);
  @$pb.TagNumber(6)
  set dropped($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDropped() => $_has(5);
  @$pb.TagNumber(6)
  void clearDropped() => $_clearField(6);
}

class LogLevelCount extends $pb.GeneratedMessage {
  factory LogLevelCount({
    LogLevel? level,
    $fixnum.Int64? count,
  }) {
    final result = LogLevelCount._();
    if (level != null) result.level = level;
    if (count != null) result.count = count;
    return result;
  }

  LogLevelCount._();

  factory LogLevelCount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogLevelCount()..mergeFromBuffer(data, registry);
  factory LogLevelCount.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogLevelCount()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogLevelCount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogLevelCount.$_createMessage)
    ..aE<LogLevel>(1, _omitFieldNames ? '' : 'level', enumValues: LogLevel.values)
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogLevelCount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogLevelCount copyWith(void Function(LogLevelCount) updates) =>
      super.copyWith((message) => updates(message as LogLevelCount)) as LogLevelCount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogLevelCount() / LogLevelCount.new instead')
  static LogLevelCount create() => LogLevelCount._();
  static $pb.GeneratedMessage $_createMessage() => LogLevelCount._();
  @$core.override
  LogLevelCount createEmptyInstance() => LogLevelCount._();
  @$core.pragma('dart2js:noInline')
  static LogLevelCount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogLevelCount>(LogLevelCount.$_createMessage);
  static LogLevelCount? _defaultInstance;

  @$pb.TagNumber(1)
  LogLevel get level => $_getN(0);
  @$pb.TagNumber(1)
  set level(LogLevel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearLevel() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class LogSourceCount extends $pb.GeneratedMessage {
  factory LogSourceCount({
    $core.String? source,
    $fixnum.Int64? count,
  }) {
    final result = LogSourceCount._();
    if (source != null) result.source = source;
    if (count != null) result.count = count;
    return result;
  }

  LogSourceCount._();

  factory LogSourceCount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogSourceCount()..mergeFromBuffer(data, registry);
  factory LogSourceCount.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogSourceCount()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogSourceCount',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogSourceCount.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'source')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'count', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSourceCount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSourceCount copyWith(void Function(LogSourceCount) updates) =>
      super.copyWith((message) => updates(message as LogSourceCount)) as LogSourceCount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogSourceCount() / LogSourceCount.new instead')
  static LogSourceCount create() => LogSourceCount._();
  static $pb.GeneratedMessage $_createMessage() => LogSourceCount._();
  @$core.override
  LogSourceCount createEmptyInstance() => LogSourceCount._();
  @$core.pragma('dart2js:noInline')
  static LogSourceCount getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogSourceCount>(LogSourceCount.$_createMessage);
  static LogSourceCount? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get source => $_getSZ(0);
  @$pb.TagNumber(1)
  set source($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSource() => $_has(0);
  @$pb.TagNumber(1)
  void clearSource() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get count => $_getI64(1);
  @$pb.TagNumber(2)
  set count($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCount() => $_has(1);
  @$pb.TagNumber(2)
  void clearCount() => $_clearField(2);
}

class WatchLogsRequest extends $pb.GeneratedMessage {
  factory WatchLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogFilter? filter,
    $fixnum.Int64? afterSequence,
  }) {
    final result = WatchLogsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (filter != null) result.filter = filter;
    if (afterSequence != null) result.afterSequence = afterSequence;
    return result;
  }

  WatchLogsRequest._();

  factory WatchLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchLogsRequest()..mergeFromBuffer(data, registry);
  factory WatchLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchLogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchLogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: WatchLogsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.$_createMessage)
    ..a<$fixnum.Int64>(4, _omitFieldNames ? '' : 'afterSequence', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchLogsRequest copyWith(void Function(WatchLogsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchLogsRequest)) as WatchLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchLogsRequest() / WatchLogsRequest.new instead')
  static WatchLogsRequest create() => WatchLogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchLogsRequest._();
  @$core.override
  WatchLogsRequest createEmptyInstance() => WatchLogsRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchLogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WatchLogsRequest>(WatchLogsRequest.$_createMessage);
  static WatchLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  /// Replays the matching entries after this sequence, then follows.
  @$pb.TagNumber(4)
  $fixnum.Int64 get afterSequence => $_getI64(3);
  @$pb.TagNumber(4)
  set afterSequence($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasAfterSequence() => $_has(3);
  @$pb.TagNumber(4)
  void clearAfterSequence() => $_clearField(4);
}

class ExportLogsRequest extends $pb.GeneratedMessage {
  factory ExportLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogFilter? filter,
    LogExportFormat? format,
  }) {
    final result = ExportLogsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (filter != null) result.filter = filter;
    if (format != null) result.format = format;
    return result;
  }

  ExportLogsRequest._();

  factory ExportLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportLogsRequest()..mergeFromBuffer(data, registry);
  factory ExportLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportLogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportLogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ExportLogsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogFilter>(3, _omitFieldNames ? '' : 'filter', subBuilder: LogFilter.$_createMessage)
    ..aE<LogExportFormat>(4, _omitFieldNames ? '' : 'format', enumValues: LogExportFormat.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportLogsRequest copyWith(void Function(ExportLogsRequest) updates) =>
      super.copyWith((message) => updates(message as ExportLogsRequest)) as ExportLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExportLogsRequest() / ExportLogsRequest.new instead')
  static ExportLogsRequest create() => ExportLogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ExportLogsRequest._();
  @$core.override
  ExportLogsRequest createEmptyInstance() => ExportLogsRequest._();
  @$core.pragma('dart2js:noInline')
  static ExportLogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportLogsRequest>(ExportLogsRequest.$_createMessage);
  static ExportLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  LogFilter get filter => $_getN(2);
  @$pb.TagNumber(3)
  set filter(LogFilter value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFilter() => $_has(2);
  @$pb.TagNumber(3)
  void clearFilter() => $_clearField(3);
  @$pb.TagNumber(3)
  LogFilter ensureFilter() => $_ensure(2);

  @$pb.TagNumber(4)
  LogExportFormat get format => $_getN(3);
  @$pb.TagNumber(4)
  set format(LogExportFormat value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasFormat() => $_has(3);
  @$pb.TagNumber(4)
  void clearFormat() => $_clearField(4);
}

class ExportLogsResponse extends $pb.GeneratedMessage {
  factory ExportLogsResponse({
    $core.List<$core.int>? data,
    $core.String? fileName,
    $core.String? mediaType,
    SoraError? error,
  }) {
    final result = ExportLogsResponse._();
    if (data != null) result.data = data;
    if (fileName != null) result.fileName = fileName;
    if (mediaType != null) result.mediaType = mediaType;
    if (error != null) result.error = error;
    return result;
  }

  ExportLogsResponse._();

  factory ExportLogsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportLogsResponse()..mergeFromBuffer(data, registry);
  factory ExportLogsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ExportLogsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ExportLogsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ExportLogsResponse.$_createMessage)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'fileName')
    ..aOS(3, _omitFieldNames ? '' : 'mediaType')
    ..aOM<SoraError>(4, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportLogsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ExportLogsResponse copyWith(void Function(ExportLogsResponse) updates) =>
      super.copyWith((message) => updates(message as ExportLogsResponse)) as ExportLogsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ExportLogsResponse() / ExportLogsResponse.new instead')
  static ExportLogsResponse create() => ExportLogsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ExportLogsResponse._();
  @$core.override
  ExportLogsResponse createEmptyInstance() => ExportLogsResponse._();
  @$core.pragma('dart2js:noInline')
  static ExportLogsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ExportLogsResponse>(ExportLogsResponse.$_createMessage);
  static ExportLogsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get data => $_getN(0);
  @$pb.TagNumber(1)
  set data($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasData() => $_has(0);
  @$pb.TagNumber(1)
  void clearData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get fileName => $_getSZ(1);
  @$pb.TagNumber(2)
  set fileName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFileName() => $_has(1);
  @$pb.TagNumber(2)
  void clearFileName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get mediaType => $_getSZ(2);
  @$pb.TagNumber(3)
  set mediaType($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMediaType() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaType() => $_clearField(3);

  @$pb.TagNumber(4)
  SoraError get error => $_getN(3);
  @$pb.TagNumber(4)
  set error(SoraError value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasError() => $_has(3);
  @$pb.TagNumber(4)
  void clearError() => $_clearField(4);
  @$pb.TagNumber(4)
  SoraError ensureError() => $_ensure(3);
}

class ClearLogsRequest extends $pb.GeneratedMessage {
  factory ClearLogsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = ClearLogsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  ClearLogsRequest._();

  factory ClearLogsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearLogsRequest()..mergeFromBuffer(data, registry);
  factory ClearLogsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearLogsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClearLogsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ClearLogsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearLogsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearLogsRequest copyWith(void Function(ClearLogsRequest) updates) =>
      super.copyWith((message) => updates(message as ClearLogsRequest)) as ClearLogsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClearLogsRequest() / ClearLogsRequest.new instead')
  static ClearLogsRequest create() => ClearLogsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ClearLogsRequest._();
  @$core.override
  ClearLogsRequest createEmptyInstance() => ClearLogsRequest._();
  @$core.pragma('dart2js:noInline')
  static ClearLogsRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearLogsRequest>(ClearLogsRequest.$_createMessage);
  static ClearLogsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);
}

class ClearLogsResponse extends $pb.GeneratedMessage {
  factory ClearLogsResponse({
    SoraError? error,
  }) {
    final result = ClearLogsResponse._();
    if (error != null) result.error = error;
    return result;
  }

  ClearLogsResponse._();

  factory ClearLogsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearLogsResponse()..mergeFromBuffer(data, registry);
  factory ClearLogsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ClearLogsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClearLogsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ClearLogsResponse.$_createMessage)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearLogsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ClearLogsResponse copyWith(void Function(ClearLogsResponse) updates) =>
      super.copyWith((message) => updates(message as ClearLogsResponse)) as ClearLogsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ClearLogsResponse() / ClearLogsResponse.new instead')
  static ClearLogsResponse create() => ClearLogsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ClearLogsResponse._();
  @$core.override
  ClearLogsResponse createEmptyInstance() => ClearLogsResponse._();
  @$core.pragma('dart2js:noInline')
  static ClearLogsResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClearLogsResponse>(ClearLogsResponse.$_createMessage);
  static ClearLogsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
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
    final result = LogSettings._();
    if (captureLevel != null) result.captureLevel = captureLevel;
    if (recordDestinations != null) result.recordDestinations = recordDestinations;
    if (maxEntries != null) result.maxEntries = maxEntries;
    if (maxBytes != null) result.maxBytes = maxBytes;
    return result;
  }

  LogSettings._();

  factory LogSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogSettings()..mergeFromBuffer(data, registry);
  factory LogSettings.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      LogSettings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: LogSettings.$_createMessage)
    ..aE<LogLevel>(1, _omitFieldNames ? '' : 'captureLevel', enumValues: LogLevel.values)
    ..aOB(2, _omitFieldNames ? '' : 'recordDestinations')
    ..aI(3, _omitFieldNames ? '' : 'maxEntries', fieldType: $pb.PbFieldType.OU3)
    ..aI(4, _omitFieldNames ? '' : 'maxBytes', fieldType: $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogSettings copyWith(void Function(LogSettings) updates) =>
      super.copyWith((message) => updates(message as LogSettings)) as LogSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use LogSettings() / LogSettings.new instead')
  static LogSettings create() => LogSettings._();
  static $pb.GeneratedMessage $_createMessage() => LogSettings._();
  @$core.override
  LogSettings createEmptyInstance() => LogSettings._();
  @$core.pragma('dart2js:noInline')
  static LogSettings getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogSettings>(LogSettings.$_createMessage);
  static LogSettings? _defaultInstance;

  /// Entries below it are dropped before they are stored. Engines run at debug
  /// level, so a change takes effect at once, without a reconnect.
  @$pb.TagNumber(1)
  LogLevel get captureLevel => $_getN(0);
  @$pb.TagNumber(1)
  set captureLevel(LogLevel value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasCaptureLevel() => $_has(0);
  @$pb.TagNumber(1)
  void clearCaptureLevel() => $_clearField(1);

  /// Keeps the hosts and addresses of visited sites in engine messages.
  @$pb.TagNumber(2)
  $core.bool get recordDestinations => $_getBF(1);
  @$pb.TagNumber(2)
  set recordDestinations($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRecordDestinations() => $_has(1);
  @$pb.TagNumber(2)
  void clearRecordDestinations() => $_clearField(2);

  /// Bounds of the record; 0 keeps the core default.
  @$pb.TagNumber(3)
  $core.int get maxEntries => $_getIZ(2);
  @$pb.TagNumber(3)
  set maxEntries($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMaxEntries() => $_has(2);
  @$pb.TagNumber(3)
  void clearMaxEntries() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get maxBytes => $_getIZ(3);
  @$pb.TagNumber(4)
  set maxBytes($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaxBytes() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaxBytes() => $_clearField(4);
}

class GetLogSettingsRequest extends $pb.GeneratedMessage {
  factory GetLogSettingsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = GetLogSettingsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  GetLogSettingsRequest._();

  factory GetLogSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLogSettingsRequest()..mergeFromBuffer(data, registry);
  factory GetLogSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLogSettingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLogSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetLogSettingsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsRequest copyWith(void Function(GetLogSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as GetLogSettingsRequest)) as GetLogSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetLogSettingsRequest() / GetLogSettingsRequest.new instead')
  static GetLogSettingsRequest create() => GetLogSettingsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetLogSettingsRequest._();
  @$core.override
  GetLogSettingsRequest createEmptyInstance() => GetLogSettingsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetLogSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLogSettingsRequest>(GetLogSettingsRequest.$_createMessage);
  static GetLogSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);
}

class GetLogSettingsResponse extends $pb.GeneratedMessage {
  factory GetLogSettingsResponse({
    LogSettings? settings,
    SoraError? error,
  }) {
    final result = GetLogSettingsResponse._();
    if (settings != null) result.settings = settings;
    if (error != null) result.error = error;
    return result;
  }

  GetLogSettingsResponse._();

  factory GetLogSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLogSettingsResponse()..mergeFromBuffer(data, registry);
  factory GetLogSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetLogSettingsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetLogSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetLogSettingsResponse.$_createMessage)
    ..aOM<LogSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetLogSettingsResponse copyWith(void Function(GetLogSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as GetLogSettingsResponse)) as GetLogSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetLogSettingsResponse() / GetLogSettingsResponse.new instead')
  static GetLogSettingsResponse create() => GetLogSettingsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetLogSettingsResponse._();
  @$core.override
  GetLogSettingsResponse createEmptyInstance() => GetLogSettingsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetLogSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetLogSettingsResponse>(GetLogSettingsResponse.$_createMessage);
  static GetLogSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(LogSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  LogSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class SetLogSettingsRequest extends $pb.GeneratedMessage {
  factory SetLogSettingsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    LogSettings? settings,
  }) {
    final result = SetLogSettingsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (settings != null) result.settings = settings;
    return result;
  }

  SetLogSettingsRequest._();

  factory SetLogSettingsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLogSettingsRequest()..mergeFromBuffer(data, registry);
  factory SetLogSettingsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLogSettingsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetLogSettingsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SetLogSettingsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<LogSettings>(3, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLogSettingsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLogSettingsRequest copyWith(void Function(SetLogSettingsRequest) updates) =>
      super.copyWith((message) => updates(message as SetLogSettingsRequest)) as SetLogSettingsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetLogSettingsRequest() / SetLogSettingsRequest.new instead')
  static SetLogSettingsRequest create() => SetLogSettingsRequest._();
  static $pb.GeneratedMessage $_createMessage() => SetLogSettingsRequest._();
  @$core.override
  SetLogSettingsRequest createEmptyInstance() => SetLogSettingsRequest._();
  @$core.pragma('dart2js:noInline')
  static SetLogSettingsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetLogSettingsRequest>(SetLogSettingsRequest.$_createMessage);
  static SetLogSettingsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  LogSettings get settings => $_getN(2);
  @$pb.TagNumber(3)
  set settings(LogSettings value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSettings() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettings() => $_clearField(3);
  @$pb.TagNumber(3)
  LogSettings ensureSettings() => $_ensure(2);
}

class SetLogSettingsResponse extends $pb.GeneratedMessage {
  factory SetLogSettingsResponse({
    LogSettings? settings,
    SoraError? error,
  }) {
    final result = SetLogSettingsResponse._();
    if (settings != null) result.settings = settings;
    if (error != null) result.error = error;
    return result;
  }

  SetLogSettingsResponse._();

  factory SetLogSettingsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLogSettingsResponse()..mergeFromBuffer(data, registry);
  factory SetLogSettingsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SetLogSettingsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SetLogSettingsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SetLogSettingsResponse.$_createMessage)
    ..aOM<LogSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: LogSettings.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLogSettingsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SetLogSettingsResponse copyWith(void Function(SetLogSettingsResponse) updates) =>
      super.copyWith((message) => updates(message as SetLogSettingsResponse)) as SetLogSettingsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SetLogSettingsResponse() / SetLogSettingsResponse.new instead')
  static SetLogSettingsResponse create() => SetLogSettingsResponse._();
  static $pb.GeneratedMessage $_createMessage() => SetLogSettingsResponse._();
  @$core.override
  SetLogSettingsResponse createEmptyInstance() => SetLogSettingsResponse._();
  @$core.pragma('dart2js:noInline')
  static SetLogSettingsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SetLogSettingsResponse>(SetLogSettingsResponse.$_createMessage);
  static SetLogSettingsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  LogSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(LogSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  LogSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = Connection._();
    if (id != null) result.id = id;
    if (network != null) result.network = network;
    if (host != null) result.host = host;
    if (port != null) result.port = port;
    if (process != null) result.process = process;
    if (rule != null) result.rule = rule;
    if (chain != null) result.chain.addAll(chain);
    if (upload != null) result.upload = upload;
    if (download != null) result.download = download;
    if (start != null) result.start = start;
    return result;
  }

  Connection._();

  factory Connection.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Connection()..mergeFromBuffer(data, registry);
  factory Connection.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      Connection()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Connection',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: Connection.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'network')
    ..aOS(3, _omitFieldNames ? '' : 'host')
    ..aI(4, _omitFieldNames ? '' : 'port', fieldType: $pb.PbFieldType.OU3)
    ..aOS(5, _omitFieldNames ? '' : 'process')
    ..aOS(6, _omitFieldNames ? '' : 'rule')
    ..pPS(7, _omitFieldNames ? '' : 'chain')
    ..a<$fixnum.Int64>(8, _omitFieldNames ? '' : 'upload', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$fixnum.Int64>(9, _omitFieldNames ? '' : 'download', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<$2.Timestamp>(10, _omitFieldNames ? '' : 'start', subBuilder: $2.Timestamp.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Connection copyWith(void Function(Connection) updates) =>
      super.copyWith((message) => updates(message as Connection)) as Connection;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use Connection() / Connection.new instead')
  static Connection create() => Connection._();
  static $pb.GeneratedMessage $_createMessage() => Connection._();
  @$core.override
  Connection createEmptyInstance() => Connection._();
  @$core.pragma('dart2js:noInline')
  static Connection getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Connection>(Connection.$_createMessage);
  static Connection? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// tcp or udp.
  @$pb.TagNumber(2)
  $core.String get network => $_getSZ(1);
  @$pb.TagNumber(2)
  set network($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNetwork() => $_has(1);
  @$pb.TagNumber(2)
  void clearNetwork() => $_clearField(2);

  /// What the application asked for: a name where one was seen, else an address.
  @$pb.TagNumber(3)
  $core.String get host => $_getSZ(2);
  @$pb.TagNumber(3)
  set host($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasHost() => $_has(2);
  @$pb.TagNumber(3)
  void clearHost() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get port => $_getIZ(3);
  @$pb.TagNumber(4)
  set port($core.int value) => $_setUnsignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPort() => $_has(3);
  @$pb.TagNumber(4)
  void clearPort() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get process => $_getSZ(4);
  @$pb.TagNumber(5)
  set process($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasProcess() => $_has(4);
  @$pb.TagNumber(5)
  void clearProcess() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get rule => $_getSZ(5);
  @$pb.TagNumber(6)
  set rule($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasRule() => $_has(5);
  @$pb.TagNumber(6)
  void clearRule() => $_clearField(6);

  /// From the group the rule chose to the outbound that carried it.
  @$pb.TagNumber(7)
  $pb.PbList<$core.String> get chain => $_getList(6);

  @$pb.TagNumber(8)
  $fixnum.Int64 get upload => $_getI64(7);
  @$pb.TagNumber(8)
  set upload($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasUpload() => $_has(7);
  @$pb.TagNumber(8)
  void clearUpload() => $_clearField(8);

  @$pb.TagNumber(9)
  $fixnum.Int64 get download => $_getI64(8);
  @$pb.TagNumber(9)
  set download($fixnum.Int64 value) => $_setInt64(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDownload() => $_has(8);
  @$pb.TagNumber(9)
  void clearDownload() => $_clearField(9);

  @$pb.TagNumber(10)
  $2.Timestamp get start => $_getN(9);
  @$pb.TagNumber(10)
  set start($2.Timestamp value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasStart() => $_has(9);
  @$pb.TagNumber(10)
  void clearStart() => $_clearField(10);
  @$pb.TagNumber(10)
  $2.Timestamp ensureStart() => $_ensure(9);
}

class ListConnectionsRequest extends $pb.GeneratedMessage {
  factory ListConnectionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? sessionId,
  }) {
    final result = ListConnectionsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (sessionId != null) result.sessionId = sessionId;
    return result;
  }

  ListConnectionsRequest._();

  factory ListConnectionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConnectionsRequest()..mergeFromBuffer(data, registry);
  factory ListConnectionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConnectionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListConnectionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ListConnectionsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsRequest copyWith(void Function(ListConnectionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsRequest)) as ListConnectionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListConnectionsRequest() / ListConnectionsRequest.new instead')
  static ListConnectionsRequest create() => ListConnectionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListConnectionsRequest._();
  @$core.override
  ListConnectionsRequest createEmptyInstance() => ListConnectionsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsRequest>(ListConnectionsRequest.$_createMessage);
  static ListConnectionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);
}

class ListConnectionsResponse extends $pb.GeneratedMessage {
  factory ListConnectionsResponse({
    $core.Iterable<Connection>? connections,
    SoraError? error,
  }) {
    final result = ListConnectionsResponse._();
    if (connections != null) result.connections.addAll(connections);
    if (error != null) result.error = error;
    return result;
  }

  ListConnectionsResponse._();

  factory ListConnectionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConnectionsResponse()..mergeFromBuffer(data, registry);
  factory ListConnectionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListConnectionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListConnectionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ListConnectionsResponse.$_createMessage)
    ..pPM<Connection>(1, _omitFieldNames ? '' : 'connections', subBuilder: Connection.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListConnectionsResponse copyWith(void Function(ListConnectionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListConnectionsResponse)) as ListConnectionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListConnectionsResponse() / ListConnectionsResponse.new instead')
  static ListConnectionsResponse create() => ListConnectionsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListConnectionsResponse._();
  @$core.override
  ListConnectionsResponse createEmptyInstance() => ListConnectionsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListConnectionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListConnectionsResponse>(ListConnectionsResponse.$_createMessage);
  static ListConnectionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Connection> get connections => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = CloseConnectionRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (sessionId != null) result.sessionId = sessionId;
    if (connectionId != null) result.connectionId = connectionId;
    return result;
  }

  CloseConnectionRequest._();

  factory CloseConnectionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CloseConnectionRequest()..mergeFromBuffer(data, registry);
  factory CloseConnectionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CloseConnectionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CloseConnectionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: CloseConnectionRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'sessionId')
    ..aOS(4, _omitFieldNames ? '' : 'connectionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionRequest copyWith(void Function(CloseConnectionRequest) updates) =>
      super.copyWith((message) => updates(message as CloseConnectionRequest)) as CloseConnectionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CloseConnectionRequest() / CloseConnectionRequest.new instead')
  static CloseConnectionRequest create() => CloseConnectionRequest._();
  static $pb.GeneratedMessage $_createMessage() => CloseConnectionRequest._();
  @$core.override
  CloseConnectionRequest createEmptyInstance() => CloseConnectionRequest._();
  @$core.pragma('dart2js:noInline')
  static CloseConnectionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseConnectionRequest>(CloseConnectionRequest.$_createMessage);
  static CloseConnectionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get sessionId => $_getSZ(2);
  @$pb.TagNumber(3)
  set sessionId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSessionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearSessionId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get connectionId => $_getSZ(3);
  @$pb.TagNumber(4)
  set connectionId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasConnectionId() => $_has(3);
  @$pb.TagNumber(4)
  void clearConnectionId() => $_clearField(4);
}

class CloseConnectionResponse extends $pb.GeneratedMessage {
  factory CloseConnectionResponse({
    SoraError? error,
  }) {
    final result = CloseConnectionResponse._();
    if (error != null) result.error = error;
    return result;
  }

  CloseConnectionResponse._();

  factory CloseConnectionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CloseConnectionResponse()..mergeFromBuffer(data, registry);
  factory CloseConnectionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      CloseConnectionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'CloseConnectionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: CloseConnectionResponse.$_createMessage)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloseConnectionResponse copyWith(void Function(CloseConnectionResponse) updates) =>
      super.copyWith((message) => updates(message as CloseConnectionResponse)) as CloseConnectionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use CloseConnectionResponse() / CloseConnectionResponse.new instead')
  static CloseConnectionResponse create() => CloseConnectionResponse._();
  static $pb.GeneratedMessage $_createMessage() => CloseConnectionResponse._();
  @$core.override
  CloseConnectionResponse createEmptyInstance() => CloseConnectionResponse._();
  @$core.pragma('dart2js:noInline')
  static CloseConnectionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloseConnectionResponse>(CloseConnectionResponse.$_createMessage);
  static CloseConnectionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
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
    final result = SubscriptionSettings._();
    if (id != null) result.id = id;
    if (url != null) result.url = url;
    if (name != null) result.name = name;
    if (userAgent != null) result.userAgent = userAgent;
    if (autoUpdate != null) result.autoUpdate = autoUpdate;
    if (updateInterval != null) result.updateInterval = updateInterval;
    return result;
  }

  SubscriptionSettings._();

  factory SubscriptionSettings.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionSettings()..mergeFromBuffer(data, registry);
  factory SubscriptionSettings.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionSettings()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionSettings',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SubscriptionSettings.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..aOS(2, _omitFieldNames ? '' : 'url')
    ..aOS(3, _omitFieldNames ? '' : 'name')
    ..aOS(4, _omitFieldNames ? '' : 'userAgent')
    ..aOB(5, _omitFieldNames ? '' : 'autoUpdate')
    ..aOM<$1.Duration>(6, _omitFieldNames ? '' : 'updateInterval', subBuilder: $1.Duration.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionSettings clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionSettings copyWith(void Function(SubscriptionSettings) updates) =>
      super.copyWith((message) => updates(message as SubscriptionSettings)) as SubscriptionSettings;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscriptionSettings() / SubscriptionSettings.new instead')
  static SubscriptionSettings create() => SubscriptionSettings._();
  static $pb.GeneratedMessage $_createMessage() => SubscriptionSettings._();
  @$core.override
  SubscriptionSettings createEmptyInstance() => SubscriptionSettings._();
  @$core.pragma('dart2js:noInline')
  static SubscriptionSettings getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SubscriptionSettings>(SubscriptionSettings.$_createMessage);
  static SubscriptionSettings? _defaultInstance;

  /// Empty on the first save; the core assigns one and answers with it.
  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// The https link. Required on the first save; empty on a later save keeps
  /// the stored link.
  @$pb.TagNumber(2)
  $core.String get url => $_getSZ(1);
  @$pb.TagNumber(2)
  set url($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUrl() => $_has(1);
  @$pb.TagNumber(2)
  void clearUrl() => $_clearField(2);

  /// Overrides the provider title in the list; empty shows the provider title.
  @$pb.TagNumber(3)
  $core.String get name => $_getSZ(2);
  @$pb.TagNumber(3)
  set name($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasName() => $_has(2);
  @$pb.TagNumber(3)
  void clearName() => $_clearField(3);

  /// Empty sends the Sora User-Agent.
  @$pb.TagNumber(4)
  $core.String get userAgent => $_getSZ(3);
  @$pb.TagNumber(4)
  set userAgent($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasUserAgent() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserAgent() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get autoUpdate => $_getBF(4);
  @$pb.TagNumber(5)
  set autoUpdate($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAutoUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearAutoUpdate() => $_clearField(5);

  /// Overrides the interval the provider asks for; unset follows the provider,
  /// and 24 hours when the provider did not say. At least one hour.
  @$pb.TagNumber(6)
  $1.Duration get updateInterval => $_getN(5);
  @$pb.TagNumber(6)
  set updateInterval($1.Duration value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasUpdateInterval() => $_has(5);
  @$pb.TagNumber(6)
  void clearUpdateInterval() => $_clearField(6);
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
    final result = SubscriptionState._();
    if (settings != null) result.settings = settings;
    if (info != null) result.info = info;
    if (outbounds != null) result.outbounds.addAll(outbounds);
    if (lastUpdate != null) result.lastUpdate = lastUpdate;
    if (nextUpdate != null) result.nextUpdate = nextUpdate;
    if (lastError != null) result.lastError = lastError;
    if (updating != null) result.updating = updating;
    if (deleted != null) result.deleted = deleted;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  SubscriptionState._();

  factory SubscriptionState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionState()..mergeFromBuffer(data, registry);
  factory SubscriptionState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SubscriptionState()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SubscriptionState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SubscriptionState.$_createMessage)
    ..aOM<SubscriptionSettings>(1, _omitFieldNames ? '' : 'settings', subBuilder: SubscriptionSettings.$_createMessage)
    ..aOM<SubscriptionInfo>(2, _omitFieldNames ? '' : 'info', subBuilder: SubscriptionInfo.$_createMessage)
    ..pPM<OutboundSpec>(3, _omitFieldNames ? '' : 'outbounds', subBuilder: OutboundSpec.$_createMessage)
    ..aOM<$2.Timestamp>(4, _omitFieldNames ? '' : 'lastUpdate', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<$2.Timestamp>(5, _omitFieldNames ? '' : 'nextUpdate', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<SoraError>(6, _omitFieldNames ? '' : 'lastError', subBuilder: SoraError.$_createMessage)
    ..aOB(7, _omitFieldNames ? '' : 'updating')
    ..aOB(8, _omitFieldNames ? '' : 'deleted')
    ..aOS(9, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionState clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SubscriptionState copyWith(void Function(SubscriptionState) updates) =>
      super.copyWith((message) => updates(message as SubscriptionState)) as SubscriptionState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SubscriptionState() / SubscriptionState.new instead')
  static SubscriptionState create() => SubscriptionState._();
  static $pb.GeneratedMessage $_createMessage() => SubscriptionState._();
  @$core.override
  SubscriptionState createEmptyInstance() => SubscriptionState._();
  @$core.pragma('dart2js:noInline')
  static SubscriptionState getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<SubscriptionState>(SubscriptionState.$_createMessage);
  static SubscriptionState? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionSettings get settings => $_getN(0);
  @$pb.TagNumber(1)
  set settings(SubscriptionSettings value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSettings() => $_has(0);
  @$pb.TagNumber(1)
  void clearSettings() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionSettings ensureSettings() => $_ensure(0);

  @$pb.TagNumber(2)
  SubscriptionInfo get info => $_getN(1);
  @$pb.TagNumber(2)
  set info(SubscriptionInfo value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasInfo() => $_has(1);
  @$pb.TagNumber(2)
  void clearInfo() => $_clearField(2);
  @$pb.TagNumber(2)
  SubscriptionInfo ensureInfo() => $_ensure(1);

  @$pb.TagNumber(3)
  $pb.PbList<OutboundSpec> get outbounds => $_getList(2);

  @$pb.TagNumber(4)
  $2.Timestamp get lastUpdate => $_getN(3);
  @$pb.TagNumber(4)
  set lastUpdate($2.Timestamp value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasLastUpdate() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastUpdate() => $_clearField(4);
  @$pb.TagNumber(4)
  $2.Timestamp ensureLastUpdate() => $_ensure(3);

  @$pb.TagNumber(5)
  $2.Timestamp get nextUpdate => $_getN(4);
  @$pb.TagNumber(5)
  set nextUpdate($2.Timestamp value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasNextUpdate() => $_has(4);
  @$pb.TagNumber(5)
  void clearNextUpdate() => $_clearField(5);
  @$pb.TagNumber(5)
  $2.Timestamp ensureNextUpdate() => $_ensure(4);

  /// The failure of the last attempt; unset after a success.
  @$pb.TagNumber(6)
  SoraError get lastError => $_getN(5);
  @$pb.TagNumber(6)
  set lastError(SoraError value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasLastError() => $_has(5);
  @$pb.TagNumber(6)
  void clearLastError() => $_clearField(6);
  @$pb.TagNumber(6)
  SoraError ensureLastError() => $_ensure(5);

  /// Whether a fetch is running right now.
  @$pb.TagNumber(7)
  $core.bool get updating => $_getBF(6);
  @$pb.TagNumber(7)
  set updating($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUpdating() => $_has(6);
  @$pb.TagNumber(7)
  void clearUpdating() => $_clearField(7);

  /// Set on a watched state when the subscription was deleted.
  @$pb.TagNumber(8)
  $core.bool get deleted => $_getBF(7);
  @$pb.TagNumber(8)
  set deleted($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(8)
  $core.bool hasDeleted() => $_has(7);
  @$pb.TagNumber(8)
  void clearDeleted() => $_clearField(8);

  /// What the list shows: the user's name, else the provider's title, else the
  /// file name the provider sent, else the host of the link. Never empty.
  @$pb.TagNumber(9)
  $core.String get displayName => $_getSZ(8);
  @$pb.TagNumber(9)
  set displayName($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasDisplayName() => $_has(8);
  @$pb.TagNumber(9)
  void clearDisplayName() => $_clearField(9);
}

class SaveSubscriptionRequest extends $pb.GeneratedMessage {
  factory SaveSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    SubscriptionSettings? settings,
  }) {
    final result = SaveSubscriptionRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (settings != null) result.settings = settings;
    return result;
  }

  SaveSubscriptionRequest._();

  factory SaveSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveSubscriptionRequest()..mergeFromBuffer(data, registry);
  factory SaveSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveSubscriptionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SaveSubscriptionRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOM<SubscriptionSettings>(3, _omitFieldNames ? '' : 'settings', subBuilder: SubscriptionSettings.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSubscriptionRequest copyWith(void Function(SaveSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as SaveSubscriptionRequest)) as SaveSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveSubscriptionRequest() / SaveSubscriptionRequest.new instead')
  static SaveSubscriptionRequest create() => SaveSubscriptionRequest._();
  static $pb.GeneratedMessage $_createMessage() => SaveSubscriptionRequest._();
  @$core.override
  SaveSubscriptionRequest createEmptyInstance() => SaveSubscriptionRequest._();
  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSubscriptionRequest>(SaveSubscriptionRequest.$_createMessage);
  static SaveSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  SubscriptionSettings get settings => $_getN(2);
  @$pb.TagNumber(3)
  set settings(SubscriptionSettings value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasSettings() => $_has(2);
  @$pb.TagNumber(3)
  void clearSettings() => $_clearField(3);
  @$pb.TagNumber(3)
  SubscriptionSettings ensureSettings() => $_ensure(2);
}

class SaveSubscriptionResponse extends $pb.GeneratedMessage {
  factory SaveSubscriptionResponse({
    SubscriptionState? state,
    SoraError? error,
  }) {
    final result = SaveSubscriptionResponse._();
    if (state != null) result.state = state;
    if (error != null) result.error = error;
    return result;
  }

  SaveSubscriptionResponse._();

  factory SaveSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveSubscriptionResponse()..mergeFromBuffer(data, registry);
  factory SaveSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      SaveSubscriptionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'SaveSubscriptionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: SaveSubscriptionResponse.$_createMessage)
    ..aOM<SubscriptionState>(1, _omitFieldNames ? '' : 'state', subBuilder: SubscriptionState.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSubscriptionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SaveSubscriptionResponse copyWith(void Function(SaveSubscriptionResponse) updates) =>
      super.copyWith((message) => updates(message as SaveSubscriptionResponse)) as SaveSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use SaveSubscriptionResponse() / SaveSubscriptionResponse.new instead')
  static SaveSubscriptionResponse create() => SaveSubscriptionResponse._();
  static $pb.GeneratedMessage $_createMessage() => SaveSubscriptionResponse._();
  @$core.override
  SaveSubscriptionResponse createEmptyInstance() => SaveSubscriptionResponse._();
  @$core.pragma('dart2js:noInline')
  static SaveSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SaveSubscriptionResponse>(SaveSubscriptionResponse.$_createMessage);
  static SaveSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(SubscriptionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class ListSubscriptionsRequest extends $pb.GeneratedMessage {
  factory ListSubscriptionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = ListSubscriptionsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  ListSubscriptionsRequest._();

  factory ListSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsRequest()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ListSubscriptionsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsRequest copyWith(void Function(ListSubscriptionsRequest) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsRequest)) as ListSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListSubscriptionsRequest() / ListSubscriptionsRequest.new instead')
  static ListSubscriptionsRequest create() => ListSubscriptionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => ListSubscriptionsRequest._();
  @$core.override
  ListSubscriptionsRequest createEmptyInstance() => ListSubscriptionsRequest._();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsRequest>(ListSubscriptionsRequest.$_createMessage);
  static ListSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);
}

class ListSubscriptionsResponse extends $pb.GeneratedMessage {
  factory ListSubscriptionsResponse({
    $core.Iterable<SubscriptionState>? subscriptions,
    SoraError? error,
  }) {
    final result = ListSubscriptionsResponse._();
    if (subscriptions != null) result.subscriptions.addAll(subscriptions);
    if (error != null) result.error = error;
    return result;
  }

  ListSubscriptionsResponse._();

  factory ListSubscriptionsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsResponse()..mergeFromBuffer(data, registry);
  factory ListSubscriptionsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      ListSubscriptionsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ListSubscriptionsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: ListSubscriptionsResponse.$_createMessage)
    ..pPM<SubscriptionState>(1, _omitFieldNames ? '' : 'subscriptions', subBuilder: SubscriptionState.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ListSubscriptionsResponse copyWith(void Function(ListSubscriptionsResponse) updates) =>
      super.copyWith((message) => updates(message as ListSubscriptionsResponse)) as ListSubscriptionsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use ListSubscriptionsResponse() / ListSubscriptionsResponse.new instead')
  static ListSubscriptionsResponse create() => ListSubscriptionsResponse._();
  static $pb.GeneratedMessage $_createMessage() => ListSubscriptionsResponse._();
  @$core.override
  ListSubscriptionsResponse createEmptyInstance() => ListSubscriptionsResponse._();
  @$core.pragma('dart2js:noInline')
  static ListSubscriptionsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ListSubscriptionsResponse>(ListSubscriptionsResponse.$_createMessage);
  static ListSubscriptionsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<SubscriptionState> get subscriptions => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class DeleteSubscriptionRequest extends $pb.GeneratedMessage {
  factory DeleteSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
  }) {
    final result = DeleteSubscriptionRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (id != null) result.id = id;
    return result;
  }

  DeleteSubscriptionRequest._();

  factory DeleteSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSubscriptionRequest()..mergeFromBuffer(data, registry);
  factory DeleteSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSubscriptionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DeleteSubscriptionRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionRequest copyWith(void Function(DeleteSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as DeleteSubscriptionRequest)) as DeleteSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteSubscriptionRequest() / DeleteSubscriptionRequest.new instead')
  static DeleteSubscriptionRequest create() => DeleteSubscriptionRequest._();
  static $pb.GeneratedMessage $_createMessage() => DeleteSubscriptionRequest._();
  @$core.override
  DeleteSubscriptionRequest createEmptyInstance() => DeleteSubscriptionRequest._();
  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSubscriptionRequest>(DeleteSubscriptionRequest.$_createMessage);
  static DeleteSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);
}

class DeleteSubscriptionResponse extends $pb.GeneratedMessage {
  factory DeleteSubscriptionResponse({
    SoraError? error,
  }) {
    final result = DeleteSubscriptionResponse._();
    if (error != null) result.error = error;
    return result;
  }

  DeleteSubscriptionResponse._();

  factory DeleteSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSubscriptionResponse()..mergeFromBuffer(data, registry);
  factory DeleteSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      DeleteSubscriptionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DeleteSubscriptionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: DeleteSubscriptionResponse.$_createMessage)
    ..aOM<SoraError>(1, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  DeleteSubscriptionResponse copyWith(void Function(DeleteSubscriptionResponse) updates) =>
      super.copyWith((message) => updates(message as DeleteSubscriptionResponse)) as DeleteSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use DeleteSubscriptionResponse() / DeleteSubscriptionResponse.new instead')
  static DeleteSubscriptionResponse create() => DeleteSubscriptionResponse._();
  static $pb.GeneratedMessage $_createMessage() => DeleteSubscriptionResponse._();
  @$core.override
  DeleteSubscriptionResponse createEmptyInstance() => DeleteSubscriptionResponse._();
  @$core.pragma('dart2js:noInline')
  static DeleteSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<DeleteSubscriptionResponse>(DeleteSubscriptionResponse.$_createMessage);
  static DeleteSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SoraError get error => $_getN(0);
  @$pb.TagNumber(1)
  set error(SoraError value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasError() => $_has(0);
  @$pb.TagNumber(1)
  void clearError() => $_clearField(1);
  @$pb.TagNumber(1)
  SoraError ensureError() => $_ensure(0);
}

class RefreshSubscriptionRequest extends $pb.GeneratedMessage {
  factory RefreshSubscriptionRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
    $core.String? id,
  }) {
    final result = RefreshSubscriptionRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    if (id != null) result.id = id;
    return result;
  }

  RefreshSubscriptionRequest._();

  factory RefreshSubscriptionRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshSubscriptionRequest()..mergeFromBuffer(data, registry);
  factory RefreshSubscriptionRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshSubscriptionRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RefreshSubscriptionRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RefreshSubscriptionRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'id')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSubscriptionRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSubscriptionRequest copyWith(void Function(RefreshSubscriptionRequest) updates) =>
      super.copyWith((message) => updates(message as RefreshSubscriptionRequest)) as RefreshSubscriptionRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RefreshSubscriptionRequest() / RefreshSubscriptionRequest.new instead')
  static RefreshSubscriptionRequest create() => RefreshSubscriptionRequest._();
  static $pb.GeneratedMessage $_createMessage() => RefreshSubscriptionRequest._();
  @$core.override
  RefreshSubscriptionRequest createEmptyInstance() => RefreshSubscriptionRequest._();
  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshSubscriptionRequest>(RefreshSubscriptionRequest.$_createMessage);
  static RefreshSubscriptionRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get id => $_getSZ(2);
  @$pb.TagNumber(3)
  set id($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasId() => $_has(2);
  @$pb.TagNumber(3)
  void clearId() => $_clearField(3);
}

class RefreshSubscriptionResponse extends $pb.GeneratedMessage {
  factory RefreshSubscriptionResponse({
    SubscriptionState? state,
    SoraError? error,
  }) {
    final result = RefreshSubscriptionResponse._();
    if (state != null) result.state = state;
    if (error != null) result.error = error;
    return result;
  }

  RefreshSubscriptionResponse._();

  factory RefreshSubscriptionResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshSubscriptionResponse()..mergeFromBuffer(data, registry);
  factory RefreshSubscriptionResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RefreshSubscriptionResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RefreshSubscriptionResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RefreshSubscriptionResponse.$_createMessage)
    ..aOM<SubscriptionState>(1, _omitFieldNames ? '' : 'state', subBuilder: SubscriptionState.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSubscriptionResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RefreshSubscriptionResponse copyWith(void Function(RefreshSubscriptionResponse) updates) =>
      super.copyWith((message) => updates(message as RefreshSubscriptionResponse)) as RefreshSubscriptionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RefreshSubscriptionResponse() / RefreshSubscriptionResponse.new instead')
  static RefreshSubscriptionResponse create() => RefreshSubscriptionResponse._();
  static $pb.GeneratedMessage $_createMessage() => RefreshSubscriptionResponse._();
  @$core.override
  RefreshSubscriptionResponse createEmptyInstance() => RefreshSubscriptionResponse._();
  @$core.pragma('dart2js:noInline')
  static RefreshSubscriptionResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RefreshSubscriptionResponse>(RefreshSubscriptionResponse.$_createMessage);
  static RefreshSubscriptionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  SubscriptionState get state => $_getN(0);
  @$pb.TagNumber(1)
  set state(SubscriptionState value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasState() => $_has(0);
  @$pb.TagNumber(1)
  void clearState() => $_clearField(1);
  @$pb.TagNumber(1)
  SubscriptionState ensureState() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

class WatchSubscriptionsRequest extends $pb.GeneratedMessage {
  factory WatchSubscriptionsRequest({
    ApiVersion? apiVersion,
    $core.List<$core.int>? controlAuthenticator,
  }) {
    final result = WatchSubscriptionsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    if (controlAuthenticator != null) result.controlAuthenticator = controlAuthenticator;
    return result;
  }

  WatchSubscriptionsRequest._();

  factory WatchSubscriptionsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchSubscriptionsRequest()..mergeFromBuffer(data, registry);
  factory WatchSubscriptionsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      WatchSubscriptionsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'WatchSubscriptionsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: WatchSubscriptionsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'controlAuthenticator', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchSubscriptionsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WatchSubscriptionsRequest copyWith(void Function(WatchSubscriptionsRequest) updates) =>
      super.copyWith((message) => updates(message as WatchSubscriptionsRequest)) as WatchSubscriptionsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use WatchSubscriptionsRequest() / WatchSubscriptionsRequest.new instead')
  static WatchSubscriptionsRequest create() => WatchSubscriptionsRequest._();
  static $pb.GeneratedMessage $_createMessage() => WatchSubscriptionsRequest._();
  @$core.override
  WatchSubscriptionsRequest createEmptyInstance() => WatchSubscriptionsRequest._();
  @$core.pragma('dart2js:noInline')
  static WatchSubscriptionsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WatchSubscriptionsRequest>(WatchSubscriptionsRequest.$_createMessage);
  static WatchSubscriptionsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get controlAuthenticator => $_getN(1);
  @$pb.TagNumber(2)
  set controlAuthenticator($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasControlAuthenticator() => $_has(1);
  @$pb.TagNumber(2)
  void clearControlAuthenticator() => $_clearField(2);
}

class GetAboutRequest extends $pb.GeneratedMessage {
  factory GetAboutRequest({
    ApiVersion? apiVersion,
  }) {
    final result = GetAboutRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    return result;
  }

  GetAboutRequest._();

  factory GetAboutRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAboutRequest()..mergeFromBuffer(data, registry);
  factory GetAboutRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAboutRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAboutRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetAboutRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAboutRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAboutRequest copyWith(void Function(GetAboutRequest) updates) =>
      super.copyWith((message) => updates(message as GetAboutRequest)) as GetAboutRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetAboutRequest() / GetAboutRequest.new instead')
  static GetAboutRequest create() => GetAboutRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetAboutRequest._();
  @$core.override
  GetAboutRequest createEmptyInstance() => GetAboutRequest._();
  @$core.pragma('dart2js:noInline')
  static GetAboutRequest getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAboutRequest>(GetAboutRequest.$_createMessage);
  static GetAboutRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);
}

class GetAboutResponse extends $pb.GeneratedMessage {
  factory GetAboutResponse({
    About? about,
    SoraError? error,
  }) {
    final result = GetAboutResponse._();
    if (about != null) result.about = about;
    if (error != null) result.error = error;
    return result;
  }

  GetAboutResponse._();

  factory GetAboutResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAboutResponse()..mergeFromBuffer(data, registry);
  factory GetAboutResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetAboutResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetAboutResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetAboutResponse.$_createMessage)
    ..aOM<About>(1, _omitFieldNames ? '' : 'about', subBuilder: About.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAboutResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetAboutResponse copyWith(void Function(GetAboutResponse) updates) =>
      super.copyWith((message) => updates(message as GetAboutResponse)) as GetAboutResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetAboutResponse() / GetAboutResponse.new instead')
  static GetAboutResponse create() => GetAboutResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetAboutResponse._();
  @$core.override
  GetAboutResponse createEmptyInstance() => GetAboutResponse._();
  @$core.pragma('dart2js:noInline')
  static GetAboutResponse getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GetAboutResponse>(GetAboutResponse.$_createMessage);
  static GetAboutResponse? _defaultInstance;

  @$pb.TagNumber(1)
  About get about => $_getN(0);
  @$pb.TagNumber(1)
  set about(About value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasAbout() => $_has(0);
  @$pb.TagNumber(1)
  void clearAbout() => $_clearField(1);
  @$pb.TagNumber(1)
  About ensureAbout() => $_ensure(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
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
    final result = About._();
    if (coreVersion != null) result.coreVersion = coreVersion;
    if (commit != null) result.commit = commit;
    if (commitTime != null) result.commitTime = commitTime;
    if (contract != null) result.contract = contract;
    if (platform != null) result.platform = platform;
    if (goVersion != null) result.goVersion = goVersion;
    if (engines != null) result.engines.addAll(engines);
    if (license != null) result.license = license;
    if (sourceUrl != null) result.sourceUrl = sourceUrl;
    return result;
  }

  About._();

  factory About.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      About()..mergeFromBuffer(data, registry);
  factory About.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      About()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'About',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: About.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'coreVersion')
    ..aOS(2, _omitFieldNames ? '' : 'commit')
    ..aOM<$2.Timestamp>(3, _omitFieldNames ? '' : 'commitTime', subBuilder: $2.Timestamp.$_createMessage)
    ..aOM<ApiVersion>(4, _omitFieldNames ? '' : 'contract', subBuilder: ApiVersion.$_createMessage)
    ..aOS(5, _omitFieldNames ? '' : 'platform')
    ..aOS(6, _omitFieldNames ? '' : 'goVersion')
    ..pPM<EngineBuild>(7, _omitFieldNames ? '' : 'engines', subBuilder: EngineBuild.$_createMessage)
    ..aOS(8, _omitFieldNames ? '' : 'license')
    ..aOS(9, _omitFieldNames ? '' : 'sourceUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  About clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  About copyWith(void Function(About) updates) => super.copyWith((message) => updates(message as About)) as About;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use About() / About.new instead')
  static About create() => About._();
  static $pb.GeneratedMessage $_createMessage() => About._();
  @$core.override
  About createEmptyInstance() => About._();
  @$core.pragma('dart2js:noInline')
  static About getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<About>(About.$_createMessage);
  static About? _defaultInstance;

  /// The release version, or "dev" for a build that was not stamped.
  @$pb.TagNumber(1)
  $core.String get coreVersion => $_getSZ(0);
  @$pb.TagNumber(1)
  set coreVersion($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCoreVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreVersion() => $_clearField(1);

  /// The commit the core was built from and when, where the build recorded it.
  @$pb.TagNumber(2)
  $core.String get commit => $_getSZ(1);
  @$pb.TagNumber(2)
  set commit($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCommit() => $_has(1);
  @$pb.TagNumber(2)
  void clearCommit() => $_clearField(2);

  @$pb.TagNumber(3)
  $2.Timestamp get commitTime => $_getN(2);
  @$pb.TagNumber(3)
  set commitTime($2.Timestamp value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasCommitTime() => $_has(2);
  @$pb.TagNumber(3)
  void clearCommitTime() => $_clearField(3);
  @$pb.TagNumber(3)
  $2.Timestamp ensureCommitTime() => $_ensure(2);

  /// The contract the core serves.
  @$pb.TagNumber(4)
  ApiVersion get contract => $_getN(3);
  @$pb.TagNumber(4)
  set contract(ApiVersion value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasContract() => $_has(3);
  @$pb.TagNumber(4)
  void clearContract() => $_clearField(4);
  @$pb.TagNumber(4)
  ApiVersion ensureContract() => $_ensure(3);

  /// For example "linux/amd64".
  @$pb.TagNumber(5)
  $core.String get platform => $_getSZ(4);
  @$pb.TagNumber(5)
  set platform($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPlatform() => $_has(4);
  @$pb.TagNumber(5)
  void clearPlatform() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get goVersion => $_getSZ(5);
  @$pb.TagNumber(6)
  set goVersion($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasGoVersion() => $_has(5);
  @$pb.TagNumber(6)
  void clearGoVersion() => $_clearField(6);

  @$pb.TagNumber(7)
  $pb.PbList<EngineBuild> get engines => $_getList(6);

  /// SPDX identifier.
  @$pb.TagNumber(8)
  $core.String get license => $_getSZ(7);
  @$pb.TagNumber(8)
  set license($core.String value) => $_setString(7, value);
  @$pb.TagNumber(8)
  $core.bool hasLicense() => $_has(7);
  @$pb.TagNumber(8)
  void clearLicense() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.String get sourceUrl => $_getSZ(8);
  @$pb.TagNumber(9)
  set sourceUrl($core.String value) => $_setString(8, value);
  @$pb.TagNumber(9)
  $core.bool hasSourceUrl() => $_has(8);
  @$pb.TagNumber(9)
  void clearSourceUrl() => $_clearField(9);
}

/// EngineBuild is one engine as this machine has it.
class EngineBuild extends $pb.GeneratedMessage {
  factory EngineBuild({
    $core.String? kind,
    $core.bool? installed,
    $core.String? version,
  }) {
    final result = EngineBuild._();
    if (kind != null) result.kind = kind;
    if (installed != null) result.installed = installed;
    if (version != null) result.version = version;
    return result;
  }

  EngineBuild._();

  factory EngineBuild.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EngineBuild()..mergeFromBuffer(data, registry);
  factory EngineBuild.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      EngineBuild()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EngineBuild',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: EngineBuild.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'kind')
    ..aOB(2, _omitFieldNames ? '' : 'installed')
    ..aOS(3, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineBuild clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EngineBuild copyWith(void Function(EngineBuild) updates) =>
      super.copyWith((message) => updates(message as EngineBuild)) as EngineBuild;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use EngineBuild() / EngineBuild.new instead')
  static EngineBuild create() => EngineBuild._();
  static $pb.GeneratedMessage $_createMessage() => EngineBuild._();
  @$core.override
  EngineBuild createEmptyInstance() => EngineBuild._();
  @$core.pragma('dart2js:noInline')
  static EngineBuild getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EngineBuild>(EngineBuild.$_createMessage);
  static EngineBuild? _defaultInstance;

  /// sing-box, xray or mihomo.
  @$pb.TagNumber(1)
  $core.String get kind => $_getSZ(0);
  @$pb.TagNumber(1)
  set kind($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.bool get installed => $_getBF(1);
  @$pb.TagNumber(2)
  set installed($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInstalled() => $_has(1);
  @$pb.TagNumber(2)
  void clearInstalled() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get version => $_getSZ(2);
  @$pb.TagNumber(3)
  set version($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
}

class GetRoutingPresetsRequest extends $pb.GeneratedMessage {
  factory GetRoutingPresetsRequest({
    ApiVersion? apiVersion,
  }) {
    final result = GetRoutingPresetsRequest._();
    if (apiVersion != null) result.apiVersion = apiVersion;
    return result;
  }

  GetRoutingPresetsRequest._();

  factory GetRoutingPresetsRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoutingPresetsRequest()..mergeFromBuffer(data, registry);
  factory GetRoutingPresetsRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoutingPresetsRequest()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetRoutingPresetsRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetRoutingPresetsRequest.$_createMessage)
    ..aOM<ApiVersion>(1, _omitFieldNames ? '' : 'apiVersion', subBuilder: ApiVersion.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutingPresetsRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutingPresetsRequest copyWith(void Function(GetRoutingPresetsRequest) updates) =>
      super.copyWith((message) => updates(message as GetRoutingPresetsRequest)) as GetRoutingPresetsRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRoutingPresetsRequest() / GetRoutingPresetsRequest.new instead')
  static GetRoutingPresetsRequest create() => GetRoutingPresetsRequest._();
  static $pb.GeneratedMessage $_createMessage() => GetRoutingPresetsRequest._();
  @$core.override
  GetRoutingPresetsRequest createEmptyInstance() => GetRoutingPresetsRequest._();
  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRoutingPresetsRequest>(GetRoutingPresetsRequest.$_createMessage);
  static GetRoutingPresetsRequest? _defaultInstance;

  @$pb.TagNumber(1)
  ApiVersion get apiVersion => $_getN(0);
  @$pb.TagNumber(1)
  set apiVersion(ApiVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasApiVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearApiVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  ApiVersion ensureApiVersion() => $_ensure(0);
}

class GetRoutingPresetsResponse extends $pb.GeneratedMessage {
  factory GetRoutingPresetsResponse({
    $core.Iterable<RoutingPreset>? presets,
    SoraError? error,
  }) {
    final result = GetRoutingPresetsResponse._();
    if (presets != null) result.presets.addAll(presets);
    if (error != null) result.error = error;
    return result;
  }

  GetRoutingPresetsResponse._();

  factory GetRoutingPresetsResponse.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoutingPresetsResponse()..mergeFromBuffer(data, registry);
  factory GetRoutingPresetsResponse.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      GetRoutingPresetsResponse()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GetRoutingPresetsResponse',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: GetRoutingPresetsResponse.$_createMessage)
    ..pPM<RoutingPreset>(1, _omitFieldNames ? '' : 'presets', subBuilder: RoutingPreset.$_createMessage)
    ..aOM<SoraError>(2, _omitFieldNames ? '' : 'error', subBuilder: SoraError.$_createMessage)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutingPresetsResponse clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GetRoutingPresetsResponse copyWith(void Function(GetRoutingPresetsResponse) updates) =>
      super.copyWith((message) => updates(message as GetRoutingPresetsResponse)) as GetRoutingPresetsResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use GetRoutingPresetsResponse() / GetRoutingPresetsResponse.new instead')
  static GetRoutingPresetsResponse create() => GetRoutingPresetsResponse._();
  static $pb.GeneratedMessage $_createMessage() => GetRoutingPresetsResponse._();
  @$core.override
  GetRoutingPresetsResponse createEmptyInstance() => GetRoutingPresetsResponse._();
  @$core.pragma('dart2js:noInline')
  static GetRoutingPresetsResponse getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GetRoutingPresetsResponse>(GetRoutingPresetsResponse.$_createMessage);
  static GetRoutingPresetsResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<RoutingPreset> get presets => $_getList(0);

  @$pb.TagNumber(2)
  SoraError get error => $_getN(1);
  @$pb.TagNumber(2)
  set error(SoraError value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
  @$pb.TagNumber(2)
  SoraError ensureError() => $_ensure(1);
}

/// RoutingPreset is one preset; the interface names it by id in its own words.
class RoutingPreset extends $pb.GeneratedMessage {
  factory RoutingPreset({
    $core.String? id,
    $core.Iterable<$core.String>? direct,
  }) {
    final result = RoutingPreset._();
    if (id != null) result.id = id;
    if (direct != null) result.direct.addAll(direct);
    return result;
  }

  RoutingPreset._();

  factory RoutingPreset.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingPreset()..mergeFromBuffer(data, registry);
  factory RoutingPreset.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      RoutingPreset()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'RoutingPreset',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: RoutingPreset.$_createMessage)
    ..aOS(1, _omitFieldNames ? '' : 'id')
    ..pPS(2, _omitFieldNames ? '' : 'direct')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingPreset clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RoutingPreset copyWith(void Function(RoutingPreset) updates) =>
      super.copyWith((message) => updates(message as RoutingPreset)) as RoutingPreset;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use RoutingPreset() / RoutingPreset.new instead')
  static RoutingPreset create() => RoutingPreset._();
  static $pb.GeneratedMessage $_createMessage() => RoutingPreset._();
  @$core.override
  RoutingPreset createEmptyInstance() => RoutingPreset._();
  @$core.pragma('dart2js:noInline')
  static RoutingPreset getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<RoutingPreset>(RoutingPreset.$_createMessage);
  static RoutingPreset? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get id => $_getSZ(0);
  @$pb.TagNumber(1)
  set id($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  /// Destinations sent direct, in the destination form of RoutingRule, for
  /// example "geosite:category-ru" or "geoip:ru".
  @$pb.TagNumber(2)
  $pb.PbList<$core.String> get direct => $_getList(1);
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
    final result = BypassStrategy._();
    if (splitPos != null) result.splitPos.addAll(splitPos);
    if (disorder != null) result.disorder = disorder;
    if (oob != null) result.oob = oob;
    if (tlsRecord != null) result.tlsRecord = tlsRecord;
    if (hostCase != null) result.hostCase = hostCase;
    if (domainCase != null) result.domainCase = domainCase;
    if (methodEol != null) result.methodEol = methodEol;
    return result;
  }

  BypassStrategy._();

  factory BypassStrategy.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassStrategy()..mergeFromBuffer(data, registry);
  factory BypassStrategy.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      BypassStrategy()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BypassStrategy',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'sora.core.v1'),
      createEmptyInstance: BypassStrategy.$_createMessage)
    ..pPS(1, _omitFieldNames ? '' : 'splitPos')
    ..aOB(2, _omitFieldNames ? '' : 'disorder')
    ..aOB(3, _omitFieldNames ? '' : 'oob')
    ..aOS(4, _omitFieldNames ? '' : 'tlsRecord')
    ..aOB(5, _omitFieldNames ? '' : 'hostCase')
    ..aOB(6, _omitFieldNames ? '' : 'domainCase')
    ..aOB(7, _omitFieldNames ? '' : 'methodEol')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassStrategy clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BypassStrategy copyWith(void Function(BypassStrategy) updates) =>
      super.copyWith((message) => updates(message as BypassStrategy)) as BypassStrategy;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  @$core.Deprecated('Use BypassStrategy() / BypassStrategy.new instead')
  static BypassStrategy create() => BypassStrategy._();
  static $pb.GeneratedMessage $_createMessage() => BypassStrategy._();
  @$core.override
  BypassStrategy createEmptyInstance() => BypassStrategy._();
  @$core.pragma('dart2js:noInline')
  static BypassStrategy getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BypassStrategy>(BypassStrategy.$_createMessage);
  static BypassStrategy? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get splitPos => $_getList(0);

  /// Sends the second part of a split first.
  @$pb.TagNumber(2)
  $core.bool get disorder => $_getBF(1);
  @$pb.TagNumber(2)
  set disorder($core.bool value) => $_setBool(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisorder() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisorder() => $_clearField(2);

  /// Sends an out-of-band byte with the split.
  @$pb.TagNumber(3)
  $core.bool get oob => $_getBF(2);
  @$pb.TagNumber(3)
  set oob($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasOob() => $_has(2);
  @$pb.TagNumber(3)
  void clearOob() => $_clearField(3);

  /// Splits the TLS ClientHello into two records at this position.
  @$pb.TagNumber(4)
  $core.String get tlsRecord => $_getSZ(3);
  @$pb.TagNumber(4)
  set tlsRecord($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasTlsRecord() => $_has(3);
  @$pb.TagNumber(4)
  void clearTlsRecord() => $_clearField(4);

  /// Reshape plain HTTP requests.
  @$pb.TagNumber(5)
  $core.bool get hostCase => $_getBF(4);
  @$pb.TagNumber(5)
  set hostCase($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHostCase() => $_has(4);
  @$pb.TagNumber(5)
  void clearHostCase() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get domainCase => $_getBF(5);
  @$pb.TagNumber(6)
  set domainCase($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDomainCase() => $_has(5);
  @$pb.TagNumber(6)
  void clearDomainCase() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.bool get methodEol => $_getBF(6);
  @$pb.TagNumber(7)
  set methodEol($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMethodEol() => $_has(6);
  @$pb.TagNumber(7)
  void clearMethodEol() => $_clearField(7);
}

const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
