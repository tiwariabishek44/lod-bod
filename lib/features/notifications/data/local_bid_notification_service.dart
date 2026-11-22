import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../../shipments/domain/models/bid_arrival_event.dart';
import '../../shipments/domain/models/pending_bid_arrival.dart';

class LocalBidNotificationService {
  LocalBidNotificationService() : _plugin = FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<String?> initialize({required ValueChanged<String> onTap}) async {
    if (!_initialized) {
      timezone_data.initializeTimeZones();
      timezone.setLocalLocation(timezone.getLocation('Asia/Kathmandu'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          linux: LinuxInitializationSettings(defaultActionName: 'Open LODBOD'),
        ),
        onDidReceiveNotificationResponse: (response) {
          final shipmentId = response.payload;
          if (shipmentId != null && shipmentId.isNotEmpty) onTap(shipmentId);
        },
      );
      _initialized = true;
    }

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final payload = launchDetails?.notificationResponse?.payload;
    return launchDetails?.didNotificationLaunchApp == true &&
            payload != null &&
            payload.isNotEmpty
        ? payload
        : null;
  }

  Future<bool> requestPermission() async {
    final androidPermission = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (androidPermission != null) return androidPermission;

    final iosPermission = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return iosPermission ?? true;
  }

  Future<bool> areNotificationsEnabled() async {
    final androidEnabled = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    if (androidEnabled != null) return androidEnabled;
    return true;
  }

  Future<void> scheduleBidArrivals({
    required PendingBidArrival arrival,
    required String reference,
  }) async {
    for (
      var bidIndex = arrival.nextBidIndex;
      bidIndex < PendingBidArrival.totalBids;
      bidIndex++
    ) {
      final dueAt = arrival.dueAt.add(
        PendingBidArrival.intervalBetweenBids *
            (bidIndex - arrival.nextBidIndex),
      );
      await _plugin.zonedSchedule(
        id: _notificationId(arrival.shipmentId, bidIndex),
        title:
            'New bid ${bidIndex + 1} of ${PendingBidArrival.totalBids} for $reference',
        body: 'A carrier submitted an offer. Tap to review this load.',
        scheduledDate: timezone.TZDateTime.from(dueAt, timezone.local),
        notificationDetails: _notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: arrival.shipmentId,
      );
    }
  }

  Future<void> showBidArrival(BidArrivalEvent arrival) async {
    final shipment = arrival.shipment;
    await _plugin.show(
      id: _notificationId(shipment.id, arrival.arrivalNumber - 1),
      title:
          'New bid ${arrival.arrivalNumber} of ${BidArrivalEvent.totalArrivals} for ${shipment.reference}',
      body: 'A carrier submitted an offer. Tap to review this load.',
      notificationDetails: _notificationDetails,
      payload: shipment.id,
    );
  }

  Future<void> cancelBidArrivals(String shipmentId) async {
    for (var bidIndex = 0; bidIndex < PendingBidArrival.totalBids; bidIndex++) {
      await _plugin.cancel(id: _notificationId(shipmentId, bidIndex));
    }
  }

  NotificationDetails get _notificationDetails => NotificationDetails(
    android: AndroidNotificationDetails(
      'carrier_bid_updates_v2',
      'Carrier bid updates',
      channelDescription:
          'Alerts with sound and vibration when carriers bid on a load.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 350, 160, 350]),
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    ),
    macOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    ),
  );

  int _notificationId(String shipmentId, int bidIndex) =>
      '$shipmentId-$bidIndex'.codeUnits.fold<int>(
        17,
        (value, codeUnit) => (value * 31 + codeUnit) & 0x7fffffff,
      );
}
