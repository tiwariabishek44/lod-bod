import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/shipments/domain/models/shipment.dart';
import '../../features/shipments/ui/shipment_presentation.dart';

class ShipmentData {
  const ShipmentData({
    required this.domainId,
    required this.id,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.from,
    required this.to,
    required this.cargo,
    required this.date,
    required this.detail,
    required this.amount,
    this.bidCount,
  });

  final String id;
  final String domainId;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final String from;
  final String to;
  final String cargo;
  final String date;
  final String detail;
  final String amount;
  final String? bidCount;
}

extension ShipmentDataFromDomain on ShipmentData {
  static ShipmentData fromShipment(Shipment shipment, {required int bidCount}) {
    final status = shipment.status;
    final color = shipmentStatusColor(status);
    final icon = shipmentStatusIcon(status);
    final pickupDate = formatShipmentDate(shipment.pickupAt);
    final fare = shipment.expectedFareNpr;
    return ShipmentData(
      domainId: shipment.id,
      id: shipment.reference,
      status: status.label,
      statusColor: color,
      statusIcon: icon,
      from: shipment.origin.displayName,
      to: shipment.destination.displayName,
      cargo: shipment.cargo.displaySummary,
      date: pickupDate,
      detail: switch (status) {
        ShipmentStatus.awaitingBids => 'Waiting for carrier bids',
        ShipmentStatus.scheduled => 'Pickup $pickupDate',
        ShipmentStatus.inTransit => 'Shipment is in transit',
        ShipmentStatus.delivered => 'Delivered $pickupDate',
        ShipmentStatus.cancelled => 'Shipment cancelled',
        ShipmentStatus.expired => 'Request expired',
      },
      amount: status == ShipmentStatus.awaitingBids
          ? 'Fare pending'
          : fare == null
          ? 'Fare not set'
          : formatNpr(fare),
      bidCount: status == ShipmentStatus.awaitingBids && bidCount > 0
          ? '$bidCount ${bidCount == 1 ? 'bid' : 'bids'}'
          : null,
    );
  }
}

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({super.key, required this.shipment, this.onTap});

  final ShipmentData shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6E8EF)),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C18274D),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    shipment.id,
                    style: AppTextStyles.body.copyWith(
                      color: Color(0xFF697286),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                _StatusTag(shipment: shipment),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Text(
                    shipment.from,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.ink,
                      letterSpacing: -.25,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                Flexible(
                  child: Text(
                    shipment.to,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: AppColors.ink,
                      letterSpacing: -.25,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.layers_outlined,
                  color: Color(0xFF596174),
                  size: 19,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shipment.cargo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF535D72),
                      fontSize: AppTextStyles.bodySize,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 13, color: const Color(0xFFD8DBE4)),
                const SizedBox(width: 9),
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF596174),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    shipment.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF535D72),
                      fontSize: AppTextStyles.bodySize,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: Color(0xFFE8EAF0)),
            ),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF657087),
                  size: 19,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    shipment.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(0xFF535D72),
                      fontSize: AppTextStyles.bodySize,
                    ),
                  ),
                ),
                if (shipment.bidCount != null) ...[
                  Text(
                    shipment.bidCount!,
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: AppTextStyles.bodySize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('·', style: TextStyle(color: AppColors.muted)),
                  ),
                  Text(
                    shipment.amount,
                    style: TextStyle(
                      color: Color(0xFF535D72),
                      fontSize: AppTextStyles.bodySize,
                    ),
                  ),
                ] else
                  Text(
                    shipment.amount,
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: AppTextStyles.sectionTitleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.2,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.shipment});

  final ShipmentData shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: shipment.statusColor.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(shipment.statusIcon, color: shipment.statusColor, size: 12),
          const SizedBox(width: 4),
          Text(
            shipment.status,
            style: TextStyle(
              color: shipment.statusColor,
              fontSize: AppTextStyles.labelSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
