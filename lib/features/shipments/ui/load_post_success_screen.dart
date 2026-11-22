import 'package:lod_board/core/theme/app_typography.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../router/route_names.dart';
import '../data/repositories/shipment_repository.dart';
import '../domain/models/shipment.dart';

class LoadPostSuccessScreen extends StatefulWidget {
  const LoadPostSuccessScreen({
    required this.result,
    required this.router,
    required this.refresh,
    super.key,
  });
  final LoadPostSubmission result;
  final GoRouter router;
  final Future<void> Function() refresh;
  @override
  State<LoadPostSuccessScreen> createState() => _LoadPostSuccessScreenState();
}

class _LoadPostSuccessScreenState extends State<LoadPostSuccessScreen> {
  late bool _refreshed = widget.result.snapshotRefreshed;
  bool _loading = false;
  String? _error;
  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.refresh();
      if (mounted) setState(() => _refreshed = true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not refresh. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _home() {
    Navigator.of(context).pop();
    widget.router.go(RouteNames.home);
  }

  void _viewShipment() {
    final id = widget.result.shipments.single.id;
    Navigator.of(context).pop();
    widget.router.go(RouteNames.home);
    unawaited(
      widget.router.push('${RouteNames.shipments}/${Uri.encodeComponent(id)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shipment = widget.result.shipments.single;
    return Scaffold(
      backgroundColor: const Color(0xffedf3ff),
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
                'Load posted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff0b1735),
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                shipment.status == ShipmentStatus.awaitingBids
                    ? 'Your shipment is ready to receive bids.'
                    : 'Your shipment has been posted.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xff53607d),
                  fontSize: AppTextStyles.buttonSize,
                ),
              ),
              if (!_refreshed) ...[
                const SizedBox(height: 12),
                const Text(
                  'Load posted, but shipment data could not be refreshed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff53607d),
                    fontSize: AppTextStyles.labelSize,
                  ),
                ),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                TextButton(
                  onPressed: _loading ? null : _retry,
                  child: Text(_loading ? 'Refreshing...' : 'Retry refresh'),
                ),
              ],
              const SizedBox(height: 20),
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
                              color: Color(0xff0b1735),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffe7f0ff),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(
                            shipment.status.label,
                            style: const TextStyle(
                              color: Color(0xff2468c2),
                              fontSize: AppTextStyles.captionSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: Color(0xffdce4f2)),
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
                              color: Color(0xff0b1735),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          color: Color(0xff53607d),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on, color: AppColors.orange),
                        Expanded(
                          child: Text(
                            shipment.destination.displayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xff0b1735),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: Color(0xffdce4f2)),
                    Row(
                      children: [
                        const Icon(
                          Icons.layers_outlined,
                          color: Color(0xff53607d),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            shipment.cargo.displaySummary,
                            style: const TextStyle(
                              color: Color(0xff53607d),
                              fontSize: AppTextStyles.bodySize,
                            ),
                          ),
                        ),
                        Text(
                          '${widget.result.loadPost.trucks.length} ${widget.result.loadPost.trucks.length == 1 ? 'truck' : 'trucks'}',
                          style: const TextStyle(
                            color: Color(0xff0b1735),
                            fontWeight: FontWeight.w800,
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
                  onPressed: _viewShipment,
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
                  onPressed: _home,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xff53607d),
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
}
