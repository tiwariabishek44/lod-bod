enum BidStatus { pending, accepted, declined, withdrawn, expired }

class Bid {
  const Bid({
    required this.id,
    required this.shipmentId,
    required this.carrierId,
    required this.fareNpr,
    required this.estimatedDeliveryAt,
    required this.status,
    required this.createdAt,
    this.proposedVehicle,
    this.carrierNote,
    this.respondedAt,
  });

  final String id;
  final String shipmentId;
  final String carrierId;
  final double fareNpr;
  final DateTime estimatedDeliveryAt;
  final BidStatus status;
  final DateTime createdAt;
  final String? proposedVehicle;
  final String? carrierNote;
  final DateTime? respondedAt;

  Bid copyWith({BidStatus? status, DateTime? respondedAt}) => Bid(
    id: id,
    shipmentId: shipmentId,
    carrierId: carrierId,
    fareNpr: fareNpr,
    estimatedDeliveryAt: estimatedDeliveryAt,
    status: status ?? this.status,
    createdAt: createdAt,
    proposedVehicle: proposedVehicle,
    carrierNote: carrierNote,
    respondedAt: respondedAt ?? this.respondedAt,
  );
}

class Carrier {
  const Carrier({
    required this.id,
    required this.displayName,
    required this.rating,
    required this.reviewCount,
  });
  final String id;
  final String displayName;
  final double rating;
  final int reviewCount;
}

class BidWithCarrier {
  const BidWithCarrier({required this.bid, required this.carrier});
  final Bid bid;
  final Carrier carrier;
  String get initials {
    final words = carrier.displayName.trim().split(RegExp(r'\s+'));
    return words
        .where((word) => word.isNotEmpty)
        .take(2)
        .map((word) => word[0])
        .join()
        .toUpperCase();
  }
}
