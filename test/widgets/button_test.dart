import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_flame_playground/widgets/button.dart';


void main() {
	testWidgets('GreenButton renders with given text', (WidgetTester tester) async {
		await tester.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: GreenButton(buttonText: 'Tap me', onPressed: () {}),
				),
			),
		);

		expect(find.text('Tap me'), findsOneWidget);
		expect(find.byType(ElevatedButton), findsOneWidget);
	});

	testWidgets('GreenButton calls onPressed when tapped', (WidgetTester tester) async {
		var pressed = false;
		await tester.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: GreenButton(buttonText: 'Tap', onPressed: () { pressed = true; }),
				),
			),
		);

		await tester.tap(find.byType(ElevatedButton));
		await tester.pumpAndSettle();
		expect(pressed, isTrue);
	});

	testWidgets('GreenButton background color matches expected', (WidgetTester tester) async {
		await tester.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: GreenButton(buttonText: 'C', onPressed: () {}),
				),
			),
		);

		final elevated = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
		final style = elevated.style;
		final bgProp = style?.backgroundColor;
		final resolved = bgProp?.resolve(<WidgetState>{});

		expect(resolved, equals(const Color.fromARGB(255, 159, 239, 167)));
	});

	testWidgets('GreenButton respects surrounding DefaultTextStyle font size', (WidgetTester tester) async {
		final baseStyle = const TextStyle(fontSize: 20);
		await tester.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: DefaultTextStyle(
						style: baseStyle,
						child: GreenButton(buttonText: 'Hello', onPressed: () {}),
					),
				),
			),
		);

		final text = tester.widget<Text>(find.text('Hello'));
		expect(text.style?.fontSize, equals(20));
	});

	testWidgets('GreenButton provides a non-null onPressed to ElevatedButton', (WidgetTester tester) async {
		await tester.pumpWidget(
			MaterialApp(
				home: Scaffold(
					body: GreenButton(buttonText: 'A', onPressed: () {}),
				),
			),
		);

		final elevated = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
		expect(elevated.onPressed, isNotNull);
	});
}

