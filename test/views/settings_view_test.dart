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
    final db = await AppDatabase.instance.database;
    await db.delete('route'); //fix as I am not working with routes
  });

  group('Settings Screen UI', () {
    Widget createTestWidget() {
      return const MaterialApp(home: SettingsScreen());
    }

    //copied from Mani's union shop as example
    // Delete as Claudia said no front end?
    testWidgets('should display settings screen with basic elements', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check that basic UI elements are present
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
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Tap the switch and verify the state change
      await tester.tap(find.byType(Switch)); //taps the switch
      await tester.pump(); // Rebuild the widget after the state change
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text("6 7"), findsOneWidget);
    });

    testWidgets('change slider and check value', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.drag(
        find.byType(Slider),
        const Offset(-120, 0),
      ); //simulates dragging; the Offset is how many PIXELS to move (negative = left, positive = right) - pixels will be problematic as we don't know how to get it exactly
      // -330 is the last 0.0
      // -260 is the last 0.1
      // -180 is the last 0.2
      // -110 is the last 0.3
      await tester.pump();

      expect(find.text('0.3'), findsOneWidget);
    });
  });
}
