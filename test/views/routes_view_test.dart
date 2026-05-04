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

      // FIX: Give the real background SQLite thread 500ms to fetch the empty data
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Tell Flutter to render the new frame
      await tester.pumpAndSettle();

      expect(find.text('My Saved Routes'), findsOneWidget);

      expect(
        find.textContaining("You haven't saved any routes yet!"), 
        findsOneWidget,
        reason: 'Failed to display empty state UI',
      );
    });
  });
}