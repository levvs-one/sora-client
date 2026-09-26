//
//  Generated code. Do not modify.
//  source: sora/core/v1/core_control.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use tunnelModeDescriptor instead')
const TunnelMode$json = {
  '1': 'TunnelMode',
  '2': [
    {'1': 'TUNNEL_MODE_UNSPECIFIED', '2': 0},
    {'1': 'TUNNEL_MODE_SYSTEM', '2': 1},
    {'1': 'TUNNEL_MODE_APPLICATION', '2': 2},
  ],
};

/// Descriptor for `TunnelMode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List tunnelModeDescriptor = $convert.base64Decode(
    'CgpUdW5uZWxNb2RlEhsKF1RVTk5FTF9NT0RFX1VOU1BFQ0lGSUVEEAASFgoSVFVOTkVMX01PRE'
    'VfU1lTVEVNEAESGwoXVFVOTkVMX01PREVfQVBQTElDQVRJT04QAg==');

@$core.Deprecated('Use connectionStateValueDescriptor instead')
const ConnectionStateValue$json = {
  '1': 'ConnectionStateValue',
  '2': [
    {'1': 'CONNECTION_STATE_VALUE_UNSPECIFIED', '2': 0},
    {'1': 'CONNECTION_STATE_VALUE_DISCONNECTED', '2': 1},
    {'1': 'CONNECTION_STATE_VALUE_CONNECTING', '2': 2},
    {'1': 'CONNECTION_STATE_VALUE_CONNECTED', '2': 3},
    {'1': 'CONNECTION_STATE_VALUE_RECONNECTING', '2': 4},
    {'1': 'CONNECTION_STATE_VALUE_FAILED', '2': 5},
  ],
};

/// Descriptor for `ConnectionStateValue`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List connectionStateValueDescriptor = $convert.base64Decode(
    'ChRDb25uZWN0aW9uU3RhdGVWYWx1ZRImCiJDT05ORUNUSU9OX1NUQVRFX1ZBTFVFX1VOU1BFQ0'
    'lGSUVEEAASJwojQ09OTkVDVElPTl9TVEFURV9WQUxVRV9ESVNDT05ORUNURUQQARIlCiFDT05O'
    'RUNUSU9OX1NUQVRFX1ZBTFVFX0NPTk5FQ1RJTkcQAhIkCiBDT05ORUNUSU9OX1NUQVRFX1ZBTF'
    'VFX0NPTk5FQ1RFRBADEicKI0NPTk5FQ1RJT05fU1RBVEVfVkFMVUVfUkVDT05ORUNUSU5HEAQS'
    'IQodQ09OTkVDVElPTl9TVEFURV9WQUxVRV9GQUlMRUQQBQ==');

@$core.Deprecated('Use soraErrorCodeDescriptor instead')
const SoraErrorCode$json = {
  '1': 'SoraErrorCode',
  '2': [
    {'1': 'SORA_ERROR_CODE_UNSPECIFIED', '2': 0},
    {'1': 'SORA_ERROR_CODE_VERSION_MISMATCH', '2': 1},
    {'1': 'SORA_ERROR_CODE_UNAUTHENTICATED', '2': 2},
    {'1': 'SORA_ERROR_CODE_INVALID_ARGUMENT', '2': 3},
    {'1': 'SORA_ERROR_CODE_FAILED_PRECONDITION', '2': 4},
    {'1': 'SORA_ERROR_CODE_NOT_FOUND', '2': 5},
    {'1': 'SORA_ERROR_CODE_RESOURCE_EXHAUSTED', '2': 6},
    {'1': 'SORA_ERROR_CODE_DEADLINE_EXCEEDED', '2': 7},
    {'1': 'SORA_ERROR_CODE_UNAVAILABLE', '2': 8},
    {'1': 'SORA_ERROR_CODE_INTERNAL', '2': 9},
  ],
};

/// Descriptor for `SoraErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List soraErrorCodeDescriptor = $convert.base64Decode(
    'Cg1Tb3JhRXJyb3JDb2RlEh8KG1NPUkFfRVJST1JfQ09ERV9VTlNQRUNJRklFRBAAEiQKIFNPUk'
    'FfRVJST1JfQ09ERV9WRVJTSU9OX01JU01BVENIEAESIwofU09SQV9FUlJPUl9DT0RFX1VOQVVU'
    'SEVOVElDQVRFRBACEiQKIFNPUkFfRVJST1JfQ09ERV9JTlZBTElEX0FSR1VNRU5UEAMSJwojU0'
    '9SQV9FUlJPUl9DT0RFX0ZBSUxFRF9QUkVDT05ESVRJT04QBBIdChlTT1JBX0VSUk9SX0NPREVf'
    'Tk9UX0ZPVU5EEAUSJgoiU09SQV9FUlJPUl9DT0RFX1JFU09VUkNFX0VYSEFVU1RFRBAGEiUKIV'
    'NPUkFfRVJST1JfQ09ERV9ERUFETElORV9FWENFRURFRBAHEh8KG1NPUkFfRVJST1JfQ09ERV9V'
    'TkFWQUlMQUJMRRAIEhwKGFNPUkFfRVJST1JfQ09ERV9JTlRFUk5BTBAJ');

@$core.Deprecated('Use apiVersionDescriptor instead')
const ApiVersion$json = {
  '1': 'ApiVersion',
  '2': [
    {'1': 'major', '3': 1, '4': 1, '5': 13, '10': 'major'},
    {'1': 'minor', '3': 2, '4': 1, '5': 13, '10': 'minor'},
    {'1': 'min_supported_minor', '3': 3, '4': 1, '5': 13, '10': 'minSupportedMinor'},
    {'1': 'capabilities', '3': 4, '4': 3, '5': 9, '10': 'capabilities'},
  ],
};

/// Descriptor for `ApiVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List apiVersionDescriptor = $convert.base64Decode(
    'CgpBcGlWZXJzaW9uEhQKBW1ham9yGAEgASgNUgVtYWpvchIUCgVtaW5vchgCIAEoDVIFbWlub3'
    'ISLgoTbWluX3N1cHBvcnRlZF9taW5vchgDIAEoDVIRbWluU3VwcG9ydGVkTWlub3ISIgoMY2Fw'
    'YWJpbGl0aWVzGAQgAygJUgxjYXBhYmlsaXRpZXM=');

@$core.Deprecated('Use connectRequestDescriptor instead')
const ConnectRequest$json = {
  '1': 'ConnectRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'session_plan', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SessionPlan', '10': 'sessionPlan'},
    {'1': 'control_authenticator', '3': 5, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `ConnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectRequestDescriptor = $convert.base64Decode(
    'Cg5Db25uZWN0UmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS5BcG'
    'lWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZBIdCgpz'
    'ZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSPAoMc2Vzc2lvbl9wbGFuGAQgASgLMhkuc29yYS'
    '5jb3JlLnYxLlNlc3Npb25QbGFuUgtzZXNzaW9uUGxhbhIzChVjb250cm9sX2F1dGhlbnRpY2F0'
    'b3IYBSABKAxSFGNvbnRyb2xBdXRoZW50aWNhdG9y');

@$core.Deprecated('Use connectResponseDescriptor instead')
const ConnectResponse$json = {
  '1': 'ConnectResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ConnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectResponseDescriptor = $convert.base64Decode(
    'Cg9Db25uZWN0UmVzcG9uc2USMwoGc3RhdHVzGAEgASgLMhsuc29yYS5jb3JlLnYxLlNlc3Npb2'
    '5TdGF0dXNSBnN0YXR1cxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JS'
    'BWVycm9y');

@$core.Deprecated('Use disconnectRequestDescriptor instead')
const DisconnectRequest$json = {
  '1': 'DisconnectRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'control_authenticator', '3': 4, '4': 1, '5': 12, '10': 'controlAuthenticator'},
  ],
};

/// Descriptor for `DisconnectRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectRequestDescriptor = $convert.base64Decode(
    'ChFEaXNjb25uZWN0UmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS52MS'
    '5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJZBId'
    'CgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSMwoVY29udHJvbF9hdXRoZW50aWNhdG9yGA'
    'QgASgMUhRjb250cm9sQXV0aGVudGljYXRvcg==');

@$core.Deprecated('Use disconnectResponseDescriptor instead')
const DisconnectResponse$json = {
  '1': 'DisconnectResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `DisconnectResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List disconnectResponseDescriptor = $convert.base64Decode(
    'ChJEaXNjb25uZWN0UmVzcG9uc2USMwoGc3RhdHVzGAEgASgLMhsuc29yYS5jb3JlLnYxLlNlc3'
    'Npb25TdGF0dXNSBnN0YXR1cxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJy'
    'b3JSBWVycm9y');

@$core.Deprecated('Use getStatusRequestDescriptor instead')
const GetStatusRequest$json = {
  '1': 'GetStatusRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetStatusRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusRequestDescriptor = $convert.base64Decode(
    'ChBHZXRTdGF0dXNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLnYxLk'
    'FwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKc2Vzc2lvbl9pZBgCIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use getStatusResponseDescriptor instead')
const GetStatusResponse$json = {
  '1': 'GetStatusResponse',
  '2': [
    {'1': 'status', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionStatus', '10': 'status'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetStatusResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatusResponseDescriptor = $convert.base64Decode(
    'ChFHZXRTdGF0dXNSZXNwb25zZRIzCgZzdGF0dXMYASABKAsyGy5zb3JhLmNvcmUudjEuU2Vzc2'
    'lvblN0YXR1c1IGc3RhdHVzEi0KBWVycm9yGAIgASgLMhcuc29yYS5jb3JlLnYxLlNvcmFFcnJv'
    'clIFZXJyb3I=');

@$core.Deprecated('Use watchEventsRequestDescriptor instead')
const WatchEventsRequest$json = {
  '1': 'WatchEventsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'after_sequence', '3': 3, '4': 1, '5': 4, '10': 'afterSequence'},
  ],
};

/// Descriptor for `WatchEventsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List watchEventsRequestDescriptor = $convert.base64Decode(
    'ChJXYXRjaEV2ZW50c1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudj'
    'EuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpzZXNzaW9uX2lkGAIgASgJUglzZXNzaW9uSWQS'
    'JQoOYWZ0ZXJfc2VxdWVuY2UYAyABKARSDWFmdGVyU2VxdWVuY2U=');

@$core.Deprecated('Use sessionPlanDescriptor instead')
const SessionPlan$json = {
  '1': 'SessionPlan',
  '2': [
    {'1': 'tunnel_mode', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.TunnelMode', '10': 'tunnelMode'},
    {'1': 'outbounds', '3': 2, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'routes', '3': 3, '4': 3, '5': 11, '6': '.sora.core.v1.RoutingRule', '10': 'routes'},
    {'1': 'dns_policy', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.DnsPolicy', '10': 'dnsPolicy'},
    {'1': 'bypass_settings', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.BypassSettings', '10': 'bypassSettings'},
    {'1': 'session_identity', '3': 6, '4': 1, '5': 9, '10': 'sessionIdentity'},
  ],
};

/// Descriptor for `SessionPlan`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionPlanDescriptor = $convert.base64Decode(
    'CgtTZXNzaW9uUGxhbhI5Cgt0dW5uZWxfbW9kZRgBIAEoDjIYLnNvcmEuY29yZS52MS5UdW5uZW'
    'xNb2RlUgp0dW5uZWxNb2RlEjgKCW91dGJvdW5kcxgCIAMoCzIaLnNvcmEuY29yZS52MS5PdXRi'
    'b3VuZFNwZWNSCW91dGJvdW5kcxIxCgZyb3V0ZXMYAyADKAsyGS5zb3JhLmNvcmUudjEuUm91dG'
    'luZ1J1bGVSBnJvdXRlcxI2CgpkbnNfcG9saWN5GAQgASgLMhcuc29yYS5jb3JlLnYxLkRuc1Bv'
    'bGljeVIJZG5zUG9saWN5EkUKD2J5cGFzc19zZXR0aW5ncxgFIAEoCzIcLnNvcmEuY29yZS52MS'
    '5CeXBhc3NTZXR0aW5nc1IOYnlwYXNzU2V0dGluZ3MSKQoQc2Vzc2lvbl9pZGVudGl0eRgGIAEo'
    'CVIPc2Vzc2lvbklkZW50aXR5');

@$core.Deprecated('Use outboundSpecDescriptor instead')
const OutboundSpec$json = {
  '1': 'OutboundSpec',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 9, '10': 'id'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'protocol', '3': 3, '4': 1, '5': 9, '10': 'protocol'},
    {'1': 'transport', '3': 4, '4': 1, '5': 9, '10': 'transport'},
    {'1': 'security', '3': 5, '4': 1, '5': 9, '10': 'security'},
    {'1': 'endpoint', '3': 6, '4': 1, '5': 11, '6': '.sora.core.v1.Endpoint', '10': 'endpoint'},
    {'1': 'credentials', '3': 7, '4': 1, '5': 11, '6': '.sora.core.v1.CredentialsRef', '10': 'credentials'},
  ],
};

/// Descriptor for `OutboundSpec`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List outboundSpecDescriptor = $convert.base64Decode(
    'CgxPdXRib3VuZFNwZWMSDgoCaWQYASABKAlSAmlkEiEKDGRpc3BsYXlfbmFtZRgCIAEoCVILZG'
    'lzcGxheU5hbWUSGgoIcHJvdG9jb2wYAyABKAlSCHByb3RvY29sEhwKCXRyYW5zcG9ydBgEIAEo'
    'CVIJdHJhbnNwb3J0EhoKCHNlY3VyaXR5GAUgASgJUghzZWN1cml0eRIyCghlbmRwb2ludBgGIA'
    'EoCzIWLnNvcmEuY29yZS52MS5FbmRwb2ludFIIZW5kcG9pbnQSPgoLY3JlZGVudGlhbHMYByAB'
    'KAsyHC5zb3JhLmNvcmUudjEuQ3JlZGVudGlhbHNSZWZSC2NyZWRlbnRpYWxz');

@$core.Deprecated('Use endpointDescriptor instead')
const Endpoint$json = {
  '1': 'Endpoint',
  '2': [
    {'1': 'host', '3': 1, '4': 1, '5': 9, '10': 'host'},
    {'1': 'port', '3': 2, '4': 1, '5': 13, '10': 'port'},
  ],
};

/// Descriptor for `Endpoint`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List endpointDescriptor = $convert.base64Decode(
    'CghFbmRwb2ludBISCgRob3N0GAEgASgJUgRob3N0EhIKBHBvcnQYAiABKA1SBHBvcnQ=');

@$core.Deprecated('Use credentialsRefDescriptor instead')
const CredentialsRef$json = {
  '1': 'CredentialsRef',
  '2': [
    {'1': 'reference', '3': 1, '4': 1, '5': 9, '10': 'reference'},
  ],
};

/// Descriptor for `CredentialsRef`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List credentialsRefDescriptor = $convert.base64Decode(
    'Cg5DcmVkZW50aWFsc1JlZhIcCglyZWZlcmVuY2UYASABKAlSCXJlZmVyZW5jZQ==');

@$core.Deprecated('Use routingRuleDescriptor instead')
const RoutingRule$json = {
  '1': 'RoutingRule',
  '2': [
    {'1': 'destination', '3': 1, '4': 1, '5': 9, '10': 'destination'},
    {'1': 'outbound_id', '3': 2, '4': 1, '5': 9, '10': 'outboundId'},
  ],
};

/// Descriptor for `RoutingRule`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List routingRuleDescriptor = $convert.base64Decode(
    'CgtSb3V0aW5nUnVsZRIgCgtkZXN0aW5hdGlvbhgBIAEoCVILZGVzdGluYXRpb24SHwoLb3V0Ym'
    '91bmRfaWQYAiABKAlSCm91dGJvdW5kSWQ=');

@$core.Deprecated('Use dnsPolicyDescriptor instead')
const DnsPolicy$json = {
  '1': 'DnsPolicy',
  '2': [
    {'1': 'servers', '3': 1, '4': 3, '5': 9, '10': 'servers'},
    {'1': 'block_private', '3': 2, '4': 1, '5': 8, '10': 'blockPrivate'},
  ],
};

/// Descriptor for `DnsPolicy`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List dnsPolicyDescriptor = $convert.base64Decode(
    'CglEbnNQb2xpY3kSGAoHc2VydmVycxgBIAMoCVIHc2VydmVycxIjCg1ibG9ja19wcml2YXRlGA'
    'IgASgIUgxibG9ja1ByaXZhdGU=');

@$core.Deprecated('Use bypassSettingsDescriptor instead')
const BypassSettings$json = {
  '1': 'BypassSettings',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'rules', '3': 2, '4': 3, '5': 9, '10': 'rules'},
  ],
};

/// Descriptor for `BypassSettings`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bypassSettingsDescriptor = $convert.base64Decode(
    'Cg5CeXBhc3NTZXR0aW5ncxIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEhQKBXJ1bGVzGAIgAy'
    'gJUgVydWxlcw==');

@$core.Deprecated('Use sessionStatusDescriptor instead')
const SessionStatus$json = {
  '1': 'SessionStatus',
  '2': [
    {'1': 'connection', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ConnectionState', '10': 'connection'},
    {'1': 'negotiated_version', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'negotiatedVersion'},
  ],
};

/// Descriptor for `SessionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sessionStatusDescriptor = $convert.base64Decode(
    'Cg1TZXNzaW9uU3RhdHVzEj0KCmNvbm5lY3Rpb24YASABKAsyHS5zb3JhLmNvcmUudjEuQ29ubm'
    'VjdGlvblN0YXRlUgpjb25uZWN0aW9uEkcKEm5lZ290aWF0ZWRfdmVyc2lvbhgCIAEoCzIYLnNv'
    'cmEuY29yZS52MS5BcGlWZXJzaW9uUhFuZWdvdGlhdGVkVmVyc2lvbg==');

@$core.Deprecated('Use getStatsRequestDescriptor instead')
const GetStatsRequest$json = {
  '1': 'GetStatsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `GetStatsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsRequestDescriptor = $convert.base64Decode(
    'Cg9HZXRTdGF0c1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudjEuQX'
    'BpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpzZXNzaW9uX2lkGAIgASgJUglzZXNzaW9uSWQ=');

@$core.Deprecated('Use getStatsResponseDescriptor instead')
const GetStatsResponse$json = {
  '1': 'GetStatsResponse',
  '2': [
    {'1': 'stats', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.StatsTick', '10': 'stats'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `GetStatsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getStatsResponseDescriptor = $convert.base64Decode(
    'ChBHZXRTdGF0c1Jlc3BvbnNlEi0KBXN0YXRzGAEgASgLMhcuc29yYS5jb3JlLnYxLlN0YXRzVG'
    'lja1IFc3RhdHMSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJv'
    'cg==');

@$core.Deprecated('Use connectionStateDescriptor instead')
const ConnectionState$json = {
  '1': 'ConnectionState',
  '2': [
    {'1': 'value', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.ConnectionStateValue', '10': 'value'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'reason', '3': 3, '4': 1, '5': 14, '6': '.sora.core.v1.SoraErrorCode', '10': 'reason'},
    {'1': 'changed_at', '3': 4, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'changedAt'},
    {'1': 'retry_after', '3': 5, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'retryAfter'},
  ],
};

/// Descriptor for `ConnectionState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List connectionStateDescriptor = $convert.base64Decode(
    'Cg9Db25uZWN0aW9uU3RhdGUSOAoFdmFsdWUYASABKA4yIi5zb3JhLmNvcmUudjEuQ29ubmVjdG'
    'lvblN0YXRlVmFsdWVSBXZhbHVlEh0KCnNlc3Npb25faWQYAiABKAlSCXNlc3Npb25JZBIzCgZy'
    'ZWFzb24YAyABKA4yGy5zb3JhLmNvcmUudjEuU29yYUVycm9yQ29kZVIGcmVhc29uEjkKCmNoYW'
    '5nZWRfYXQYBCABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUgljaGFuZ2VkQXQSOgoL'
    'cmV0cnlfYWZ0ZXIYBSABKAsyGS5nb29nbGUucHJvdG9idWYuRHVyYXRpb25SCnJldHJ5QWZ0ZX'
    'I=');

@$core.Deprecated('Use coreEventDescriptor instead')
const CoreEvent$json = {
  '1': 'CoreEvent',
  '2': [
    {'1': 'sequence', '3': 1, '4': 1, '5': 4, '10': 'sequence'},
    {'1': 'session_id', '3': 2, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'emitted_at', '3': 3, '4': 1, '5': 11, '6': '.google.protobuf.Timestamp', '10': 'emittedAt'},
    {'1': 'state_changed', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.StateChanged', '9': 0, '10': 'stateChanged'},
    {'1': 'stats_tick', '3': 5, '4': 1, '5': 11, '6': '.sora.core.v1.StatsTick', '9': 0, '10': 'statsTick'},
    {'1': 'bypass_strategy_changed', '3': 6, '4': 1, '5': 11, '6': '.sora.core.v1.BypassStrategyChanged', '9': 0, '10': 'bypassStrategyChanged'},
    {'1': 'probe_result', '3': 7, '4': 1, '5': 11, '6': '.sora.core.v1.ProbeResult', '9': 0, '10': 'probeResult'},
    {'1': 'log_batch', '3': 8, '4': 1, '5': 11, '6': '.sora.core.v1.LogBatch', '9': 0, '10': 'logBatch'},
    {'1': 'error', '3': 9, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '9': 0, '10': 'error'},
  ],
  '8': [
    {'1': 'payload'},
  ],
};

/// Descriptor for `CoreEvent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List coreEventDescriptor = $convert.base64Decode(
    'CglDb3JlRXZlbnQSGgoIc2VxdWVuY2UYASABKARSCHNlcXVlbmNlEh0KCnNlc3Npb25faWQYAi'
    'ABKAlSCXNlc3Npb25JZBI5CgplbWl0dGVkX2F0GAMgASgLMhouZ29vZ2xlLnByb3RvYnVmLlRp'
    'bWVzdGFtcFIJZW1pdHRlZEF0EkEKDXN0YXRlX2NoYW5nZWQYBCABKAsyGi5zb3JhLmNvcmUudj'
    'EuU3RhdGVDaGFuZ2VkSABSDHN0YXRlQ2hhbmdlZBI4CgpzdGF0c190aWNrGAUgASgLMhcuc29y'
    'YS5jb3JlLnYxLlN0YXRzVGlja0gAUglzdGF0c1RpY2sSXQoXYnlwYXNzX3N0cmF0ZWd5X2NoYW'
    '5nZWQYBiABKAsyIy5zb3JhLmNvcmUudjEuQnlwYXNzU3RyYXRlZ3lDaGFuZ2VkSABSFWJ5cGFz'
    'c1N0cmF0ZWd5Q2hhbmdlZBI+Cgxwcm9iZV9yZXN1bHQYByABKAsyGS5zb3JhLmNvcmUudjEuUH'
    'JvYmVSZXN1bHRIAFILcHJvYmVSZXN1bHQSNQoJbG9nX2JhdGNoGAggASgLMhYuc29yYS5jb3Jl'
    'LnYxLkxvZ0JhdGNoSABSCGxvZ0JhdGNoEi8KBWVycm9yGAkgASgLMhcuc29yYS5jb3JlLnYxLl'
    'NvcmFFcnJvckgAUgVlcnJvckIJCgdwYXlsb2Fk');

@$core.Deprecated('Use stateChangedDescriptor instead')
const StateChanged$json = {
  '1': 'StateChanged',
  '2': [
    {'1': 'state', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ConnectionState', '10': 'state'},
  ],
};

/// Descriptor for `StateChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List stateChangedDescriptor = $convert.base64Decode(
    'CgxTdGF0ZUNoYW5nZWQSMwoFc3RhdGUYASABKAsyHS5zb3JhLmNvcmUudjEuQ29ubmVjdGlvbl'
    'N0YXRlUgVzdGF0ZQ==');

@$core.Deprecated('Use statsTickDescriptor instead')
const StatsTick$json = {
  '1': 'StatsTick',
  '2': [
    {'1': 'bytes_up', '3': 1, '4': 1, '5': 4, '10': 'bytesUp'},
    {'1': 'bytes_down', '3': 2, '4': 1, '5': 4, '10': 'bytesDown'},
    {'1': 'active_connections', '3': 3, '4': 1, '5': 4, '10': 'activeConnections'},
  ],
};

/// Descriptor for `StatsTick`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List statsTickDescriptor = $convert.base64Decode(
    'CglTdGF0c1RpY2sSGQoIYnl0ZXNfdXAYASABKARSB2J5dGVzVXASHQoKYnl0ZXNfZG93bhgCIA'
    'EoBFIJYnl0ZXNEb3duEi0KEmFjdGl2ZV9jb25uZWN0aW9ucxgDIAEoBFIRYWN0aXZlQ29ubmVj'
    'dGlvbnM=');

@$core.Deprecated('Use bypassStrategyChangedDescriptor instead')
const BypassStrategyChanged$json = {
  '1': 'BypassStrategyChanged',
  '2': [
    {'1': 'strategy', '3': 1, '4': 1, '5': 9, '10': 'strategy'},
  ],
};

/// Descriptor for `BypassStrategyChanged`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List bypassStrategyChangedDescriptor = $convert.base64Decode(
    'ChVCeXBhc3NTdHJhdGVneUNoYW5nZWQSGgoIc3RyYXRlZ3kYASABKAlSCHN0cmF0ZWd5');

@$core.Deprecated('Use probeResultDescriptor instead')
const ProbeResult$json = {
  '1': 'ProbeResult',
  '2': [
    {'1': 'server_id', '3': 1, '4': 1, '5': 9, '10': 'serverId'},
    {'1': 'reachable', '3': 2, '4': 1, '5': 8, '10': 'reachable'},
    {'1': 'latency_ms', '3': 3, '4': 1, '5': 13, '10': 'latencyMs'},
    {'1': 'error', '3': 4, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ProbeResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List probeResultDescriptor = $convert.base64Decode(
    'CgtQcm9iZVJlc3VsdBIbCglzZXJ2ZXJfaWQYASABKAlSCHNlcnZlcklkEhwKCXJlYWNoYWJsZR'
    'gCIAEoCFIJcmVhY2hhYmxlEh0KCmxhdGVuY3lfbXMYAyABKA1SCWxhdGVuY3lNcxItCgVlcnJv'
    'chgEIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use logBatchDescriptor instead')
const LogBatch$json = {
  '1': 'LogBatch',
  '2': [
    {'1': 'lines', '3': 1, '4': 3, '5': 9, '10': 'lines'},
  ],
};

/// Descriptor for `LogBatch`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logBatchDescriptor = $convert.base64Decode(
    'CghMb2dCYXRjaBIUCgVsaW5lcxgBIAMoCVIFbGluZXM=');

@$core.Deprecated('Use parseImportRequestDescriptor instead')
const ParseImportRequest$json = {
  '1': 'ParseImportRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'payload', '3': 3, '4': 1, '5': 12, '10': 'payload'},
  ],
};

/// Descriptor for `ParseImportRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseImportRequestDescriptor = $convert.base64Decode(
    'ChJQYXJzZUltcG9ydFJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcmUudj'
    'EuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0SWQS'
    'GAoHcGF5bG9hZBgDIAEoDFIHcGF5bG9hZA==');

@$core.Deprecated('Use parseImportResponseDescriptor instead')
const ParseImportResponse$json = {
  '1': 'ParseImportResponse',
  '2': [
    {'1': 'session_plan', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.SessionPlan', '10': 'sessionPlan'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ParseImportResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List parseImportResponseDescriptor = $convert.base64Decode(
    'ChNQYXJzZUltcG9ydFJlc3BvbnNlEjwKDHNlc3Npb25fcGxhbhgBIAEoCzIZLnNvcmEuY29yZS'
    '52MS5TZXNzaW9uUGxhblILc2Vzc2lvblBsYW4SLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUu'
    'djEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use fetchSubscriptionRequestDescriptor instead')
const FetchSubscriptionRequest$json = {
  '1': 'FetchSubscriptionRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'reference', '3': 3, '4': 1, '5': 9, '10': 'reference'},
  ],
};

/// Descriptor for `FetchSubscriptionRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSubscriptionRequestDescriptor = $convert.base64Decode(
    'ChhGZXRjaFN1YnNjcmlwdGlvblJlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
    'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1'
    'ZXN0SWQSHAoJcmVmZXJlbmNlGAMgASgJUglyZWZlcmVuY2U=');

@$core.Deprecated('Use fetchSubscriptionResponseDescriptor instead')
const FetchSubscriptionResponse$json = {
  '1': 'FetchSubscriptionResponse',
  '2': [
    {'1': 'outbounds', '3': 1, '4': 3, '5': 11, '6': '.sora.core.v1.OutboundSpec', '10': 'outbounds'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `FetchSubscriptionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List fetchSubscriptionResponseDescriptor = $convert.base64Decode(
    'ChlGZXRjaFN1YnNjcmlwdGlvblJlc3BvbnNlEjgKCW91dGJvdW5kcxgBIAMoCzIaLnNvcmEuY2'
    '9yZS52MS5PdXRib3VuZFNwZWNSCW91dGJvdW5kcxItCgVlcnJvchgCIAEoCzIXLnNvcmEuY29y'
    'ZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use probeServersRequestDescriptor instead')
const ProbeServersRequest$json = {
  '1': 'ProbeServersRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'endpoints', '3': 3, '4': 3, '5': 11, '6': '.sora.core.v1.Endpoint', '10': 'endpoints'},
  ],
};

/// Descriptor for `ProbeServersRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List probeServersRequestDescriptor = $convert.base64Decode(
    'ChNQcm9iZVNlcnZlcnNSZXF1ZXN0EjkKC2FwaV92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
    'YxLkFwaVZlcnNpb25SCmFwaVZlcnNpb24SHQoKcmVxdWVzdF9pZBgCIAEoCVIJcmVxdWVzdElk'
    'EjQKCWVuZHBvaW50cxgDIAMoCzIWLnNvcmEuY29yZS52MS5FbmRwb2ludFIJZW5kcG9pbnRz');

@$core.Deprecated('Use runDiagnosticsRequestDescriptor instead')
const RunDiagnosticsRequest$json = {
  '1': 'RunDiagnosticsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `RunDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runDiagnosticsRequestDescriptor = $convert.base64Decode(
    'ChVSdW5EaWFnbm9zdGljc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLmNvcm'
    'UudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1ZXN0'
    'SWQSHQoKc2Vzc2lvbl9pZBgDIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use runDiagnosticsResponseDescriptor instead')
const RunDiagnosticsResponse$json = {
  '1': 'RunDiagnosticsResponse',
  '2': [
    {'1': 'report', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.DiagnosticReport', '10': 'report'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `RunDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List runDiagnosticsResponseDescriptor = $convert.base64Decode(
    'ChZSdW5EaWFnbm9zdGljc1Jlc3BvbnNlEjYKBnJlcG9ydBgBIAEoCzIeLnNvcmEuY29yZS52MS'
    '5EaWFnbm9zdGljUmVwb3J0UgZyZXBvcnQSLQoFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEu'
    'U29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use exportDiagnosticsRequestDescriptor instead')
const ExportDiagnosticsRequest$json = {
  '1': 'ExportDiagnosticsRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
  ],
};

/// Descriptor for `ExportDiagnosticsRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDiagnosticsRequestDescriptor = $convert.base64Decode(
    'ChhFeHBvcnREaWFnbm9zdGljc1JlcXVlc3QSOQoLYXBpX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
    'NvcmUudjEuQXBpVmVyc2lvblIKYXBpVmVyc2lvbhIdCgpyZXF1ZXN0X2lkGAIgASgJUglyZXF1'
    'ZXN0SWQSHQoKc2Vzc2lvbl9pZBgDIAEoCVIJc2Vzc2lvbklk');

@$core.Deprecated('Use exportDiagnosticsResponseDescriptor instead')
const ExportDiagnosticsResponse$json = {
  '1': 'ExportDiagnosticsResponse',
  '2': [
    {'1': 'archive', '3': 1, '4': 1, '5': 12, '10': 'archive'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `ExportDiagnosticsResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List exportDiagnosticsResponseDescriptor = $convert.base64Decode(
    'ChlFeHBvcnREaWFnbm9zdGljc1Jlc3BvbnNlEhgKB2FyY2hpdmUYASABKAxSB2FyY2hpdmUSLQ'
    'oFZXJyb3IYAiABKAsyFy5zb3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use setKillSwitchRequestDescriptor instead')
const SetKillSwitchRequest$json = {
  '1': 'SetKillSwitchRequest',
  '2': [
    {'1': 'api_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'apiVersion'},
    {'1': 'request_id', '3': 2, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'session_id', '3': 3, '4': 1, '5': 9, '10': 'sessionId'},
    {'1': 'enabled', '3': 4, '4': 1, '5': 8, '10': 'enabled'},
  ],
};

/// Descriptor for `SetKillSwitchRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setKillSwitchRequestDescriptor = $convert.base64Decode(
    'ChRTZXRLaWxsU3dpdGNoUmVxdWVzdBI5CgthcGlfdmVyc2lvbhgBIAEoCzIYLnNvcmEuY29yZS'
    '52MS5BcGlWZXJzaW9uUgphcGlWZXJzaW9uEh0KCnJlcXVlc3RfaWQYAiABKAlSCXJlcXVlc3RJ'
    'ZBIdCgpzZXNzaW9uX2lkGAMgASgJUglzZXNzaW9uSWQSGAoHZW5hYmxlZBgEIAEoCFIHZW5hYm'
    'xlZA==');

@$core.Deprecated('Use setKillSwitchResponseDescriptor instead')
const SetKillSwitchResponse$json = {
  '1': 'SetKillSwitchResponse',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `SetKillSwitchResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setKillSwitchResponseDescriptor = $convert.base64Decode(
    'ChVTZXRLaWxsU3dpdGNoUmVzcG9uc2USGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBItCgVlcn'
    'JvchgCIAEoCzIXLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JSBWVycm9y');

@$core.Deprecated('Use diagnosticReportDescriptor instead')
const DiagnosticReport$json = {
  '1': 'DiagnosticReport',
  '2': [
    {'1': 'lines', '3': 1, '4': 3, '5': 9, '10': 'lines'},
  ],
};

/// Descriptor for `DiagnosticReport`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List diagnosticReportDescriptor = $convert.base64Decode(
    'ChBEaWFnbm9zdGljUmVwb3J0EhQKBWxpbmVzGAEgAygJUgVsaW5lcw==');

@$core.Deprecated('Use handshakeRequestDescriptor instead')
const HandshakeRequest$json = {
  '1': 'HandshakeRequest',
  '2': [
    {'1': 'client_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'clientVersion'},
  ],
};

/// Descriptor for `HandshakeRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeRequestDescriptor = $convert.base64Decode(
    'ChBIYW5kc2hha2VSZXF1ZXN0Ej8KDmNsaWVudF92ZXJzaW9uGAEgASgLMhguc29yYS5jb3JlLn'
    'YxLkFwaVZlcnNpb25SDWNsaWVudFZlcnNpb24=');

@$core.Deprecated('Use handshakeResponseDescriptor instead')
const HandshakeResponse$json = {
  '1': 'HandshakeResponse',
  '2': [
    {'1': 'negotiated_version', '3': 1, '4': 1, '5': 11, '6': '.sora.core.v1.ApiVersion', '10': 'negotiatedVersion'},
    {'1': 'error', '3': 2, '4': 1, '5': 11, '6': '.sora.core.v1.SoraError', '10': 'error'},
  ],
};

/// Descriptor for `HandshakeResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeResponseDescriptor = $convert.base64Decode(
    'ChFIYW5kc2hha2VSZXNwb25zZRJHChJuZWdvdGlhdGVkX3ZlcnNpb24YASABKAsyGC5zb3JhLm'
    'NvcmUudjEuQXBpVmVyc2lvblIRbmVnb3RpYXRlZFZlcnNpb24SLQoFZXJyb3IYAiABKAsyFy5z'
    'b3JhLmNvcmUudjEuU29yYUVycm9yUgVlcnJvcg==');

@$core.Deprecated('Use soraErrorDescriptor instead')
const SoraError$json = {
  '1': 'SoraError',
  '2': [
    {'1': 'code', '3': 1, '4': 1, '5': 14, '6': '.sora.core.v1.SoraErrorCode', '10': 'code'},
    {'1': 'user_message_key', '3': 2, '4': 1, '5': 9, '10': 'userMessageKey'},
    {'1': 'detail_redacted', '3': 3, '4': 1, '5': 9, '10': 'detailRedacted'},
    {'1': 'retryable', '3': 4, '4': 1, '5': 8, '10': 'retryable'},
    {'1': 'request_id', '3': 5, '4': 1, '5': 9, '10': 'requestId'},
    {'1': 'retry_after', '3': 6, '4': 1, '5': 11, '6': '.google.protobuf.Duration', '10': 'retryAfter'},
  ],
};

/// Descriptor for `SoraError`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List soraErrorDescriptor = $convert.base64Decode(
    'CglTb3JhRXJyb3ISLwoEY29kZRgBIAEoDjIbLnNvcmEuY29yZS52MS5Tb3JhRXJyb3JDb2RlUg'
    'Rjb2RlEigKEHVzZXJfbWVzc2FnZV9rZXkYAiABKAlSDnVzZXJNZXNzYWdlS2V5EicKD2RldGFp'
    'bF9yZWRhY3RlZBgDIAEoCVIOZGV0YWlsUmVkYWN0ZWQSHAoJcmV0cnlhYmxlGAQgASgIUglyZX'
    'RyeWFibGUSHQoKcmVxdWVzdF9pZBgFIAEoCVIJcmVxdWVzdElkEjoKC3JldHJ5X2FmdGVyGAYg'
    'ASgLMhkuZ29vZ2xlLnByb3RvYnVmLkR1cmF0aW9uUgpyZXRyeUFmdGVy');

