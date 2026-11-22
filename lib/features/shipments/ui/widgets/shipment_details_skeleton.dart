import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../router/route_names.dart';

/// A lightweight placeholder matching the details page while data loads.
class ShipmentDetailsSkeleton extends StatefulWidget {
  const ShipmentDetailsSkeleton({super.key});
  @override
  State<ShipmentDetailsSkeleton> createState() =>
      _ShipmentDetailsSkeletonState();
}

class _ShipmentDetailsSkeletonState extends State<ShipmentDetailsSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffe5edf7),
    child: SafeArea(
      child: Semantics(
        label: 'Loading shipment details',
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.shipments),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, _) {
                  final opacity = MediaQuery.disableAnimationsOf(context)
                      ? .55
                      : .35 + .25 * _animation.value;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [
                      _bar(210, 24, opacity),
                      const SizedBox(height: 20),
                      _card(opacity, [1.0, .68, .86]),
                      const SizedBox(height: 12),
                      _card(opacity, [.55, .9, .72]),
                      const SizedBox(height: 12),
                      _card(opacity, [.62, .82, .7]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _bar(double width, double height, double opacity) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xffa9b8cf).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(7),
      ),
    ),
  );
  Widget _card(double opacity, List<double> widths) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .8),
      borderRadius: BorderRadius.circular(17),
    ),
    child: LayoutBuilder(
      builder: (context, size) => Column(
        children: [
          for (final width in widths) ...[
            _bar(size.maxWidth * width, 15, opacity),
            const SizedBox(height: 14),
          ],
        ],
      ),
    ),
  );
}
