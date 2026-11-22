part of '../post_load_sections.dart';

mixin _RouteStep on _PostLoadSectionsBase {
  @override
  Widget route() => Column(
    children: [
      _routeCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.alt_route_rounded,
                  color: AppColors.navy,
                  size: 25,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Route',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Where do you want to move your cargo?',
                        style: TextStyle(
                          fontSize: AppTextStyles.labelSize,
                          color: const Color(0xFF51586D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 104,
                  child: Column(
                    children: [
                      const SizedBox(height: 13),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.orange, width: 2),
                        ),
                      ),
                      Expanded(
                        child: CustomPaint(
                          size: const Size(2, double.infinity),
                          painter: _RouteDashes(),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        size: 17,
                        color: AppColors.orange,
                      ),
                      const SizedBox(height: 13),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    children: [
                      locationField(origin, 'Pickup location'),
                      const SizedBox(height: 8),
                      locationField(destination, 'Drop location'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      final tmp = origin.text;
                      origin.text = destination.text;
                      destination.text = tmp;
                    }),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.navy,
                      side: const BorderSide(color: Color(0xFFCDD2DE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Icon(Icons.swap_vert_rounded, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Text(
              'Suggested locations',
              style: TextStyle(
                fontSize: AppTextStyles.labelSize,
                color: Color(0xFF46516A),
              ),
            ),
            const SizedBox(height: 7),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final place in locations.take(4))
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: Material(
                        color: const Color(0xFFE9EBF1),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () => setState(() {
                            if (lastLocationWasPickup) {
                              origin.text = place;
                            } else {
                              destination.text = place;
                            }
                            FocusManager.instance.primaryFocus?.unfocus();
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: AppColors.navy,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  place,
                                  style: const TextStyle(
                                    fontSize: AppTextStyles.labelSize,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _routeCard(
        Column(
          children: [
            schedule('Pickup date & time', true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFD9DDE7)),
            ),
            schedule('Delivery date & time', false),
          ],
        ),
      ),
    ],
  );

  @override
  Widget _routeCard(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFAFBFE),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFFD9DFEC)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D14244A),
          blurRadius: 7,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );

  Widget locationField(TextEditingController controller, String label) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final isPickup = identical(controller, origin);
          return RawAutocomplete<String>(
            textEditingController: controller,
            focusNode: isPickup ? originFocus : destinationFocus,
            optionsBuilder: (v) {
              final query = v.text.trim().toLowerCase();
              return query.isEmpty
                  ? locations
                  : locations.where(
                      (place) => place.toLowerCase().contains(query),
                    );
            },
            onSelected: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              setState(() {});
            },
            optionsViewBuilder: (context, onSelected, options) => Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Material(
                  color: Colors.white,
                  elevation: 8,
                  shadowColor: const Color(0x33101B42),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    width: constraints.maxWidth,
                    constraints: const BoxConstraints(maxHeight: 230),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCE1ED)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, index) => const Divider(
                        height: 1,
                        indent: 42,
                        color: Color(0xFFF0F1F5),
                      ),
                      itemBuilder: (context, index) {
                        final place = options.elementAt(index);
                        final highlighted =
                            AutocompleteHighlightedOption.of(context) == index;
                        return Material(
                          color: highlighted
                              ? const Color(0xFFFFF1EC)
                              : Colors.white,
                          child: InkWell(
                            onTap: () => onSelected(place),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFEDE7),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_outlined,
                                      color: AppColors.orange,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      place,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: AppTextStyles.bodySize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.north_west_rounded,
                                    size: 16,
                                    color: Color(0xFF8A92A5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            fieldViewBuilder: (context, field, focus, submit) => SizedBox(
              height: 48,
              child: TextField(
                controller: field,
                focusNode: focus,
                onTap: () => lastLocationWasPickup = isPickup,
                onEditingComplete: () {
                  submit();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    color: Color(0xFF46516A),
                    fontSize: AppTextStyles.labelSize,
                    fontWeight: FontWeight.w400,
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: Color(0xFF46516A),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFBFE),
                  contentPadding: const EdgeInsets.fromLTRB(10, 12, 8, 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC9CEDA)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFC9CEDA)),
                  ),
                ),
              ),
            ),
          );
        },
      );

  Widget schedule(String title, bool pickup) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        pickup ? Icons.local_shipping_outlined : Icons.flag_outlined,
        color: AppColors.orange,
        size: 22,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => selectDate(pickup),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.orange,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Select from calendar',
                        style: TextStyle(
                          fontSize: AppTextStyles.labelSize,
                          color: AppColors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              pickup
                  ? 'When will the load be ready?'
                  : 'When should the load be delivered?',
              style: const TextStyle(
                color: Color(0xFF46516A),
                fontSize: AppTextStyles.captionSize,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _scheduleBox(
                    onTap: () => selectDate(pickup),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateLabel(pickup ? pickupDate : deliveryDate),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: AppTextStyles.labelSize,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: AppColors.navy,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _scheduleBox(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.navy,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: pickup ? pickupWindow : deliveryWindow,
                              onTap: () =>
                                  FocusManager.instance.primaryFocus?.unfocus(),
                              isExpanded: true,
                              isDense: true,
                              hint: const Text(
                                'Time window',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: AppTextStyles.labelSize,
                                  color: AppColors.navy,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 18,
                                color: AppColors.navy,
                              ),
                              style: const TextStyle(
                                fontSize: AppTextStyles.labelSize,
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                              ),
                              items:
                                  [
                                        'Morning',
                                        'Afternoon',
                                        'Evening',
                                        'Full day',
                                      ]
                                      .map(
                                        (v) => DropdownMenuItem(
                                          value: v,
                                          child: Text(
                                            v,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (v) => setState(() {
                                FocusManager.instance.primaryFocus?.unfocus();
                                if (pickup) {
                                  pickupWindow = v;
                                } else {
                                  deliveryWindow = v;
                                }
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget _scheduleBox({
    required Widget child,
    VoidCallback? onTap,
    double height = 37,
  }) => Material(
    color: const Color(0xFFFAFBFE),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFCDD2DE)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    ),
  );
}
