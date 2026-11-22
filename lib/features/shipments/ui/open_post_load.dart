import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../router/route_names.dart';
import '../domain/shipment_rules.dart';
import '../providers/post_load_controller.dart';
import '../providers/shipment_providers.dart';
import 'mobile_request_limit_dialog.dart';

bool _openingPostLoad = false;

/// Checks the request limit and any saved draft before opening the form.
Future<void> openPostLoad(BuildContext context, WidgetRef ref) async {
  if (_openingPostLoad) return;
  _openingPostLoad = true;
  try {
    final snapshot = await ref.read(shipmentWorkflowProvider.future);
    if (!context.mounted) return;
    if (snapshot.mobileRequestsUsed >= ShipmentRules.mobileRequestLimit) {
      await showMobileRequestLimitDialog(context);
      return;
    }
    final draft = await ref.read(postLoadControllerProvider).readDraft();
    if (!context.mounted) return;
    bool? resume = false;
    if (draft != null) {
      resume = await showModalBottomSheet<bool>(
        context: context,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          padding: EdgeInsets.fromLTRB(
            22,
            16,
            22,
            24 + MediaQuery.viewPaddingOf(sheetContext).bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xfff4f7ff),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xffa9b8d6),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You have a saved draft',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Continue where you left off or start a new load. Your saved draft will stay on this device.',
                style: TextStyle(
                  color: Color(0xff53607d),
                  fontSize: AppTextStyles.bodySize,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: () => Navigator.pop(sheetContext, true),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Continue with draft'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(sheetContext, false),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create new load'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
      if (!context.mounted || resume == null) return;
    }
    if (!context.mounted) return;
    context.push(
      resume == true
          ? '${RouteNames.createShipment}?resumeDraft=1'
          : RouteNames.createShipment,
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Post Load. Please try again.'),
        ),
      );
    }
  } finally {
    _openingPostLoad = false;
  }
}
