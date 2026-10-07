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

import 'package:protobuf/protobuf.dart' as $pb;

class GroupType extends $pb.ProtobufEnum {
  static const GroupType GROUP_TYPE_UNSPECIFIED = GroupType._(0, _omitEnumNames ? '' : 'GROUP_TYPE_UNSPECIFIED');
  static const GroupType GROUP_TYPE_SELECT = GroupType._(1, _omitEnumNames ? '' : 'GROUP_TYPE_SELECT');
  static const GroupType GROUP_TYPE_URL_TEST = GroupType._(2, _omitEnumNames ? '' : 'GROUP_TYPE_URL_TEST');
  static const GroupType GROUP_TYPE_FALLBACK = GroupType._(3, _omitEnumNames ? '' : 'GROUP_TYPE_FALLBACK');
  static const GroupType GROUP_TYPE_LOAD_BALANCE = GroupType._(4, _omitEnumNames ? '' : 'GROUP_TYPE_LOAD_BALANCE');

  static const $core.List<GroupType> values = <GroupType> [
    GROUP_TYPE_UNSPECIFIED,
    GROUP_TYPE_SELECT,
    GROUP_TYPE_URL_TEST,
    GROUP_TYPE_FALLBACK,
    GROUP_TYPE_LOAD_BALANCE,
  ];

  static final $core.Map<$core.int, GroupType> _byValue = $pb.ProtobufEnum.initByValue(values);
  static GroupType? valueOf($core.int value) => _byValue[value];

  const GroupType._($core.int v, $core.String n) : super(v, n);
}

class TunnelMode extends $pb.ProtobufEnum {
  static const TunnelMode TUNNEL_MODE_UNSPECIFIED = TunnelMode._(0, _omitEnumNames ? '' : 'TUNNEL_MODE_UNSPECIFIED');
  static const TunnelMode TUNNEL_MODE_SYSTEM = TunnelMode._(1, _omitEnumNames ? '' : 'TUNNEL_MODE_SYSTEM');
  static const TunnelMode TUNNEL_MODE_APPLICATION = TunnelMode._(2, _omitEnumNames ? '' : 'TUNNEL_MODE_APPLICATION');

  static const $core.List<TunnelMode> values = <TunnelMode> [
    TUNNEL_MODE_UNSPECIFIED,
    TUNNEL_MODE_SYSTEM,
    TUNNEL_MODE_APPLICATION,
  ];

  static final $core.Map<$core.int, TunnelMode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static TunnelMode? valueOf($core.int value) => _byValue[value];

  const TunnelMode._($core.int v, $core.String n) : super(v, n);
}

class ConnectionStateValue extends $pb.ProtobufEnum {
  static const ConnectionStateValue CONNECTION_STATE_VALUE_UNSPECIFIED = ConnectionStateValue._(0, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_UNSPECIFIED');
  static const ConnectionStateValue CONNECTION_STATE_VALUE_DISCONNECTED = ConnectionStateValue._(1, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_DISCONNECTED');
  static const ConnectionStateValue CONNECTION_STATE_VALUE_CONNECTING = ConnectionStateValue._(2, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_CONNECTING');
  static const ConnectionStateValue CONNECTION_STATE_VALUE_CONNECTED = ConnectionStateValue._(3, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_CONNECTED');
  static const ConnectionStateValue CONNECTION_STATE_VALUE_RECONNECTING = ConnectionStateValue._(4, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_RECONNECTING');
  static const ConnectionStateValue CONNECTION_STATE_VALUE_FAILED = ConnectionStateValue._(5, _omitEnumNames ? '' : 'CONNECTION_STATE_VALUE_FAILED');

  static const $core.List<ConnectionStateValue> values = <ConnectionStateValue> [
    CONNECTION_STATE_VALUE_UNSPECIFIED,
    CONNECTION_STATE_VALUE_DISCONNECTED,
    CONNECTION_STATE_VALUE_CONNECTING,
    CONNECTION_STATE_VALUE_CONNECTED,
    CONNECTION_STATE_VALUE_RECONNECTING,
    CONNECTION_STATE_VALUE_FAILED,
  ];

  static final $core.Map<$core.int, ConnectionStateValue> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ConnectionStateValue? valueOf($core.int value) => _byValue[value];

  const ConnectionStateValue._($core.int v, $core.String n) : super(v, n);
}

class ProbeMethod extends $pb.ProtobufEnum {
  static const ProbeMethod PROBE_METHOD_UNSPECIFIED = ProbeMethod._(0, _omitEnumNames ? '' : 'PROBE_METHOD_UNSPECIFIED');
  static const ProbeMethod PROBE_METHOD_ENGINE = ProbeMethod._(1, _omitEnumNames ? '' : 'PROBE_METHOD_ENGINE');
  static const ProbeMethod PROBE_METHOD_CONNECT = ProbeMethod._(2, _omitEnumNames ? '' : 'PROBE_METHOD_CONNECT');

  static const $core.List<ProbeMethod> values = <ProbeMethod> [
    PROBE_METHOD_UNSPECIFIED,
    PROBE_METHOD_ENGINE,
    PROBE_METHOD_CONNECT,
  ];

  static final $core.Map<$core.int, ProbeMethod> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ProbeMethod? valueOf($core.int value) => _byValue[value];

  const ProbeMethod._($core.int v, $core.String n) : super(v, n);
}

class SoraErrorCode extends $pb.ProtobufEnum {
  static const SoraErrorCode SORA_ERROR_CODE_UNSPECIFIED = SoraErrorCode._(0, _omitEnumNames ? '' : 'SORA_ERROR_CODE_UNSPECIFIED');
  static const SoraErrorCode SORA_ERROR_CODE_VERSION_MISMATCH = SoraErrorCode._(1, _omitEnumNames ? '' : 'SORA_ERROR_CODE_VERSION_MISMATCH');
  static const SoraErrorCode SORA_ERROR_CODE_UNAUTHENTICATED = SoraErrorCode._(2, _omitEnumNames ? '' : 'SORA_ERROR_CODE_UNAUTHENTICATED');
  static const SoraErrorCode SORA_ERROR_CODE_INVALID_ARGUMENT = SoraErrorCode._(3, _omitEnumNames ? '' : 'SORA_ERROR_CODE_INVALID_ARGUMENT');
  static const SoraErrorCode SORA_ERROR_CODE_FAILED_PRECONDITION = SoraErrorCode._(4, _omitEnumNames ? '' : 'SORA_ERROR_CODE_FAILED_PRECONDITION');
  static const SoraErrorCode SORA_ERROR_CODE_NOT_FOUND = SoraErrorCode._(5, _omitEnumNames ? '' : 'SORA_ERROR_CODE_NOT_FOUND');
  static const SoraErrorCode SORA_ERROR_CODE_RESOURCE_EXHAUSTED = SoraErrorCode._(6, _omitEnumNames ? '' : 'SORA_ERROR_CODE_RESOURCE_EXHAUSTED');
  static const SoraErrorCode SORA_ERROR_CODE_DEADLINE_EXCEEDED = SoraErrorCode._(7, _omitEnumNames ? '' : 'SORA_ERROR_CODE_DEADLINE_EXCEEDED');
  static const SoraErrorCode SORA_ERROR_CODE_UNAVAILABLE = SoraErrorCode._(8, _omitEnumNames ? '' : 'SORA_ERROR_CODE_UNAVAILABLE');
  static const SoraErrorCode SORA_ERROR_CODE_INTERNAL = SoraErrorCode._(9, _omitEnumNames ? '' : 'SORA_ERROR_CODE_INTERNAL');
  static const SoraErrorCode SORA_ERROR_CODE_PERMISSION_DENIED = SoraErrorCode._(10, _omitEnumNames ? '' : 'SORA_ERROR_CODE_PERMISSION_DENIED');
  static const SoraErrorCode SORA_ERROR_CODE_CANCELLED = SoraErrorCode._(11, _omitEnumNames ? '' : 'SORA_ERROR_CODE_CANCELLED');

  static const $core.List<SoraErrorCode> values = <SoraErrorCode> [
    SORA_ERROR_CODE_UNSPECIFIED,
    SORA_ERROR_CODE_VERSION_MISMATCH,
    SORA_ERROR_CODE_UNAUTHENTICATED,
    SORA_ERROR_CODE_INVALID_ARGUMENT,
    SORA_ERROR_CODE_FAILED_PRECONDITION,
    SORA_ERROR_CODE_NOT_FOUND,
    SORA_ERROR_CODE_RESOURCE_EXHAUSTED,
    SORA_ERROR_CODE_DEADLINE_EXCEEDED,
    SORA_ERROR_CODE_UNAVAILABLE,
    SORA_ERROR_CODE_INTERNAL,
    SORA_ERROR_CODE_PERMISSION_DENIED,
    SORA_ERROR_CODE_CANCELLED,
  ];

  static final $core.Map<$core.int, SoraErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static SoraErrorCode? valueOf($core.int value) => _byValue[value];

  const SoraErrorCode._($core.int v, $core.String n) : super(v, n);
}

class LogLevel extends $pb.ProtobufEnum {
  static const LogLevel LOG_LEVEL_UNSPECIFIED = LogLevel._(0, _omitEnumNames ? '' : 'LOG_LEVEL_UNSPECIFIED');
  static const LogLevel LOG_LEVEL_DEBUG = LogLevel._(1, _omitEnumNames ? '' : 'LOG_LEVEL_DEBUG');
  static const LogLevel LOG_LEVEL_INFO = LogLevel._(2, _omitEnumNames ? '' : 'LOG_LEVEL_INFO');
  static const LogLevel LOG_LEVEL_WARNING = LogLevel._(3, _omitEnumNames ? '' : 'LOG_LEVEL_WARNING');
  static const LogLevel LOG_LEVEL_ERROR = LogLevel._(4, _omitEnumNames ? '' : 'LOG_LEVEL_ERROR');

  static const $core.List<LogLevel> values = <LogLevel> [
    LOG_LEVEL_UNSPECIFIED,
    LOG_LEVEL_DEBUG,
    LOG_LEVEL_INFO,
    LOG_LEVEL_WARNING,
    LOG_LEVEL_ERROR,
  ];

  static final $core.Map<$core.int, LogLevel> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LogLevel? valueOf($core.int value) => _byValue[value];

  const LogLevel._($core.int v, $core.String n) : super(v, n);
}

class LogExportFormat extends $pb.ProtobufEnum {
  static const LogExportFormat LOG_EXPORT_FORMAT_UNSPECIFIED = LogExportFormat._(0, _omitEnumNames ? '' : 'LOG_EXPORT_FORMAT_UNSPECIFIED');
  static const LogExportFormat LOG_EXPORT_FORMAT_JSON_LINES = LogExportFormat._(1, _omitEnumNames ? '' : 'LOG_EXPORT_FORMAT_JSON_LINES');
  static const LogExportFormat LOG_EXPORT_FORMAT_CSV = LogExportFormat._(2, _omitEnumNames ? '' : 'LOG_EXPORT_FORMAT_CSV');

  static const $core.List<LogExportFormat> values = <LogExportFormat> [
    LOG_EXPORT_FORMAT_UNSPECIFIED,
    LOG_EXPORT_FORMAT_JSON_LINES,
    LOG_EXPORT_FORMAT_CSV,
  ];

  static final $core.Map<$core.int, LogExportFormat> _byValue = $pb.ProtobufEnum.initByValue(values);
  static LogExportFormat? valueOf($core.int value) => _byValue[value];

  const LogExportFormat._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
