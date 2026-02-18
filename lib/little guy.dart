import 'package:flutter/material.dart';
import 'dart:math';

class LittleGuy extends StatefulWidget {
  const LittleGuy({super.key});

  @override
  State<LittleGuy> createState() => _LittleGuyState();
}

class _LittleGuyState extends State<LittleGuy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t = _controller.value * 2 * pi;

        final dx = cos(t) * 6;  // left/right
        final dy = sin(t) * 8;  // up/down

        return Transform.translate(
          offset: Offset(dx, dy),
          child: child,
        );
      },
      child: Image.asset(
        'images/clover.png', // need to change to be pet but structure
        width: 150,
      ),
    );
  }
}