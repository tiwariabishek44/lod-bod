import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class ShipmentFilter {
  const ShipmentFilter(this.label, this.count);

  final String label;
  final int count;
}

const shipmentFilterLabels = [
  'All',
  'In Transit',
  'Bidding',
  'Scheduled',
  'Delivered',
];

class ShipmentFilterChip extends StatelessWidget {
  const ShipmentFilterChip({
    super.key,
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final ShipmentFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.orange : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: selected ? 2 : 0,
      shadowColor: AppColors.orange.withValues(alpha: .22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.orange : const Color(0xFFE1E3E9),
            ),
          ),
          child: Text(
            '${filter.label} (${filter.count})',
            style: TextStyle(
              color: selected ? Colors.white : AppColors.ink,
              fontSize: AppTextStyles.bodySize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class ShipmentHeaderButton extends StatelessWidget {
  const ShipmentHeaderButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE4E6EC)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0818274D),
                blurRadius: 7,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: icon == Icons.tune_rounded
                ? AppColors.orange
                : AppColors.ink,
            size: 23,
          ),
        ),
      ),
    );
  }
}

class ShipmentNotificationsButton extends StatelessWidget {
  const ShipmentNotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifications',
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE9E8EE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10151C33),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.ink,
              size: 28,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyShipments extends StatelessWidget {
  const EmptyShipments({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, color: AppColors.muted, size: 32),
            SizedBox(height: 8),
            Text(
              'No shipments found',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: AppTextStyles.sectionTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
