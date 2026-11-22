import 'package:dio/dio.dart';

import '../session/token_manager.dart';
import 'api_client.dart';
import 'api_exception.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required Dio dio, required TokenManager tokenManager})
    : _dio = dio,
      _tokenManager = tokenManager;

  final Dio _dio;
  final TokenManager _tokenManager;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuth = options.extra[ApiClient.requiresAuthKey] != false;
    if (!requiresAuth) {
      handler.next(options);
      return;
    }

    try {
      final token = await _tokenManager.getValidAccessToken();
      if (token == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: const ApiException(
              message: 'Sign in is required to make this request.',
              code: 'unauthorized',
            ),
          ),
        );
        return;
      }

      options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error is ApiException
              ? error
              : const ApiException(
                  message: 'Could not prepare the authenticated request.',
                  code: 'auth_request_failed',
                ),
        ),
      );
    }
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final requiresAuth = request.extra[ApiClient.requiresAuthKey] != false;
    final alreadyRetried = request.extra[_refreshRetryKey] == true;

    if (err.response?.statusCode != 401 || !requiresAuth || alreadyRetried) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _tokenManager.refreshAccessToken();
      if (accessToken == null) {
        handler.next(err);
        return;
      }

      request
        ..headers['Authorization'] = 'Bearer $accessToken'
        ..extra[_refreshRetryKey] = true;
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    } catch (_) {
      handler.next(err);
    }
  }

  static const _refreshRetryKey = 'loadboard.refresh_retry';
}
