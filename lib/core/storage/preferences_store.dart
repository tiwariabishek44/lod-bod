import 'package:shared_preferences/shared_preferences.dart';

class PreferencesStore {
  PreferencesStore(this._preferences);

  static const _onboardingCompleteKey = 'loadboard.onboarding_complete';

  final SharedPreferences _preferences;

  bool get hasCompletedOnboarding =>
      _preferences.getBool(_onboardingCompleteKey) ?? false;

  Future<void> setOnboardingComplete() =>
      _preferences.setBool(_onboardingCompleteKey, true);
}
