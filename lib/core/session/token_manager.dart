import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import 'session_service.dart';

class TokenManager {
  TokenManager({required SessionService session, required Dio refreshDio})
    : _session = session,
      _refreshDio = refreshDio;

  final SessionService _session;
  final Dio _refreshDio;

  Future<void> Function()? onAuthenticationExpired;
  Completer<String?>? _refreshCompleter;

  Future<String?> getValidAccessToken() async {
    final accessToken = _session.accessToken;
    final expiry = _session.accessTokenExpiry;

    if (accessToken != null &&
        expiry != null &&
        expiry.difference(DateTime.now()) >
            AppConfig.accessTokenRefreshBuffer) {
      return accessToken;
    }

    return refreshAccessToken();
  }

  Future<String?> refreshAccessToken() async {
    final ongoingRefresh = _refreshCompleter;
    if (ongoingRefresh != null) return ongoingRefresh.future;

    final refreshToken = _session.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }
    final refreshExpiry = _session.refreshTokenExpiry;
    if (refreshExpiry != null && !refreshExpiry.isAfter(DateTime.now())) {
      await _expireSession();
      return null;
    }

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final tokenData = _parseTokenResponse(response.data);

      await _session.updateTokens(
        accessToken: tokenData.accessToken,
        accessTokenExpiresIn: tokenData.accessTokenExpiresIn,
        refreshToken: tokenData.refreshToken,
        refreshTokenExpiresIn: tokenData.refreshTokenExpiresIn,
      );

      completer.complete(tokenData.accessToken);
      return tokenData.accessToken;
    } on DioException catch (exception) {
      final statusCode = exception.response?.statusCode;
      if (statusCode == 401) {
        await _expireSession();
      }
      completer.complete(null);
      return null;
    } catch (_) {
      completer.complete(null);
      return null;
    } finally {
      if (!completer.isCompleted) completer.complete(null);
      if (identical(_refreshCompleter, completer)) {
        _refreshCompleter = null;
      }
    }
  }

  Future<void> _expireSession() async {
    await _session.clear();
    await onAuthenticationExpired?.call();
  }

  _RefreshTokenData _parseTokenResponse(dynamic response) {
    if (response is! Map) {
      throw const FormatException('Invalid token refresh response.');
    }

    final data =
        _asMap(response['data']) ?? Map<String, dynamic>.from(response);
    final tokens = _asMap(data['tokens']) ?? data;
    final accessToken =
        _readString(tokens['accessToken']) ??
        _readString(tokens['access_token']);

    if (accessToken == null) {
      throw const FormatException('No access token in refresh response.');
    }

    return _RefreshTokenData(
      accessToken: accessToken,
      refreshToken:
          _readString(tokens['refreshToken']) ??
          _readString(tokens['refresh_token']),
      accessTokenExpiresIn:
          _readInt(tokens['expiresIn']) ??
          _readInt(tokens['expires_in']) ??
          3600,
      refreshTokenExpiresIn:
          _readInt(tokens['refreshExpiresIn']) ??
          _readInt(tokens['refresh_expires_in']),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _readString(dynamic value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }
}

class _RefreshTokenData {
  const _RefreshTokenData({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresIn,
    required this.refreshTokenExpiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final int accessTokenExpiresIn;
  final int? refreshTokenExpiresIn;
}
