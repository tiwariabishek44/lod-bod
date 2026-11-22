import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../core/notifications/root_scaffold_messenger.dart';
import '../core/config/app_config.dart';
import '../core/providers/core_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/notifications/providers/mock_bid_arrival_coordinator.dart';
import '../router/app_router.dart';

class LoadBoardApp extends ConsumerWidget {
  const LoadBoardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    if (ref.watch(appDataModeProvider) == AppDataMode.mock) {
      ref.watch(mockBidArrivalCoordinatorProvider);
    }

    return ResponsiveSizer(
      builder: (context, orientation, screenType) => MaterialApp.router(
        title: 'LodBod',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: router,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
      ),
    );
  }
}
