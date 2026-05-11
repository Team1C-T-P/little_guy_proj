// UI test for the Routes screen.
//
// Uses a fresh in-memory DB per test (TestDatabase.createFresh) wired into
// the AppDatabase singleton via setTestDatabase, so the view's call to
// AppDatabase.instance.database returns the test DB. No state leaks
// between tests or between files.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/routes_view.dart';
import 'package:flutter_flame_playground/models/database.dart';
import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    AppDatabase.setTestDatabase(db);
  });

  tearDown(() async {
    AppDatabase.setTestDatabase(null);
    await db.close();
  });

  group('Routes View UI Tests', () {
    testWidgets('[TR-UI-02] Displays empty state text when no routes exist', (WidgetTester tester) async {

      await tester.pumpWidget(
        const MaterialApp(
          home: RoutesView(),
        ),
      );

      // Let the real SQLite thread fetch data without deadlocking Flutter's
      // fake test clock.
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 1));
      });

      // Render the exact frame, ignoring any infinite loading animations.
      await tester.pump();

      expect(find.text('My Saved Routes'), findsOneWidget);

      expect(
        find.textContaining("You haven't saved any routes yet!"),
        findsOneWidget,
        reason: 'Failed to display empty state UI',
      );
    });
  });
}
