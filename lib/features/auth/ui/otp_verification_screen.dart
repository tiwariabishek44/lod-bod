import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_components.dart';
import 'widgets/otp_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    required this.onBack,
    required this.onVerify,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onVerify;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _secondsLeft = 42;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _verify() {
    if (_controllers.any((controller) => controller.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit verification code.')),
      );
      return;
    }
    widget.onVerify();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft == 0) {
        timer.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _resendCode() {
    setState(() => _secondsLeft = 42);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _countdown {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7F8FF), Color(0xFFF5F5FC), Color(0xFFFFF8F2)],
              stops: [0, .68, 1],
            ),
          ),
        ),
        Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.height(11),
                AppSpacing.pageHorizontal,
                AppSpacing.height(6),
              ),
              child: Row(
                children: [
                  AuthBackButton(onTap: widget.onBack),
                  const SizedBox(width: 13),
                  Text(
                    'Verify your number',
                    style: TextStyle(
                      color: AuthPalette.navy,
                      fontSize: AppTypography.size(17),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pageHorizontal,
                  0,
                  AppSpacing.pageHorizontal,
                  AppSpacing.height(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OtpIllustration(),
                    const SizedBox(height: 2),
                    Text(
                      'Enter the 6-digit code',
                      style: TextStyle(
                        color: AuthPalette.navy,
                        fontSize: AppTypography.size(26),
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.65,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: AuthPalette.muted,
                                fontSize: AppTypography.size(13),
                                height: 1.35,
                              ),
                              children: [
                                TextSpan(text: 'We sent a code to '),
                                TextSpan(
                                  text: '+977 98XXXXXXX21.',
                                  style: TextStyle(
                                    color: AuthPalette.navy,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onBack,
                          style: TextButton.styleFrom(
                            foregroundColor: AuthPalette.orange,
                            padding: const EdgeInsets.only(left: 7),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Change',
                            style: TextStyle(
                              fontSize: AppTypography.size(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OtpCodeFields(
                      controllers: _controllers,
                      focusNodes: _focusNodes,
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: TextStyle(
                                color: AuthPalette.muted,
                                fontSize: AppTypography.size(13),
                              ),
                              children: [
                                const TextSpan(text: 'Resend code in '),
                                TextSpan(
                                  text: _countdown,
                                  style: TextStyle(
                                    color: AuthPalette.orange,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _secondsLeft == 0 ? _resendCode : null,
                          style: TextButton.styleFrom(
                            foregroundColor: AuthPalette.navy,
                            disabledForegroundColor: AuthPalette.muted
                                .withValues(alpha: .5),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Resend',
                            style: TextStyle(
                              fontSize: AppTypography.size(13),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    AuthPrimaryButton(
                      label: 'Verify & continue',
                      onPressed: _verify,
                      height: 54,
                    ),
                    const SizedBox(height: 13),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: AuthPalette.muted,
                            fontSize: AppTypography.size(13),
                          ),
                          children: [
                            const TextSpan(text: 'Forgot password?  '),
                            TextSpan(
                              text: 'Reset via OTP',
                              style: TextStyle(
                                color: AuthPalette.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const OtpRoadFooter(),
          ],
        ),
      ],
    );
  }
}
