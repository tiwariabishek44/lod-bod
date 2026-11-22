import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/shipment_repository.dart';
import 'package:lod_board/features/shipments/domain/models/load_post.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'package:lod_board/features/shipments/providers/shipment_providers.dart';
import 'mock_shipment_repository_test.dart' as fixtures;

class _Repository implements ShipmentRepository {
  _Repository(this.delegate);
  final MockShipmentRepository delegate;
  bool failRefresh = false;
  bool failSubmit = false;
  int submitCount = 0;
  @override
  Future<ShipmentWorkflowSnapshot> fetchSnapshot() async {
    if (failRefresh) throw StateError('refresh failed');
    return delegate.fetchSnapshot();
  }

  @override
  Future<LoadPostSubmission> submitLoadPost(LoadPost post) async {
    submitCount++;
    if (failSubmit) throw const ShipmentOperationException('submission failed');
    return delegate.submitLoadPost(post);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('successful post with failed refresh is not submitted again', () async {
    final mock = MockShipmentRepository(
      await SharedPreferences.getInstance(),
      'user',
    );
    final repository = _Repository(mock);
    final container = ProviderContainer(
      overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(shipmentWorkflowProvider.future);
    repository.failRefresh = true;
    final controller = container.read(shipmentWorkflowProvider.notifier);
    final result = await controller.submit(fixtures.samplePost());
    expect(result.snapshotRefreshed, isFalse);
    expect(result.shipments.single.status, ShipmentStatus.awaitingBids);
    expect(container.read(shipmentWorkflowProvider).hasError, isTrue);
    repository.failRefresh = false;
    await controller.refresh();
    expect(
      container
          .read(shipmentWorkflowProvider)
          .requireValue
          .shipmentById(result.shipments.single.id),
      isNotNull,
    );
    expect(repository.submitCount, 1);
  });
  test('failed post leaves shipment list unchanged', () async {
    final mock = MockShipmentRepository(
      await SharedPreferences.getInstance(),
      'user',
    );
    final repository = _Repository(mock)..failSubmit = true;
    final container = ProviderContainer(
      overrides: [shipmentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(shipmentWorkflowProvider.future);
    await expectLater(
      container
          .read(shipmentWorkflowProvider.notifier)
          .submit(fixtures.samplePost()),
      throwsA(isA<ShipmentOperationException>()),
    );
    expect((await mock.fetchSnapshot()).shipments, isEmpty);
  });
}
