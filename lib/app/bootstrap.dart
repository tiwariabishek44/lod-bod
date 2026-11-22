import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/core_providers.dart';
import '../core/config/app_config.dart';
import '../core/session/session_service.dart';
import '../core/storage/preferences_store.dart';
import '../core/storage/secure_token_storage.dart';
import 'load_board_app.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final mode = configuredDataMode();
  final sharedPreferences = await SharedPreferences.getInstance();
  final secureTokenStorage = SecureTokenStorage();
  final session = SessionService(
    tokenStorage: secureTokenStorage,
    preferences: sharedPreferences,
  );
  // Existing installations used mock mode by default. Never reuse a session
  // from another data source, including a legacy demo session in API mode.
  const modeKey = 'loadboard.session_data_mode';
  final previousMode = sharedPreferences.getString(modeKey) ?? 'mock';
  if (previousMode != mode.name) await session.clear();
  await sharedPreferences.setString(modeKey, mode.name);
  await session.initialize();

  runApp(
    ProviderScope(
      overrides: [
        appDataModeProvider.overrideWithValue(mode),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        secureTokenStorageProvider.overrideWithValue(secureTokenStorage),
        sessionServiceProvider.overrideWithValue(session),
        preferencesStoreProvider.overrideWithValue(
          PreferencesStore(sharedPreferences),
        ),
      ],
      child: const LoadBoardApp(),
    ),
  );
}
