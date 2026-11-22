import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'shipper_nav_icon.dart';

class ShipperBottomNavigation extends StatelessWidget {
  const ShipperBottomNavigation({
    required this.selectedIndex,
    required this.onSelect,
    required this.onPostLoad,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onPostLoad;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _CurvedNavigationPainter()),
          ),
          Positioned.fill(
            top: 15,
            child: Row(
              children: [
                _NavigationItem(
                  icon: ShipperNavIconType.home,
                  label: 'Home',
                  selected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _NavigationItem(
                  icon: ShipperNavIconType.shipments,
                  label: 'Shipments',
                  selected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                const SizedBox(width: 58),
                _NavigationItem(
                  icon: ShipperNavIconType.analytics,
                  label: 'Analytics',
                  selected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
                _NavigationItem(
                  icon: ShipperNavIconType.account,
                  label: 'Account',
                  selected: selectedIndex == 4,
                  onTap: () => onSelect(4),
                ),
              ],
            ),
          ),
          Positioned(
            top: -6,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: 'Post Load',
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: .27),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: AppColors.orange.withValues(alpha: .12),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Material(
                    color: AppColors.orange,
                    elevation: 1.5,
                    shadowColor: AppColors.orange.withValues(alpha: .2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onPostLoad,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvedNavigationPainter extends CustomPainter {
  const _CurvedNavigationPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final path = Path()
      ..moveTo(0, 13)
      ..lineTo(center - 46, 13)
      ..cubicTo(center - 36, 13, center - 35, 24, center - 27, 32)
      ..cubicTo(center - 19, 40, center - 10, 46, center, 46)
      ..cubicTo(center + 10, 46, center + 19, 40, center + 27, 32)
      ..cubicTo(center + 35, 24, center + 36, 13, center + 46, 13)
      ..lineTo(size.width, 13)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: .08), 5, true);
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFEAE9EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7,
    );
  }

  @override
  bool shouldRepaint(covariant _CurvedNavigationPainter oldDelegate) => false;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ShipperNavIconType icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.orange : const Color(0xFF73747A);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShipperNavIcon(type: icon, color: color, selected: selected),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: AppTextStyles.captionSize,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
