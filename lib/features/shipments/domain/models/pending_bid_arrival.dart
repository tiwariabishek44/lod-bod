class PendingBidArrival {
  const PendingBidArrival({
    required this.shipmentId,
    required this.dueAt,
    this.nextBidIndex = 0,
  });

  static const totalBids = 3;
  static const firstBidDelay = Duration(minutes: 1);
  static const intervalBetweenBids = Duration(seconds: 30);

  final String shipmentId;
  final DateTime dueAt;
  final int nextBidIndex;

  PendingBidArrival copyWith({DateTime? dueAt, int? nextBidIndex}) =>
      PendingBidArrival(
        shipmentId: shipmentId,
        dueAt: dueAt ?? this.dueAt,
        nextBidIndex: nextBidIndex ?? this.nextBidIndex,
      );
}
