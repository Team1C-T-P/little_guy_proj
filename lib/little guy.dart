import 'package:flutter/material.dart';

class LittleGuy extends StatefulWidget {
  const LittleGuy({super.key});

  @override
  State<LittleGuy> createState() => _LittleGuyState();
}

class _LittleGuyState extends State<LittleGuy>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _walkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    //walking back and forth animation
    _walkAnimation = TweenSequence([
      // Walk right
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 30.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),

      TweenSequenceItem(tween: ConstantTween(30.0), weight: 10),

      TweenSequenceItem(
        tween: Tween(
          begin: 30.0,
          end: -30.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),

      TweenSequenceItem(tween: ConstantTween(-30.0), weight: 10),

      TweenSequenceItem(
        tween: Tween(
          begin: -30.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _walkAnimation,
      builder: (_, child) {
        // final t = _controller.value * 2 * pi;

        // final dx = cos(t) * 6;  // left/right
        // final dy = sin(t) * 8;  // up/down

        return Transform.translate(
          offset: Offset(_walkAnimation.value, 0),
          child: child,
        );
      },
      child: Image.asset(
        'images/funnyguy.png', // need to change to be pet but structure
        width: 150,
      ),
    );
  }
}
