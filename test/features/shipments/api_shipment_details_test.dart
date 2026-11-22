import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/core/network/api_client.dart';
import 'package:lod_board/core/network/api_exception.dart';
import 'package:lod_board/features/shipments/data/repositories/api_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'mock_shipment_repository_test.dart' as fixtures;

class _Client extends ApiClient {
  _Client(this.payload) : super(Dio());
  final Object? payload;
  String? path;
  bool? authenticated;
  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requiresAuth = true,
  }) async {
    this.path = path;
    authenticated = requiresAuth;
    if (payload is ApiException) throw payload as ApiException;
    return payload as T;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'provisional detail endpoint encodes shipment ID and decodes its record',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await MockShipmentRepository(
        prefs,
        'user',
      ).submitLoadPost(fixtures.samplePost());
      final state =
          jsonDecode(prefs.getString('loadboard.shipments.v2.user')!) as Map;
      final record = Map<String, dynamic>.from(
        (state['submitted'] as List).single as Map,
      );
      record['id'] = 'id / ?';
      final client = _Client({
        'data': {'shipment': record},
      });
      final result = await ApiShipmentRepository(
        client,
      ).fetchShipmentDetails('id / ?');
      expect(client.path, '/shipments/id%20%2F%20%3F');
      expect(client.authenticated, isTrue);
      expect(result!.shipmentById('id / ?')!.cargo.description, 'Cement');
    },
  );
  test('404 is not found while other errors propagate', () async {
    final missing = ApiShipmentRepository(
      _Client(const ApiException(message: 'missing', statusCode: 404)),
    );
    expect(await missing.fetchShipmentDetails('missing'), isNull);
    final failure = ApiShipmentRepository(
      _Client(const ApiException(message: 'offline', code: 'network')),
    );
    await expectLater(
      failure.fetchShipmentDetails('id'),
      throwsA(isA<ApiException>()),
    );
  });
}
