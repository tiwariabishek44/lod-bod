import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lod_board/features/auth/providers/auth_providers.dart';
import 'package:lod_board/features/home/ui/home_screen.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'package:lod_board/features/shipments/providers/shipment_providers.dart';
import 'package:lod_board/features/shipments/ui/shipments_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class _Auth extends AuthStateController {
  @override
  AuthState build() => const AuthState(isAuthenticated: true);
}

class _Workflow extends ShipmentWorkflowController {
  @override
  Future<ShipmentWorkflowSnapshot> build() async {
    final now = DateTime.now();
    return ShipmentWorkflowSnapshot(
      shipments: [
        for (final (index, status) in [
          ShipmentStatus.awaitingBids,
          ShipmentStatus.scheduled,
          ShipmentStatus.inTransit,
          ShipmentStatus.delivered,
        ].indexed)
          Shipment(
            id: '$index',
            reference: 'LOD-100$index',
            shipperCompanyId: 'company',
            origin: ShipmentLocation(
              city: index == 0 ? 'Kathmandu' : 'Birgunj',
            ),
            destination: const ShipmentLocation(city: 'Pokhara'),
            cargo: const CargoDetails(
              description: 'Cement',
              weight: 1,
              weightUnit: 'T',
            ),
            requiredVehicleType: 'Open',
            pickupAt: now,
            status: status,
            createdAt: now,
            updatedAt: now,
          ),
      ],
      bidsByShipmentId: const {},
      carriersById: const {},
      eventsByShipmentId: const {},
      pendingBidArrivals: const [],
    );
  }
}

void main() {
  testWidgets('dashboard counts and shipment filters use the same data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1800, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: HomeScreen()),
        ),
        GoRoute(
          path: '/shipments',
          builder: (_, _) => const Scaffold(body: ShipmentsScreen()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shipmentWorkflowProvider.overrideWith(_Workflow.new),
          authStateProvider.overrideWith(_Auth.new),
        ],
        child: ResponsiveSizer(
          builder: (_, _, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final dashboard = tester.widget<HomeDashboardScreen>(
      find.byType(HomeDashboardScreen),
    );
    expect(dashboard.activeShipmentsCount, 2);
    expect(dashboard.biddingShipmentsCount, 1);
    expect(dashboard.completedShipmentsCount, 1);
    expect(dashboard.mobileRequestsUsed, 3);

    router.go('/shipments');
    await tester.pumpAndSettle();
    expect(find.text('All (4)'), findsOneWidget);
    expect(find.text('Bidding (1)'), findsOneWidget);
    await tester.tap(find.text('Bidding (1)'));
    await tester.pumpAndSettle();
    expect(find.text('LOD-1000'), findsOneWidget);
    expect(find.text('LOD-1001'), findsNothing);
    await tester.enterText(find.byType(TextField), 'nonexistent');
    await tester.pumpAndSettle();
    expect(find.text('LOD-1000'), findsNothing);
    await tester.enterText(find.byType(TextField), 'kathmandu');
    await tester.pumpAndSettle();
    expect(find.text('LOD-1000'), findsOneWidget);
  });
}
