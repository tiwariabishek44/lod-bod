import 'package:lod_board/core/theme/app_typography.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../router/route_names.dart';
import '../../../shared/widgets/operation_progress_sheet.dart';
import '../../shipments/domain/models/shipment.dart';
import '../../shipments/ui/shipment_presentation.dart';
import '../domain/models/bid.dart';

const _ink = Color(0xff0b1735);
const _muted = Color(0xff53607d);
const _canvas = Color(0xffedf3ff);

Future<void> showBidAcceptance(
  BuildContext context, {
  required Shipment shipment,
  required BidWithCarrier offer,
  required GoRouter router,
  required Future<bool> Function() accept,
  required Future<void> Function() refresh,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xA5101728),
    builder: (dialogContext) =>
        _BidConfirmationDialog(shipment: shipment, offer: offer),
  );
  if (confirmed != true || !context.mounted) return;

  final refreshed = await showOperationProgress<bool>(
    context,
    title: 'Accepting bid',
    message: 'Please wait while we confirm your carrier.',
    progressLabel: 'Confirming bid...',
    icon: Icons.local_shipping_rounded,
    summary: _PreviewSummary(shipment: shipment, offer: offer),
    operation: accept,
  );
  if (!context.mounted) return;
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => _BidAcceptedScreen(
        shipment: shipment,
        offer: offer,
        router: router,
        refreshed: refreshed,
        refresh: refresh,
      ),
    ),
  );
}

class _BidConfirmationDialog extends StatelessWidget {
  const _BidConfirmationDialog({required this.shipment, required this.offer});

  final Shipment shipment;
  final BidWithCarrier offer;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: const Color(0xFFFFFBF9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/bid_confirmation_illustration.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Confirm bid acceptance',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ink,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Are you sure you want to accept this bid? This will assign the shipment to the carrier.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _ConfirmationDetail(
                      icon: Icons.local_shipping_outlined,
                      label: 'Carrier',
                      value: offer.carrier.displayName,
                    ),
                    const SizedBox(height: 12),
                    _ConfirmationDetail(
                      icon: Icons.inventory_2_outlined,
                      label: 'Shipment',
                      value: shipment.reference,
                    ),
                    const SizedBox(height: 12),
                    _ConfirmationDetail(
                      icon: Icons.payments_outlined,
                      label: 'Fare',
                      value: formatNpr(offer.bid.fareNpr),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Confirm bid'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ink,
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: Color(0xFFD6DAE3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmationDetail extends StatelessWidget {
  const _ConfirmationDetail({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.orange, size: 20),
      const SizedBox(width: 10),
      SizedBox(
        width: 68,
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            color: _ink,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.shipment, required this.offer});
  final Shipment shipment;
  final BidWithCarrier offer;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffd9e4f8)),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1019315f),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(
          Icons.inventory_2_outlined,
          color: AppColors.orange,
          size: 23,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            shipment.reference,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: AppTextStyles.captionSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          height: 30,
          width: 1,
          color: const Color(0xffd6dfed),
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        Expanded(
          child: Text(
            offer.carrier.displayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ink,
              fontSize: AppTextStyles.captionSize,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          height: 30,
          width: 1,
          color: const Color(0xffd6dfed),
          margin: const EdgeInsets.symmetric(horizontal: 8),
        ),
        Text(
          formatNpr(offer.bid.fareNpr),
          style: const TextStyle(
            color: _ink,
            fontSize: AppTextStyles.bodySize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _BidAcceptedScreen extends StatelessWidget {
  const _BidAcceptedScreen({
    required this.shipment,
    required this.offer,
    required this.router,
    required this.refreshed,
    required this.refresh,
  });
  final Shipment shipment;
  final BidWithCarrier offer;
  final GoRouter router;
  final bool refreshed;
  final Future<void> Function() refresh;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _canvas,
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
        child: Column(
          children: [
            Image.asset(
              'assets/images/bid_sheet_banner.png',
              width: double.infinity,
              height: 145,
              fit: BoxFit.contain,
            ),
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xff21b44c),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffcff3d9), width: 12),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bid Accepted!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ink,
                fontSize: 31,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'The carrier has been selected for your shipment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: AppTextStyles.buttonSize,
              ),
            ),
            const SizedBox(height: 8),
            if (!refreshed) _RefreshWarning(refresh: refresh),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xffd9e4f8)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.orange,
                        size: 27,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          shipment.reference,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffdff5ed),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Scheduled',
                          style: TextStyle(
                            color: Color(0xff078442),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: AppColors.orange,
                        size: 12,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shipment.origin.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward, color: _muted),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, color: AppColors.orange),
                      Expanded(
                        child: Text(
                          shipment.destination.displayName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xffdce4f2)),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xffe6eeff),
                        child: Text(
                          offer.initials,
                          style: const TextStyle(
                            color: Color(0xff2866b5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.carrier.displayName,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: AppTextStyles.buttonSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xffffb000),
                                  size: 19,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer.carrier.rating.toStringAsFixed(1)} (${offer.carrier.reviewCount} reviews)',
                                  style: const TextStyle(
                                    color: _muted,
                                    fontSize: AppTextStyles.labelSize,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: Color(0xffdce4f2)),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined, color: _muted),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Accepted Fare',
                          style: TextStyle(
                            color: _muted,
                            fontSize: AppTextStyles.bodySize,
                          ),
                        ),
                      ),
                      Text(
                        formatNpr(offer.bid.fareNpr),
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  router.go(RouteNames.home);
                  unawaited(
                    router.push(
                      '${RouteNames.shipments}/${Uri.encodeComponent(shipment.id)}',
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: const Text(
                  'View shipment',
                  style: TextStyle(
                    fontSize: AppTextStyles.sectionTitleSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  router.go(RouteNames.home);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _muted,
                  side: const BorderSide(color: Color(0xffa6b4ce)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.home_outlined),
                label: const Text(
                  'Back to home',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RefreshWarning extends StatefulWidget {
  const _RefreshWarning({required this.refresh});
  final Future<void> Function() refresh;
  @override
  State<_RefreshWarning> createState() => _RefreshWarningState();
}

class _RefreshWarningState extends State<_RefreshWarning> {
  bool _loading = false;
  bool _resolved = false;
  String? _error;
  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.refresh();
      if (mounted) setState(() => _resolved = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not refresh. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 10),
        const Text(
          'Bid accepted, but shipment data could not be refreshed.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: AppTextStyles.labelSize),
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
        TextButton(
          onPressed: _loading ? null : _retry,
          child: Text(_loading ? 'Refreshing...' : 'Retry refresh'),
        ),
      ],
    );
  }
}
