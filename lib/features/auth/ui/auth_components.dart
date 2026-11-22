import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';

abstract final class AuthPalette {
  static const navy = AppColors.navy;
  static const muted = AppColors.authMuted;
  static const orange = AppColors.orange;
  static const pale = Color(0xFFF6F7FF);
  static const border = AppColors.authBorder;
  static const lavender = AppColors.authLavender;
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: AuthPalette.border),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AuthPalette.navy.withValues(alpha: .05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            size: 21,
            color: AuthPalette.navy,
          ),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.height = 45,
    this.isLoading = false,
    this.textStyle,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool isLoading;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: AuthPalette.orange.withValues(alpha: .19),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AuthPalette.orange,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AuthPalette.orange,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: isLoading
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  label,
                  style:
                      textStyle ??
                      TextStyle(
                        fontSize: AppTypography.size(16),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.2,
                      ),
                ),
        ),
      ),
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.label, {this.required = false, super.key});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.label.copyWith(
          color: AuthPalette.navy,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: label),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AuthPalette.orange),
            ),
        ],
      ),
    );
  }
}

class AuthInput extends StatelessWidget {
  const AuthInput({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.icon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.focused = false,
    this.height = 40,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final IconData? icon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool focused;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        style: AppTextStyles.button.copyWith(
          color: AuthPalette.navy,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.button.copyWith(
            color: AuthPalette.muted,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: icon == null
              ? null
              : Icon(icon, size: 20, color: AuthPalette.muted),
          prefixIconConstraints: const BoxConstraints(minWidth: 50),
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white.withValues(alpha: .92),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: _border(active: focused),
          focusedBorder: _border(active: true, focused: true),
          border: _border(active: focused),
        ),
      ),
    );
  }

  OutlineInputBorder _border({bool active = false, bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: active ? AuthPalette.orange : AuthPalette.border,
        width: focused ? 1.5 : 1,
      ),
    );
  }
}

class AuthTermsFooter extends StatelessWidget {
  const AuthTermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTextStyles.caption.copyWith(color: AuthPalette.muted),
        children: [
          const TextSpan(text: 'By continuing you agree to the '),
          TextSpan(
            text: 'Terms',
            style: TextStyle(
              color: AuthPalette.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: TextStyle(
              color: AuthPalette.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class LodbodWordmark extends StatelessWidget {
  const LodbodWordmark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 46 : 54,
          height: compact ? 46 : 54,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(compact ? 14 : 17),
            boxShadow: [
              BoxShadow(
                color: AppColors.orange.withValues(alpha: .24),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 7,
                top: compact ? 15 : 18,
                child: _SpeedDash(width: compact ? 8 : 10),
              ),
              Positioned(
                left: 7,
                top: compact ? 21 : 25,
                child: _SpeedDash(width: compact ? 12 : 15),
              ),
              Positioned(
                left: 7,
                top: compact ? 27 : 32,
                child: _SpeedDash(width: compact ? 7 : 9),
              ),
              Positioned(
                right: 5,
                top: compact ? 10 : 12,
                child: Icon(
                  Icons.local_shipping_rounded,
                  color: Colors.white,
                  size: compact ? 24 : 28,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: AppTypography.size(compact ? 23 : 27),
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.9,
                ),
                children: const [
                  TextSpan(
                    text: 'LOD',
                    style: TextStyle(color: AuthPalette.navy),
                  ),
                  TextSpan(
                    text: 'BOD',
                    style: TextStyle(color: AuthPalette.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'TRUCKING  •  LOAD BIDDING',
              style: TextStyle(
                color: AuthPalette.navy,
                fontSize: AppTypography.size(compact ? 7 : 8),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SpeedDash extends StatelessWidget {
  const _SpeedDash({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2.4,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
