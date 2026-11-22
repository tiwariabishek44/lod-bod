import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/notifications/root_scaffold_messenger.dart';
import '../../shipments/providers/shipment_providers.dart';

import '../domain/models/bid.dart';
import '../../shipments/domain/models/shipment.dart';
import '../../shipments/data/repositories/shipment_repository.dart';
import 'bid_offers_bottom_sheet.dart';
import 'bid_acceptance_preview.dart';

Future<void> reviewShipmentBids({
  required BuildContext context,
  required WidgetRef ref,
  required Shipment shipment,
  required ShipmentWorkflowSnapshot snapshot,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final router = GoRouter.of(context);
  final controller = ref.read(shipmentWorkflowProvider.notifier);
  final offers = snapshot
      .bidsFor(shipment.id)
      .where((offer) => offer.bid.status == BidStatus.pending)
      .toList();
  final action = await showBidOffersBottomSheet(
    context,
    shipment: shipment,
    bids: offers,
  );
  if (action == null || !navigator.mounted) return;
  try {
    await showBidAcceptance(
      navigator.context,
      shipment: shipment,
      offer: action.offer,
      router: router,
      accept: () => controller.acceptBid(
        shipmentId: shipment.id,
        bidId: action.offer.bid.id,
      ),
      refresh: controller.refresh,
    );
  } catch (error) {
    final message = switch (error) {
      ShipmentOperationException() => error.message,
      ApiException() => error.message,
      _ => 'Could not accept this bid. Please try again.',
    };
    rootScaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
