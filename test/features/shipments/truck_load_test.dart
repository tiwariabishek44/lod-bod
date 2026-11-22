import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';

LoadStop stop(bool pickup, double quantity) => LoadStop(
  isPickup: pickup,
  location: 'Stop',
  quantity: quantity,
  contact: '',
);

void main() {
  test('journey total determines initial pickup and final delivery', () {
    final summary = calculateTruckLoad(18, 15, [stop(false, 6), stop(true, 3)]);
    expect(summary!.initialPickup, 12);
    expect(summary.finalDelivery, 9);
    expect(finalTruckLoad(18, [stop(false, 6)], startingLoad: 18), 12);
    expect(finalTruckLoad(18, [], startingLoad: 18), 18);
  });

  test(
    'rejects invalid totals and pickups or drops exceeding journey load',
    () {
      expect(finalTruckLoad(18, [], startingLoad: 19), isNull);
      expect(
        finalTruckLoad(18, [stop(false, 10), stop(false, 9)], startingLoad: 18),
        isNull,
      );
      expect(finalTruckLoad(18, [stop(true, 7)], startingLoad: 6), isNull);
      expect(finalTruckLoad(18, []), isNull);
    },
  );
}
