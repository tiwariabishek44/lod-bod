import 'session_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    this.refreshTokenExpiresIn,
    this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int accessTokenExpiresIn;
  final int? refreshTokenExpiresIn;
  final SessionUser? user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']) ?? json;
    final tokens = _asMap(data['tokens']) ?? data;
    final userJson = _asMap(data['user']);
    final accessToken =
        _string(tokens['accessToken']) ?? _string(tokens['access_token']);
    final refreshToken =
        _string(tokens['refreshToken']) ?? _string(tokens['refresh_token']);

    if (accessToken == null || refreshToken == null) {
      throw const FormatException(
        'The login response did not include both session tokens.',
      );
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresIn:
          _integer(tokens['expiresIn']) ??
          _integer(tokens['expires_in']) ??
          3600,
      refreshTokenExpiresIn:
          _integer(tokens['refreshExpiresIn']) ??
          _integer(tokens['refresh_expires_in']),
      user: userJson == null ? null : SessionUser.fromJson(userJson),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _string(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _integer(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}
