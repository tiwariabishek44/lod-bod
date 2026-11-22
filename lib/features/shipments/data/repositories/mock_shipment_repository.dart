import 'dart:convert';
import 'dart:async';

import '../../../../core/mock/mock_delay.dart';

import '../../../bids/domain/models/bid.dart';
import '../../domain/models/pending_bid_arrival.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/bid_arrival_event.dart';
import '../../domain/models/load_post.dart';
import '../../domain/models/shipment.dart';
import '../../domain/models/shipment_event.dart';
import '../../domain/shipment_rules.dart';
import 'shipment_repository.dart';
import 'shipment_mapping.dart';

/// Locally persisted, whole-shipment prototype. Each submitted post is one job.
class MockShipmentRepository implements ShipmentRepository {
  MockShipmentRepository(this.preferences, this.ownerId);
  final SharedPreferences preferences;
  final String ownerId;
  String get _key => 'loadboard.shipments.v2.$ownerId';
  // Serialize read-modify-write operations for this user within the app process.
  static final Map<String, Future<void>> _locks = {};
  Future<T> _locked<T>(Future<T> Function() action) async {
    final previous = _locks[_key] ?? Future<void>.value();
    final done = Completer<void>();
    _locks[_key] = done.future;
    await previous;
    try {
      return await action();
    } finally {
      if (identical(_locks[_key], done.future)) _locks.remove(_key);
      done.complete();
    }
  }

  Future<T> _delayedLocked<T>(Future<T> Function() action) async {
    await waitForMockRepository();
    return _locked(action);
  }

  static const _carriers = [
    Carrier(
      id: 'swift',
      displayName: 'Swift Transport',
      rating: 4.1,
      reviewCount: 58,
    ),
    Carrier(
      id: 'koshi',
      displayName: 'Koshi Logistics',
      rating: 4.4,
      reviewCount: 76,
    ),
    Carrier(
      id: 'himalayan',
      displayName: 'Himalayan Cargo',
      rating: 4.6,
      reviewCount: 120,
    ),
  ];

  Bid _bid(Map<String, dynamic> data) => Bid(
    id: data['id'] as String,
    shipmentId: data['shipmentId'] as String,
    carrierId: data['carrierId'] as String,
    fareNpr: (data['fareNpr'] as num).toDouble(),
    estimatedDeliveryAt: DateTime.parse(data['estimatedDeliveryAt'] as String),
    status: BidStatus.values.byName(data['status'] as String),
    createdAt: DateTime.parse(data['createdAt'] as String),
    respondedAt: data['respondedAt'] == null
        ? null
        : DateTime.parse(data['respondedAt'] as String),
  );
  List<Map<String, dynamic>> _bids(Map<String, dynamic> row) => [
    for (final bid in (row['bids'] as List? ?? const []))
      Map<String, dynamic>.from(bid as Map),
  ];
  DateTime _dueAt(Map<String, dynamic> row, int index) =>
      DateTime.parse(row['createdAt'] as String).add(
        PendingBidArrival.firstBidDelay +
            PendingBidArrival.intervalBetweenBids * index,
      );

  Future<Map<String, dynamic>> _read() async {
    final stored = preferences.getString(_key);
    if (stored == null) return {'draft': null, 'submitted': <dynamic>[]};
    Map<String, dynamic> state;
    try {
      state = Map<String, dynamic>.from(jsonDecode(stored) as Map);
    } catch (_) {
      throw const ShipmentOperationException(
        'Saved shipments could not be read.',
      );
    }
    final rows = [
      for (final row in (state['submitted'] as List? ?? const []))
        Map<String, dynamic>.from(row as Map),
    ];
    // Preserve internal shipment IDs while replacing older timestamp references.
    final legacy =
        rows
            .where(
              (row) => RegExp(
                r'^LOD-\d{13,}$',
              ).hasMatch(row['reference'] as String? ?? ''),
            )
            .toList()
          ..sort((a, b) {
            final dateOrder = (a['createdAt'] as String).compareTo(
              b['createdAt'] as String,
            );
            return dateOrder != 0
                ? dateOrder
                : (a['id'] as String).compareTo(b['id'] as String);
          });
    if (legacy.isNotEmpty) {
      final used = {for (final row in rows) row['reference'] as String?};
      var number = 1001;
      for (final row in legacy) {
        while (used.contains('LOD-$number')) {
          number++;
        }
        row['reference'] = 'LOD-$number';
        used.add(row['reference'] as String);
        number++;
      }
      state['submitted'] = rows;
      await _write(state);
    }
    return state;
  }

  String _nextReference(List<dynamic> rows) {
    var highest = 1000;
    for (final row in rows) {
      final match = RegExp(
        r'^LOD-(\d{1,8})$',
      ).firstMatch((row as Map)['reference'] as String? ?? '');
      final number = match == null ? null : int.tryParse(match.group(1)!);
      if (number != null && number > highest) highest = number;
    }
    return 'LOD-${highest + 1}';
  }

  Future<void> _write(Map<String, dynamic> state) async {
    if (!await preferences.setString(_key, jsonEncode(state))) {
      throw const ShipmentOperationException(
        'Could not save changes on this device.',
      );
    }
  }

  @override
  Future<ShipmentWorkflowSnapshot> fetchSnapshot() => _delayedLocked(() async {
    final state = await _read();
    final rows = [
      for (final row in (state['submitted'] as List? ?? const []))
        Map<String, dynamic>.from(row as Map),
    ];
    return _snapshotForRows(rows);
  });

  @override
  Future<ShipmentWorkflowSnapshot?> fetchShipmentDetails(String shipmentId) =>
      _delayedLocked(() async {
        final state = await _read();
        final rows = (state['submitted'] as List? ?? const []);
        for (final value in rows) {
          final row = Map<String, dynamic>.from(value as Map);
          if (row['id'] == shipmentId) return _snapshotForRows([row]);
        }
        return null;
      });

  ShipmentWorkflowSnapshot _snapshotForRows(List<Map<String, dynamic>> rows) {
    final shipments = [for (final row in rows) shipmentFromRecord(row)];
    return ShipmentWorkflowSnapshot(
      shipments: shipments,
      loadPosts: [for (final shipment in shipments) shipment.loadPostSnapshot!],
      bidsByShipmentId: {
        for (final row in rows)
          row['id'] as String: [for (final bid in _bids(row)) _bid(bid)],
      },
      carriersById: {for (final carrier in _carriers) carrier.id: carrier},
      eventsByShipmentId: {
        for (final row in rows)
          row['id'] as String: [
            ShipmentEvent(
              id: 'posted-${row['id']}',
              shipmentId: row['id'] as String,
              type: ShipmentEventType.loadPosted,
              occurredAt: DateTime.parse(row['createdAt'] as String),
              summary: 'Shipment posted and awaiting carrier bids.',
            ),
            for (final bid in _bids(row))
              ShipmentEvent(
                id: 'received-${bid['id']}',
                shipmentId: row['id'] as String,
                type: ShipmentEventType.bidReceived,
                occurredAt: DateTime.parse(bid['createdAt'] as String),
                summary: 'Carrier bid received.',
              ),
            if (row['acceptedBidId'] != null)
              ShipmentEvent(
                id: 'accepted-${row['id']}',
                shipmentId: row['id'] as String,
                type: ShipmentEventType.carrierSelected,
                occurredAt: DateTime.parse(row['updatedAt'] as String),
                summary: 'Carrier selected.',
              ),
          ],
      },
      pendingBidArrivals: [
        for (final row in rows)
          if (row['status'] == ShipmentStatus.awaitingBids.name &&
              _bids(row).length < PendingBidArrival.totalBids)
            PendingBidArrival(
              shipmentId: row['id'] as String,
              nextBidIndex: _bids(row).length,
              dueAt: _dueAt(row, _bids(row).length),
            ),
      ],
    );
  }

  @override
  Future<LoadPost?> latestLoadPostDraft() => _delayedLocked(() async {
    final state = await _read();
    final draft = state['draft'];
    return draft == null
        ? null
        : LoadPost.fromJson(Map<String, dynamic>.from(draft as Map));
  });

  @override
  Future<LoadPost> saveLoadPostDraft(LoadPost draft) =>
      _delayedLocked(() async {
        final state = await _read();
        final saved = draft.copyWith(
          status: LoadPostStatus.draft,
          updatedAt: DateTime.now(),
        );
        state['draft'] = saved.toJson();
        await _write(state);
        return saved;
      });

  @override
  Future<LoadPostSubmission> submitLoadPost(LoadPost draft) =>
      _delayedLocked(() async {
        final state = await _read();
        final rows = List<dynamic>.of(state['submitted'] as List? ?? const []);
        for (final row in rows) {
          final item = Map<String, dynamic>.from(row as Map);
          final post = LoadPost.fromJson(
            Map<String, dynamic>.from(item['post'] as Map),
          );
          if (post.id == draft.id) {
            return LoadPostSubmission(
              loadPost: post,
              shipments: [shipmentFromRecord(item)],
            );
          }
        }
        final error = validateLoadPost(draft);
        if (error != null) throw ShipmentOperationException(error);
        // Count the whole shipment once, regardless of its number of trucks.
        final active = rows
            .map(
              (row) =>
                  shipmentFromRecord(Map<String, dynamic>.from(row as Map)),
            )
            .where(
              (shipment) =>
                  shipment.creationChannel == ShipmentCreationChannel.mobile &&
                  shipment.status.countsTowardMobileLimit,
            )
            .length;
        if (active >= ShipmentRules.mobileRequestLimit) {
          throw ShipmentRequestLimitException(
            used: active,
            limit: ShipmentRules.mobileRequestLimit,
          );
        }
        final now = DateTime.now();
        final post = draft.copyWith(
          status: LoadPostStatus.submitted,
          currentStep: 3,
          updatedAt: now,
          submittedAt: now,
        );
        final record = <String, dynamic>{
          'id': 'shipment-${draft.id}',
          'reference': _nextReference(rows),
          'status': ShipmentStatus.awaitingBids.name,
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'post': post.toJson(),
        };
        rows.insert(0, record);
        state['submitted'] = rows;
        final savedDraft = state['draft'];
        if (savedDraft is Map && savedDraft['id'] == draft.id) {
          state['draft'] = null;
        }
        await _write(state);
        return LoadPostSubmission(
          loadPost: post,
          shipments: [shipmentFromRecord(record)],
        );
      });

  @override
  Future<void> acceptBid({required String shipmentId, required String bidId}) =>
      _delayedLocked(() async {
        final state = await _read();
        final rows = [
          for (final row in (state['submitted'] as List? ?? const []))
            Map<String, dynamic>.from(row as Map),
        ];
        final index = rows.indexWhere((row) => row['id'] == shipmentId);
        if (index < 0) {
          throw const ShipmentOperationException('Shipment not found.');
        }
        final row = rows[index];
        if (row['status'] != ShipmentStatus.awaitingBids.name) {
          throw const ShipmentOperationException(
            'This shipment is no longer accepting bids.',
          );
        }
        final bids = _bids(row);
        final selectedIndex = bids.indexWhere(
          (bid) =>
              bid['id'] == bidId &&
              bid['shipmentId'] == shipmentId &&
              bid['status'] == BidStatus.pending.name,
        );
        if (selectedIndex < 0) {
          throw const ShipmentOperationException(
            'This bid is no longer available for this shipment.',
          );
        }
        final selected = bids[selectedIndex];
        final now = DateTime.now().toIso8601String();
        for (final bid in bids) {
          if (bid['status'] == BidStatus.pending.name) {
            bid['status'] = bid['id'] == bidId
                ? BidStatus.accepted.name
                : BidStatus.declined.name;
            bid['respondedAt'] = now;
          }
        }
        row['bids'] = bids;
        row['status'] = ShipmentStatus.scheduled.name;
        row['acceptedBidId'] = bidId;
        row['assignedCarrierId'] = selected['carrierId'];
        row['acceptedFareNpr'] = selected['fareNpr'];
        row['updatedAt'] = now;
        rows[index] = row;
        state['submitted'] = rows;
        await _write(state);
      });
  @override
  Future<List<BidArrivalEvent>> processDueBidArrivals({DateTime? now}) =>
      _delayedLocked(() async {
        final current = now ?? DateTime.now();
        final state = await _read();
        final rows = [
          for (final row in (state['submitted'] as List? ?? const []))
            Map<String, dynamic>.from(row as Map),
        ];
        final events = <BidArrivalEvent>[];
        const fares = [29500.0, 30800.0, 32000.0];
        for (final row in rows) {
          if (row['status'] != ShipmentStatus.awaitingBids.name) continue;
          final bids = _bids(row);
          while (bids.length < PendingBidArrival.totalBids &&
              !_dueAt(row, bids.length).isAfter(current)) {
            final index = bids.length;
            final due = _dueAt(row, index);
            final id = row['id'] as String;
            final data = <String, dynamic>{
              'id': '$id-bid-$index',
              'shipmentId': id,
              'carrierId': _carriers[index].id,
              'fareNpr': fares[index],
              'createdAt': due.toIso8601String(),
              'estimatedDeliveryAt': due
                  .add(Duration(days: index == 0 ? 3 : 2))
                  .toIso8601String(),
              'status': BidStatus.pending.name,
            };
            bids.add(data);
            events.add(
              BidArrivalEvent(
                shipment: shipmentFromRecord(row),
                bid: _bid(data),
                arrivalNumber: index + 1,
              ),
            );
          }
          row['bids'] = bids;
        }
        if (events.isNotEmpty) {
          state['submitted'] = rows;
          await _write(state);
        }
        return events;
      });
}
