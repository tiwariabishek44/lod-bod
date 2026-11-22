import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      requiresAuth: requiresAuth,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
    bool requiresAuth = true,
  }) {
    return _request<T>(
      'POST',
      path,
      data: data,
      headers: headers,
      requiresAuth: requiresAuth,
    );
  }

  Future<T> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    required bool requiresAuth,
  }) async {
    if (!AppConfig.hasApiBaseUrl) {
      throw const ApiException(
        message:
            'The API address is not configured. Set LOADBOARD_API_BASE_URL to connect a backend.',
        code: 'api_not_configured',
      );
    }

    try {
      final response = await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
          extra: {_requiresAuthKey: requiresAuth},
        ),
      );
      return response.data as T;
    } on ApiException {
      rethrow;
    } on DioException catch (exception) {
      final cause = exception.error;
      if (cause is ApiException) throw cause;
      throw ApiException.fromDio(exception);
    } on TypeError {
      throw const ApiException(
        message: 'The server returned a response in an unexpected format.',
        code: 'invalid_response',
      );
    }
  }

  static const requiresAuthKey = _requiresAuthKey;
  static const _requiresAuthKey = 'loadboard.requires_auth';
}
