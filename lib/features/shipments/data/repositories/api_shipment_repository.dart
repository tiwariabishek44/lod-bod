import '../../../../core/config/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/models/bid_arrival_event.dart';
import '../../../bids/domain/models/bid.dart';
import '../../domain/models/shipment_event.dart';
import '../../domain/models/load_post.dart';
import 'shipment_mapping.dart';
import 'shipment_repository.dart';

/// Provisional HTTP contract: records contain a submitted `post` snapshot.
/// Adapt endpoint and payload mapping when the real backend is available.
class ApiShipmentRepository implements ShipmentRepository {
  ApiShipmentRepository(this.client);
  final ApiClient client;

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ApiException(
      message: 'The server returned an unexpected response.',
      code: 'invalid_response',
    );
  }

  dynamic _data(dynamic value) {
    final map = _map(value);
    return map['data'] ?? map;
  }

  /// The provisional contract returns shipments, bids, carriers and events as
  /// lists. Detail responses use the same shape with a single shipment.
  ShipmentWorkflowSnapshot _snapshot(Map<String, dynamic> body) {
    try {
      final records = body['shipments'];
      if (records is! List) throw const FormatException('Missing shipments');
      final shipments = [
        for (final record in records)
          shipmentFromRecord(_map(record), apiJourneyTotal: true),
      ];
      final bids = [
        for (final value in (body['bids'] as List? ?? const []))
          _bid(_map(value)),
      ];
      final carriers = [
        for (final value in (body['carriers'] as List? ?? const []))
          _carrier(_map(value)),
      ];
      final events = [
        for (final value in (body['events'] as List? ?? const []))
          _event(_map(value)),
      ];
      return ShipmentWorkflowSnapshot(
        shipments: shipments,
        loadPosts: [
          for (final item in shipments)
            if (item.loadPostSnapshot != null) item.loadPostSnapshot!,
        ],
        bidsByShipmentId: {
          for (final shipment in shipments)
            shipment.id: bids
                .where((bid) => bid.shipmentId == shipment.id)
                .toList(),
        },
        carriersById: {for (final carrier in carriers) carrier.id: carrier},
        eventsByShipmentId: {
          for (final shipment in shipments)
            shipment.id: events
                .where((event) => event.shipmentId == shipment.id)
                .toList(),
        },
        pendingBidArrivals: const [],
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message: 'The server returned an unexpected shipment response.',
        code: 'invalid_response',
      );
    }
  }

  Bid _bid(Map<String, dynamic> item) => Bid(
    id: item['id'] as String,
    shipmentId: item['shipmentId'] as String,
    carrierId: item['carrierId'] as String,
    fareNpr: (item['fareNpr'] as num).toDouble(),
    estimatedDeliveryAt: DateTime.parse(item['estimatedDeliveryAt'] as String),
    status: BidStatus.values.byName(item['status'] as String),
    createdAt: DateTime.parse(item['createdAt'] as String),
    proposedVehicle: item['proposedVehicle'] as String?,
    carrierNote: item['carrierNote'] as String?,
    respondedAt: item['respondedAt'] == null
        ? null
        : DateTime.parse(item['respondedAt'] as String),
  );

  Carrier _carrier(Map<String, dynamic> item) => Carrier(
    id: item['id'] as String,
    displayName: item['displayName'] as String,
    rating: (item['rating'] as num).toDouble(),
    reviewCount: item['reviewCount'] as int,
  );

  ShipmentEvent _event(Map<String, dynamic> item) => ShipmentEvent(
    id: item['id'] as String,
    shipmentId: item['shipmentId'] as String,
    type: ShipmentEventType.values.byName(item['type'] as String),
    occurredAt: DateTime.parse(item['occurredAt'] as String),
    actorId: item['actorId'] as String?,
    actorType: item['actorType'] as String?,
    summary: item['summary'] as String?,
  );

  @override
  Future<ShipmentWorkflowSnapshot> fetchSnapshot() async => _snapshot(
    _map(_data(await client.get<dynamic>(ApiEndpoints.shipmentWorkflow))),
  );

  @override
  Future<ShipmentWorkflowSnapshot?> fetchShipmentDetails(
    String shipmentId,
  ) async {
    try {
      final data = _map(
        _data(
          await client.get<dynamic>(ApiEndpoints.shipmentDetails(shipmentId)),
        ),
      );
      final record = data['shipment'] ?? data;
      return _snapshot({
        'shipments': [record],
        'bids': data['bids'] ?? const [],
        'carriers': data['carriers'] ?? const [],
        'events': data['events'] ?? const [],
      });
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<LoadPost?> latestLoadPostDraft() async {
    try {
      final data = _data(
        await client.get<dynamic>(ApiEndpoints.latestLoadPostDraft),
      );
      final draft = data is Map && data.containsKey('draft')
          ? data['draft']
          : data;
      return draft == null ? null : LoadPost.fromJson(_map(draft));
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<LoadPost> saveLoadPostDraft(LoadPost draft) async {
    final data = _data(
      await client.post<dynamic>(
        ApiEndpoints.loadPostDrafts,
        data: _requestBody(draft),
      ),
    );
    return LoadPost.fromJson(
      _map(data is Map && data.containsKey('draft') ? data['draft'] : data),
    );
  }

  @override
  Future<LoadPostSubmission> submitLoadPost(LoadPost draft) async {
    final error = validateLoadPost(draft);
    if (error != null) throw ShipmentOperationException(error);
    final body = _map(
      _data(
        await client.post<dynamic>(
          ApiEndpoints.submitLoadPost(draft.id),
          data: _requestBody(draft),
          headers: {'Idempotency-Key': draft.id},
        ),
      ),
    );
    final post = LoadPost.fromJson(apiLoadPostRecord(_map(body['loadPost'])));
    final shipment = shipmentFromRecord(
      _map(body['shipment']),
      apiJourneyTotal: true,
    );
    return LoadPostSubmission(loadPost: post, shipments: [shipment]);
  }

  Map<String, Object?> _requestBody(LoadPost post) {
    final body = post.toJson()
      ..remove('shipperCompanyId')
      ..remove('createdByUserId');
    // This flag only controls the local form and is not part of the API contract.
    for (final truck in body['trucks'] as List) {
      (truck as Map)
        ..remove('loadWeightAutoFilled')
        ..remove('loadWeightMeaning');
    }
    return body;
  }

  @override
  Future<void> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    await client.post<dynamic>(ApiEndpoints.acceptBid(shipmentId, bidId));
  }

  @override
  Future<List<BidArrivalEvent>> processDueBidArrivals({DateTime? now}) async =>
      const [];
}
