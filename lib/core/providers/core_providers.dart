import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/auth_interceptor.dart';
import '../session/session_service.dart';
import '../session/token_manager.dart';
import '../storage/preferences_store.dart';
import '../storage/secure_token_storage.dart';

final appDataModeProvider = Provider<AppDataMode>(
  (ref) => configuredDataMode(),
);

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError(
    'sharedPreferencesProvider must be overridden during app bootstrap.',
  ),
);

final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => PreferencesStore(ref.watch(sharedPreferencesProvider)),
);

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(),
);

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(
    tokenStorage: ref.watch(secureTokenStorageProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  ),
);

final tokenManagerProvider = Provider<TokenManager>((ref) {
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {'Accept': 'application/json'},
    ),
  );
  ref.onDispose(() => refreshDio.close());

  return TokenManager(
    session: ref.watch(sessionServiceProvider),
    refreshDio: refreshDio,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(dio: dio, tokenManager: ref.watch(tokenManagerProvider)),
  );
  ref.onDispose(() => dio.close());
  return ApiClient(dio);
});
