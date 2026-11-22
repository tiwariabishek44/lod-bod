import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';

import 'mock_shipment_repository_test.dart' show samplePost;

void main() {
  test('mobile count includes only active mobile shipments', () {
    final now = DateTime.now();
    Shipment shipment(ShipmentStatus status, ShipmentCreationChannel channel) =>
        Shipment(
          id: '${status.name}-${channel.name}',
          reference: 'LOD-1',
          shipperCompanyId: 'company',
          origin: const ShipmentLocation(city: 'Kathmandu'),
          destination: const ShipmentLocation(city: 'Pokhara'),
          cargo: const CargoDetails(
            description: 'Cement',
            weight: 1,
            weightUnit: 'T',
          ),
          requiredVehicleType: 'Open',
          pickupAt: now,
          status: status,
          creationChannel: channel,
          createdAt: now,
          updatedAt: now,
        );
    final snapshot = ShipmentWorkflowSnapshot(
      shipments: [
        for (final status in ShipmentStatus.values)
          shipment(status, ShipmentCreationChannel.mobile),
        shipment(ShipmentStatus.awaitingBids, ShipmentCreationChannel.web),
      ],
      bidsByShipmentId: const {},
      carriersById: const {},
      eventsByShipmentId: const {},
      pendingBidArrivals: const [],
    );
    expect(snapshot.mobileRequestsUsed, 3);
  });

  test(
    'shipment validation rejects missing or identical routes and invalid weight or dates',
    () {
      final valid = samplePost();
      expect(validateLoadPost(valid), isNull);
      LoadPost changed(Map<String, Object?> overrides) =>
          LoadPost.fromJson({...valid.toJson(), ...overrides});
      expect(
        validateLoadPost(changed({'routeOrigin': null})),
        'Choose pickup and delivery locations.',
      );
      expect(
        validateLoadPost(
          changed({'routeDestination': valid.routeOrigin!.toJson()}),
        ),
        'Pickup and delivery must be different.',
      );
      expect(
        validateLoadPost(
          changed({'pickupDate': DateTime(2000).toIso8601String()}),
        ),
        'Choose a pickup time that has not passed.',
      );
      final cargo = {...valid.cargo!.toJson(), 'weight': 0};
      expect(
        validateLoadPost(changed({'cargo': cargo})),
        'Enter a positive cargo weight and unit.',
      );
      expect(
        validateLoadPost(
          changed({
            'cargo': {...cargo, 'weight': 19},
          }),
        ),
        'Cargo weight must match the total load of the trucks.',
      );
    },
  );
}
