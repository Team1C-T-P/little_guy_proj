import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/views/profile_view.dart';

void main() {
  // Copied from settings_view_test.dart
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

  group('Profile Screen Tests', () {
    Widget createTestWidget() {
      return const MaterialApp(home: ProfileScreen());
    }

    testWidgets('should display profile screen with basic elements', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Animations are fucking me over

      // Check that basic UI elements are present
      expect(find.textContaining('|'), findsOneWidget);
      expect(find.textContaining('Total Steps'), findsOneWidget);
      expect(find.textContaining('Items Collected'), findsOneWidget);
      expect(find.text('Achievements'), findsOneWidget);
    });
  });
}
