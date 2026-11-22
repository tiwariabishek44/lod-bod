import 'load_post.dart';

enum ShipmentStatus {
  awaitingBids,
  scheduled,
  inTransit,
  delivered,
  cancelled,
  expired,
}

enum ShipmentCreationChannel { mobile, web }

extension ShipmentStatusPresentation on ShipmentStatus {
  String get label => switch (this) {
    ShipmentStatus.awaitingBids => 'Awaiting Bids',
    ShipmentStatus.scheduled => 'Scheduled',
    ShipmentStatus.inTransit => 'In Transit',
    ShipmentStatus.delivered => 'Delivered',
    ShipmentStatus.cancelled => 'Cancelled',
    ShipmentStatus.expired => 'Expired',
  };

  bool get countsTowardMobileLimit => switch (this) {
    ShipmentStatus.awaitingBids ||
    ShipmentStatus.scheduled ||
    ShipmentStatus.inTransit => true,
    ShipmentStatus.delivered ||
    ShipmentStatus.cancelled ||
    ShipmentStatus.expired => false,
  };
}

class ShipmentLocation {
  const ShipmentLocation({
    required this.city,
    this.region,
    this.country = 'Nepal',
  });

  final String city;
  final String? region;
  final String country;

  String get displayName => region == null ? city : '$city, $region';
}

class CargoDetails {
  const CargoDetails({
    required this.description,
    required this.weight,
    required this.weightUnit,
    this.category,
    this.quantity,
  });

  final String description;
  final String? category;
  final double weight;
  final String weightUnit;
  final int? quantity;

  String get displaySummary => weight > 0
      ? '$description · ${_weightLabel(weight)} $weightUnit'
      : description;

  static String _weightLabel(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class Shipment {
  const Shipment({
    required this.id,
    required this.reference,
    required this.shipperCompanyId,
    required this.origin,
    required this.destination,
    required this.cargo,
    required this.requiredVehicleType,
    required this.pickupAt,
    required this.status,
    this.creationChannel = ShipmentCreationChannel.mobile,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId,
    this.loadPostId,
    this.truckPlanId,
    this.pickupWindow,
    this.expectedFareNpr,
    this.contactDetails,
    this.notes,
    this.acceptedBidId,
    this.assignedCarrierId,
    this.loadPostSnapshot,
  });

  final String id;
  final String reference;
  final String shipperCompanyId;
  final String? createdByUserId;
  final String? loadPostId;
  final String? truckPlanId;
  final ShipmentLocation origin;
  final ShipmentLocation destination;
  final CargoDetails cargo;
  final String requiredVehicleType;
  final DateTime pickupAt;
  final String? pickupWindow;
  final double? expectedFareNpr;
  final String? contactDetails;
  final String? notes;
  final ShipmentStatus status;
  final ShipmentCreationChannel creationChannel;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acceptedBidId;
  final String? assignedCarrierId;
  final LoadPost? loadPostSnapshot;

  Shipment copyWith({
    ShipmentStatus? status,
    DateTime? updatedAt,
    double? expectedFareNpr,
    String? acceptedBidId,
    String? assignedCarrierId,
  }) => Shipment(
    id: id,
    reference: reference,
    shipperCompanyId: shipperCompanyId,
    createdByUserId: createdByUserId,
    loadPostId: loadPostId,
    truckPlanId: truckPlanId,
    origin: origin,
    destination: destination,
    cargo: cargo,
    requiredVehicleType: requiredVehicleType,
    pickupAt: pickupAt,
    pickupWindow: pickupWindow,
    expectedFareNpr: expectedFareNpr ?? this.expectedFareNpr,
    contactDetails: contactDetails,
    notes: notes,
    status: status ?? this.status,
    creationChannel: creationChannel,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    acceptedBidId: acceptedBidId ?? this.acceptedBidId,
    assignedCarrierId: assignedCarrierId ?? this.assignedCarrierId,
    loadPostSnapshot: loadPostSnapshot,
  );
}
