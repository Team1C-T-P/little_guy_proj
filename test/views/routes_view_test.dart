import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/routes_view.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });
  
  setUp(() async {
    // Ensure the routes table is completely empty for the empty state test
    final db = await AppDatabase.instance.database;
    await db.delete('route'); 
  });

  group('Routes View UI Tests', () {
    testWidgets('[TR-UI-02] Displays empty state text when no routes exist', (WidgetTester tester) async {
      
      await tester.pumpWidget(
        const MaterialApp(
          home: RoutesView(),
        ),
      );

      // FIX: Use pump with a duration to step past the spinning loading circle
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('My Saved Routes'), findsOneWidget);

      expect(
        find.textContaining("You haven't saved any routes yet!"), 
        findsOneWidget,
        reason: 'Failed to display empty state UI',
      );
    });
  });
}