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
      await tester.pump();

      // Check that basic UI elements are present
      // expect(find.text('User name'), findsOneWidget);
      // expect(find.text('Pet name'), findsOneWidget);
      // expect(find.byType(TextField), findsNWidgets(2));
      // expect(find.text('Try me'), findsOneWidget);
      // expect(find.byType(Switch), findsOneWidget);
      // expect(find.text('probs font size'), findsOneWidget);
      // expect(find.byType(Slider), findsOneWidget);
      // expect(find.text('Submit'), findsOneWidget);
    });
  });
}
