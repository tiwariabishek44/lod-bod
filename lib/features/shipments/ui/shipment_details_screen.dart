import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../router/route_names.dart';
import 'widgets/shipment_details_skeleton.dart';

import '../../bids/domain/models/bid.dart';
import '../../bids/ui/bid_review_flow.dart';
import '../data/repositories/shipment_repository.dart';
import '../domain/models/load_post.dart';
import '../domain/models/shipment.dart';
import '../providers/shipment_providers.dart';
import 'shipment_presentation.dart';

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  const ShipmentDetailsScreen({
    required this.shipmentId,
    this.showBidsOnOpen = false,
    super.key,
  });

  final String shipmentId;
  final bool showBidsOnOpen;

  @override
  ConsumerState<ShipmentDetailsScreen> createState() =>
      _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen> {
  bool _didAutoOpenBids = false;

  @override
  void didUpdateWidget(covariant ShipmentDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipmentId != widget.shipmentId) _didAutoOpenBids = false;
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(shipmentDetailsProvider(widget.shipmentId));
    return workflow.when(
      skipLoadingOnRefresh: true,
      loading: () => const ShipmentDetailsSkeleton(),
      error: (error, stackTrace) => _DetailMessage(
        title: 'Could not load this shipment.',
        message: error is ApiException
            ? error.message
            : 'Please check your connection and try again.',
        onRetry: () =>
            ref.invalidate(shipmentDetailsProvider(widget.shipmentId)),
      ),
      data: (snapshot) {
        final shipment = snapshot?.shipmentById(widget.shipmentId);
        if (shipment == null || snapshot == null) {
          return const _DetailMessage(
            title: 'Shipment could not be found.',
            message: 'It may no longer be available.',
          );
        }
        final hasBids = snapshot
            .bidsFor(shipment.id)
            .any((offer) => offer.bid.status == BidStatus.pending);
        if (widget.showBidsOnOpen &&
            !_didAutoOpenBids &&
            shipment.status == ShipmentStatus.awaitingBids &&
            hasBids) {
          _didAutoOpenBids = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              reviewShipmentBids(
                context: context,
                ref: ref,
                shipment: shipment,
                snapshot: snapshot,
              );
            }
          });
        }
        return _ShipmentDetailsContent(shipment: shipment, snapshot: snapshot);
      },
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });
  final String title, message;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xffe5edf7),
    child: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Back',
              onPressed: () => context.canPop()
                  ? context.pop()
                  : context.go(RouteNames.shipments),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xff0c1033),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xff465274)),
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: onRetry,
                        child: const Text('Try again'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

const _ink = Color(0xff0c1033);
const _muted = Color(0xff465274);
const _orange = Color(0xffff4d00);
const _background = Color(0xffe5edf7);

class _ShipmentDetailsContent extends ConsumerWidget {
  const _ShipmentDetailsContent({
    required this.shipment,
    required this.snapshot,
  });
  final Shipment shipment;
  final ShipmentWorkflowSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = shipment.loadPostSnapshot;
    final trucks = post?.trucks.length;
    final bids = snapshot
        .bidsFor(shipment.id)
        .where((b) => b.bid.status == BidStatus.pending)
        .toList();
    final awaiting = shipment.status == ShipmentStatus.awaitingBids;
    final carrier = snapshot.carriersById[shipment.assignedCarrierId];
    return ColoredBox(
      color: _background,
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/shipment_details_mountains.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go('/shipments'),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: _ink,
                            size: 28,
                          ),
                          tooltip: 'Back',
                        ),
                        const SizedBox(height: 65),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Shipment Details',
                            style: TextStyle(
                              fontSize: 27,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              color: _ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              sliver: SliverList.list(
                children: [
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shipment.reference,
                                    style: const TextStyle(
                                      fontSize: 27,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xff090b18),
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    awaiting
                                        ? 'Posted ${formatShipmentDate(shipment.createdAt)}'
                                        : '${shipment.origin.displayName} → ${shipment.destination.displayName}',
                                    style: TextStyle(
                                      color: awaiting ? _muted : _ink,
                                      fontSize: AppTextStyles.bodySize,
                                      fontWeight: awaiting
                                          ? FontWeight.w400
                                          : FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _Status(status: shipment.status),
                          ],
                        ),
                        const _Divider(),
                        Row(
                          children: [
                            Expanded(
                              child: _Metric(
                                icon: Icons.layers_outlined,
                                label: awaiting ? 'Cargo' : null,
                                value: shipment.cargo.displaySummary,
                              ),
                            ),
                            const _VerticalDivider(),
                            Expanded(
                              child: _Metric(
                                icon: Icons.local_shipping_outlined,
                                label: awaiting ? 'Trucks' : null,
                                value: trucks == null
                                    ? shipment.requiredVehicleType
                                    : awaiting
                                    ? '$trucks'
                                    : '$trucks ${trucks == 1 ? 'truck' : 'trucks'}',
                              ),
                            ),
                          ],
                        ),
                        if (awaiting) ...[
                          const _Divider(),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: _orange,
                                size: 25,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  shipment.origin.displayName,
                                  style: _bold,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(Icons.arrow_forward, color: _muted),
                              ),
                              const Icon(
                                Icons.location_on,
                                color: _orange,
                                size: 25,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  shipment.destination.displayName,
                                  style: _bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 17),
                          _ActionButton(
                            label: bids.isEmpty
                                ? 'No bids yet'
                                : 'View bids (${bids.length})',
                            icon: Icons.chat_bubble_outline,
                            onPressed: bids.isEmpty
                                ? null
                                : () => reviewShipmentBids(
                                    context: context,
                                    ref: ref,
                                    shipment: shipment,
                                    snapshot: snapshot,
                                  ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (awaiting) ...[
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Heading(
                            Icons.route_outlined,
                            'Route & Schedule',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Metric(
                                  icon: Icons.calendar_month_outlined,
                                  label: 'Pickup',
                                  value: _date(shipment.pickupAt),
                                  detail:
                                      '${shipment.pickupWindow ?? ''}\n${shipment.origin.displayName}',
                                ),
                              ),
                              const _VerticalDivider(),
                              Expanded(
                                child: _Metric(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Delivery',
                                  value: post?.deliveryDate == null
                                      ? 'Not set'
                                      : _date(post!.deliveryDate!),
                                  detail:
                                      '${post?.deliveryWindow?.label ?? ''}\n${shipment.destination.displayName}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Metric(
                              icon: Icons.layers_outlined,
                              label: 'Cargo',
                              value: shipment.cargo.displaySummary,
                              detail: post?.cargo?.natureAttributes.join(', '),
                            ),
                          ),
                          const _VerticalDivider(),
                          Expanded(
                            child: _Metric(
                              icon: Icons.local_shipping_outlined,
                              label: 'Vehicle requirement',
                              value: trucks == null
                                  ? shipment.requiredVehicleType
                                  : '$trucks ${trucks == 1 ? 'truck' : 'trucks'}',
                              detail: shipment.requiredVehicleType,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _Progress(shipment: shipment),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Heading(Icons.person_outline, 'Carrier'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xffffe8da),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: _orange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      carrier?.displayName ??
                                          'Carrier information unavailable',
                                      style: _bold,
                                    ),
                                    if (carrier != null)
                                      const Text(
                                        'Assigned carrier',
                                        style: TextStyle(color: _muted),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Heading(
                            Icons.layers_outlined,
                            'Shipment Summary',
                          ),
                          const _Divider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Metric(
                                  icon: Icons.layers_outlined,
                                  label: 'Cargo',
                                  value: shipment.cargo.displaySummary,
                                ),
                              ),
                              const _VerticalDivider(),
                              Expanded(
                                child: _Metric(
                                  icon: Icons.local_shipping_outlined,
                                  label: 'Trucks',
                                  value: trucks?.toString() ?? '—',
                                ),
                              ),
                              const _VerticalDivider(),
                              Expanded(
                                child: _Metric(
                                  icon: Icons.route,
                                  label: 'Route',
                                  value:
                                      '${shipment.origin.displayName} → ${shipment.destination.displayName}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (post != null) ...[
                    const SizedBox(height: 12),
                    _TruckPlans(post: post, shipment: shipment),
                  ],
                  const SizedBox(height: 12),
                  _MoreDetails(shipment: shipment, snapshot: snapshot),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _bold = TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w800);
String _date(DateTime value) => '${formatShipmentDate(value)} ${value.year}';

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xfffafbfd),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffd2ddeb)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x160d3157),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Divider(height: 1, color: Color(0xffdce3ec)),
  );
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 42,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: const Color(0xffd0d9e6),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _orange, size: 24),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    this.label,
    required this.value,
    this.detail,
  });
  final IconData icon;
  final String? label;
  final String value;
  final String? detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: _orange, size: 27),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (label != null)
              Text(
                label!,
                style: const TextStyle(
                  color: _ink,
                  fontSize: AppTextStyles.captionSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(value, style: _bold),
            if (detail != null && detail!.trim().isNotEmpty)
              Text(
                detail!.trim(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: AppTextStyles.captionSize,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.status});
  final ShipmentStatus status;
  @override
  Widget build(BuildContext context) {
    final color = status == ShipmentStatus.awaitingBids
        ? const Color(0xff0865f7)
        : status == ShipmentStatus.inTransit
        ? const Color(0xff15977d)
        : shipmentStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == ShipmentStatus.awaitingBids
                ? Icons.hourglass_bottom
                : shipmentStatusIcon(status),
            size: 19,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: AppTextStyles.labelSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: _orange,
        disabledBackgroundColor: const Color(0xffffb998),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward),
        ],
      ),
    ),
  );
}

class _TruckPlans extends StatelessWidget {
  const _TruckPlans({required this.post, required this.shipment});
  final LoadPost post;
  final Shipment shipment;
  @override
  Widget build(BuildContext context) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(
          Icons.local_shipping_outlined,
          'Truck Plans (${post.trucks.length})',
        ),
        const SizedBox(height: 12),
        for (final truck in post.trucks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xfff2f6fc),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(),
                collapsedShape: const RoundedRectangleBorder(),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                iconColor: _orange,
                collapsedIconColor: _muted,
                leading: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffffebe3),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${truck.truckNumber}',
                    style: const TextStyle(
                      color: _orange,
                      fontSize: AppTextStyles.buttonSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                title: Text('Truck Plan ${truck.truckNumber}', style: _bold),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '${shipment.origin.displayName} → ${shipment.destination.displayName}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: AppTextStyles.captionSize,
                    ),
                  ),
                ),
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _DetailChip(
                        Icons.local_shipping_outlined,
                        truck.vehicleType.label,
                      ),
                      _DetailChip(
                        Icons.tire_repair_outlined,
                        truck.wheelClass.label,
                      ),
                      _DetailChip(
                        Icons.scale_outlined,
                        '${_tons(truck.capacityTons)} T capacity',
                      ),
                      if (truck.loadWeightTons != null)
                        _DetailChip(
                          Icons.inventory_2_outlined,
                          '${_tons(truck.loadWeightTons!)} T ${truck.loadWeightIsTotal ? 'total load' : 'starting load (earlier post)'}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      truck.stops.isEmpty
                          ? 'No additional stops'
                          : 'STOPS ON THE WAY',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .4,
                      ),
                    ),
                  ),
                  for (final stop in truck.stops)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _DetailEntry(
                        icon: stop.isPickup
                            ? Icons.add_location_alt_outlined
                            : Icons.location_on_outlined,
                        label: stop.isPickup ? 'Pickup' : 'Drop',
                        value: '${stop.location} · ${_tons(stop.quantity)} T',
                        detail: stop.contact.isEmpty ? null : stop.contact,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

String _tons(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

class _DetailChip extends StatelessWidget {
  const _DetailChip(this.icon, this.text);
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _orange, size: 15),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DetailEntry extends StatelessWidget {
  const _DetailEntry({
    required this.icon,
    required this.label,
    required this.value,
    this.detail,
  });
  final IconData icon;
  final String label, value;
  final String? detail;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xffffebe3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _orange),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: _ink,
                fontSize: AppTextStyles.labelSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (detail != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detail!,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: AppTextStyles.captionSize,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _Progress extends StatelessWidget {
  const _Progress({required this.shipment});
  final Shipment shipment;
  @override
  Widget build(BuildContext context) {
    final step = switch (shipment.status) {
      ShipmentStatus.scheduled => 0,
      ShipmentStatus.inTransit => 2,
      ShipmentStatus.delivered => 3,
      _ => -1,
    };
    final labels = [
      'Shipment accepted',
      'Pickup in progress',
      'In transit',
      'Delivered',
    ];
    final descriptions = [
      'Carrier confirmed and assigned',
      'Pickup is being arranged',
      'On the way to ${shipment.destination.displayName}',
      'Delivery completed',
    ];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading(Icons.route, 'Shipment Progress'),
          const SizedBox(height: 12),
          if (step < 0)
            Text('Current status: ${shipment.status.label}', style: _bold)
          else
            for (var i = 0; i < labels.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 5),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: i == step
                      ? const Color(0xffdfebfd)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      i < step
                          ? Icons.check_circle
                          : i == step
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: i < step
                          ? const Color(0xff21a055)
                          : i == step
                          ? const Color(0xff0865f7)
                          : Colors.grey,
                      size: 25,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(labels[i], style: _bold),
                          Text(
                            i == 3 && i > step
                                ? 'Awaiting delivery'
                                : descriptions[i],
                            style: const TextStyle(
                              color: _muted,
                              fontSize: AppTextStyles.captionSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i == step)
                      const Text(
                        'Current',
                        style: TextStyle(
                          color: Color(0xff0865f7),
                          fontWeight: FontWeight.w700,
                          fontSize: AppTextStyles.captionSize,
                        ),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _MoreDetails extends StatelessWidget {
  const _MoreDetails({required this.shipment, required this.snapshot});
  final Shipment shipment;
  final ShipmentWorkflowSnapshot snapshot;
  @override
  Widget build(BuildContext context) {
    final post = shipment.loadPostSnapshot;
    final events = snapshot.eventsFor(shipment.id).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return _Card(
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(),
        collapsedShape: const RoundedRectangleBorder(),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 6),
        iconColor: _orange,
        collapsedIconColor: _muted,
        title: const _Heading(
          Icons.receipt_long_outlined,
          'More details & history',
        ),
        children: [
          if (shipment.expectedFareNpr != null) ...[
            _DetailEntry(
              icon: Icons.payments_outlined,
              label: 'Expected fare',
              value: formatNpr(shipment.expectedFareNpr!),
            ),
            const SizedBox(height: 14),
          ],
          if (post?.totalConsignmentValueNpr != null) ...[
            _DetailEntry(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Consignment value',
              value: formatNpr(post!.totalConsignmentValueNpr!.toDouble()),
            ),
            const SizedBox(height: 14),
          ],
          if (post?.pickupContact != null) ...[
            _DetailEntry(
              icon: Icons.person_outline,
              label: 'Pickup contact',
              value: post!.pickupContact!.name,
              detail: post.pickupContact!.phone,
            ),
            const SizedBox(height: 14),
          ],
          if (post?.deliveryContact != null) ...[
            _DetailEntry(
              icon: Icons.person_outline,
              label: 'Delivery contact',
              value: post!.deliveryContact!.name,
              detail: post.deliveryContact!.phone,
            ),
            const SizedBox(height: 14),
          ],
          if (shipment.notes != null) ...[
            _DetailEntry(
              icon: Icons.notes,
              label: 'Notes',
              value: shipment.notes!,
            ),
            const SizedBox(height: 14),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xfff2f6fc),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: _orange, size: 18),
                    SizedBox(width: 7),
                    Text(
                      'Shipment history',
                      style: TextStyle(
                        color: _ink,
                        fontSize: AppTextStyles.labelSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (events.isEmpty)
                  const Text(
                    'No activity has been recorded yet.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: AppTextStyles.captionSize,
                    ),
                  )
                else
                  for (final event in events)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Icon(Icons.circle, color: _orange, size: 7),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.summary ?? event.type.name,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: AppTextStyles.captionSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _date(event.occurredAt),
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
