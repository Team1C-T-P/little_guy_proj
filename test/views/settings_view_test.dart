import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/views/settings_view.dart';

void main() {
  group('Settings Screen Tests', () {
    Widget createTestWidget() {
      return const MaterialApp(home: SettingsScreen());
    }

    testWidgets('should display settings screen with basic elements', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Check that basic UI elements are present
      expect(find.text('User name'), findsOneWidget);
      expect(find.text('Pet name'), findsOneWidget);
      expect(find.text('some attribute'), findsOneWidget);
    });

    //copied from Mani's union shop as example
    // testWidgets('should display size dropdown', (tester) async {
    //   await tester.pumpWidget(createTestWidget());
    //   await tester.pump();

    //   expect(find.text('Size'), findsOneWidget);
    //   //expect(find.byType(DropdownButtonFormField<dynamic>), findsOneWidget);
    // });
  });
}
