import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/routes_view.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbPath = inMemoryDatabasePath;
    await databaseFactory.deleteDatabase(dbPath);
    await AppDatabase.instance.initializeDefaultData(); 
  });

  group('Routes View UI Tests', () {
    testWidgets('[TR-UI-02] Displays empty state text when no routes exist', (WidgetTester tester) async {
      
      // Build the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: RoutesView(),
        ),
      );

      // Wait for the async database fetch (_loadRoutes) to finish
      await tester.pumpAndSettle();

      // Verify the AppBar title exists
      expect(find.text('My Saved Routes'), findsOneWidget);

      // Verify the empty state message is shown
      expect(
        find.textContaining("You haven't saved any routes yet!"), 
        findsOneWidget,
        reason: 'Failed to display empty state UI',
      );
    });
  });
}