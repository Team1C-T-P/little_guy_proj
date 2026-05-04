import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/summary_view.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });

  group('Summary View UI Tests', () {
    testWidgets('[TR-UI-01] Renders passed steps and UI elements correctly', (WidgetTester tester) async {
      
      // FIX: Force the test environment to emulate a modern phone screen (1080x2400)
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
      // Cleanup the screen resize after the test finishes
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRoute = [const LatLng(50.0, -1.0), const LatLng(50.1, -1.1)];

      await tester.pumpWidget(
        MaterialApp(
          home: SummaryScreen(
            totalSteps: 1500,
            route: fakeRoute,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1500 Steps'), findsOneWidget);
      expect(find.text('Walk Summary'), findsOneWidget);
      expect(find.text('Save as Route'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
    });
  });
}