import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'otp_verification_screen.dart';

class OtpScreen extends StatelessWidget {
  const OtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OtpVerificationScreen(
      onBack: () => context.pop(),
      onVerify: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'OTP verification will be connected in the backend phase.',
            ),
          ),
        );
      },
    );
  }
}
