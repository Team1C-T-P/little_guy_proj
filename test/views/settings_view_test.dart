// UI tests for the Settings screen.
//
// SettingsScreen kicks off an async _loadData() chain from initState that
// hits the singleton DB. The chain catches its own errors (so missing
// user/pet data doesn't crash the screen), but we still let it drain before
// asserting so the widget is in its steady state.
//
// Uses a fresh in-memory DB per test (TestDatabase.createFresh) wired into
// the singleton via setTestDatabase. No state leaks between tests.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/settings_view.dart';
import 'package:flutter_flame_playground/models/database.dart';
import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    // SettingsScreen reads the user and pet rows for user_id 1 in initState.
    // Seed them so _loadData succeeds and we don't get a stray async error
    // logged after the test body completes.
    final userId = await TestDatabase.seedUser(db);
    await TestDatabase.seedLittleGuy(db, userId: userId);
    expect(userId, 1, reason: 'first seeded user should get user_id 1');
    final users = await db.query('user');
    expect(users.length, 1, reason: 'user row should exist after seedUser');
    AppDatabase.setTestDatabase(db);
    final usersViaSingleton = await (await AppDatabase.instance.database).query('user');
    expect(usersViaSingleton.length, 1, reason: 'singleton override DB should have the seeded user');
  });

  tearDown(() async {
    AppDatabase.setTestDatabase(null);
    await db.close();
  });

  group('Settings Screen UI', () {
    Widget createTestWidget() {
      return const MaterialApp(home: SettingsScreen());
    }

    // Pump the widget and drain the async load chain before returning, so
    // all three tests start from the same steady state.
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
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Font size'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Submit'), findsOneWidget);
    });

    testWidgets('pump switch and see snack', (tester) async {
      await pumpAndDrain(tester);

      // Tap the switch and verify the state change.
      await tester.tap(find.byType(Switch));
      await tester.pump(); // Rebuild after the state change.

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Notifications enabled'), findsOneWidget);
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
