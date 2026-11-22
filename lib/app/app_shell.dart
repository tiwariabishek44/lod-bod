import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shipments/ui/open_post_load.dart';

import '../shared/widgets/shipper_bottom_navigation.dart';

class AppShell extends ConsumerWidget {
  const AppShell({
    required this.navigationShell,
    required this.showBottomNavigation,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedNavIndex = navigationShell.currentIndex < 2
        ? navigationShell.currentIndex
        : navigationShell.currentIndex + 1;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: showBottomNavigation
          ? ShipperBottomNavigation(
              selectedIndex: selectedNavIndex,
              onSelect: (index) {
                final branchIndex = index < 2 ? index : index - 1;
                navigationShell.goBranch(
                  branchIndex,
                  initialLocation: branchIndex == navigationShell.currentIndex,
                );
              },
              onPostLoad: () => openPostLoad(context, ref),
            )
          : null,
    );
  }
}
