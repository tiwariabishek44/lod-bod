import '../../../../core/session/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  });
}
