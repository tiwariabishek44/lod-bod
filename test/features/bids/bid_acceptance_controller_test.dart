import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/bids/domain/models/bid.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'package:lod_board/features/shipments/providers/shipment_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../shipments/mock_shipment_repository_test.dart' as fixtures;

class _Repository implements ShipmentRepository {
  _Repository(this.delegate);
  final MockShipmentRepository delegate;
  bool failAccept = false;
  bool failRefresh = false;
  int acceptCount = 0;
  @override
  Future<ShipmentWorkflowSnapshot> fetchSnapshot() async {
    if (failRefresh) throw StateError('Refresh failed');
    return delegate.fetchSnapshot();
  }

  @override
  Future<void> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    acceptCount++;
    if (failAccept) throw const ShipmentOperationException('Acceptance failed');
    await delegate.acceptBid(shipmentId: shipmentId, bidId: bidId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('successful acceptance refreshes shared shipment data', () async {
    final mock = MockShipmentRepository(
      await SharedPreferences.getInstance(),
      'user',
    );
    final shipment = (await mock.submitLoadPost(
      fixtures.samplePost(),
    )).shipments.single;
    await mock.processDueBidArrivals(
      now: shipment.createdAt.add(const Duration(seconds: 90)),
    );
    final repository = _Repository(mock);
    final container = ProviderContainer(
      overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final before = await container.read(shipmentWorkflowProvider.future);
    final offer = before.bidsFor(shipment.id).first;
    expect(
      await container
          .read(shipmentWorkflowProvider.notifier)
          .acceptBid(shipmentId: shipment.id, bidId: offer.bid.id),
      isTrue,
    );
    final after = container.read(shipmentWorkflowProvider).requireValue;
    expect(after.shipmentById(shipment.id)!.status, ShipmentStatus.scheduled);
    expect(
      after.shipmentById(shipment.id)!.assignedCarrierId,
      offer.carrier.id,
    );
    expect(
      after
          .bidsFor(shipment.id)
          .where((item) => item.bid.status == BidStatus.pending),
      isEmpty,
    );
    expect(after.awaitingBidShipments, isEmpty);
    expect(after.recentShipments.single.status, ShipmentStatus.scheduled);
  });
  test(
    'accept failure preserves state; refresh failure preserves successful acceptance and allows retry',
    () async {
      final mock = MockShipmentRepository(
        await SharedPreferences.getInstance(),
        'user',
      );
      final shipment = (await mock.submitLoadPost(
        fixtures.samplePost(),
      )).shipments.single;
      await mock.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 1)),
      );
      final repository = _Repository(mock);
      final container = ProviderContainer(
        overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final before = await container.read(shipmentWorkflowProvider.future);
      final bid = before.bidsFor(shipment.id).single.bid;
      final controller = container.read(shipmentWorkflowProvider.notifier);
      repository.failAccept = true;
      await expectLater(
        controller.acceptBid(shipmentId: shipment.id, bidId: bid.id),
        throwsA(isA<ShipmentOperationException>()),
      );
      expect(
        container
            .read(shipmentWorkflowProvider)
            .requireValue
            .shipmentById(shipment.id)!
            .status,
        ShipmentStatus.awaitingBids,
      );
      repository.failAccept = false;
      repository.failRefresh = true;
      expect(
        await controller.acceptBid(shipmentId: shipment.id, bidId: bid.id),
        isFalse,
      );
      expect(container.read(shipmentWorkflowProvider).hasError, isTrue);
      expect(
        (await mock.fetchSnapshot()).shipmentById(shipment.id)!.status,
        ShipmentStatus.scheduled,
      );
      repository.failRefresh = false;
      await controller.refresh();
      expect(
        container
            .read(shipmentWorkflowProvider)
            .requireValue
            .shipmentById(shipment.id)!
            .status,
        ShipmentStatus.scheduled,
      );
      expect(repository.acceptCount, 2);
    },
  );
}
