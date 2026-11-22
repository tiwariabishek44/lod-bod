import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../storage/secure_token_storage.dart';
import 'auth_session.dart';
import 'session_user.dart';

class SessionService {
  SessionService({
    required SecureTokenStorage tokenStorage,
    required SharedPreferences preferences,
  }) : _tokenStorage = tokenStorage,
       _preferences = preferences;

  static const _userKey = 'loadboard.session_user';

  final SecureTokenStorage _tokenStorage;
  final SharedPreferences _preferences;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiry;
  DateTime? _refreshTokenExpiry;
  SessionUser? _user;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get accessTokenExpiry => _accessTokenExpiry;
  DateTime? get refreshTokenExpiry => _refreshTokenExpiry;
  SessionUser? get user => _user;

  bool get isAuthenticated =>
      _accessToken != null &&
      _refreshToken != null &&
      _user?.role == UserRole.shipper;

  Future<void> initialize() async {
    _accessToken = await _tokenStorage.readAccessToken();
    _refreshToken = await _tokenStorage.readRefreshToken();
    _accessTokenExpiry = await _tokenStorage.readAccessTokenExpiry();
    _refreshTokenExpiry = await _tokenStorage.readRefreshTokenExpiry();
    _user = decodeUser(_preferences.getString(_userKey));

    final hasStoredToken = _accessToken != null || _refreshToken != null;
    final refreshTokenExpired =
        _refreshTokenExpiry != null &&
        !_refreshTokenExpiry!.isAfter(DateTime.now());
    if (hasStoredToken && (!isAuthenticated || refreshTokenExpired)) {
      await clear();
    }
  }

  Future<void> saveSession(AuthSession session, {bool persist = true}) async {
    final now = DateTime.now();
    final accessExpiry = now.add(
      Duration(seconds: session.accessTokenExpiresIn),
    );
    final refreshExpiry = now.add(
      Duration(seconds: session.refreshTokenExpiresIn ?? 604800),
    );

    if (persist) {
      await _tokenStorage.writeTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        accessTokenExpiry: accessExpiry,
        refreshTokenExpiry: refreshExpiry,
      );
      if (session.user != null) {
        await _saveUser(session.user!);
      }
    } else {
      await _tokenStorage.clear();
      await _preferences.remove(_userKey);
    }

    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken;
    _accessTokenExpiry = accessExpiry;
    _refreshTokenExpiry = refreshExpiry;
    _user = session.user;
  }

  Future<void> updateTokens({
    required String accessToken,
    required int accessTokenExpiresIn,
    String? refreshToken,
    int? refreshTokenExpiresIn,
  }) async {
    final accessExpiry = DateTime.now().add(
      Duration(seconds: accessTokenExpiresIn),
    );
    final updatedRefreshToken = refreshToken ?? _refreshToken;
    final refreshExpiry = refreshTokenExpiresIn == null
        ? _refreshTokenExpiry ?? DateTime.now().add(const Duration(days: 7))
        : DateTime.now().add(Duration(seconds: refreshTokenExpiresIn));

    if (updatedRefreshToken == null) {
      throw StateError(
        'Cannot update an access token without a refresh token.',
      );
    }

    if (refreshToken != null || _refreshToken == null) {
      await _tokenStorage.writeTokens(
        accessToken: accessToken,
        refreshToken: updatedRefreshToken,
        accessTokenExpiry: accessExpiry,
        refreshTokenExpiry: refreshExpiry,
      );
    } else {
      await _tokenStorage.writeAccessToken(
        accessToken: accessToken,
        expiry: accessExpiry,
      );
    }

    _accessToken = accessToken;
    _refreshToken = updatedRefreshToken;
    _accessTokenExpiry = accessExpiry;
    _refreshTokenExpiry = refreshExpiry;
  }

  Future<void> clear() async {
    await _tokenStorage.clear();
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiry = null;
    _refreshTokenExpiry = null;
    _user = null;
    await _preferences.remove(_userKey);
  }

  Future<void> _saveUser(SessionUser user) async {
    _user = user;
    await _preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  static SessionUser? decodeUser(String? json) {
    if (json == null) return null;
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return SessionUser.fromJson(decoded);
      if (decoded is Map) {
        return SessionUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
