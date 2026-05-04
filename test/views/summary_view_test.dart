import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX: Required to mock platform channels
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/views/summary_view.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // FIX: Intercept the map's request for a physical device folder and give it a safe dummy path.
    // This perfectly isolates the UI test from hardware dependencies.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.'; // Return the current testing directory as a safe fallback
      },
    );

    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });

  group('Summary View UI Tests', () {
    testWidgets('[TR-UI-01] Renders passed steps and UI elements correctly', (WidgetTester tester) async {
      
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      
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

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 500));
      });
      
      await tester.pump();

      expect(find.text('1500 Steps'), findsOneWidget);
      expect(find.text('Walk Summary'), findsOneWidget);
      expect(find.text('Save as Route'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);
    });
  });
}