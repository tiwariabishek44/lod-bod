import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'loadboard.access_token';
  static const _refreshTokenKey = 'loadboard.refresh_token';
  static const _accessTokenExpiryKey = 'loadboard.access_token_expiry';
  static const _refreshTokenExpiryKey = 'loadboard.refresh_token_expiry';

  final FlutterSecureStorage _storage;

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readAccessTokenExpiry() async =>
      _readDateTime(_accessTokenExpiryKey);

  Future<DateTime?> readRefreshTokenExpiry() async =>
      _readDateTime(_refreshTokenExpiryKey);

  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiry,
    required DateTime refreshTokenExpiry,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(
      key: _accessTokenExpiryKey,
      value: accessTokenExpiry.toIso8601String(),
    );
    await _storage.write(
      key: _refreshTokenExpiryKey,
      value: refreshTokenExpiry.toIso8601String(),
    );
  }

  Future<void> writeAccessToken({
    required String accessToken,
    required DateTime expiry,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(
      key: _accessTokenExpiryKey,
      value: expiry.toIso8601String(),
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessTokenExpiryKey);
    await _storage.delete(key: _refreshTokenExpiryKey);
  }

  Future<DateTime?> _readDateTime(String key) async {
    final value = await _storage.read(key: key);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }
}
