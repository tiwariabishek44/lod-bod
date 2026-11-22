import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers/core_providers.dart';
import '../../bids/domain/models/bid.dart';
import '../data/repositories/api_shipment_repository.dart';
import '../data/repositories/load_catalog_repository.dart';
import '../data/repositories/local_load_draft_store.dart';
import '../data/repositories/mock_shipment_repository.dart';
import '../data/repositories/shipment_repository.dart';
import '../domain/models/bid_arrival_event.dart';
import '../domain/models/load_post.dart';
import '../../auth/providers/auth_providers.dart';

final shipmentRepositoryProvider = Provider<ShipmentRepository>(
  (ref) => ref.watch(appDataModeProvider) == AppDataMode.mock
      ? MockShipmentRepository(
          ref.watch(sharedPreferencesProvider),
          ref.watch(authStateProvider).user?.id ?? 'anonymous',
        )
      : ApiShipmentRepository(ref.watch(apiClientProvider)),
);

final localLoadDraftStoreProvider = Provider<LocalLoadDraftStore>(
  (ref) => LocalLoadDraftStore(
    ref.watch(sharedPreferencesProvider),
    ref.watch(authStateProvider).user?.id ?? 'anonymous',
  ),
);

final loadCatalogRepositoryProvider = Provider<LoadCatalogRepository>(
  (ref) => ref.watch(appDataModeProvider) == AppDataMode.mock
      ? MockLoadCatalogRepository(
          ref.watch(sharedPreferencesProvider),
          ref.watch(authStateProvider).user?.id ?? 'anonymous',
        )
      : ApiLoadCatalogRepository(ref.watch(apiClientProvider)),
);

/// Independently fetches the requested shipment for the detail screen.
final shipmentDetailsProvider = FutureProvider.autoDispose
    .family<ShipmentWorkflowSnapshot?, String>(
      (ref, shipmentId) => ref
          .watch(shipmentRepositoryProvider)
          .fetchShipmentDetails(shipmentId),
    );

final shipmentWorkflowProvider =
    AsyncNotifierProvider<ShipmentWorkflowController, ShipmentWorkflowSnapshot>(
      ShipmentWorkflowController.new,
    );

class ShipmentWorkflowController
    extends AsyncNotifier<ShipmentWorkflowSnapshot> {
  bool _submitting = false;
  final Set<String> _acceptingShipmentIds = {};

  @override
  Future<ShipmentWorkflowSnapshot> build() =>
      ref.watch(shipmentRepositoryProvider).fetchSnapshot();

  Future<LoadPost?> latestDraft() =>
      ref.read(localLoadDraftStoreProvider).read();

  Future<LoadPost> saveDraft(LoadPost draft) =>
      ref.read(localLoadDraftStoreProvider).save(draft);

  Future<LoadPostSubmission> submit(LoadPost draft) async {
    if (_submitting) {
      throw const ShipmentOperationException(
        'A submission is already in progress.',
      );
    }
    _submitting = true;
    try {
      final result = await ref
          .read(shipmentRepositoryProvider)
          .submitLoadPost(draft);
      for (final shipment in result.shipments) {
        ref.invalidate(shipmentDetailsProvider(shipment.id));
      }
      // A successful submission remains successful even if the subsequent
      // reload fails; invalidate so other views can retry independently.
      try {
        await _refreshSnapshot();
      } catch (error, stackTrace) {
        state = AsyncError(error, stackTrace);
        return result.withSnapshotRefreshed(false);
      }
      return result;
    } finally {
      _submitting = false;
    }
  }

  Future<bool> acceptBid({
    required String shipmentId,
    required String bidId,
  }) async {
    if (!_acceptingShipmentIds.add(shipmentId)) {
      throw const ShipmentOperationException(
        'A bid decision is already being saved for this shipment.',
      );
    }
    try {
      await ref
          .read(shipmentRepositoryProvider)
          .acceptBid(shipmentId: shipmentId, bidId: bidId);
      ref.invalidate(shipmentDetailsProvider(shipmentId));
      try {
        await _refreshSnapshot();
        return true;
      } catch (error, stackTrace) {
        state = AsyncError(error, stackTrace);
        return false;
      }
    } finally {
      _acceptingShipmentIds.remove(shipmentId);
    }
  }

  Future<List<BidArrivalEvent>> processDueBidArrivals({DateTime? now}) async {
    final bidArrivals = await ref
        .read(shipmentRepositoryProvider)
        .processDueBidArrivals(now: now);
    if (bidArrivals.isNotEmpty) {
      for (final shipmentId
          in bidArrivals.map((event) => event.shipment.id).toSet()) {
        ref.invalidate(shipmentDetailsProvider(shipmentId));
      }
      await _refreshSnapshot();
    }
    return bidArrivals;
  }

  Future<void> refresh() async {
    try {
      await _refreshSnapshot();
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> _refreshSnapshot() async {
    final snapshot = await ref.read(shipmentRepositoryProvider).fetchSnapshot();
    state = AsyncData(snapshot);
  }
}

final pendingBidCountProvider = Provider.family<int, String>((ref, shipmentId) {
  final snapshot = ref.watch(shipmentWorkflowProvider).valueOrNull;
  return snapshot
          ?.bidsFor(shipmentId)
          .where((offer) => offer.bid.status == BidStatus.pending)
          .length ??
      0;
});
