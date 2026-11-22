import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lod_board/features/shipments/ui/stop_editor_sheet.dart';

void main() {
  testWidgets(
    'stop editor validates required data and returns the entered stop',
    (tester) async {
      StopEditorResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<StopEditorResult>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const StopEditorSheet(
                      isPickup: false,
                      contacts: ['Hari · 9841000001'],
                    ),
                  );
                },
                child: const Text('Open editor'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open editor'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save stop'));
      await tester.tap(find.text('Save stop'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a location.'), findsOneWidget);
      expect(
        find.text('Enter a valid quantity greater than zero.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextFormField).at(0), 'Hetauda');
      await tester.enterText(find.byType(TextFormField).at(1), '2.5');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hari · 9841000001').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save stop'));
      await tester.tap(find.text('Save stop'));
      await tester.pumpAndSettle();
      expect(result!.location, 'Hetauda');
      expect(result!.quantity, 2.5);
      expect(result!.contact, 'Hari · 9841000001');
    },
  );
}
