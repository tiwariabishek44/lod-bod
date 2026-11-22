import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/features/bids/ui/bid_acceptance_preview.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import '../shipments/mock_shipment_reference_test.dart' as fixtures;

void main() {
  testWidgets('waits for acceptance and returns from shipment to home', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockShipmentRepository(
        await SharedPreferences.getInstance(),
        'user',
      );
      final shipment = (await repo.submitLoadPost(
        fixtures.validPost('post-1'),
      )).shipments.single;
      await repo.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 1)),
      );
      final offer = (await repo.fetchSnapshot()).bidsFor(shipment.id).single;
      return (shipment, offer);
    });
    final (shipment, offer) = fixture!;
    final result = Completer<bool>();
    var acceptCalls = 0;
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showBidAcceptance(
                context,
                shipment: shipment,
                offer: offer,
                router: router,
                accept: () {
                  acceptCalls++;
                  return result.future;
                },
                refresh: () async {},
              ),
              child: const Text('Accept'),
            ),
          ),
        ),
        GoRoute(
          path: '/shipments/:id',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back from shipment'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm bid acceptance'), findsOneWidget);
    expect(find.textContaining('Swift Transport'), findsOneWidget);
    expect(find.textContaining('Rs. 29,500'), findsOneWidget);
    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(acceptCalls, 0);
    expect(find.text('Accepting bid'), findsNothing);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm bid'));
    await tester.tap(find.text('Confirm bid'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(acceptCalls, 1);
    expect(find.text('Accepting bid'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Accepting bid'), findsOneWidget);
    expect(find.text('Bid Accepted!'), findsNothing);
    result.complete(true);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Bid Accepted!'), findsOneWidget);
    await tester.ensureVisible(find.text('View shipment'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('View shipment'));
    await tester.pumpAndSettle();
    expect(find.text('Back from shipment'), findsOneWidget);
    await tester.tap(find.text('Back from shipment'));
    await tester.pumpAndSettle();
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Bid Accepted!'), findsNothing);
  });

  testWidgets('refresh failure shows success and permits retry', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockShipmentRepository(
        await SharedPreferences.getInstance(),
        'user',
      );
      final shipment = (await repo.submitLoadPost(
        fixtures.validPost('post-1'),
      )).shipments.single;
      await repo.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 1)),
      );
      final offer = (await repo.fetchSnapshot()).bidsFor(shipment.id).single;
      return (shipment, offer);
    });
    final (shipment, offer) = fixture!;
    var retryCount = 0;
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => showBidAcceptance(
                context,
                shipment: shipment,
                offer: offer,
                router: router,
                accept: () async => false,
                refresh: () async {
                  retryCount++;
                },
              ),
              child: const Text('Accept'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm bid'));
    await tester.tap(find.text('Confirm bid'));
    await tester.pumpAndSettle();
    expect(find.text('Bid Accepted!'), findsOneWidget);
    expect(find.textContaining('could not be refreshed'), findsOneWidget);
    await tester.ensureVisible(find.text('Retry refresh'));
    await tester.tap(find.text('Retry refresh'));
    await tester.pumpAndSettle();
    expect(retryCount, 1);
    expect(find.text('Retry refresh'), findsNothing);
  });
  testWidgets('acceptance failure closes progress and never shows success', (
    tester,
  ) async {
    final fixture = await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockShipmentRepository(
        await SharedPreferences.getInstance(),
        'user',
      );
      final shipment = (await repo.submitLoadPost(
        fixtures.validPost('post-1'),
      )).shipments.single;
      await repo.processDueBidArrivals(
        now: shipment.createdAt.add(const Duration(minutes: 1)),
      );
      final offer = (await repo.fetchSnapshot()).bidsFor(shipment.id).single;
      return (shipment, offer);
    });
    final (shipment, offer) = fixture!;
    late GoRouter router;
    router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async {
                try {
                  await showBidAcceptance(
                    context,
                    shipment: shipment,
                    offer: offer,
                    router: router,
                    accept: () async => throw StateError('failure'),
                    refresh: () async {},
                  );
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Acceptance failed')),
                    );
                  }
                }
              },
              child: const Text('Accept'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Confirm bid'));
    await tester.tap(find.text('Confirm bid'));
    await tester.pumpAndSettle();
    expect(find.text('Acceptance failed'), findsOneWidget);
    expect(find.text('Accepting bid'), findsNothing);
    expect(find.text('Bid Accepted!'), findsNothing);
  });
}
