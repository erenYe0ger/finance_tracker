// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'created_at': instance.createdAt.toIso8601String(),
};

_TokenPair _$TokenPairFromJson(Map<String, dynamic> json) => _TokenPair(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  tokenType: json['token_type'] as String? ?? 'bearer',
  expiresIn: (json['expires_in'] as num).toInt(),
);

Map<String, dynamic> _$TokenPairToJson(_TokenPair instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'token_type': instance.tokenType,
      'expires_in': instance.expiresIn,
    };

_Credentials _$CredentialsFromJson(Map<String, dynamic> json) => _Credentials(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$CredentialsToJson(_Credentials instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    _RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$RegisterRequestToJson(_RegisterRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) =>
    _LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$LoginRequestToJson(_LoginRequest instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_RefreshRequest _$RefreshRequestFromJson(Map<String, dynamic> json) =>
    _RefreshRequest(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$RefreshRequestToJson(_RefreshRequest instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};

_LogoutRequest _$LogoutRequestFromJson(Map<String, dynamic> json) =>
    _LogoutRequest(refreshToken: json['refresh_token'] as String);

Map<String, dynamic> _$LogoutRequestToJson(_LogoutRequest instance) =>
    <String, dynamic>{'refresh_token': instance.refreshToken};

_SafeUser _$SafeUserFromJson(Map<String, dynamic> json) => _SafeUser(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$SafeUserToJson(_SafeUser instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'created_at': instance.createdAt.toIso8601String(),
};

_LogoutResponse _$LogoutResponseFromJson(Map<String, dynamic> json) =>
    _LogoutResponse(detail: json['detail'] as String);

Map<String, dynamic> _$LogoutResponseToJson(_LogoutResponse instance) =>
    <String, dynamic>{'detail': instance.detail};

_HealthResponse _$HealthResponseFromJson(Map<String, dynamic> json) =>
    _HealthResponse(
      status: json['status'] as String,
      service: json['service'] as String,
    );

Map<String, dynamic> _$HealthResponseToJson(_HealthResponse instance) =>
    <String, dynamic>{'status': instance.status, 'service': instance.service};

_DatabaseHealthResponse _$DatabaseHealthResponseFromJson(
  Map<String, dynamic> json,
) => _DatabaseHealthResponse(
  status: json['status'] as String,
  database: json['database'] as String,
);

Map<String, dynamic> _$DatabaseHealthResponseToJson(
  _DatabaseHealthResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'database': instance.database,
};
