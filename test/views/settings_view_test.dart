import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../helpers/test_database.dart'; // instead of import ../lib/database
import 'package:flutter_flame_playground/views/settings_view.dart';

void main() {
  // Copied from Sam's routes_view_test.dart (set up db for testing)
  // TestWidgetsFlutterBinding.ensureInitialized();

  // setUpAll(() async {
  //   sqfliteFfiInit();
  //   databaseFactory = databaseFactoryFfi;
  //   await AppDatabase.instance.initializeDefaultData();
  // });

  // setUp(() async {
  //   final db = await AppDatabase.instance.database;
  //   await db.delete('route'); //fix as I am not working with routes
  // });

  // Testing db changed in code, we can shorten the code?
  late Database db;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
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

    testWidgets('submit button updates db', (tester) async {
      final userId = await TestDatabase.seedUser(db);
      await TestDatabase.seedLittleGuy(db, userId: userId);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'New User Name');
      await tester.enterText(find.byType(TextField).at(1), 'New Pet Name');
      await tester.tap(find.text('Submit'));

      await tester.pumpWidget(
        createTestWidget(),
      ); // Rebuild the widget to reflect changes
      await tester.pump();

      expect(find.text('New User Name'), findsOneWidget);
      expect(find.text('New Pet Name'), findsOneWidget);
    });
  });
  group("Settings Screen fetch/update db", () {
    // move this to the submit button test? First check init and then change?
    test('init values show', () async {
      final userId = await TestDatabase.seedUser(db);
      await TestDatabase.seedLittleGuy(db, userId: userId);
      expect(
        find.text('Test User'),
        findsOneWidget,
      ); // init user - in actual db it is "Default User"
      expect(find.text('Buddy'), findsOneWidget); // init pet
    });

    // update values in db and see if they update on the screen - or would this be a full db work? Or just a test for the db update function (not UI settings screen test)

    // test submit button? Again -  a UI thing or DB test?
  });
}
