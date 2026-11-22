import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../auth_components.dart';

class LoginHero extends StatelessWidget {
  const LoginHero({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/auth/login_hero_artwork_recreated.png',
            fit: BoxFit.cover,
            alignment: Alignment.centerRight,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0x36FFFFFF), Color(0x00FFFFFF)],
                stops: [0, .78],
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00F6F7FF),
                    Color(0x00F6F7FF),
                    Color(0xBFF6F7FF),
                    AuthPalette.pale,
                  ],
                  stops: [0, .64, .87, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            top: 25,
            child: Image.asset(
              'assets/images/auth/lodbod_logo_horizontal.png',
              width: 216,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class LoginTitleAccent extends StatelessWidget {
  const LoginTitleAccent({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 82,
      height: 6,
      child: CustomPaint(painter: _OrangeAccentPainter()),
    );
  }
}

class _OrangeAccentPainter extends CustomPainter {
  const _OrangeAccentPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuthPalette.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(2, size.height - 1)
      ..quadraticBezierTo(size.width * .44, 0, size.width - 2, 3);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginMethodSelector extends StatelessWidget {
  const LoginMethodSelector({
    super.key,
    required this.useEmail,
    required this.onChanged,
  });

  final bool useEmail;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AuthPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodChoice(
              label: 'Phone',
              icon: Icons.call_rounded,
              selected: !useEmail,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _MethodChoice(
              label: 'Email',
              icon: Icons.mail_outline_rounded,
              selected: useEmail,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodChoice extends StatelessWidget {
  const _MethodChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AuthPalette.orange : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AuthPalette.navy,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AuthPalette.navy,
                  fontSize: AppTextStyles.bodySize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginOptions extends StatelessWidget {
  const LoginOptions({
    super.key,
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPassword,
  });

  final bool rememberMe;
  final VoidCallback onRememberChanged;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 26),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          InkWell(
            onTap: onRememberChanged,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  width: 21,
                  height: 21,
                  decoration: BoxDecoration(
                    color: rememberMe ? AuthPalette.orange : Colors.white,
                    border: Border.all(
                      color: rememberMe
                          ? AuthPalette.orange
                          : AuthPalette.border,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: rememberMe
                      ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Keep me signed in',
                    style: TextStyle(
                      color: AuthPalette.muted,
                      fontSize: AppTextStyles.labelSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onForgotPassword,
            style: TextButton.styleFrom(
              foregroundColor: AuthPalette.orange,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: AppTextStyles.labelSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoginOrDivider extends StatelessWidget {
  const LoginOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AuthPalette.border, height: 1)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              color: AuthPalette.muted,
              fontSize: AppTextStyles.captionSize,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AuthPalette.border, height: 1)),
      ],
    );
  }
}
