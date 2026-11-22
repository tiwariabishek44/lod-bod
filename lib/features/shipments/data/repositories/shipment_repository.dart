import '../../../bids/domain/models/bid.dart';
import '../../domain/models/bid_arrival_event.dart';
import '../../domain/models/load_post.dart';
import '../../domain/models/pending_bid_arrival.dart';
import '../../domain/models/shipment.dart';
import '../../domain/models/shipment_event.dart';

class ShipmentWorkflowSnapshot {
  ShipmentWorkflowSnapshot({
    required List<Shipment> shipments,
    List<LoadPost> loadPosts = const [],
    required Map<String, List<Bid>> bidsByShipmentId,
    required Map<String, Carrier> carriersById,
    required Map<String, List<ShipmentEvent>> eventsByShipmentId,
    required List<PendingBidArrival> pendingBidArrivals,
  }) : shipments = List.unmodifiable(shipments),
       loadPosts = List.unmodifiable(loadPosts),
       bidsByShipmentId = Map.unmodifiable({
         for (final entry in bidsByShipmentId.entries)
           entry.key: List<Bid>.unmodifiable(entry.value),
       }),
       carriersById = Map.unmodifiable(carriersById),
       pendingBidArrivals = List.unmodifiable(pendingBidArrivals),
       eventsByShipmentId = Map.unmodifiable({
         for (final entry in eventsByShipmentId.entries)
           entry.key: List<ShipmentEvent>.unmodifiable(entry.value),
       });

  final List<Shipment> shipments;
  final List<LoadPost> loadPosts;
  final Map<String, List<Bid>> bidsByShipmentId;
  final Map<String, Carrier> carriersById;
  final List<PendingBidArrival> pendingBidArrivals;
  final Map<String, List<ShipmentEvent>> eventsByShipmentId;

  int get mobileRequestsUsed => shipments
      .where(
        (shipment) =>
            shipment.creationChannel == ShipmentCreationChannel.mobile &&
            shipment.status.countsTowardMobileLimit,
      )
      .length;

  List<BidWithCarrier> bidsFor(String shipmentId) => [
    for (final bid in bidsByShipmentId[shipmentId] ?? const <Bid>[])
      if (carriersById[bid.carrierId] case final carrier?)
        BidWithCarrier(bid: bid, carrier: carrier),
  ];

  List<ShipmentEvent> eventsFor(String shipmentId) =>
      eventsByShipmentId[shipmentId] ?? const <ShipmentEvent>[];

  Shipment? shipmentById(String id) {
    for (final shipment in shipments) {
      if (shipment.id == id || shipment.reference == id) return shipment;
    }
    return null;
  }

  List<Shipment> get awaitingBidShipments =>
      shipments
          .where((shipment) => shipment.status == ShipmentStatus.awaitingBids)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Shipment> get recentShipments =>
      shipments.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

abstract interface class ShipmentRepository {
  Future<ShipmentWorkflowSnapshot> fetchSnapshot();

  /// Loads one shipment with the data required by its detail screen.
  Future<ShipmentWorkflowSnapshot?> fetchShipmentDetails(String shipmentId);

  Future<LoadPost?> latestLoadPostDraft();

  Future<LoadPost> saveLoadPostDraft(LoadPost draft);

  Future<LoadPostSubmission> submitLoadPost(LoadPost draft);

  Future<void> acceptBid({required String shipmentId, required String bidId});

  Future<List<BidArrivalEvent>> processDueBidArrivals({DateTime? now});
}

class LoadPostSubmission {
  LoadPostSubmission({
    required this.loadPost,
    required List<Shipment> shipments,
    this.snapshotRefreshed = true,
  }) : shipments = List.unmodifiable(shipments);

  final LoadPost loadPost;
  final List<Shipment> shipments;
  final bool snapshotRefreshed;

  LoadPostSubmission withSnapshotRefreshed(bool value) => LoadPostSubmission(
    loadPost: loadPost,
    shipments: shipments,
    snapshotRefreshed: value,
  );
}

class ShipmentRequestLimitException implements Exception {
  const ShipmentRequestLimitException({
    required this.used,
    required this.limit,
  });

  final int used;
  final int limit;

  @override
  String toString() =>
      'You have reached the mobile request limit of $limit. Please use the LODBOD web platform to create additional requests.';
}

class ShipmentOperationException implements Exception {
  const ShipmentOperationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Validates the form consistently before mock or API submission.
String? validateLoadPost(LoadPost post) {
  final origin = post.routeOrigin?.name.trim() ?? '';
  final destination = post.routeDestination?.name.trim() ?? '';
  if (origin.isEmpty || destination.isEmpty) {
    return 'Choose pickup and delivery locations.';
  }
  if (origin.toLowerCase() == destination.toLowerCase()) {
    return 'Pickup and delivery must be different.';
  }
  if (post.pickupDate == null ||
      post.pickupWindow == null ||
      post.deliveryDate == null ||
      post.deliveryWindow == null) {
    return 'Choose pickup and delivery dates and time windows.';
  }
  final pickup = post.pickupDate!;
  final delivery = post.deliveryDate!;
  if (!post.pickupWindow!.atEndOf(pickup).isAfter(DateTime.now())) {
    return 'Choose a pickup time that has not passed.';
  }
  if (DateTime(
    delivery.year,
    delivery.month,
    delivery.day,
  ).isBefore(DateTime(pickup.year, pickup.month, pickup.day))) {
    return 'Delivery cannot be before pickup.';
  }
  if (!post.deliveryWindow!.atEndOf(delivery).isAfter(DateTime.now())) {
    return 'Choose a delivery time that has not passed.';
  }
  if (post.cargo == null ||
      post.cargo!.material.trim().isEmpty ||
      (post.cargo!.material == 'Other' &&
          (post.cargo!.description?.trim().isEmpty ?? true))) {
    return 'Choose or describe the cargo material.';
  }
  if (post.cargo!.natureAttributes.isEmpty) {
    return 'Choose at least one cargo characteristic.';
  }
  if (post.pickupContact == null ||
      post.deliveryContact == null ||
      post.pickupContact!.name.trim().isEmpty ||
      post.pickupContact!.phone.trim().isEmpty ||
      post.deliveryContact!.name.trim().isEmpty ||
      post.deliveryContact!.phone.trim().isEmpty) {
    return 'Choose pickup and delivery contacts.';
  }
  if (post.totalConsignmentValueNpr == null ||
      post.totalConsignmentValueNpr! < 0) {
    return 'Enter the total consignment value.';
  }
  if (post.trucks.isEmpty ||
      post.trucks.any(
        (truck) =>
            !truck.capacityTons.isFinite ||
            truck.capacityTons <= 0 ||
            truck.loadWeightTons == null ||
            !truck.loadWeightTons!.isFinite ||
            truck.loadWeightTons! <= 0 ||
            truck.stops.any(
              (stop) =>
                  stop.location.trim().isEmpty ||
                  stop.quantity <= 0 ||
                  stop.quantity > truck.capacityTons,
            ) ||
            calculateTruckLoad(
                  truck.capacityTons,
                  truck.loadWeightTons,
                  truck.stops,
                ) ==
                null,
      )) {
    return 'Check the truck requirements and stops.';
  }
  final cargoWeight = post.cargo!.weight;
  final unit = post.cargo!.weightUnit;
  if (cargoWeight == null ||
      !cargoWeight.isFinite ||
      cargoWeight <= 0 ||
      (unit != 'T' && unit != 'kg')) {
    return 'Enter a positive cargo weight and unit.';
  }
  final weightInTons = unit == 'kg' ? cargoWeight / 1000 : cargoWeight;
  final allocated = post.trucks.fold<double>(
    0,
    (sum, truck) => sum + truck.loadWeightTons!,
  );
  if ((weightInTons - allocated).abs() > 0.000001) {
    return 'Cargo weight must match the total load of the trucks.';
  }
  return null;
}
