import '../../domain/models/load_post.dart';
import '../../domain/models/shipment.dart';

Map<String, dynamic> apiLoadPostRecord(Map<String, dynamic> record) => {
  ...record,
  'trucks': [
    for (final raw in (record['trucks'] as List? ?? const []))
      {
        ...Map<String, dynamic>.from(raw as Map),
        'loadWeightMeaning': 'journeyTotal',
      },
  ],
};

Shipment shipmentFromRecord(
  Map<String, dynamic> item, {
  bool apiJourneyTotal = false,
}) {
  final rawPost = Map<String, dynamic>.from(item['post'] as Map);
  final post = LoadPost.fromJson(
    apiJourneyTotal ? apiLoadPostRecord(rawPost) : rawPost,
  );
  final cargo = post.cargo!;
  return Shipment(
    id: item['id'] as String,
    reference: item['reference'] as String,
    shipperCompanyId: post.shipperCompanyId,
    createdByUserId: post.createdByUserId,
    loadPostId: post.id,
    origin: ShipmentLocation(city: post.routeOrigin!.name),
    destination: ShipmentLocation(city: post.routeDestination!.name),
    cargo: CargoDetails(
      description: cargo.material == 'Other'
          ? (cargo.description ?? 'Other')
          : cargo.material,
      category: cargo.material,
      weight: cargo.weight ?? 0,
      weightUnit: cargo.weightUnit ?? 'T',
    ),
    requiredVehicleType:
        '${post.trucks.first.vehicleType.label} · ${post.trucks.first.wheelClass.label} · ${post.trucks.length} ${post.trucks.length == 1 ? 'truck' : 'trucks'}',
    pickupAt: post.pickupWindow!.atStartOf(post.pickupDate!),
    pickupWindow: post.pickupWindow!.label,
    status: ShipmentStatus.values.byName(item['status'] as String),
    creationChannel: item['creationChannel'] == null
        ? ShipmentCreationChannel.mobile
        : ShipmentCreationChannel.values.byName(
            item['creationChannel'] as String,
          ),
    createdAt: DateTime.parse(item['createdAt'] as String),
    updatedAt: DateTime.parse(item['updatedAt'] as String),
    contactDetails: post.pickupContact?.displayLabel,
    assignedCarrierId: item['assignedCarrierId'] as String?,
    acceptedBidId: item['acceptedBidId'] as String?,
    expectedFareNpr: (item['acceptedFareNpr'] as num?)?.toDouble(),
    loadPostSnapshot: post,
  );
}
