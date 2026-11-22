import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/models/shipment.dart';

Color shipmentStatusColor(ShipmentStatus status) => switch (status) {
  ShipmentStatus.awaitingBids => const Color(0xFF2476D4),
  ShipmentStatus.scheduled => const Color(0xFF8546D7),
  ShipmentStatus.inTransit => AppColors.orange,
  ShipmentStatus.delivered => const Color(0xFF159A54),
  ShipmentStatus.cancelled || ShipmentStatus.expired => AppColors.muted,
};

IconData shipmentStatusIcon(ShipmentStatus status) => switch (status) {
  ShipmentStatus.awaitingBids => Icons.gavel_rounded,
  ShipmentStatus.scheduled => Icons.calendar_month_outlined,
  ShipmentStatus.inTransit => Icons.local_shipping_outlined,
  ShipmentStatus.delivered => Icons.check_circle_outline_rounded,
  ShipmentStatus.cancelled => Icons.cancel_outlined,
  ShipmentStatus.expired => Icons.timer_off_outlined,
};

String formatShipmentDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String formatNpr(double amount) {
  final whole = amount.round().toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs. $grouped';
}
