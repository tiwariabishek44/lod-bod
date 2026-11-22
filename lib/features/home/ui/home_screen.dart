import 'package:lod_board/core/theme/app_typography.dart';
import '../../shipments/ui/open_post_load.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../../../shared/widgets/shipment_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../bids/domain/models/bid.dart';
import '../../bids/ui/bid_review_flow.dart';
import '../../shipments/domain/models/shipment.dart';
import '../../shipments/domain/shipment_rules.dart';
import '../../shipments/providers/shipment_providers.dart';
import 'widgets/home_dashboard_widgets.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    required this.onPostLoad,
    required this.onOpenAccount,
    required this.onSeeShipments,
    required this.onReviewBids,
    required this.onOpenShipment,
    required this.recentShipments,
    this.bidCounts = const {},
    required this.needsReviewShipments,
    required this.mobileRequestsUsed,
    required this.mobileRequestLimit,
    required this.activeShipmentsCount,
    required this.biddingShipmentsCount,
    required this.completedShipmentsCount,
    required this.displayName,
    super.key,
  });

  final VoidCallback onPostLoad;
  final VoidCallback onOpenAccount;
  final VoidCallback onSeeShipments;
  final ValueChanged<Shipment> onReviewBids;
  final ValueChanged<Shipment> onOpenShipment;
  final List<Shipment> recentShipments;
  final Map<String, int> bidCounts;
  final List<Shipment> needsReviewShipments;
  final int mobileRequestsUsed;
  final int mobileRequestLimit;
  final int activeShipmentsCount;
  final int biddingShipmentsCount;
  final int completedShipmentsCount;
  final String displayName;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.loginBackground,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pageHorizontal,
            AppSpacing.height(10),
            AppSpacing.pageHorizontal,
            AppSpacing.height(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(onOpenAccount: widget.onOpenAccount),
              SizedBox(height: AppSpacing.height(15)),
              Text(
                'Good morning,',
                style: TextStyle(
                  color: Color(0xFF687184),
                  fontSize: 20,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                widget.displayName,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.4,
                ),
              ),
              SizedBox(height: AppSpacing.height(15)),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 3,
                  child: Image.asset(
                    'assets/images/home/home_hero_banner.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel:
                        'Post your loads and get competitive bids instantly',
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.height(16)),
              HomeLoadQuotaCard(
                onPostLoad: widget.onPostLoad,
                mobileRequestsUsed: widget.mobileRequestsUsed,
                mobileRequestLimit: widget.mobileRequestLimit,
              ),
              SizedBox(height: AppSpacing.height(14)),
              HomeStatsSummary(
                activeCount: widget.activeShipmentsCount,
                biddingCount: widget.biddingShipmentsCount,
                completedCount: widget.completedShipmentsCount,
              ),
              SizedBox(height: AppSpacing.sectionGap),
              const HomeSectionHeader(title: 'Needs your action'),
              SizedBox(height: AppSpacing.itemGap),
              if (widget.needsReviewShipments.isEmpty)
                const HomeNoNeedsActionCard()
              else
                for (final shipment in widget.needsReviewShipments) ...[
                  HomeNeedsActionCard(
                    shipment: shipment,
                    bidCount: widget.bidCounts[shipment.id] ?? 0,
                    onTap: () => widget.onReviewBids(shipment),
                  ),
                  if (shipment != widget.needsReviewShipments.last)
                    SizedBox(height: AppSpacing.itemGap),
                ],
              SizedBox(height: AppSpacing.sectionGap),
              HomeSectionHeader(
                title: 'Recent shipments',
                onSeeAll: widget.onSeeShipments,
              ),
              SizedBox(height: AppSpacing.itemGap),
              if (widget.recentShipments.isEmpty)
                const HomeNoNeedsActionCard(
                  message: 'No shipments yet. Post a load to get started.',
                )
              else
                for (final shipment in widget.recentShipments.take(2)) ...[
                  ShipmentCard(
                    shipment: ShipmentDataFromDomain.fromShipment(
                      shipment,
                      bidCount: widget.bidCounts[shipment.id] ?? 0,
                    ),
                    onTap: () => widget.onOpenShipment(shipment),
                  ),
                  if (shipment != widget.recentShipments.take(2).last)
                    SizedBox(height: AppSpacing.itemGap),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar({required VoidCallback onOpenAccount}) {
    return Row(
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(-6, 0),
            child: Image.asset(
              'assets/images/auth/lodbod_home_logo.png',
              height: AppSpacing.height(58),
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.width(12)),
        const HomeNotificationButton(),
        SizedBox(width: AppSpacing.width(12)),
        Semantics(
          button: true,
          label: 'Open account',
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onOpenAccount,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: AppSpacing.width(25),
                backgroundColor: AppColors.orange,
                child: Text(
                  'AS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTextStyles.buttonSize,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workflow = ref.watch(shipmentWorkflowProvider);
    final user = ref.watch(authStateProvider).user;
    return workflow.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your dashboard.'),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () =>
                  ref.read(shipmentWorkflowProvider.notifier).refresh(),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
      data: (snapshot) {
        final shipmentsNeedingReview = snapshot.awaitingBidShipments
            .where(
              (shipment) => snapshot
                  .bidsFor(shipment.id)
                  .any((offer) => offer.bid.status == BidStatus.pending),
            )
            .toList();
        final activeCount = snapshot.shipments
            .where(
              (shipment) =>
                  shipment.status == ShipmentStatus.scheduled ||
                  shipment.status == ShipmentStatus.inTransit,
            )
            .length;
        final biddingCount = snapshot.shipments
            .where((shipment) => shipment.status == ShipmentStatus.awaitingBids)
            .length;
        final completedCount = snapshot.shipments
            .where((shipment) => shipment.status == ShipmentStatus.delivered)
            .length;
        return HomeDashboardScreen(
          onPostLoad: () => openPostLoad(context, ref),
          onOpenAccount: () => context.go(RouteNames.profile),
          onSeeShipments: () => context.go(RouteNames.shipments),
          onReviewBids: (shipment) async {
            await reviewShipmentBids(
              context: context,
              ref: ref,
              shipment: shipment,
              snapshot: snapshot,
            );
          },
          onOpenShipment: (shipment) =>
              context.push('${RouteNames.shipments}/${shipment.id}'),
          recentShipments: snapshot.recentShipments,
          bidCounts: {
            for (final shipment in snapshot.recentShipments)
              shipment.id: snapshot
                  .bidsFor(shipment.id)
                  .where((offer) => offer.bid.status == BidStatus.pending)
                  .length,
          },
          needsReviewShipments: shipmentsNeedingReview,
          mobileRequestsUsed: snapshot.mobileRequestsUsed,
          mobileRequestLimit: ShipmentRules.mobileRequestLimit,
          activeShipmentsCount: activeCount,
          biddingShipmentsCount: biddingCount,
          completedShipmentsCount: completedCount,
          displayName: user?.name ?? 'Aarav Shrestha',
        );
      },
    );
  }
}
