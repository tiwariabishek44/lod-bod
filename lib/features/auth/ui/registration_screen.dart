import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_components.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthPalette.pale,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7F8FF),
                  Color(0xFFF4F5FC),
                  Color(0xFFF9F7F6),
                ],
                stops: [0, .65, 1],
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: -44,
            left: -44,
            child: IgnorePointer(
              child: Opacity(
                opacity: .24,
                child: Image.asset(
                  'assets/images/auth/auth_mountain_ridge.png',
                  height: 156,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: -55,
            right: -55,
            child: IgnorePointer(
              child: Opacity(
                opacity: .19,
                child: Image.asset(
                  'assets/images/auth/auth_mountain_ridge.png',
                  height: 120,
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pageHorizontal,
                AppSpacing.height(13),
                AppSpacing.pageHorizontal,
                AppSpacing.height(18),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AuthBackButton(onTap: onBack),
                      const SizedBox(width: 13),
                      Text(
                        'Shipper account',
                        style: TextStyle(
                          color: AuthPalette.navy,
                          fontSize: AppTypography.size(14),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.width(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: AuthPalette.orange.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AuthPalette.orange.withValues(
                                    alpha: .2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 16,
                                    color: AuthPalette.orange,
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    'COMING SOON',
                                    style: TextStyle(
                                      color: AuthPalette.orange,
                                      fontSize: AppTypography.size(12),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .9),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AuthPalette.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: AuthPalette.navy.withValues(
                                      alpha: .06,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 34,
                                color: AuthPalette.navy,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Create account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AuthPalette.navy,
                                fontSize: AppTypography.size(28),
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.65,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Registration is not available in this prototype yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AuthPalette.muted,
                                fontSize: AppTypography.size(15),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  AuthPrimaryButton(
                    label: 'Back to login',
                    onPressed: onBack,
                    height: 54,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
