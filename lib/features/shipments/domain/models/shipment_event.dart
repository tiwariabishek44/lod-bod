enum ShipmentEventType {
  loadPosted,
  bidReceived,
  carrierSelected,
  pickedUp,
  delivered,
  cancelled,
}

class ShipmentEvent {
  const ShipmentEvent({
    required this.id,
    required this.shipmentId,
    required this.type,
    required this.occurredAt,
    this.actorId,
    this.actorType,
    this.summary,
  });

  final String id;
  final String shipmentId;
  final ShipmentEventType type;
  final DateTime occurredAt;
  final String? actorId;
  final String? actorType;
  final String? summary;
}
