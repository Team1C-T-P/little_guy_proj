// UI tests for the Settings screen.
//
// SettingsScreen kicks off an async _loadData() chain from initState that
// hits the singleton DB. The chain catches its own errors (so missing
// user/pet data doesn't crash the screen), but we still let it drain before
// asserting so the widget is in its steady state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/views/settings_view.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData();
  });

  setUp(() async {
    // Reset rows that previous tests may have touched.
    final db = await AppDatabase.instance.database;
    await db.delete('route');
  });

  group('Settings Screen UI', () {
    Widget createTestWidget() {
      return const MaterialApp(home: SettingsScreen());
    }

    // Helper: pump the widget and drain the async load chain before
    // returning, so all three tests start from the same steady state.
    Future<void> pumpAndDrain(WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 300));
      });
      await tester.pump();
    }

    testWidgets('should display settings screen with basic elements', (
      tester,
    ) async {
      await pumpAndDrain(tester);

      // Check that basic UI elements are present.
      expect(find.text('User name'), findsOneWidget);
      expect(find.text('Pet name'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Try me'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('probs font size'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('pump switch and see snack', (tester) async {
      await pumpAndDrain(tester);

      // Tap the switch and verify the state change.
      await tester.tap(find.byType(Switch));
      await tester.pump(); // Rebuild after the state change.

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text("6 7"), findsOneWidget);
    });

    testWidgets('change slider and check value', (tester) async {
      await pumpAndDrain(tester);

      // Simulates dragging the slider left by 120 pixels. Approximate
      // calibration (negative = left, positive = right):
      //   -330 -> 0.0, -260 -> 0.1, -180 -> 0.2, -110 -> 0.3
      await tester.drag(find.byType(Slider), const Offset(-120, 0));
      await tester.pump();

      expect(find.text('0.3'), findsOneWidget);
    });
  });
}
