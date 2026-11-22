import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/session/session_user.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/demo_auth_repository.dart';

class AuthState {
  const AuthState({required this.isAuthenticated, this.user});

  const AuthState.unauthenticated() : isAuthenticated = false, user = null;

  final bool isAuthenticated;
  final SessionUser? user;
}

final authStateProvider = NotifierProvider<AuthStateController, AuthState>(
  AuthStateController.new,
);

class AuthStateController extends Notifier<AuthState> with ChangeNotifier {
  @override
  AuthState build() {
    ref.read(tokenManagerProvider).onAuthenticationExpired =
        _handleAuthenticationExpired;
    final session = ref.read(sessionServiceProvider);
    return AuthState(
      isAuthenticated: session.isAuthenticated,
      user: session.user,
    );
  }

  void onSignedIn(SessionUser? user) {
    state = AuthState(isAuthenticated: true, user: user);
    notifyListeners();
  }

  Future<void> signOut() async {
    await ref.read(sessionServiceProvider).clear();
    state = const AuthState.unauthenticated();
    notifyListeners();
  }

  Future<void> _handleAuthenticationExpired() async {
    state = const AuthState.unauthenticated();
    notifyListeners();
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(appDataModeProvider) == AppDataMode.mock
      ? DemoAuthRepository()
      : ApiAuthRepository(ref.watch(apiClientProvider)),
);

final loginControllerProvider = AsyncNotifierProvider<LoginController, void>(
  LoginController.new,
);

class LoginController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signIn({
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authSession = await ref
          .read(authRepositoryProvider)
          .signIn(identifier: identifier.trim(), password: password);
      final user = authSession.user;
      if (user == null || user.role != UserRole.shipper) {
        throw const ApiException(
          message: 'This account does not have shipper access.',
          code: 'role_not_allowed',
        );
      }
      await ref
          .read(sessionServiceProvider)
          .saveSession(authSession, persist: rememberMe);
      ref.read(authStateProvider.notifier).onSignedIn(user);
    });
  }
}
