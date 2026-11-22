enum AppDataMode { mock, api }

class AppConfig {
  const AppConfig._();

  /// Supply the backend root at build/run time. Keep it empty until the
  /// LoadBoard API contract and host are confirmed.
  static const apiBaseUrl = String.fromEnvironment(
    'LOADBOARD_API_BASE_URL',
    defaultValue: '',
  );

  /// Select one data source for the whole app at startup.
  static const dataModeName = String.fromEnvironment(
    'LOADBOARD_DATA_MODE',
    defaultValue: 'mock',
  );

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);
  static const accessTokenRefreshBuffer = Duration(seconds: 90);

  static bool get hasApiBaseUrl => apiBaseUrl.trim().isNotEmpty;
}

AppDataMode configuredDataMode() => switch (AppConfig.dataModeName) {
  'mock' => AppDataMode.mock,
  'api' => AppDataMode.api,
  _ => throw StateError('LOADBOARD_DATA_MODE must be mock or api.'),
};
