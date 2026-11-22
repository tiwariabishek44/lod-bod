import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/auth/ui/login_screen.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() {
  testWidgets('login remains usable on a small phone with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ResponsiveSizer(
        builder: (context, orientation, screenType) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: const LodbodLoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Log in'));
    expect(find.text('Log in'), findsOneWidget);
  });
}
