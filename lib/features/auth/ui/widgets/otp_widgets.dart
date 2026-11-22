import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../auth_components.dart';

class OtpIllustration extends StatelessWidget {
  const OtpIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 151,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: -45,
            right: -45,
            bottom: -2,
            child: Opacity(
              opacity: .55,
              child: Image.asset(
                'assets/images/auth/auth_mountain_ridge.png',
                height: 112,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Image.asset(
            'assets/images/auth/otp_phone_chat.png',
            height: 148,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}

class OtpCodeFields extends StatelessWidget {
  const OtpCodeFields({
    super.key,
    required this.controllers,
    required this.focusNodes,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        final selected = index == 3;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 5 ? 0 : 7),
            child: SizedBox(
              height: 53,
              child: TextField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                textInputAction: index == 5
                    ? TextInputAction.done
                    : TextInputAction.next,
                autofillHints: index == 0
                    ? const [AutofillHints.oneTimeCode]
                    : null,
                maxLength: 1,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  color: AuthPalette.navy,
                  fontSize: AppTypography.size(22),
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .9),
                  contentPadding: const EdgeInsets.only(bottom: 1),
                  enabledBorder: _otpBorder(active: selected),
                  focusedBorder: _otpBorder(active: true),
                  border: _otpBorder(active: selected),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    focusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                },
                onEditingComplete: () {
                  if (index < 5) {
                    focusNodes[index + 1].requestFocus();
                  } else {
                    focusNodes[index].unfocus();
                  }
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class OtpRoadFooter extends StatelessWidget {
  const OtpRoadFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 108,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth/otp_nepal_road.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF6F6FC), Color(0x00F6F6FC)],
                stops: [0, .55],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

OutlineInputBorder _otpBorder({required bool active}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: BorderSide(
      color: active ? AuthPalette.orange : AuthPalette.border,
      width: active ? 1.5 : 1,
    ),
  );
}
