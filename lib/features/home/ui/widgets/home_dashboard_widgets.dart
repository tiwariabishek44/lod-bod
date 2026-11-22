import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shipments/domain/models/shipment.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notifications',
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFE9E8EE)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10151C33),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.ink,
              size: 28,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeLoadQuotaCard extends StatelessWidget {
  const HomeLoadQuotaCard({
    super.key,
    required this.onPostLoad,
    required this.mobileRequestsUsed,
    required this.mobileRequestLimit,
  });

  final VoidCallback onPostLoad;
  final int mobileRequestsUsed;
  final int mobileRequestLimit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFA589)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A19264B),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ship something new',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: AppTextStyles.sectionTitleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Color(0xFF697286),
                      fontSize: AppTextStyles.labelSize,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      TextSpan(text: 'Mobile requests used: '),
                      TextSpan(
                        text: '$mobileRequestsUsed of $mobileRequestLimit',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: SizedBox(
                    height: 5,
                    child: LinearProgressIndicator(
                      value: (mobileRequestsUsed / mobileRequestLimit)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                      backgroundColor: Color(0xFFFFE5DC),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onPostLoad,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Post Load',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTextStyles.bodySize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeStatsSummary extends StatelessWidget {
  const HomeStatsSummary({
    required this.activeCount,
    required this.biddingCount,
    required this.completedCount,
    super.key,
  });

  final int activeCount;
  final int biddingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E6EE)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0818274D),
            blurRadius: 13,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              count: activeCount,
              label: 'Active',
              icon: Icons.inventory_2_outlined,
              tint: Color(0xFFFFECE5),
              iconColor: AppColors.orange,
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              count: biddingCount,
              label: 'Bidding',
              icon: Icons.gavel_rounded,
              tint: Color(0xFFE7F0FF),
              iconColor: Color(0xFF2471D7),
            ),
          ),
          _StatDivider(),
          Expanded(
            child: _StatItem(
              count: completedCount,
              label: 'Completed',
              icon: Icons.check_circle_outline_rounded,
              tint: Color(0xFFE5F6EE),
              iconColor: Color(0xFF16A665),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.count,
    required this.label,
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color tint;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF687184),
                  fontSize: AppTextStyles.captionSize,
                  height: 1,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: const Color(0xFFD9DEEA),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
        ),
        if (onSeeAll != null)
          InkWell(
            onTap: onSeeAll,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: AppTextStyles.bodySize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.orange,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class HomeNeedsActionCard extends StatelessWidget {
  const HomeNeedsActionCard({
    super.key,
    required this.shipment,
    required this.bidCount,
    required this.onTap,
    this.isPreview = false,
  });

  final Shipment shipment;
  final bool isPreview;
  final int bidCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF9CCAFF), width: 1.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F0FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  color: Color(0xFF2471D7),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${isPreview ? 'Example: ' : ''}$bidCount ${bidCount == 1 ? 'bid' : 'bids'} on ${shipment.reference}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: AppTextStyles.sectionTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${shipment.origin.displayName} → ${shipment.destination.displayName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFF626D85),
                        fontSize: AppTextStyles.bodySize,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.ink,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeNoNeedsActionCard extends StatelessWidget {
  const HomeNoNeedsActionCard({
    super.key,
    this.message = 'No bids need your review right now.',
  });

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE3E5ED)),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: Color(0xFF168B58),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: AppTextStyles.bodySize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
