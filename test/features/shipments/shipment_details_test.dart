import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'package:lod_board/features/shipments/domain/models/bid_arrival_event.dart';
import 'package:lod_board/features/shipments/providers/shipment_providers.dart';
import 'package:lod_board/features/shipments/ui/shipment_details_screen.dart';
import 'package:lod_board/features/shipments/ui/widgets/shipment_details_skeleton.dart';
import 'mock_shipment_repository_test.dart' as fixtures;

class _DetailsRepository implements ShipmentRepository {
  _DetailsRepository(this.delegate);
  final MockShipmentRepository delegate;
  Completer<ShipmentWorkflowSnapshot?>? pending;
  int detailsCalls = 0, listCalls = 0;
  @override
  Future<ShipmentWorkflowSnapshot?> fetchShipmentDetails(String id) {
    detailsCalls++;
    return pending?.future ?? delegate.fetchShipmentDetails(id);
  }

  @override
  Future<ShipmentWorkflowSnapshot> fetchSnapshot() {
    listCalls++;
    return delegate.fetchSnapshot();
  }

  @override
  Future<void> acceptBid({required String shipmentId, required String bidId}) =>
      delegate.acceptBid(shipmentId: shipmentId, bidId: bidId);
  @override
  Future<List<BidArrivalEvent>> processDueBidArrivals({DateTime? now}) =>
      delegate.processDueBidArrivals(now: now);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('details load independently, show skeleton and retry on error', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      final mock = MockShipmentRepository(
        await SharedPreferences.getInstance(),
        'user',
      );
      final shipment = (await mock.submitLoadPost(
        fixtures.samplePost(),
      )).shipments.single;
      return (mock, shipment);
    });
    final (mock, shipment) = fixture!;
    final repository = _DetailsRepository(mock)
      ..pending = Completer<ShipmentWorkflowSnapshot?>();
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, _) =>
              Scaffold(body: ShipmentDetailsScreen(shipmentId: shipment.id)),
        ),
        GoRoute(
          path: '/shipments',
          builder: (_, _) => const Scaffold(body: Text('Shipments')),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.byType(ShipmentDetailsSkeleton), findsOneWidget);
    expect(repository.listCalls, 0);
    repository.pending!.completeError(StateError('network failed'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load this shipment.'), findsOneWidget);
    repository.pending = null;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text(shipment.reference), findsOneWidget);
    expect(repository.detailsCalls, 2);
    expect(repository.listCalls, 0);
    await tester.scrollUntilVisible(
      find.text('Truck Plan 1'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Truck Plan 1'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hetauda · 2 T'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('More details & history'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('More details & history'));
    await tester.pumpAndSettle();
    expect(find.text('Shipment history'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('missing shipment shows not found and back control', (
    tester,
  ) async {
    final repository = _DetailsRepository(
      MockShipmentRepository(await SharedPreferences.getInstance(), 'user'),
    );
    final router = GoRouter(
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, _) => const Scaffold(
            body: ShipmentDetailsScreen(shipmentId: 'missing'),
          ),
        ),
        GoRoute(
          path: '/shipments',
          builder: (_, _) => const Scaffold(body: Text('Shipments')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shipment could not be found.'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Shipments'), findsOneWidget);
  });
  test(
    'detail provider refreshes by shipment after bid arrival and acceptance',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final mock = MockShipmentRepository(prefs, 'user');
      final first = (await mock.submitLoadPost(
        fixtures.samplePost(id: 'one'),
      )).shipments.single;
      final other = (await mock.submitLoadPost(
        fixtures.samplePost(id: 'two'),
      )).shipments.single;
      final repository = _DetailsRepository(mock);
      final container = ProviderContainer(
        overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        shipmentDetailsProvider(first.id),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);
      final firstDetail = await container.read(
        shipmentDetailsProvider(first.id).future,
      );
      expect(firstDetail!.shipments.single.id, first.id);
      expect(firstDetail.bidsFor(first.id), isEmpty);
      expect(
        await MockShipmentRepository(
          prefs,
          'other-user',
        ).fetchShipmentDetails(first.id),
        isNull,
      );
      await container.read(shipmentWorkflowProvider.future);
      final controller = container.read(shipmentWorkflowProvider.notifier);
      await controller.processDueBidArrivals(
        now: other.createdAt.add(const Duration(minutes: 1)),
      );
      final withBid = await container.read(
        shipmentDetailsProvider(first.id).future,
      );
      expect(withBid!.bidsFor(first.id), hasLength(1));
      await controller.acceptBid(
        shipmentId: first.id,
        bidId: withBid.bidsFor(first.id).single.bid.id,
      );
      final updated = await container.read(
        shipmentDetailsProvider(first.id).future,
      );
      expect(updated!.shipmentById(first.id)!.status, ShipmentStatus.scheduled);
      expect(updated.shipments, hasLength(1));
      expect(updated.shipmentById(other.id), isNull);
    },
  );
}
