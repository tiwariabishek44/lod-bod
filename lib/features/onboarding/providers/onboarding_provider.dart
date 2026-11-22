import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(preferencesStoreProvider).hasCompletedOnboarding;

  Future<void> complete() async {
    await ref.read(preferencesStoreProvider).setOnboardingComplete();
    state = true;
  }
}
