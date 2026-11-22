part of '../post_load_sections.dart';

mixin _TrucksStep on _PostLoadSectionsBase {
  @override
  Widget trucks() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _routeCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.local_shipping_outlined, 'Truck configuration'),
            const SizedBox(height: 3),
            const Text(
              'Same vehicle requirements for all trucks.',
              style: TextStyle(
                fontSize: AppTextStyles.labelSize,
                color: Color(0xFF46516A),
              ),
            ),
            const SizedBox(height: 12),
            _fieldHeading('Vehicle requirement', ''),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final v in [
                    'Open',
                    'Closed',
                    'Trailer',
                    'Container',
                    'Tipper',
                    'Tanker',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _vehicleOption(v),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wheel size',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          for (final v in ['10W', '12W', '14W'])
                            _option(
                              v,
                              wheel == v,
                              () => setState(() => wheel = v),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Capacity (per truck)',
                        style: TextStyle(
                          fontSize: AppTextStyles.bodySize,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: capacity,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        onChanged: (text) =>
                            setState(() => _updateCapacity(text)),
                        decoration: const InputDecoration(
                          hintText: 'Enter capacity',
                          suffixText: 'T',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the required capacity for each truck in tonnes.',
              style: TextStyle(fontSize: 11, color: Color(0xFF596174)),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of trucks',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                _scheduleBox(
                  height: 41,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: _journeys.length > 1
                            ? () => setState(() => _journeys.removeLast())
                            : null,
                        child: const Icon(Icons.remove, size: 20),
                      ),
                      Text(
                        '${_journeys.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      InkWell(
                        onTap: _journeys.length < 10
                            ? () => setState(
                                () => _journeys.add(
                                  _Journey()..loadWeight = _capacityAsWeight(),
                                ),
                              )
                            : null,
                        child: const Icon(
                          Icons.add,
                          size: 20,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total consignment value',
                  style: TextStyle(
                    fontSize: AppTextStyles.bodySize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                _scheduleBox(
                  height: 41,
                  child: Row(
                    children: [
                      const Text(
                        'NPR',
                        style: TextStyle(
                          fontSize: AppTextStyles.labelSize,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: value,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: AppTextStyles.bodySize,
                            color: AppColors.navy,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                            hintText: 'Enter value',
                          ),
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
      const SizedBox(height: 15),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.navy,
            size: 22,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Truck journeys (individual)',
                  style: TextStyle(
                    fontSize: AppTextStyles.sectionTitleSize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Each truck can have its own load and route (stops), while sharing the above vehicle configuration.',
                  style: TextStyle(
                    fontSize: AppTextStyles.captionSize,
                    color: Color(0xFF46516A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _journeys.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _journeyCard(i),
        ),
    ],
  );

  Widget _journeyCard(int index) {
    final journey = _journeys[index];
    final summary = calculateTruckLoad(
      double.tryParse(capacity) ?? 0,
      _weightInTons(journey.loadWeight),
      journey.stops.map(
        (stop) => LoadStop(
          isPickup: stop.isPickup,
          location: stop.location,
          quantity: stop.quantity,
          contact: stop.contact,
        ),
      ),
    );
    final starting = summary?.initialPickup;
    final label = starting == null
        ? '—'
        : '${starting == starting.roundToDouble() ? starting.toInt() : starting} T';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE7E9EF)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping_outlined,
            color: AppColors.navy,
            size: 20,
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 2,
            child: Text(
              'Truck ${index + 1}',
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: AppTextStyles.labelSize,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(width: 1, height: 40, color: const Color(0xFFD5DAE4)),
          const SizedBox(width: 7),
          const Icon(
            Icons.inventory_2_outlined,
            size: 19,
            color: Color(0xFF596174),
          ),
          const SizedBox(width: 5),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Starting load',
                  maxLines: 1,
                  style: TextStyle(fontSize: 11, color: Color(0xFF596174)),
                ),
                Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: AppTextStyles.bodySize,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 4,
            child: OutlinedButton(
              onPressed: () => editJourney(index),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                minimumSize: const Size(0, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_location_alt_outlined, size: 16),
                    SizedBox(width: 3),
                    Text(
                      'Set load & stops',
                      style: TextStyle(
                        fontSize: AppTextStyles.captionSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 17),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vehicleOption(String v) => InkWell(
    onTap: () => setState(() => vehicle = v),
    borderRadius: BorderRadius.circular(9),
    child: Container(
      width: 87,
      height: 72,
      decoration: BoxDecoration(
        color: vehicle == v ? const Color(0xFFFFF1EC) : Colors.white,
        border: Border.all(
          color: vehicle == v ? AppColors.orange : const Color(0xFFD6DBE5),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VehicleTypeIcon(type: v),
          const SizedBox(height: 3),
          Text(
            v,
            style: const TextStyle(
              fontSize: AppTextStyles.labelSize,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    ),
  );
}
