import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../router/route_names.dart';
import '../../../shared/widgets/shipment_card.dart';
import '../../bids/domain/models/bid.dart';
import '../data/repositories/shipment_repository.dart';
import '../domain/models/shipment.dart';
import '../providers/shipment_providers.dart';
import 'widgets/shipment_widgets.dart';
import 'widgets/more_filters_drawer.dart';

class ShipmentsScreen extends ConsumerStatefulWidget {
  const ShipmentsScreen({super.key});

  @override
  ConsumerState<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends ConsumerState<ShipmentsScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Shipment> _visibleShipments(List<Shipment> allShipments) {
    final query = _searchController.text.trim().toLowerCase();
    return allShipments.where((shipment) {
      final matchesFilter =
          _selectedFilter == 'All' ||
          (_selectedFilter == 'Bidding'
              ? shipment.status == ShipmentStatus.awaitingBids
              : shipment.status.label.toLowerCase() ==
                    _selectedFilter.toLowerCase());
      final matchesSearch =
          query.isEmpty ||
          '${shipment.reference} ${shipment.origin.displayName} ${shipment.destination.displayName} ${shipment.cargo.displaySummary} ${shipment.status.label}'
              .toLowerCase()
              .contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int _countForFilter(String filter, List<Shipment> shipments) =>
      switch (filter) {
        'All' => shipments.length,
        'Bidding' =>
          shipments
              .where(
                (shipment) => shipment.status == ShipmentStatus.awaitingBids,
              )
              .length,
        'In Transit' =>
          shipments
              .where((shipment) => shipment.status == ShipmentStatus.inTransit)
              .length,
        'Scheduled' =>
          shipments
              .where((shipment) => shipment.status == ShipmentStatus.scheduled)
              .length,
        'Delivered' =>
          shipments
              .where((shipment) => shipment.status == ShipmentStatus.delivered)
              .length,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(shipmentWorkflowProvider);
    return workflow.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load shipments.'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    ref.read(shipmentWorkflowProvider.notifier).refresh(),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
      data: (snapshot) => _buildContent(context, snapshot),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ShipmentWorkflowSnapshot snapshot,
  ) {
    final shipments = _visibleShipments(snapshot.shipments);
    final filters = [
      for (final label in shipmentFilterLabels)
        ShipmentFilter(label, _countForFilter(label, snapshot.shipments)),
    ];
    final screenSize = MediaQuery.sizeOf(context);
    final bannerHeight = screenSize.width * (548 / 2040) * 1.152;
    const logoHeight = 58.0;
    final logoTopPadding = AppSpacing.height(10);
    final logoBottomPadding = AppSpacing.height(6);
    // Keep the reserved header height in sync with the row's actual contents.
    // The logo is fixed-height, so scaling a combined 74px value can leave the
    // Column a few pixels taller on shorter screens and trigger a Flex overflow.
    final logoRowHeight = logoTopPadding + logoHeight + logoBottomPadding;
    const searchHeight = 48.0;
    final filtersGap = AppSpacing.height(12);
    const filtersHeight = 44.0;
    final listGap = AppSpacing.height(12);
    final headerContentHeight = logoRowHeight + bannerHeight;
    final controlsHeight = searchHeight + filtersGap + filtersHeight;
    final controlsOverlap =
        (searchHeight + filtersGap + filtersHeight + listGap) * .10;
    final topSectionHeight =
        headerContentHeight - controlsOverlap + controlsHeight + listGap;
    return ColoredBox(
      color: AppColors.loginBackground,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: topSectionHeight,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: headerContentHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.loginBackground,
                            Color(0xFFFCF4F2),
                            Color(0xFFF7F2FB),
                          ],
                          stops: [0, .58, 1],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              AppSpacing.pageHorizontal,
                              logoTopPadding,
                              AppSpacing.pageHorizontal,
                              logoBottomPadding,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(-6, 0),
                                    child: Image.asset(
                                      'assets/images/auth/lodbod_home_logo.png',
                                      height: logoHeight,
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const ShipmentNotificationsButton(),
                                const SizedBox(width: 12),
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: AppColors.orange,
                                  child: Text(
                                    'AS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppTypography.size(14),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Image.asset(
                            'assets/images/auth/shipments_header.png',
                            width: double.infinity,
                            height: bannerHeight,
                            fit: BoxFit.fill,
                            alignment: Alignment.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: headerContentHeight - controlsOverlap,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.pageHorizontal,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: searchHeight,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFE5E7ED),
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0818274D),
                                        blurRadius: 9,
                                        offset: Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (_) => setState(() {}),
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 15,
                                    ),
                                    decoration: InputDecoration(
                                      hintText:
                                          'Search reference, route, cargo...',
                                      hintStyle: TextStyle(
                                        color: Color(0xFF777D8B),
                                        fontSize: AppTextStyles.bodySize,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.search_rounded,
                                        color: Color(0xFF596174),
                                        size: 23,
                                      ),
                                      prefixIconConstraints: BoxConstraints(
                                        minWidth: 42,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Tooltip(
                                message: 'More filters',
                                child: ShipmentHeaderButton(
                                  icon: Icons.tune_rounded,
                                  onPressed: () =>
                                      showMoreFiltersDrawer(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: filtersGap),
                        SizedBox(
                          height: filtersHeight,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.pageHorizontal,
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: filters.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 7),
                            itemBuilder: (context, index) {
                              final filter = filters[index];
                              return ShipmentFilterChip(
                                filter: filter,
                                selected: _selectedFilter == filter.label,
                                onTap: () => setState(
                                  () => _selectedFilter = filter.label,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: shipments.isEmpty
                  ? const EmptyShipments()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.pageHorizontal,
                        0,
                        AppSpacing.pageHorizontal,
                        AppSpacing.height(12),
                      ),
                      itemCount: shipments.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final shipment = shipments[index];
                        final bids = snapshot
                            .bidsFor(shipment.id)
                            .where(
                              (offer) => offer.bid.status == BidStatus.pending,
                            )
                            .toList();
                        return ShipmentCard(
                          shipment: ShipmentDataFromDomain.fromShipment(
                            shipment,
                            bidCount: bids.length,
                          ),
                          onTap: () => context.push(
                            '${RouteNames.shipments}/${shipment.id}',
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
