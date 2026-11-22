part of '../post_load_sections.dart';

mixin _CargoStep on _PostLoadSectionsBase {
  @override
  Widget cargo() => Column(
    children: [
      routeSummary(),
      const SizedBox(height: 10),
      _routeCard(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(Icons.inventory_2_outlined, 'Cargo & contacts'),
            const SizedBox(height: 14),
            _fieldHeading(
              'Material / Goods',
              'Select the primary material',
              cargo: true,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in materials)
                  _option(
                    v,
                    material == v,
                    () => setState(() => material = v),
                    icon: switch (v) {
                      'Cement' => Icons.inventory_2_outlined,
                      'Steel' => Icons.layers_outlined,
                      'Electronics' => Icons.desktop_windows_outlined,
                      _ => null,
                    },
                    cargo: true,
                  ),
              ],
            ),
            if (material == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextField(
                  controller: other,
                  onChanged: (_) => setState(() {}),
                  decoration: input('Describe the material', null),
                ),
              ),
            const SizedBox(height: 16),
            _fieldHeading(
              'Nature of cargo',
              'Select all that apply',
              cargo: true,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final v in characteristics)
                  _option(
                    v,
                    nature.contains(v),
                    () => setState(() {
                      if (!nature.add(v)) nature.remove(v);
                    }),
                    icon: switch (v) {
                      'Stackable' => Icons.layers_outlined,
                      'Fragile' => Icons.wine_bar_outlined,
                      'Hazardous' => Icons.warning_amber_rounded,
                      _ => null,
                    },
                    cargo: true,
                  ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFD9DDE7)),
            ),
            contactField('Pickup contact', true),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: Color(0xFFD9DDE7)),
            ),
            contactField('Delivery consignee', false),
          ],
        ),
      ),
    ],
  );

  @override
  Widget _sectionTitle(IconData icon, String title) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFFFEDE7),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: AppColors.orange, size: 20),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
      ),
    ],
  );

  @override
  Widget _fieldHeading(String title, String helper, {bool cargo = false}) =>
      Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: cargo ? 15 : 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          Flexible(
            child: Text(
              helper,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: cargo ? 11 : 10,
                color: const Color(0xFF596174),
              ),
            ),
          ),
        ],
      );

  @override
  Widget _option(
    String text,
    bool selected,
    VoidCallback onTap, {
    IconData? icon,
    bool cargo = false,
  }) => Material(
    color: selected ? AppColors.orange : Colors.white,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: cargo ? 11 : 9,
          vertical: cargo ? 11 : 9,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.orange : const Color(0xFFCFD6E2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: cargo ? 19 : 17,
                color: selected ? Colors.white : AppColors.navy,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: AppTextStyles.labelSize,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget contactField(String title, bool pickup) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F1F5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(
          pickup ? Icons.person_outline : Icons.local_shipping_outlined,
          size: 19,
          color: AppColors.navy,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            Text(
              pickup
                  ? 'Person at loading location'
                  : 'Receiving person at delivery location',
              style: const TextStyle(
                fontSize: AppTextStyles.captionSize,
                color: Color(0xFF596174),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _scheduleBox(
                    height: 44,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: pickup ? pickupContact : deliveryContact,
                        isExpanded: true,
                        isDense: true,
                        hint: Text(
                          pickup
                              ? 'Select pickup contact'
                              : 'Select delivery consignee',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: AppTextStyles.labelSize,
                            color: Color(0xFF596174),
                          ),
                        ),
                        selectedItemBuilder: (context) => contacts
                            .map(
                              (contact) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _contact(contact)?.name ?? contact,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppTextStyles.labelSize,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        items: contacts
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(
                                  v,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: AppTextStyles.labelSize,
                                    color: AppColors.navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          if (pickup) {
                            pickupContact = v;
                          } else {
                            deliveryContact = v;
                          }
                        }),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => addContact(pickup),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: const BorderSide(color: AppColors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '+ New',
                      style: TextStyle(
                        fontSize: AppTextStyles.labelSize,
                        fontWeight: FontWeight.w700,
                      ),
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
}
