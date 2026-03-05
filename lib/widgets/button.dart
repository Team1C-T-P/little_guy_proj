import 'package:flutter/material.dart';

class TempButton extends StatelessWidget {
	const TempButton({super.key, required this.buttonText});

	final String buttonText;

	@override
	Widget build(BuildContext context) {
		return ElevatedButton(
			style: ElevatedButton.styleFrom(
				backgroundColor: const Color.fromARGB(255, 159, 239, 167),
			),
			onPressed: () {},
			child: Text(
				buttonText,
				style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1),
			),
		);
	}
}
