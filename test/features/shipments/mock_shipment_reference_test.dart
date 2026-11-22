import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_shipment_repository_test.dart' show samplePost;

LoadPost validPost(String id) {
  final json = samplePost(id: id).toJson();
  json['cargo'] = {
    ...json['cargo'] as Map<String, dynamic>,
    'weight': 20,
    'weightUnit': 'T',
  };
  json['trucks'] = [
    for (final truck in json['trucks'] as List)
      {...truck as Map<String, dynamic>, 'loadWeightTons': 10},
  ];
  return LoadPost.fromJson(json);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migrates saved references and allocates unique references on concurrent submissions',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = MockShipmentRepository(prefs, 'reference-test');
      final first = (await repo.submitLoadPost(
        validPost('one'),
      )).shipments.single;
      expect(first.reference, 'LOD-1001');

      const key = 'loadboard.shipments.v2.reference-test';
      final state = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      (state['submitted'] as List).single['reference'] = 'LOD-1795158974848000';
      await prefs.setString(key, jsonEncode(state));

      final migrated = (await repo.fetchSnapshot()).shipments.single;
      expect(migrated.reference, 'LOD-1001');
      expect(migrated.id, first.id);
      expect(
        jsonDecode(prefs.getString(key)!)['submitted'][0]['reference'],
        'LOD-1001',
      );

      final results = await Future.wait([
        repo.submitLoadPost(validPost('two')),
        MockShipmentRepository(
          prefs,
          'reference-test',
        ).submitLoadPost(validPost('three')),
      ]);
      expect(
        results.map((result) => result.shipments.single.reference).toSet(),
        {'LOD-1002', 'LOD-1003'},
      );
      expect(
        (await repo.fetchShipmentDetails(first.id))!.shipments.single.reference,
        'LOD-1001',
      );
    },
  );
}
