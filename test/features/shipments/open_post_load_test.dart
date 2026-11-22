import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lod_board/core/providers/core_providers.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'package:lod_board/features/shipments/providers/shipment_providers.dart';
import 'package:lod_board/features/shipments/ui/open_post_load.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Workflow extends ShipmentWorkflowController {
  _Workflow(this.count);
  final int count;

  @override
  Future<ShipmentWorkflowSnapshot> build() async {
    final now = DateTime.now();
    return ShipmentWorkflowSnapshot(
      shipments: [
        for (var i = 0; i < count; i++)
          Shipment(
            id: '$i',
            reference: 'LOD-$i',
            shipperCompanyId: 'company',
            origin: const ShipmentLocation(city: 'Kathmandu'),
            destination: const ShipmentLocation(city: 'Pokhara'),
            cargo: const CargoDetails(
              description: 'Cement',
              weight: 1,
              weightUnit: 'T',
            ),
            requiredVehicleType: 'Open',
            pickupAt: now,
            status: ShipmentStatus.awaitingBids,
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
  testWidgets('both entry buttons show the limit dialog and do not navigate', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  TextButton(
                    onPressed: () => openPostLoad(context, ref),
                    child: const Text('Home Post Load'),
                  ),
                  TextButton(
                    onPressed: () => openPostLoad(context, ref),
                    child: const Text('Navigation Post Load'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/shipments/create',
          builder: (context, state) => const Text('Form opened'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [shipmentWorkflowProvider.overrideWith(() => _Workflow(3))],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    for (final label in ['Home Post Load', 'Navigation Post Load']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(find.text('Mobile Request Limit Reached'), findsOneWidget);
      expect(
        find.text(
          'You have reached the mobile request limit of 3. Please use the LODBOD web platform to create additional requests.',
        ),
        findsOneWidget,
      );
      expect(find.text('Form opened'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets('below the limit opens the form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                onPressed: () => openPostLoad(context, ref),
                child: const Text('Post Load'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/shipments/create',
          builder: (context, state) => const Text('Form opened'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shipmentWorkflowProvider.overrideWith(() => _Workflow(2)),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Post Load'));
    await tester.pumpAndSettle();
    expect(find.text('Form opened'), findsOneWidget);
    expect(find.text('Mobile Request Limit Reached'), findsNothing);
  });
}
