import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Future<void> showMoreFiltersDrawer(
  BuildContext context,
) => showGeneralDialog<void>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Close filters',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 250),
  pageBuilder: (context, animation, secondaryAnimation) => Align(
    alignment: Alignment.centerRight,
    child: FractionallySizedBox(
      widthFactor: .82,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Material(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filters',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 28),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.tune_rounded,
                    color: AppColors.orange,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'More filters coming soon',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: AppTextStyles.sectionTitleSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can use the status filters on the shipments page for now.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: AppTextStyles.bodySize,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
);
