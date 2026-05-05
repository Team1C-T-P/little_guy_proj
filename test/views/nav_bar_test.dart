import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/views/nav_bar.dart';

void main() {
  testWidgets('MainNavBar renders without errors', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byType(MainNavBar), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets('MainNavBar has five navigation items', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.items.length, equals(5));
  });

  testWidgets('MainNavBar has correct item labels', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('Little Guy'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Dress'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('MainNavBar has correct icons for each item', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.byIcon(Icons.spa), findsOneWidget);
    expect(find.byIcon(Icons.map), findsOneWidget);
    expect(find.byIcon(Icons.checkroom), findsOneWidget);
    expect(find.byIcon(Icons.tag), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('MainNavBar has correct background color', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(
      navBar.backgroundColor,
      equals(const Color.fromARGB(219, 150, 242, 176)),
    );
  });

  testWidgets('MainNavBar has correct selected item color', (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(
      navBar.selectedItemColor,
      equals(const Color.fromARGB(255, 77, 151, 86)),
    );
  });

  testWidgets('MainNavBar respects currentIndex property', (WidgetTester tester) async {
    int currentIndex = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.currentIndex, equals(2));
  });

  testWidgets('MainNavBar calls onTap when an item is tapped', (WidgetTester tester) async {
    int currentIndex = 0;
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    // Tap on the 'Map' item (index 1)
    await tester.tap(find.byIcon(Icons.map));
    await tester.pumpAndSettle();

    expect(tappedIndex, equals(1));
  });

  testWidgets('MainNavBar calls onTap with correct index for each item',
      (WidgetTester tester) async {
    int currentIndex = 0;
    int tappedIndex = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {
              tappedIndex = index;
            },
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    // Test tapping each item
    final List<IconData> icons = [
      Icons.spa,
      Icons.map,
      Icons.checkroom,
      Icons.tag,
      Icons.person,
    ];

    for (int i = 0; i < icons.length; i++) {
      tappedIndex = -1;
      await tester.tap(find.byIcon(icons[i]));
      await tester.pumpAndSettle();
      expect(tappedIndex, equals(i));
    }
  });

  testWidgets('MainNavBar has correct backgroundColor for each item',
      (WidgetTester tester) async {
    int currentIndex = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: currentIndex,
            onTap: (index) {},
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    for (var item in navBar.items) {
      expect(
        item.backgroundColor,
        equals(const Color.fromARGB(219, 150, 242, 176)),
      );
    }
  });

  testWidgets('MainNavBar updates when currentIndex changes', (WidgetTester tester) async {
    int currentIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              bottomNavigationBar: MainNavBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
              ),
              body: const SizedBox.expand(),
            );
          },
        ),
      ),
    );

    expect(find.byType(MainNavBar), findsOneWidget);
    var navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.currentIndex, equals(0));

    // Tap on the 'Shop' item (index 3)
    await tester.tap(find.byIcon(Icons.tag));
    await tester.pumpAndSettle();

    navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.currentIndex, equals(3));
  });

  testWidgets('MainNavBar is const constructible', (WidgetTester tester) async {
    const navBar = MainNavBar(
      currentIndex: 0,
      onTap: print,
    );
    expect(navBar, isNotNull);
  });

  testWidgets('MainNavBar onTap callback is not null', (WidgetTester tester) async {
    void mockOnTap(int index) {}

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MainNavBar(
            currentIndex: 0,
            onTap: mockOnTap,
          ),
          body: const SizedBox.expand(),
        ),
      ),
    );

    final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(navBar.onTap, isNotNull);
  });
}
