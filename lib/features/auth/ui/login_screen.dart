import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../providers/auth_providers.dart';
import 'auth_components.dart';
import 'widgets/login_widgets.dart';

typedef LoginSubmitCallback =
    void Function(String identifier, String password, bool rememberMe);

class LodbodLoginScreen extends StatefulWidget {
  const LodbodLoginScreen({
    super.key,
    this.onLogin,
    this.onCreateAccount,
    this.onForgotPassword,
    this.isLoading = false,
  });

  final LoginSubmitCallback? onLogin;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;
  final bool isLoading;

  @override
  State<LodbodLoginScreen> createState() => _LodbodLoginScreenState();
}

class _LodbodLoginScreenState extends State<LodbodLoginScreen> {
  bool _useEmail = false;
  bool _rememberMe = true;
  bool _showPassword = false;
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your phone or email and password.'),
        ),
      );
      return;
    }

    if (_useEmail &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(identifier)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address.')),
      );
      return;
    }

    if (!_useEmail) {
      final digits = identifier.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 8 || digits.length > 15) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid phone number.')),
        );
        return;
      }
    }

    widget.onLogin?.call(identifier, password, _rememberMe);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AuthPalette.pale,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final heroHeight = (constraints.maxHeight * .26)
              .clamp(198.0, 220.0)
              .toDouble();
          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AuthPalette.pale),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 84,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/auth/login_footer_wave.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
              Column(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        LoginHero(height: heroHeight),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontal,
                              AppSpacing.height(12),
                              AppSpacing.pageHorizontal,
                              AppSpacing.height(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: AuthPalette.navy,
                                    fontSize: AppTypography.size(29),
                                    height: 1.08,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const LoginTitleAccent(),
                                const SizedBox(height: 11),
                                Text(
                                  'Log in to manage your shipments.',
                                  style: TextStyle(
                                    color: AuthPalette.muted,
                                    fontSize: AppTextStyles.buttonSize,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                LoginMethodSelector(
                                  useEmail: _useEmail,
                                  onChanged: (value) =>
                                      setState(() => _useEmail = value),
                                ),
                                const SizedBox(height: 13),
                                AuthFieldLabel(
                                  _useEmail ? 'Email address' : 'Phone number',
                                  required: true,
                                ),
                                const SizedBox(height: 6),
                                AuthInput(
                                  key: ValueKey(_useEmail),
                                  controller: _identifierController,
                                  height: 43,
                                  hintText: _useEmail
                                      ? 'name@example.com'
                                      : '+977 98XXXXXXXX',
                                  keyboardType: _useEmail
                                      ? TextInputType.emailAddress
                                      : TextInputType.phone,
                                  textInputAction: TextInputAction.next,
                                  icon: _useEmail
                                      ? Icons.mail_outline_rounded
                                      : Icons.call_rounded,
                                  focused: !_useEmail,
                                ),
                                const SizedBox(height: 11),
                                const AuthFieldLabel(
                                  'Password',
                                  required: true,
                                ),
                                const SizedBox(height: 6),
                                AuthInput(
                                  controller: _passwordController,
                                  height: 43,
                                  obscureText: !_showPassword,
                                  textInputAction: TextInputAction.done,
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    tooltip: _showPassword
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: () => setState(
                                      () => _showPassword = !_showPassword,
                                    ),
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 20,
                                      color: AuthPalette.muted,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                LoginOptions(
                                  rememberMe: _rememberMe,
                                  onRememberChanged: () => setState(
                                    () => _rememberMe = !_rememberMe,
                                  ),
                                  onForgotPassword: widget.onForgotPassword,
                                ),
                                const SizedBox(height: 15),
                                AuthPrimaryButton(
                                  label: 'Log in',
                                  onPressed: widget.isLoading ? null : _submit,
                                  height: 47,
                                  isLoading: widget.isLoading,
                                  textStyle: AppTextStyles.button,
                                ),
                                const SizedBox(height: 15),
                                const LoginOrDivider(),
                                const SizedBox(height: 15),
                                SizedBox(
                                  height: 43,
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: widget.onCreateAccount,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AuthPalette.navy,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: .82,
                                      ),
                                      side: const BorderSide(
                                        color: AuthPalette.border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Create a shipper account',
                                      style: TextStyle(
                                        fontSize: AppTextStyles.buttonSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 3, 16, 14),
                    child: AuthTermsFooter(),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(loginControllerProvider, (previous, next) {
      if (!next.hasError) return;
      final error = next.error;
      final message = error is ApiException
          ? error.message
          : 'Sign in could not be completed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    });

    final loginState = ref.watch(loginControllerProvider);
    return LodbodLoginScreen(
      isLoading: loginState.isLoading,
      onLogin: (identifier, password, rememberMe) {
        ref
            .read(loginControllerProvider.notifier)
            .signIn(
              identifier: identifier,
              password: password,
              rememberMe: rememberMe,
            );
      },
      onCreateAccount: () => context.push(RouteNames.register),
      onForgotPassword: () => context.push(RouteNames.otp),
    );
  }
}
