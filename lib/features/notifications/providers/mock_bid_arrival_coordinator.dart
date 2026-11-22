import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/root_scaffold_messenger.dart';
import '../../../router/app_router.dart';
import '../../../router/route_names.dart';
import '../../shipments/domain/models/bid_arrival_event.dart';
import '../../shipments/domain/models/pending_bid_arrival.dart';
import '../../shipments/data/repositories/shipment_repository.dart';
import '../../shipments/providers/shipment_providers.dart';
import '../data/local_bid_notification_service.dart';

final localBidNotificationServiceProvider =
    Provider<LocalBidNotificationService>(
      (ref) => LocalBidNotificationService(),
    );

final mockBidArrivalCoordinatorProvider = Provider<MockBidArrivalCoordinator>((
  ref,
) {
  final coordinator = MockBidArrivalCoordinator(
    notificationService: ref.watch(localBidNotificationServiceProvider),
    router: ref.watch(appRouterProvider),
    messengerKey: rootScaffoldMessengerKey,
    loadSnapshot: () => ref.read(shipmentWorkflowProvider.future),
    processDueArrivals: () =>
        ref.read(shipmentWorkflowProvider.notifier).processDueBidArrivals(),
  );
  ref.listen(shipmentWorkflowProvider, (previous, next) {
    coordinator.updateSnapshot(next.valueOrNull);
  });
  unawaited(coordinator.start());
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class MockBidArrivalCoordinator with WidgetsBindingObserver {
  MockBidArrivalCoordinator({
    required LocalBidNotificationService notificationService,
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
    required Future<ShipmentWorkflowSnapshot> Function() loadSnapshot,
    required Future<List<BidArrivalEvent>> Function() processDueArrivals,
  }) : _notificationService = notificationService,
       _router = router,
       _messengerKey = messengerKey,
       _loadSnapshot = loadSnapshot,
       _processDueArrivals = processDueArrivals;

  final LocalBidNotificationService _notificationService;
  final GoRouter _router;
  final GlobalKey<ScaffoldMessengerState> _messengerKey;
  final Future<ShipmentWorkflowSnapshot> Function() _loadSnapshot;
  final Future<List<BidArrivalEvent>> Function() _processDueArrivals;
  final Completer<void> _ready = Completer<void>();
  final Map<String, PendingBidArrival> _pendingByShipmentId = {};
  final Map<String, String> _referencesByShipmentId = {};
  final Map<String, Timer> _timersByShipmentId = {};

  bool _notificationPermissionGranted = false;
  bool _suppressNextArrivalAlert = false;
  bool _disposed = false;

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);
    String? launchShipmentId;
    try {
      if (_supportsLocalNotifications) {
        try {
          launchShipmentId = await _notificationService.initialize(
            onTap: _handleNotificationTap,
          );
          _notificationPermissionGranted = await _notificationService
              .areNotificationsEnabled();
          if (launchShipmentId != null) {
            _queueOpenShipmentBids(launchShipmentId);
          }
        } catch (_) {
          // A local notification failure must not block shipment creation or bids.
        }
      }
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }

    try {
      final snapshot = await _loadSnapshot();
      updateSnapshot(snapshot);
      await _processDueBidArrivals(
        showInApp: _isForeground && launchShipmentId == null,
      );
    } catch (_) {
      // The workflow provider shows its own recoverable loading/error state.
    }
  }

  void updateSnapshot(ShipmentWorkflowSnapshot? snapshot) {
    if (_disposed || snapshot == null) return;
    final previousArrivals = Map<String, PendingBidArrival>.of(
      _pendingByShipmentId,
    );
    _pendingByShipmentId
      ..clear()
      ..addEntries(
        snapshot.pendingBidArrivals.map(
          (arrival) => MapEntry(arrival.shipmentId, arrival),
        ),
      );
    _referencesByShipmentId
      ..clear()
      ..addEntries(
        snapshot.shipments.map(
          (shipment) => MapEntry(shipment.id, shipment.reference),
        ),
      );

    for (final entry in _timersByShipmentId.entries.toList()) {
      final previousDueAt = previousArrivals[entry.key]?.dueAt;
      final nextArrival = _pendingByShipmentId[entry.key];
      if (nextArrival == null || previousDueAt != nextArrival.dueAt) {
        entry.value.cancel();
        _timersByShipmentId.remove(entry.key);
        if (nextArrival == null) {
          unawaited(_cancelNotifications(entry.key));
        }
      }
    }

    for (final arrival in _pendingByShipmentId.values) {
      _timersByShipmentId.putIfAbsent(arrival.shipmentId, () {
        final delay = arrival.dueAt.difference(DateTime.now());
        return Timer(delay.isNegative ? Duration.zero : delay, () {
          _timersByShipmentId.remove(arrival.shipmentId);
          if (_isForeground) {
            unawaited(_processDueBidArrivals(showInApp: true));
          }
        });
      });
    }

    final addedIds = _pendingByShipmentId.keys.toSet().difference(
      previousArrivals.keys.toSet(),
    );
    if (addedIds.isNotEmpty) unawaited(_requestNotificationPermission());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_scheduleBackgroundNotifications());
    }
  }

  Future<void> _onResume() async {
    await _ready.future;
    for (final shipmentId in _pendingByShipmentId.keys) {
      await _cancelNotifications(shipmentId);
    }
    final showInApp = !_suppressNextArrivalAlert;
    _suppressNextArrivalAlert = false;
    await _processDueBidArrivals(showInApp: showInApp);
    if (_notificationPermissionGranted) {
      _notificationPermissionGranted = await _notificationService
          .areNotificationsEnabled();
    }
  }

  Future<void> _scheduleBackgroundNotifications() async {
    await _ready.future;
    if (!_notificationPermissionGranted) return;
    for (final arrival in _pendingByShipmentId.values) {
      final reference = _referencesByShipmentId[arrival.shipmentId];
      if (reference == null) continue;
      try {
        await _notificationService.scheduleBidArrivals(
          arrival: arrival,
          reference: reference,
        );
      } catch (_) {
        // The timer and resume processing remain as a fallback.
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    await _ready.future;
    try {
      _notificationPermissionGranted =
          await _notificationService.areNotificationsEnabled() ||
          await _notificationService.requestPermission();
    } catch (_) {
      _notificationPermissionGranted = false;
    }
  }

  Future<void> _processDueBidArrivals({required bool showInApp}) async {
    final arrivals = await _processDueArrivals();
    if (arrivals.isEmpty) return;
    for (final arrival in arrivals) {
      await _cancelNotifications(arrival.shipment.id);
    }
    if (!showInApp || !_isForeground) return;

    for (final arrival in arrivals) {
      await HapticFeedback.mediumImpact();
      if (_supportsLocalNotifications) {
        try {
          await _notificationService.showBidArrival(arrival);
        } catch (_) {
          // Haptics and the in-app alert still work if sound is unavailable.
        }
      }
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Bid ${arrival.arrivalNumber} of ${BidArrivalEvent.totalArrivals} arrived for ${arrival.shipment.reference}.',
            ),
            action: SnackBarAction(
              label: 'Review bids',
              onPressed: () => _openShipmentBids(arrival.shipment.id),
            ),
          ),
        );
    }
  }

  Future<void> _cancelNotifications(String shipmentId) async {
    await _ready.future;
    try {
      await _notificationService.cancelBidArrivals(shipmentId);
    } catch (_) {
      // No scheduled notification is also a valid state.
    }
  }

  bool get _isForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  void _queueOpenShipmentBids(String shipmentId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) _openShipmentBids(shipmentId);
    });
  }

  void _openShipmentBids(String shipmentId) {
    if (_disposed) return;
    _router.go(
      '${RouteNames.shipments}/${Uri.encodeComponent(shipmentId)}?reviewBids=1',
    );
  }

  void _handleNotificationTap(String shipmentId) {
    _suppressNextArrivalAlert = true;
    _openShipmentBids(shipmentId);
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    for (final timer in _timersByShipmentId.values) {
      timer.cancel();
    }
    _timersByShipmentId.clear();
  }
}
