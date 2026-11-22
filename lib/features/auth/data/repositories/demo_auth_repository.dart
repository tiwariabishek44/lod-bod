import '../../../../core/network/api_exception.dart';
import '../../../../core/mock/mock_delay.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/session/session_user.dart';
import 'auth_repository.dart';

class DemoAuthRepository implements AuthRepository {
  static const email = 'shipper.demo@lodbod.com';
  static const phone = '+9779800000001';
  static const password = 'Demo@123';

  static const _accounts = [
    _DemoAccount(
      id: 'demo-email-shipper-001',
      name: 'Aarav Shrestha',
      email: email,
      phone: null,
    ),
    _DemoAccount(
      id: 'demo-phone-shipper-002',
      name: 'Sita Gurung',
      email: null,
      phone: phone,
    ),
  ];

  @override
  Future<AuthSession> signIn({
    required String identifier,
    required String password,
  }) async {
    await waitForMockRepository();

    final account = _findAccount(identifier);
    if (account == null || password != DemoAuthRepository.password) {
      throw const ApiException(
        message: 'Email/phone or password is incorrect. Please try again.',
        code: 'invalid_credentials',
      );
    }

    // Local-only preview values. These are not valid backend credentials.
    return AuthSession(
      accessToken: 'loadboard-local-${account.id}-access',
      refreshToken: 'loadboard-local-${account.id}-refresh',
      accessTokenExpiresIn: 31536000,
      refreshTokenExpiresIn: 31536000,
      user: SessionUser(
        id: account.id,
        name: account.name,
        email: account.email,
        phone: account.phone,
        role: UserRole.shipper,
      ),
    );
  }

  _DemoAccount? _findAccount(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      final email = trimmed.toLowerCase();
      for (final account in _accounts) {
        if (account.email?.toLowerCase() == email) return account;
      }
      return null;
    }

    final phone = _normalizePhone(trimmed);
    for (final account in _accounts) {
      if (account.phone != null && _normalizePhone(account.phone!) == phone) {
        return account;
      }
    }
    return null;
  }

  String _normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('977')) return digits;
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.isEmpty ? '' : '977$digits';
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String id;
  final String name;
  final String? email;
  final String? phone;
}
