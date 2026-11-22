import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_providers.dart';
import '../domain/models/load_post.dart';
import '../data/repositories/shipment_repository.dart';
import '../providers/post_load_controller.dart';

import '../../../core/theme/app_colors.dart';
import '../../../router/route_names.dart';
import 'vehicle_type_icon.dart';
import 'stop_editor_sheet.dart';
import 'load_post_success_screen.dart';
import '../../../shared/widgets/operation_progress_sheet.dart';

part 'post_load/route_step.dart';
part 'post_load/cargo_step.dart';
part 'post_load/trucks_step.dart';
part 'post_load/review_step.dart';
part 'post_load/form_sheets.dart';

/// Form state and actions for the load-post workflow.
class PostLoadSections extends ConsumerStatefulWidget {
  const PostLoadSections({
    super.key,
    required this.step,
    required this.onStepChanged,
    required this.isContract,
    required this.onTypeRestored,
    required this.onCloseConfirmed,
    this.resumeDraft = false,
  });
  final int step;
  final ValueChanged<int> onStepChanged;
  final bool isContract;
  final ValueChanged<bool> onTypeRestored;
  final VoidCallback onCloseConfirmed;
  final bool resumeDraft;

  @override
  ConsumerState<PostLoadSections> createState() => PostLoadSectionsState();
}

class _Journey {
  String loadWeight = '';
  bool loadWeightAutoFilled = true;
  int weightRevision = 0;
  final List<_JourneyStop> stops = [];
}

class _JourneyStop {
  _JourneyStop({
    required this.isPickup,
    required this.location,
    required this.quantity,
    this.contact = '',
  });
  final bool isPickup;
  final String location;
  double quantity;
  final String contact;
  _JourneyStop copy() => _JourneyStop(
    isPickup: isPickup,
    location: location,
    quantity: quantity,
    contact: contact,
  );
}

class PostLoadSectionsState extends _PostLoadSectionsBase
    with _RouteStep, _CargoStep, _TrucksStep, _ReviewStep, _FormSheets {}

abstract class _PostLoadSectionsBase extends ConsumerState<PostLoadSections> {
  Widget route();
  Widget cargo();
  Widget trucks();
  Widget review();
  Widget _routeCard(Widget child);
  Widget _sectionTitle(IconData icon, String title);
  // The named options are used by the step mixins.
  // ignore: unused_element_parameter
  Widget _fieldHeading(String title, String helper, {bool cargo = false});
  // ignore: unused_element_parameter
  Widget _option(
    String text,
    bool selected,
    VoidCallback onTap, {
    // ignore: unused_element_parameter
    IconData? icon,
    // ignore: unused_element_parameter
    bool cargo = false,
  });
  Future<void> addContact(bool pickup);
  Future<void> editJourney(int index);
  Widget routeSummary();
  // ignore: unused_element_parameter
  Widget _scheduleBox({
    required Widget child,
    // ignore: unused_element_parameter
    VoidCallback? onTap,
    double height = 37,
  });
  InputDecoration input(String label, IconData? icon);
  final origin = TextEditingController();
  final destination = TextEditingController();
  final originFocus = FocusNode();
  final destinationFocus = FocusNode();
  bool lastLocationWasPickup = true;
  final other = TextEditingController();
  final value = TextEditingController();
  final List<_Journey> _journeys = [_Journey()];
  final List<String> contacts = [];
  List<String> locations = [];
  List<String> materials = [];
  List<String> characteristics = [];
  final Set<String> nature = {};
  String? material, pickupContact, deliveryContact;

  String vehicle = 'Open', wheel = '12W', capacity = '';
  String weightUnit = 'T';
  String? pickupWindow, deliveryWindow;
  DateTime? pickupDate, deliveryDate;

  late String postId;
  late DateTime createdAt;
  bool busy = false;
  bool restoring = true;
  bool restoreFailed = false;

  @override
  void initState() {
    super.initState();
    createdAt = DateTime.now();
    postId = 'post-${createdAt.microsecondsSinceEpoch}';
    Future.microtask(_restoreDraft);
  }

  LoadContactRef? _contact(String? text) {
    if (text == null) return null;
    final parts = text.split(' · ');
    return LoadContactRef(
      name: parts.first,
      phone: parts.length > 1 ? parts.last : '',
    );
  }

  LoadTimeWindow? _window(String? value) => switch (value) {
    'Morning' => LoadTimeWindow.morning,
    'Afternoon' => LoadTimeWindow.afternoon,
    'Evening' => LoadTimeWindow.evening,
    'Full day' => LoadTimeWindow.fullDay,
    _ => null,
  };

  String _capacityAsWeight() {
    final amount = double.tryParse(capacity);
    if (amount == null || !amount.isFinite || amount <= 0) return '';
    final converted = weightUnit == 'kg' ? amount * 1000 : amount;
    return converted == converted.roundToDouble()
        ? converted.toInt().toString()
        : converted.toString();
  }

  void _updateCapacity(String value) {
    capacity = value;
    for (final journey in _journeys) {
      if (journey.loadWeightAutoFilled) {
        journey.loadWeight = _capacityAsWeight();
        journey.weightRevision++;
      }
    }
  }

  double? _weightInTons(String text) {
    final amount = double.tryParse(text);
    if (amount == null || !amount.isFinite) return null;
    return weightUnit == 'kg' ? amount / 1000 : amount;
  }

  double? get _totalWeight {
    final values = _journeys
        .map((journey) => double.tryParse(journey.loadWeight))
        .toList();
    if (values.any((value) => value == null || !value.isFinite)) return null;
    return values.fold<double>(0, (total, value) => total + value!);
  }

  LoadPost _buildPost() {
    final user = ref.read(authStateProvider).user;
    final vehicleType = TruckVehicleType.values.firstWhere(
      (item) => item.name.toLowerCase() == vehicle.toLowerCase(),
    );
    final wheelType = switch (wheel) {
      '10W' => TruckWheelClass.tenW,
      '14W' => TruckWheelClass.fourteenW,
      _ => TruckWheelClass.twelveW,
    };
    return LoadPost(
      id: postId,
      shipperCompanyId: 'demo-company',
      createdByUserId: user?.id,
      loadType: widget.isContract ? LoadType.contract : LoadType.normal,
      status: LoadPostStatus.draft,
      routeOrigin: origin.text.trim().isEmpty
          ? null
          : LoadLocation(name: origin.text.trim()),
      routeDestination: destination.text.trim().isEmpty
          ? null
          : LoadLocation(name: destination.text.trim()),
      pickupDate: pickupDate,
      pickupWindow: _window(pickupWindow),
      deliveryDate: deliveryDate,
      deliveryWindow: _window(deliveryWindow),
      cargo: LoadCargoDetails(
        material: material ?? '',
        natureAttributes: nature.toList(),
        description: material == 'Other' ? other.text.trim() : null,
        weight: _totalWeight,
        weightUnit: weightUnit,
      ),
      pickupContact: _contact(pickupContact),
      deliveryContact: _contact(deliveryContact),
      totalConsignmentValueNpr: int.tryParse(value.text),
      trucks: [
        for (var i = 0; i < _journeys.length; i++)
          TruckPlan(
            id: '$postId-truck-$i',
            truckNumber: i + 1,
            vehicleType: vehicleType,
            wheelClass: wheelType,
            capacityTons: double.tryParse(capacity) ?? 0,
            loadWeightTons: _weightInTons(_journeys[i].loadWeight),
            loadWeightAutoFilled: _journeys[i].loadWeightAutoFilled,
            stops: [
              for (final stop in _journeys[i].stops)
                LoadStop(
                  isPickup: stop.isPickup,
                  location: stop.location,
                  quantity: stop.quantity,
                  contact: stop.contact,
                ),
            ],
          ),
      ],
      currentStep: widget.step,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _restoreDraft() async {
    try {
      final catalog = await ref.read(postLoadControllerProvider).loadCatalog();
      if (!mounted) return;
      setState(() {
        locations = catalog.locations;
        materials = catalog.materials;
        characteristics = catalog.characteristics;
        contacts
          ..clear()
          ..addAll(catalog.contacts);
      });
      if (!widget.resumeDraft) return;
      final draft = await ref.read(postLoadControllerProvider).readDraft();
      if (!mounted) return;
      if (draft == null) {
        throw StateError('The saved draft is no longer available.');
      }
      setState(() {
        postId = draft.id;
        createdAt = draft.createdAt;
        origin.text = draft.routeOrigin?.name ?? '';
        destination.text = draft.routeDestination?.name ?? '';
        pickupDate = draft.pickupDate;
        deliveryDate = draft.deliveryDate;
        pickupWindow = draft.pickupWindow?.label;
        deliveryWindow = draft.deliveryWindow?.label;
        material = (draft.cargo?.material.isEmpty ?? true)
            ? null
            : draft.cargo!.material;
        weightUnit = draft.cargo?.weightUnit == 'kg' ? 'kg' : 'T';
        other.text = draft.cargo?.description ?? '';
        nature
          ..clear()
          ..addAll(draft.cargo?.natureAttributes ?? const []);
        pickupContact = draft.pickupContact?.displayLabel;
        deliveryContact = draft.deliveryContact?.displayLabel;
        for (final item in [pickupContact, deliveryContact]) {
          if (item != null && !contacts.contains(item)) contacts.add(item);
        }
        value.text = draft.totalConsignmentValueNpr?.toString() ?? '';
        if (draft.trucks.isNotEmpty) {
          vehicle =
              draft.trucks.first.vehicleType.name[0].toUpperCase() +
              draft.trucks.first.vehicleType.name.substring(1);
          wheel = draft.trucks.first.wheelClass.label;
          final amount = draft.trucks.first.capacityTons;
          capacity = amount > 0
              ? (amount == amount.roundToDouble()
                    ? amount.toInt().toString()
                    : amount.toString())
              : '';
          _journeys
            ..clear()
            ..addAll(
              draft.trucks.map(
                (truck) => _Journey()
                  ..loadWeightAutoFilled =
                      truck.loadWeightTons == null ||
                      (truck.loadWeightAutoFilled &&
                          (truck.loadWeightIsTotal ||
                              !truck.stops.any((stop) => stop.isPickup)))
                  ..loadWeight = truck.loadWeightTons == null
                      ? _capacityAsWeight()
                      : ((weightUnit == 'kg' ? 1000 : 1) *
                                (truck.loadWeightTons! +
                                    (truck.loadWeightIsTotal
                                        ? 0
                                        : truck.stops
                                              .where((stop) => stop.isPickup)
                                              .fold<double>(
                                                0,
                                                (sum, stop) =>
                                                    sum + stop.quantity,
                                              ))))
                            .toString()
                  ..stops.addAll(
                    truck.stops.map(
                      (stop) => _JourneyStop(
                        isPickup: stop.isPickup,
                        location: stop.location,
                        quantity: stop.quantity,
                        contact: stop.contact,
                      ),
                    ),
                  ),
              ),
            );
        }
      });
      widget.onTypeRestored(draft.loadType == LoadType.contract);
      widget.onStepChanged(draft.currentStep.clamp(0, 3));
    } catch (_) {
      if (mounted) {
        setState(() => restoreFailed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not restore the saved draft. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => restoring = false);
    }
  }

  Future<void> closeForm() async {
    if (busy || restoring) return;
    final choice = await showDialog<String>(
      context: context,
      barrierColor: AppColors.navy.withValues(alpha: .46),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCFCFF),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE4E8F4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x35101B42),
                      blurRadius: 34,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 2),
                    Image.asset(
                      'assets/images/leave_load_illustration.png',
                      width: 164,
                      height: 142,
                      fit: BoxFit.contain,
                      semanticLabel: 'Shipment document and delivery truck',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Leave this load?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: AppTextStyles.pageTitleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save your progress as a draft and continue later, or leave without saving.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.authMuted,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF4B0B), Color(0xFFF34205)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40F24B16),
                              blurRadius: 13,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(ctx, 'save'),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.save_outlined,
                                  color: Colors.white,
                                  size: 21,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Save draft',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppTextStyles.buttonSize,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF8F9FD),
                                foregroundColor: AppColors.navy,
                                side: const BorderSide(
                                  color: Color(0xFFE1E5EF),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, 'stay'),
                              child: const Text(
                                'Keep editing',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 58,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF0EB),
                                foregroundColor: const Color(0xFFC93E1A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: const BorderSide(
                                    color: Color(0xFFFAD8CE),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, 'discard'),
                              child: const Text(
                                'Leave without\nsaving',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  tooltip: 'Keep editing',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F2F8),
                    foregroundColor: AppColors.navy,
                    fixedSize: const Size(42, 42),
                  ),
                  onPressed: () => Navigator.pop(ctx, 'stay'),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null || choice == 'stay') return;
    if (choice == 'save') {
      await saveDraft();
      return;
    }
    if (mounted) widget.onCloseConfirmed();
  }

  Future<bool> saveDraft() async {
    if (busy || restoring || restoreFailed) return false;
    final post = _buildPost();
    final router = GoRouter.of(context);
    setState(() => busy = true);
    try {
      await ref.read(postLoadControllerProvider).saveDraft(post);
      if (!mounted) return true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Draft saved',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            content: const Text(
              'Your load is saved on this device. You can continue editing it later.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      );
      if (mounted) router.go(RouteNames.home);
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save draft: $error')));
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _submit() async {
    if (busy || restoring || restoreFailed) return;
    final post = _buildPost();
    final error = validateLoadPost(post);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final navigator = Navigator.of(context, rootNavigator: true);
    final router = GoRouter.of(context);
    final controller = ref.read(postLoadControllerProvider);
    setState(() => busy = true);
    LoadPostSubmission result;
    try {
      result = await showOperationProgress<LoadPostSubmission>(
        navigator.context,
        title: 'Posting your load',
        message: 'Please wait while we create your shipment.',
        progressLabel: 'Posting load...',
        icon: Icons.inventory_2_outlined,
        summary: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffd9e4f8)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '${post.routeOrigin?.name ?? ''}  →  ${post.routeDestination?.name ?? ''}\n${post.cargo?.material ?? ''} · ${post.trucks.length} ${post.trucks.length == 1 ? 'truck' : 'trucks'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: AppTextStyles.bodySize,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        operation: () => controller.submit(post),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not submit: $error')));
      }
      return;
    } finally {
      if (mounted) setState(() => busy = false);
    }
    if (widget.resumeDraft) {
      try {
        await ref
            .read(postLoadControllerProvider)
            .removeDraftIfMatching(post.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Load posted, but the saved draft could not be removed.',
              ),
            ),
          );
        }
      }
    }
    if (!navigator.mounted) return;
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => LoadPostSuccessScreen(
          result: result,
          router: router,
          refresh: controller.refresh,
        ),
      ),
    );
  }

  void _continue() {
    if (busy || restoring || restoreFailed) return;
    final post = _buildPost();
    String? error;
    if (widget.step == 0) {
      final pickup = post.routeOrigin?.name ?? '';
      final drop = post.routeDestination?.name ?? '';
      if (pickup.isEmpty || drop.isEmpty) {
        error = 'Choose pickup and delivery locations.';
      } else if (pickup.toLowerCase() == drop.toLowerCase()) {
        error = 'Pickup and delivery must be different.';
      } else if (post.pickupDate == null ||
          post.deliveryDate == null ||
          post.pickupWindow == null ||
          post.deliveryWindow == null) {
        error = 'Choose pickup and delivery dates and time windows.';
      } else if (!post.pickupWindow!
              .atEndOf(post.pickupDate!)
              .isAfter(DateTime.now()) ||
          !post.deliveryWindow!
              .atEndOf(post.deliveryDate!)
              .isAfter(DateTime.now())) {
        error = 'Choose pickup and delivery times that have not passed.';
      } else if (DateUtils.dateOnly(
        post.deliveryDate!,
      ).isBefore(DateUtils.dateOnly(post.pickupDate!))) {
        error = 'Delivery cannot be before pickup.';
      }
    } else if (widget.step == 1) {
      if (post.cargo == null ||
          post.cargo!.material.trim().isEmpty ||
          (post.cargo!.material == 'Other' &&
              (post.cargo!.description?.isEmpty ?? true))) {
        error = 'Choose or describe the cargo material.';
      } else if (post.cargo!.natureAttributes.isEmpty) {
        error = 'Choose at least one cargo characteristic.';
      } else if (post.pickupContact == null || post.deliveryContact == null) {
        error = 'Choose pickup and delivery contacts.';
      }
    } else if (widget.step == 2) {
      if (post.totalConsignmentValueNpr == null) {
        error = 'Enter the total consignment value.';
      } else if (post.trucks.any(
        (truck) =>
            truck.capacityTons <= 0 ||
            truck.loadWeightTons == null ||
            truck.loadWeightTons! <= 0 ||
            calculateTruckLoad(
                  truck.capacityTons,
                  truck.loadWeightTons,
                  truck.stops,
                ) ==
                null ||
            truck.stops.any(
              (stop) =>
                  stop.quantity <= 0 || stop.quantity > truck.capacityTons,
            ),
      )) {
        error =
            'Check each truck’s load weight, capacity and total pickups and drops.';
      }
    }
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    widget.onStepChanged(widget.step + 1);
  }

  @override
  void dispose() {
    originFocus.dispose();
    destinationFocus.dispose();
    origin.dispose();
    destination.dispose();
    other.dispose();
    value.dispose();
    super.dispose();
  }

  String dateLabel(DateTime? date) =>
      date == null ? 'Select date' : '${date.day}/${date.month}/${date.year}';

  Future<void> selectDate(bool pickup) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: (pickup ? pickupDate : deliveryDate) ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) {
        final theme = Theme.of(context);
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF98513F),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF4D3C39),
              surface: const Color(0xFFF9E7E4),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: const Color(0xFFF9E7E4),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (chosen != null) {
      setState(() {
        if (pickup) {
          pickupDate = chosen;
        } else {
          deliveryDate = chosen;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (restoring) {
      return const Center(child: CircularProgressIndicator());
    }
    if (restoreFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load the form or saved draft.'),
            TextButton(
              onPressed: () {
                setState(() {
                  restoring = true;
                  restoreFailed = false;
                });
                _restoreDraft();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final sections = [route(), cargo(), trucks(), review()];
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: PageStorageKey('post-step-${widget.step}'),
            padding: const EdgeInsets.only(bottom: 16),
            child: sections[widget.step],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: widget.step == 3
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: busy || restoring ? null : saveDraft,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.navy,
                            side: const BorderSide(color: Color(0xFFE1E4EA)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Save draft'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: busy || restoring ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppColors.orange.withValues(alpha: .3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          label: Text(busy ? 'Posting…' : 'Place order'),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: busy || restoring ? null : _continue,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      disabledBackgroundColor: AppColors.orange.withValues(
                        alpha: .4,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          [
                            'Continue to Cargo',
                            'Continue to Trucks',
                            'Continue to Review',
                          ][widget.step],
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _RouteDashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFABB1C0)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    for (double y = 3; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + 4).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
