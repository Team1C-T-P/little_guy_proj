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

      // FIX: Use runAsync to allow the real SQLite thread to fetch the data
      // without deadlocking Flutter's fake test clock.
      await tester.runAsync(() async {
        await Future.delayed(const Duration(seconds: 1));
      });
      
      // Render the exact frame, ignoring any infinite loading animations
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