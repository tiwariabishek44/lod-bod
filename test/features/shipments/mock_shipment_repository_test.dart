import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/bids/domain/models/bid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';

LoadPost samplePost({String id = 'post-1'}) {
  final now = DateTime.now();
  final pickup = DateTime(
    now.year,
    now.month,
    now.day,
  ).add(const Duration(days: 1));
  return LoadPost(
    id: id,
    shipperCompanyId: 'company',
    createdByUserId: 'user',
    loadType: LoadType.normal,
    status: LoadPostStatus.draft,
    routeOrigin: const LoadLocation(name: 'Kathmandu'),
    routeDestination: const LoadLocation(name: 'Chitwan'),
    pickupDate: pickup,
    pickupWindow: LoadTimeWindow.morning,
    deliveryDate: pickup.add(const Duration(days: 1)),
    deliveryWindow: LoadTimeWindow.afternoon,
    cargo: LoadCargoDetails(
      material: 'Cement',
      natureAttributes: ['Stackable'],
      weight: 20,
      weightUnit: 'T',
    ),
    pickupContact: const LoadContactRef(name: 'Ram', phone: '9841000001'),
    deliveryContact: const LoadContactRef(name: 'Sita', phone: '9841000002'),
    totalConsignmentValueNpr: 100000,
    trucks: [
      for (var i = 0; i < 2; i++)
        TruckPlan(
          id: 'truck-$i',
          truckNumber: i + 1,
          vehicleType: TruckVehicleType.open,
          wheelClass: TruckWheelClass.twelveW,
          capacityMatch: CapacityMatch.exact,
          capacityTons: 18,
          loadWeightTons: 10,
          billingType: TruckBillingType.nonVat,
          consignmentValueNpr: 0,
          stops: i == 0
              ? [
                  const LoadStop(
                    isPickup: false,
                    location: 'Hetauda',
                    quantity: 2,
                    contact: 'Hari',
                  ),
                ]
              : [],
        ),
    ],
    currentStep: 3,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'draft survives repository recreation without creating a shipment',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await MockShipmentRepository(
        prefs,
        'user',
      ).saveLoadPostDraft(samplePost());
      final repo = MockShipmentRepository(prefs, 'user');
      expect(
        (await repo.latestLoadPostDraft())!.trucks.first.stops.single.location,
        'Hetauda',
      );
      expect((await repo.fetchSnapshot()).shipments, isEmpty);
      expect(
        await MockShipmentRepository(prefs, 'other').latestLoadPostDraft(),
        isNull,
      );
    },
  );

  test(
    'two trucks create one awaiting-bids shipment and retries are idempotent',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = MockShipmentRepository(prefs, 'user');
      final post = samplePost();
      await repo.saveLoadPostDraft(post);
      final first = await repo.submitLoadPost(post);
      final retry = await repo.submitLoadPost(post);
      final snapshot = await MockShipmentRepository(
        prefs,
        'user',
      ).fetchSnapshot();
      expect(first.shipments.single.id, retry.shipments.single.id);
      expect(snapshot.shipments, hasLength(1));
      expect(snapshot.shipments.single.status, ShipmentStatus.awaitingBids);
      expect(snapshot.shipments.single.loadPostSnapshot!.trucks, hasLength(2));
      expect(
        snapshot
            .shipments
            .single
            .loadPostSnapshot!
            .trucks
            .first
            .stops
            .single
            .location,
        'Hetauda',
      );
      expect(await repo.latestLoadPostDraft(), isNull);
    },
  );

  test('invalid submission leaves draft and shipment list intact', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = MockShipmentRepository(prefs, 'user');
    final now = DateTime.now();
    final draft = LoadPost(
      id: 'empty',
      shipperCompanyId: 'company',
      loadType: LoadType.normal,
      status: LoadPostStatus.draft,
      trucks: const [],
      currentStep: 0,
      createdAt: now,
      updatedAt: now,
    );
    await repo.saveLoadPostDraft(draft);
    await expectLater(
      repo.submitLoadPost(draft),
      throwsA(isA<ShipmentOperationException>()),
    );
    expect((await repo.latestLoadPostDraft())!.id, 'empty');
    expect((await repo.fetchSnapshot()).shipments, isEmpty);
  });

  test(
    'mobile limit counts whole shipments and preserves the next draft',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = MockShipmentRepository(prefs, 'user');
      for (var i = 0; i < 3; i++) {
        await repo.submitLoadPost(samplePost(id: 'post-$i'));
      }
      final fourth = samplePost(id: 'post-4');
      await repo.saveLoadPostDraft(fourth);
      await expectLater(
        repo.submitLoadPost(fourth),
        throwsA(isA<ShipmentRequestLimitException>()),
      );
      expect((await repo.fetchSnapshot()).shipments, hasLength(3));
      expect((await repo.latestLoadPostDraft())!.id, 'post-4');
    },
  );
  test(
    'bids arrive on schedule per shipment and survive repository recreation',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = MockShipmentRepository(prefs, 'user');
      final first = (await repo.submitLoadPost(
        samplePost(id: 'one'),
      )).shipments.single;
      final second = (await repo.submitLoadPost(
        samplePost(id: 'two'),
      )).shipments.single;
      expect(
        await repo.processDueBidArrivals(
          now: first.createdAt.add(const Duration(seconds: 59)),
        ),
        isEmpty,
      );
      final initial = await repo.processDueBidArrivals(
        now: second.createdAt.add(const Duration(minutes: 1)),
      );
      expect(initial, hasLength(2));
      expect(initial.map((e) => e.shipment.id).toSet(), {first.id, second.id});
      expect(initial.every((e) => e.bid.shipmentId == e.shipment.id), isTrue);
      final later = await MockShipmentRepository(prefs, 'user')
          .processDueBidArrivals(
            now: second.createdAt.add(const Duration(seconds: 120)),
          );
      expect(later, hasLength(4));
      expect(
        await repo.processDueBidArrivals(
          now: second.createdAt.add(const Duration(minutes: 5)),
        ),
        isEmpty,
      );
      final snapshot = await MockShipmentRepository(
        prefs,
        'user',
      ).fetchSnapshot();
      expect(snapshot.bidsFor(first.id), hasLength(3));
      expect(snapshot.bidsFor(second.id), hasLength(3));
      expect(snapshot.pendingBidArrivals, isEmpty);
      expect(
        (await MockShipmentRepository(
          prefs,
          'other',
        ).fetchSnapshot()).shipments,
        isEmpty,
      );
    },
  );

  test('acceptance is shipment scoped and stops later arrivals', () async {
    final prefs = await SharedPreferences.getInstance();
    final repo = MockShipmentRepository(prefs, 'user');
    final first = (await repo.submitLoadPost(
      samplePost(id: 'one'),
    )).shipments.single;
    final second = (await repo.submitLoadPost(
      samplePost(id: 'two'),
    )).shipments.single;
    await repo.processDueBidArrivals(
      now: second.createdAt.add(const Duration(seconds: 90)),
    );
    final before = await repo.fetchSnapshot();
    final selected = before.bidsFor(first.id).first.bid;
    final otherBid = before.bidsFor(second.id).first.bid;
    await expectLater(
      repo.acceptBid(shipmentId: first.id, bidId: otherBid.id),
      throwsA(isA<ShipmentOperationException>()),
    );
    await repo.acceptBid(shipmentId: first.id, bidId: selected.id);
    final after = await MockShipmentRepository(prefs, 'user').fetchSnapshot();
    expect(after.shipmentById(first.id)!.status, ShipmentStatus.scheduled);
    expect(after.shipmentById(first.id)!.assignedCarrierId, selected.carrierId);
    expect(after.shipmentById(first.id)!.expectedFareNpr, selected.fareNpr);
    expect(after.bidsFor(first.id).map((o) => o.bid.status), [
      BidStatus.accepted,
      BidStatus.declined,
    ]);
    expect(after.shipmentById(second.id)!.status, ShipmentStatus.awaitingBids);
    await expectLater(
      repo.acceptBid(shipmentId: first.id, bidId: selected.id),
      throwsA(isA<ShipmentOperationException>()),
    );
    await repo.processDueBidArrivals(
      now: second.createdAt.add(const Duration(minutes: 4)),
    );
    final finalSnapshot = await repo.fetchSnapshot();
    expect(finalSnapshot.bidsFor(first.id), hasLength(2));
    expect(finalSnapshot.bidsFor(second.id), hasLength(3));
  });

  test('concurrent arrival processing does not duplicate bids', () async {
    final prefs = await SharedPreferences.getInstance();
    final a = MockShipmentRepository(prefs, 'user');
    final b = MockShipmentRepository(prefs, 'user');
    final shipment = (await a.submitLoadPost(samplePost())).shipments.single;
    final results = await Future.wait([
      a.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 3)),
      ),
      b.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 3)),
      ),
    ]);
    expect(results.map((e) => e.length).reduce((a, b) => a + b), 3);
    expect((await a.fetchSnapshot()).bidsFor(shipment.id), hasLength(3));
  });
}
