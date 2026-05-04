import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/summary_view.dart';
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

  group('Summary View UI Tests', () {
    testWidgets('[TR-UI-01] Renders passed steps and UI elements correctly', (WidgetTester tester) async {
      // Setup a fake route
      final fakeRoute = [const LatLng(50.0, -1.0), const LatLng(50.1, -1.1)];

      // Build the widget inside a dummy app environment
      await tester.pumpWidget(
        MaterialApp(
          home: SummaryScreen(
            totalSteps: 1500,
            route: fakeRoute,
          ),
        ),
      );

      // Allow the async database save function in initState to complete
      await tester.pumpAndSettle();

      // Verify the UI text rendered the steps correctly
      expect(find.text('1500 Steps'), findsOneWidget);
      expect(find.text('Walk Summary'), findsOneWidget);
      
      // Verify our dynamic buttons exist
      expect(find.text('Save as Route'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
    });
  });
}