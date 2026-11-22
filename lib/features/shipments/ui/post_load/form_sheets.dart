part of '../post_load_sections.dart';

mixin _FormSheets on _PostLoadSectionsBase {
  @override
  Future<void> addContact(bool pickup) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var savingContact = false;
    String? saveError;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, updateSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                9,
                20,
                MediaQuery.viewInsetsOf(ctx).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E2E8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDE7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Add contact',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  pickup
                                      ? 'Add a person for pickup'
                                      : 'Add a consignee for delivery',
                                  style: const TextStyle(
                                    fontSize: AppTextStyles.captionSize,
                                    color: Color(0xFF697084),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            tooltip: 'Close',
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Full name',
                        style: TextStyle(
                          fontSize: AppTextStyles.labelSize,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'Enter full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter a name.'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Phone number',
                        style: TextStyle(
                          fontSize: AppTextStyles.labelSize,
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Enter phone number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          final digits = (v ?? '').replaceAll(
                            RegExp(r'\D'),
                            '',
                          );
                          return digits.length < 8 || digits.length > 15
                              ? 'Enter a valid phone number.'
                              : null;
                        },
                      ),
                      if (saveError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            saveError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: savingContact
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  updateSheet(() {
                                    savingContact = true;
                                    saveError = null;
                                  });
                                  try {
                                    final saved = await ref
                                        .read(postLoadControllerProvider)
                                        .saveContact(
                                          name.text.trim(),
                                          phone.text.trim(),
                                        );
                                    if (ctx.mounted) Navigator.pop(ctx, saved);
                                  } catch (_) {
                                    if (ctx.mounted) {
                                      updateSheet(() {
                                        savingContact = false;
                                        saveError =
                                            'Could not save contact. Please try again.';
                                      });
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: Text(
                            savingContact ? 'Saving…' : 'Save contact',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      if (!contacts.contains(result)) contacts.add(result);
      if (pickup) {
        pickupContact = result;
      } else {
        deliveryContact = result;
      }
    });
  }

  @override
  Future<void> editJourney(int index) async {
    final stops = _journeys[index].stops.map((stop) => stop.copy()).toList();
    var showPickups = false;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) {
          final visibleStops = stops
              .where((stop) => stop.isPickup == showPickups)
              .toList();
          final maxCapacity = double.tryParse(capacity) ?? 0;
          final totalLoad = _weightInTons(_journeys[index].loadWeight);
          final summary = calculateTruckLoad(
            maxCapacity,
            totalLoad,
            stops.map(
              (stop) => LoadStop(
                isPickup: stop.isPickup,
                location: stop.location,
                quantity: stop.quantity,
                contact: stop.contact,
              ),
            ),
          );
          final valid = summary != null;
          final finalLoad = summary?.finalDelivery;
          String amount(double value) => value == value.roundToDouble()
              ? value.toInt().toString()
              : value
                    .toStringAsFixed(3)
                    .replaceFirst(RegExp(r'0+$'), '')
                    .replaceFirst(RegExp(r'\.$'), '');

          Future<void> editStop({
            _JourneyStop? previous,
            bool editContact = false,
          }) async {
            final saved = await showModalBottomSheet<StopEditorResult>(
              context: sheetContext,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: Colors.transparent,
              builder: (_) => StopEditorSheet(
                isPickup: previous?.isPickup ?? showPickups,
                focusContact: editContact,
                contacts: contacts,
                initial: previous == null
                    ? null
                    : StopEditorResult(
                        location: previous.location,
                        quantity: previous.quantity,
                        contact: previous.contact,
                      ),
              ),
            );
            if (saved != null && sheetContext.mounted) {
              update(() {
                final stop = _JourneyStop(
                  isPickup: previous?.isPickup ?? showPickups,
                  location: saved.location,
                  quantity: saved.quantity,
                  contact: saved.contact,
                );
                if (previous != null) {
                  final pos = stops.indexOf(previous);
                  if (pos >= 0) stops[pos] = stop;
                } else {
                  stops.add(stop);
                }
              });
            }
          }

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * .85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.viewInsetsOf(sheetContext).bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E2E8),
                          borderRadius: BorderRadius.circular(4),
                        ),
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
                                'Stops on the way',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Truck ${index + 1} · ${origin.text.isEmpty ? 'Pickup' : origin.text} → ${destination.text.isEmpty ? 'Final destination' : destination.text}\nWeights are in tonnes; stop sequence is not checked.',
                                style: const TextStyle(
                                  fontSize: AppTextStyles.labelSize,
                                  color: Color(0xFF46516A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE3E5EB)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            tooltip: 'Close',
                            constraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.close, size: 19),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 42,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final pickup in [true, false])
                            Expanded(
                              child: Material(
                                color: pickup == showPickups
                                    ? AppColors.orange
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      update(() => showPickups = pickup),
                                  child: Center(
                                    child: Text(
                                      '${pickup ? 'Extra pickups' : 'Drops'} · ${stops.where((s) => s.isPickup == pickup).length}',
                                      style: TextStyle(
                                        color: pickup == showPickups
                                            ? Colors.white
                                            : AppColors.navy,
                                        fontSize: AppTextStyles.bodySize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < visibleStops.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFFE2E5EC),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 11,
                                            backgroundColor: AppColors.orange,
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize:
                                                    AppTextStyles.labelSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  visibleStops[i].location,
                                                  style: const TextStyle(
                                                    color: AppColors.navy,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  visibleStops[i]
                                                          .contact
                                                          .isEmpty
                                                      ? 'Contact not set'
                                                      : visibleStops[i].contact,
                                                  style: const TextStyle(
                                                    fontSize:
                                                        AppTextStyles.labelSize,
                                                    color: Color(0xFF46516A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F7),
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () => update(() {
                                                    if (visibleStops[i]
                                                            .quantity >
                                                        1) {
                                                      visibleStops[i]
                                                              .quantity -=
                                                          1;
                                                    }
                                                  }),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                      color: AppColors.orange,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${amount(visibleStops[i].quantity)} T',
                                                  style: const TextStyle(
                                                    color: AppColors.navy,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize:
                                                        AppTextStyles.bodySize,
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () => update(
                                                    () =>
                                                        visibleStops[i]
                                                                .quantity +=
                                                            1,
                                                  ),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(8),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: AppColors.orange,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 7),
                                      Row(
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: () => editStop(
                                              previous: visibleStops[i],
                                            ),
                                            icon: const Icon(
                                              Icons.edit_location_alt_outlined,
                                              size: 15,
                                            ),
                                            label: const Text('Change stop'),
                                            style: OutlinedButton.styleFrom(
                                              visualDensity:
                                                  VisualDensity.compact,
                                              foregroundColor: const Color(
                                                0xFF596174,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFE3E5EB),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 9,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontSize:
                                                    AppTextStyles.captionSize,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: OutlinedButton.icon(
                                              onPressed: () => editStop(
                                                previous: visibleStops[i],
                                                editContact: true,
                                              ),
                                              icon: const Icon(
                                                Icons.person_add_alt_1_outlined,
                                                size: 14,
                                              ),
                                              label: Text(
                                                showPickups
                                                    ? 'Pickup contact'
                                                    : 'Consignee',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                foregroundColor: const Color(
                                                  0xFF596174,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFE3E5EB),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                textStyle: const TextStyle(
                                                  fontSize:
                                                      AppTextStyles.captionSize,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () => update(
                                              () =>
                                                  stops.remove(visibleStops[i]),
                                            ),
                                            tooltip: 'Remove stop',
                                            visualDensity:
                                                VisualDensity.compact,
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              size: 18,
                                              color: AppColors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFAF8),
                                border: Border.all(
                                  color: const Color(0xFFF0DCD4),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.flag_outlined,
                                    size: 19,
                                    color: AppColors.orange,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${destination.text.isEmpty ? 'Final destination' : destination.text} · final delivery',
                                          style: const TextStyle(
                                            color: AppColors.navy,
                                            fontSize: AppTextStyles.bodySize,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          deliveryContact ??
                                              'Consignee not selected',
                                          style: const TextStyle(
                                            color: Color(0xFF46516A),
                                            fontSize: AppTextStyles.labelSize,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    finalLoad == null
                                        ? '—'
                                        : '${amount(finalLoad)} T',
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 9),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => editStop(),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(
                                  showPickups ? 'Add pickup' : 'Add stop',
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  foregroundColor: AppColors.orange,
                                  side: const BorderSide(
                                    color: AppColors.orange,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: valid
                                    ? const Color(0xFFE9F7F1)
                                    : const Color(0xFFFFEEE9),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    valid
                                        ? Icons.check_circle_outline
                                        : Icons.error_outline,
                                    color: valid
                                        ? const Color(0xFF26856C)
                                        : AppColors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      valid
                                          ? 'Initial pickup: ${amount(summary.initialPickup)} T. Final delivery: ${amount(summary.finalDelivery)} T. Stop sequence is not checked.'
                                          : 'Enter a positive load within capacity. Extra pickups and extra drops must each be no greater than the total load.',
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
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: valid
                            ? () => Navigator.pop(sheetContext, true)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save load & stops',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || result != true) return;
    setState(() {
      _journeys[index].stops
        ..clear()
        ..addAll(stops);
    });
  }
}
