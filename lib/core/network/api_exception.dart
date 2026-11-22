import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  factory ApiException.fromDio(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;
    final serverMessage = _messageFrom(responseData);

    if (statusCode == 401) {
      return ApiException(
        message: serverMessage ?? 'Your session has expired. Please sign in.',
        statusCode: statusCode,
        code: 'unauthorized',
      );
    }

    if (statusCode == 403) {
      return ApiException(
        message: serverMessage ?? 'You do not have permission to do that.',
        statusCode: statusCode,
        code: 'forbidden',
      );
    }

    if (statusCode == 404) {
      return ApiException(
        message: serverMessage ?? 'The requested item could not be found.',
        statusCode: statusCode,
        code: 'not_found',
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return ApiException(
        message: serverMessage ?? 'The server could not complete the request.',
        statusCode: statusCode,
        code: 'server_error',
      );
    }

    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const ApiException(
        message: 'The request timed out. Please try again.',
        code: 'timeout',
      ),
      DioExceptionType.connectionError => const ApiException(
        message: 'Could not connect. Check your internet connection.',
        code: 'network',
      ),
      _ => ApiException(
        message: serverMessage ?? 'The request could not be completed.',
        statusCode: statusCode,
        code: 'request_failed',
      ),
    };
  }

  static String? _messageFrom(dynamic data) {
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    return null;
  }

  @override
  String toString() => message;
}
