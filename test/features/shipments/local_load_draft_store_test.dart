import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/features/shipments/data/repositories/local_load_draft_store.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';

LoadPost draft(String id) => LoadPost(
  id: id,
  shipperCompanyId: 'company',
  loadType: LoadType.normal,
  status: LoadPostStatus.draft,
  routeOrigin: const LoadLocation(name: 'Kathmandu'),
  trucks: [],
  currentStep: 1,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('stores one draft and removes only the matching submission', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalLoadDraftStore(
      await SharedPreferences.getInstance(),
      'u',
    );
    expect(await store.read(), isNull);
    await store.save(draft('first'));
    expect((await store.read())?.routeOrigin?.name, 'Kathmandu');
    await store.save(draft('second'));
    await store.removeIfMatching('first');
    expect((await store.read())?.id, 'second');
    await store.removeIfMatching('second');
    expect(await store.read(), isNull);
  });

  test('migrates an existing mock draft only once', () async {
    SharedPreferences.setMockInitialValues({
      'loadboard.shipments.v2.u': jsonEncode({
        'draft': draft('legacy').toJson(),
        'submitted': [],
      }),
    });
    final store = LocalLoadDraftStore(
      await SharedPreferences.getInstance(),
      'u',
    );
    expect((await store.read())?.id, 'legacy');
    await store.removeIfMatching('legacy');
    expect(await store.read(), isNull);
  });
}
