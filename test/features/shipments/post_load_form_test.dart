import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lod_board/core/providers/core_providers.dart';
import 'package:lod_board/features/shipments/ui/post_load_sections.dart';
import 'package:lod_board/features/shipments/data/repositories/mock_shipment_repository.dart';
import 'package:lod_board/features/shipments/data/repositories/local_load_draft_store.dart';
import 'package:lod_board/features/shipments/domain/models/shipment.dart';
import 'mock_shipment_repository_test.dart' show samplePost;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('route edits are persisted in the saved draft', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final key = GlobalKey<PostLoadSectionsState>();
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, _) => Scaffold(
            body: PostLoadSections(
              key: key,
              step: 0,
              isContract: false,
              onStepChanged: (_) {},
              onTypeRestored: (_) {},
              onCloseConfirmed: () {},
            ),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
      ],
    );
    addTearDown(router.dispose);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Kathmandu');
    await tester.enterText(find.byType(TextField).at(1), 'Chitwan');
    final save = key.currentState!.saveDraft();
    await tester.pumpAndSettle();
    expect(find.text('Draft saved'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await save, isTrue);
    final saved = await LocalLoadDraftStore(prefs, 'anonymous').read();
    expect(saved!.routeOrigin!.name, 'Kathmandu');
    expect(saved.routeDestination!.name, 'Chitwan');
  });

  testWidgets('review submission creates a whole-shipment confirmation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final key = GlobalKey<PostLoadSectionsState>();
    await LocalLoadDraftStore(prefs, 'anonymous').save(samplePost());
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(
      initialLocation: '/create',
      routes: [
        GoRoute(
          path: '/create',
          builder: (_, _) => Scaffold(
            body: PostLoadSections(
              key: key,
              step: 3,
              resumeDraft: true,
              isContract: false,
              onStepChanged: (_) {},
              onTypeRestored: (_) {},
              onCloseConfirmed: () {},
            ),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('Home screen')),
        ),
        GoRoute(
          path: '/shipments/:id',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.pop(),
              child: Text('Details ${state.pathParameters['id']}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    Widget screen() => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp.router(routerConfig: router),
    );
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    final form = key.currentState!;
    form.origin.text = 'Kathmandu';
    form.destination.text = 'Chitwan';
    form.pickupDate = DateTime.now().add(const Duration(days: 1));
    form.deliveryDate = DateTime.now().add(const Duration(days: 2));
    form.pickupWindow = 'Morning';
    form.deliveryWindow = 'Afternoon';
    form.material = 'Cement';
    form.nature.add('Stackable');
    form.pickupContact = 'Ram Shrestha · 9841000001';
    form.deliveryContact = 'Sita Thapa · 9841000002';
    form.value.text = '100000';
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
    expect(find.text('Load posted!'), findsOneWidget);
    final snapshot = await tester.runAsync(
      () => MockShipmentRepository(prefs, 'anonymous').fetchSnapshot(),
    );
    final shipments = snapshot!.shipments;
    expect(shipments, hasLength(1));
    expect(shipments.single.status, ShipmentStatus.awaitingBids);
    expect(shipments.single.loadPostSnapshot!.cargo!.material, 'Cement');
    await tester.ensureVisible(find.text('View shipment'));
    await tester.tap(find.text('View shipment'));
    await tester.pumpAndSettle();
    expect(find.text('Details ${shipments.single.id}'), findsOneWidget);
    await tester.tap(find.text('Details ${shipments.single.id}'));
    await tester.pumpAndSettle();
    expect(find.text('Home screen'), findsOneWidget);
  });
  testWidgets('contact dropdown shows phone in menu and name after selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final key = GlobalKey<PostLoadSectionsState>();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(
            body: PostLoadSections(
              key: key,
              step: 1,
              isContract: false,
              onStepChanged: (_) {},
              onTypeRestored: (_) {},
              onCloseConfirmed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Select pickup contact'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<String>).first);
    await tester.pumpAndSettle();
    expect(find.text('Ram Shrestha · 9841000001'), findsOneWidget);
    await tester.tap(find.text('Ram Shrestha · 9841000001'));
    await tester.pumpAndSettle();
    expect(find.text('Ram Shrestha'), findsOneWidget);
    expect(find.text('Ram Shrestha · 9841000001'), findsNothing);
    expect(key.currentState!.pickupContact, 'Ram Shrestha · 9841000001');
  });
  testWidgets(
    'truck capacity is entered explicitly and saved with wheel size',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final key = GlobalKey<PostLoadSectionsState>();
      final router = GoRouter(
        initialLocation: '/create',
        routes: [
          GoRoute(
            path: '/create',
            builder: (_, _) => Scaffold(
              body: PostLoadSections(
                key: key,
                step: 2,
                isContract: false,
                onStepChanged: (_) {},
                onTypeRestored: (_) {},
                onCloseConfirmed: () {},
              ),
            ),
          ),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      addTearDown(router.dispose);
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      expect(key.currentState!.capacity, isEmpty);
      await tester.tap(find.text('14W'));
      await tester.pumpAndSettle();
      expect(key.currentState!.capacity, isEmpty);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enter capacity'),
        '24',
      );
      expect(key.currentState!.capacity, '24');
      final save = key.currentState!.saveDraft();
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await save, isTrue);
      final saved = await LocalLoadDraftStore(prefs, 'anonymous').read();
      expect(saved!.trucks.single.wheelClass.name, 'fourteenW');
      expect(saved.trucks.single.capacityTons, 24);
    },
  );
}
