import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/models/bid.dart';
import '../../shipments/domain/models/shipment.dart';
import '../../shipments/providers/shipment_providers.dart';

class BidSheetAction {
  const BidSheetAction({required this.offer});

  final BidWithCarrier offer;
}

Future<BidSheetAction?> showBidOffersBottomSheet(
  BuildContext context, {
  required Shipment shipment,
  required List<BidWithCarrier> bids,
  bool preview = false,
}) => showModalBottomSheet<BidSheetAction>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0xFF101426).withValues(alpha: .46),
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: .91,
    minChildSize: .58,
    maxChildSize: .98,
    expand: false,
    builder: (context, scrollController) => _BidOffersSheet(
      shipment: shipment,
      bids: bids,
      scrollController: scrollController,
      preview: preview,
    ),
  ),
);

class _BidOffersSheet extends ConsumerWidget {
  const _BidOffersSheet({
    required this.shipment,
    required this.bids,
    required this.scrollController,
    required this.preview,
  });

  final Shipment shipment;
  final List<BidWithCarrier> bids;
  final ScrollController scrollController;
  final bool preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSnapshot = ref.watch(shipmentWorkflowProvider).valueOrNull;
    final offers =
        (currentSnapshot?.bidsFor(shipment.id) ?? bids)
            .where((offer) => offer.bid.status == BidStatus.pending)
            .toList()
          ..sort(
            (left, right) => right.bid.createdAt.compareTo(left.bid.createdAt),
          );

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(
          17,
          10,
          17,
          18 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFADB9D2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SheetHeader(),
          if (preview)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Example bids · UI preview",
                style: TextStyle(
                  color: Color(0xFF59637A),
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 12),
          _ShipmentSummary(shipment: shipment, preview: preview),
          const SizedBox(height: 15),
          Text(
            '${offers.length} ${offers.length == 1 ? 'Bid' : 'Bids'} Received',
            style: TextStyle(
              color: const Color(0xFF10162B),
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -.45,
            ),
          ),
          const SizedBox(height: 10),
          if (offers.isEmpty)
            const _NoBidsCard()
          else
            for (var index = 0; index < offers.length; index++) ...[
              _BidOfferCard(
                offer: offers[index],
                preview: preview,
                onAccept: () => Navigator.of(
                  context,
                ).pop(BidSheetAction(offer: offers[index])),
              ),
              if (index != offers.length - 1) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 84,
    child: Stack(
      children: [
        Positioned(
          right: -8,
          top: 0,
          bottom: 0,
          width: 150,
          child: Image.asset(
            'assets/images/bid_sheet_banner.png',
            fit: BoxFit.contain,
          ),
        ),
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff6488ff), Color(0xff392ce6)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33392ce6),
                    blurRadius: 14,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gavel_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Needs Your Action',
                    style: TextStyle(
                      color: Color(0xff10162b),
                      fontSize: AppTextStyles.sectionTitleSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Review bids and choose a carrier for your load.',
                    maxLines: 2,
                    style: TextStyle(
                      color: const Color(0xff454e67),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(color: const Color(0xfff8f9fd), blurRadius: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ShipmentSummary extends StatelessWidget {
  const _ShipmentSummary({required this.shipment, required this.preview});
  final Shipment shipment;
  final bool preview;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffdde5f7)),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0c1b3a7a),
          blurRadius: 14,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xffffece5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Color(0xffe74614),
                size: 23,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                shipment.reference,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff10162b),
                  fontSize: AppTextStyles.buttonSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xffe7f0ff),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                shipment.status.label,
                style: const TextStyle(
                  color: Color(0xff2365bb),
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            const Icon(Icons.circle, size: 10, color: Color(0xffe94617)),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                shipment.origin.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextStyles.captionSize,
                  color: Color(0xff10162b),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.trending_flat,
                color: Color(0xff68748a),
                size: 28,
              ),
            ),
            const Icon(Icons.location_on, size: 20, color: Color(0xffe94617)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                shipment.destination.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextStyles.captionSize,
                  color: Color(0xff10162b),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (preview) ...[
              Container(
                width: 1,
                height: 43,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                color: const Color(0xffcfd6e3),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 15,
                        color: Color(0xff59637a),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Bidding closes in',
                        style: TextStyle(fontSize: 9, color: Color(0xff59637a)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  _PreviewTime(),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xff59637a),
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                shipment.cargo.displaySummary,
                style: const TextStyle(
                  color: Color(0xff59637a),
                  fontSize: AppTextStyles.captionSize,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PreviewTime extends StatelessWidget {
  const _PreviewTime();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xffffe5dc),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      '5 hours',
      style: TextStyle(
        color: Color(0xffdf4a1d),
        fontSize: AppTextStyles.captionSize,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _BidOfferCard extends StatelessWidget {
  const _BidOfferCard({
    required this.offer,
    required this.onAccept,
    required this.preview,
  });
  final BidWithCarrier offer;
  final VoidCallback? onAccept;
  final bool preview;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 350;
      return Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xffdce4f4)),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x101b3a7a),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffe8eeff),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    offer.initials,
                    style: const TextStyle(
                      color: Color(0xff315dae),
                      fontSize: AppTextStyles.buttonSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.carrier.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: AppTextStyles.buttonSize,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xffffb300),
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${offer.carrier.rating.toStringAsFixed(1)} (${offer.carrier.reviewCount} reviews)',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xff59637a),
                                fontSize: AppTextStyles.labelSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatNpr(offer.bid.fareNpr),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: AppTextStyles.sectionTitleSize,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.local_shipping_outlined,
                  size: 15,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Delivery ${_formatDate(offer.bid.estimatedDeliveryAt)}${offer.bid.proposedVehicle == null ? '' : ' · ${offer.bid.proposedVehicle}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xff59637a),
                      fontSize: AppTextStyles.labelSize,
                    ),
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 9),
                  _AcceptButton(onPressed: onAccept, preview: preview),
                ],
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: .4,
                  child: _AcceptButton(onPressed: onAccept, preview: preview),
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _AcceptButton extends StatelessWidget {
  const _AcceptButton({required this.onPressed, required this.preview});
  final VoidCallback? onPressed;
  final bool preview;
  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
    label: const Text('Accept'),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.orange,
      disabledBackgroundColor: AppColors.orange,
      disabledForegroundColor: Colors.white,
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

class _NoBidsCard extends StatelessWidget {
  const _NoBidsCard();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 34),
    child: Center(child: Text('No pending bids for this shipment.')),
  );
}

String _formatNpr(double amount) {
  final whole = amount.round().toString();
  final grouped = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return 'Rs. $grouped';
}

String _formatDate(DateTime date) {
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
