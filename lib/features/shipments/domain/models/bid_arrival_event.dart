import '../../../bids/domain/models/bid.dart';
import 'shipment.dart';

class BidArrivalEvent {
  const BidArrivalEvent({
    required this.shipment,
    required this.bid,
    required this.arrivalNumber,
  });

  final Shipment shipment;
  final Bid bid;
  final int arrivalNumber;

  static const totalArrivals = 3;
}
