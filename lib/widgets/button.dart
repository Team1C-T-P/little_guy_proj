import 'package:flutter/material.dart';

class GreenButton extends StatelessWidget {
  const GreenButton({
    super.key,
    required this.buttonText,
    required this.onPressed,
  });

  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 159, 239, 167),
      ),
      onPressed: onPressed,
      child: Text(
        buttonText,
        style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1),
      ),
    );
  }
}
