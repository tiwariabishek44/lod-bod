import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(0xFFF5F5F7),
      child: Center(
        child: Text(
          'Analytics',
          style: TextStyle(
            color: AppColors.ink,
            fontSize: AppTypography.size(22),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
