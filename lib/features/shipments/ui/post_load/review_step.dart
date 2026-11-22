part of '../post_load_sections.dart';

mixin _ReviewStep on _PostLoadSectionsBase {
  @override
  Widget review() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Review your load',
        style: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: AppColors.navy,
        ),
      ),
      const SizedBox(height: 3),
      const Text(
        'Check the details below before placing your order.',
        style: TextStyle(
          fontSize: AppTextStyles.bodySize,
          color: Color(0xFF46516A),
        ),
      ),
      const SizedBox(height: 12),
      _reviewCard(
        Icons.alt_route_rounded,
        'Route',
        '${origin.text.isEmpty ? 'Pickup' : origin.text} → ${destination.text.isEmpty ? 'Destination' : destination.text}',
        0,
        [
          _reviewInfo(
            Icons.calendar_today_outlined,
            'Pickup',
            '${dateLabel(pickupDate)} · ${pickupWindow ?? 'Time not set'}',
          ),
          _reviewInfo(
            Icons.event_outlined,
            'Delivery',
            '${dateLabel(deliveryDate)} · ${deliveryWindow ?? 'Time not set'}',
          ),
        ],
      ),
      const SizedBox(height: 8),
      _reviewCard(
        Icons.inventory_2_outlined,
        'Cargo',
        material == 'Other'
            ? (other.text.isEmpty ? 'Other' : other.text)
            : material ?? 'Material not selected',
        1,
        [
          _reviewInfo(
            Icons.scale_outlined,
            'Total cargo weight',
            _totalWeight == null
                ? 'Not entered'
                : '${_totalWeight!} $weightUnit',
          ),
          _reviewInfo(
            Icons.category_outlined,
            'Nature',
            nature.isEmpty ? 'Not selected' : nature.join(', '),
          ),
          _reviewInfo(
            Icons.person_outline,
            'Contacts',
            '${pickupContact ?? 'Pickup not selected'}\n${deliveryContact ?? 'Delivery not selected'}',
          ),
        ],
      ),
      const SizedBox(height: 8),
      _reviewCard(
        Icons.local_shipping_outlined,
        'Trucks',
        '${_journeys.length} ${_journeys.length == 1 ? 'Truck' : 'Trucks'} · $vehicle · $wheel · $capacity T capacity',
        2,
        [
          for (var i = 0; i < _journeys.length; i++)
            _reviewInfo(
              Icons.local_shipping_outlined,
              'Truck ${i + 1}',
              '${_journeys[i].loadWeight.isEmpty ? 'Weight not entered' : '${_journeys[i].loadWeight} $weightUnit'} total load · ${_journeys[i].stops.length} stops',
            ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECE7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppColors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total consignment value',
                    style: TextStyle(
                      fontSize: AppTextStyles.labelSize,
                      color: Color(0xFF46516A),
                    ),
                  ),
                  Text(
                    value.text.isEmpty ? 'Not entered' : 'NPR ${value.text}',
                    style: const TextStyle(
                      fontSize: AppTextStyles.buttonSize,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0EFFF),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF2172BE), size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${_journeys.length} ${_journeys.length == 1 ? 'truck' : 'trucks'} · 1 shipment request.',
                style: const TextStyle(
                  fontSize: AppTextStyles.labelSize,
                  color: AppColors.navy,
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _reviewCard(
    IconData icon,
    String title,
    String headline,
    int step,
    List<Widget> details,
  ) => _routeCard(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDE7),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: AppColors.orange, size: 19),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: AppTextStyles.labelSize,
                      color: Color(0xFF46516A),
                    ),
                  ),
                  Text(
                    headline,
                    style: const TextStyle(
                      fontSize: AppTextStyles.bodySize,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => widget.onStepChanged(step),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.orange,
                      size: 15,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: AppTextStyles.labelSize,
                        color: AppColors.orange,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Wrap(spacing: 12, runSpacing: 8, children: details),
      ],
    ),
  );

  Widget _reviewInfo(IconData icon, String title, String text) => SizedBox(
    width: 135,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF46516A)),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTextStyles.bodySize,
                  color: Color(0xFF46516A),
                ),
              ),
              Text(
                text,
                style: const TextStyle(
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  Widget routeSummary() => _routeCard(
    Row(
      children: [
        const Icon(Icons.location_on_outlined, size: 20, color: AppColors.navy),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                origin.text.isEmpty ? 'Pickup' : origin.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Pickup',
                style: TextStyle(
                  fontSize: AppTextStyles.bodySize,
                  color: Color(0xFF46516A),
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, size: 17, color: Color(0xFF46516A)),
        const SizedBox(width: 8),
        const Icon(Icons.location_on_outlined, size: 20, color: AppColors.navy),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                destination.text.isEmpty ? 'Destination' : destination.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Text(
                'Delivery',
                style: TextStyle(
                  fontSize: AppTextStyles.bodySize,
                  color: Color(0xFF46516A),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => widget.onStepChanged(0),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 5),
          ),
          child: const Text(
            'Edit',
            style: TextStyle(
              fontSize: AppTextStyles.labelSize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget heading(IconData icon, String title, String subtitle) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.orange),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    ],
  );
  Widget label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 15,
      color: AppColors.navy,
    ),
  );
  Widget card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .82),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDDE1EC)),
    ),
    child: child,
  );
  @override
  InputDecoration input(String label, IconData? icon) => InputDecoration(
    labelText: label,
    suffixIcon: icon == null ? null : Icon(icon),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    isDense: true,
  );
}
