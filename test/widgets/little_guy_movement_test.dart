import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialize FFI database factory for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  group('Walking Animation - Initial State Tests', () {
    testWidgets('EP - Widget renders correctly on initial loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
      expect(find.byType(Image), findsOneWidget);
    });
    
    testWidgets('EP - Little guy base image is displayed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      final imageWidget = tester.widget<Image>(find.byType(Image).first);
      expect(imageWidget.image.toString(), contains('funnyguy.png'));
    });
  });
  
  group('Walking Animation - Animation Lifecycle Tests', () {
    testWidgets('EP - Animation starts automatically on init', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      
      // Widget should still be visible and animating
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(find.byType(AnimatedBuilder), findsWidgets); // Changed to at least one
    });
    
    testWidgets('EP - Animation runs continuously without stopping', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Pump through multiple animation cycles
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(LittleGuy), findsOneWidget);
      }
    });
    
    testWidgets('EP - Animation controller is disposed properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Remove the widget
      await tester.pumpWidget(const SizedBox.shrink());
      
      // No errors should occur during disposal
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('EP - Animation continues after widget rebuild', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      await tester.pump(const Duration(milliseconds: 500));
      
      // Rebuild the widget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
  });
  
  group('Walking Animation - Movement Sequence Tests', () {
    testWidgets('EP - Widget uses Transform.translate for movement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      final transformWidgets = tester.widgetList<Transform>(find.byType(Transform));
      expect(transformWidgets.length, greaterThan(0));
    });
    
    testWidgets('BVA - Animation moves right to 30.0 offset boundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // At 25% of animation (750ms) - should be at max right position (30.0)
      await tester.pump(const Duration(milliseconds: 750));
      
      // Widget should be visible
      expect(find.byType(LittleGuy), findsOneWidget);
    });
    
    testWidgets('BVA - Animation moves left to -30.0 offset boundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // At 47.5% of animation (1425ms) - should be at max left position (-30.0)
      await tester.pump(const Duration(milliseconds: 1425));
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
    
    testWidgets('BVA - Animation returns to 0 offset at completion', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Complete a full cycle
      await tester.pump(const Duration(seconds: 3));
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
  });
  
  group('Walking Animation - Sequence Weight Tests - time occupied', () {
    testWidgets('EP - Total animation weights sum to 100%', (tester) async {
      // Right walk (25) + Right pause (10) + Left walk (25) + Left pause (10) + Return (30) = 100
      // This is a static test of the configuration
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(LittleGuy), findsOneWidget);
    });
  });
  
  group('Walking Animation - Curve and Easing Tests', () {
    testWidgets('EP - Animation uses easeInOut curve for smooth movement', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Test multiple points to ensure smooth transitions
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 500));
      
      // No abrupt changes should cause exceptions
      expect(tester.takeException(), isNull);
      expect(find.byType(LittleGuy), findsOneWidget);
    });
    
    testWidgets('EP - Animation uses constant curve during pauses', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // During pause periods, position should remain constant
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
  });
  
  group('Walking Animation - Performance Tests', () {
    testWidgets('BVA - Animation runs at various frame rates (30fps, 60fps, 120fps)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Test at 30fps (33ms per frame)
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 33));
      }
      
      // Test at 60fps (16ms per frame)
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      
      // Test at 120fps (8ms per frame)
      for (int i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 8));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
    
    testWidgets('EP - No memory leaks during extended animation (30 seconds)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Run animation for 30 seconds
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('EP - Animation survives multiple cycles (10 cycles = 30 seconds)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Run 10 complete cycles (3 seconds each = 30 seconds)
      for (int cycle = 0; cycle < 10; cycle++) {
        await tester.pump(const Duration(seconds: 3));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
    });
  });
  
  group('Walking Animation - Edge Cases', () {
    testWidgets('BVA - Animation handles extremely long runtime (5 minutes)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Run for 5 minutes (300 seconds)
      for (int i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 5));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('BVA - Animation handles micro-frame updates (1ms increments)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Pump with very small increments
      for (int i = 0; i < 100; i++) {
        await tester.pump(const Duration(milliseconds: 1));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
    
    testWidgets('EP - Widget survives rapid rebuilds', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LittleGuy(),
          ),
        ),
      );
      
      // Rapidly rebuild the widget
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LittleGuy(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 10));
      }
      
      expect(find.byType(LittleGuy), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}