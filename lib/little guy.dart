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
    return Align(
      alignment: Alignment.bottomCenter, // Aligns the widget to the bottom
      child: AnimatedBuilder(
        animation: _walkAnimation,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(_walkAnimation.value, 0),
            child: child,
          );
        },
        child: Image.asset('assets/images/funnyguy.png', width: 180),
      ),
    );
  }
}

class CleaningLittleGuy extends StatefulWidget {
  final ValueNotifier<bool> trigger;

  const CleaningLittleGuy({super.key, required this.trigger});

  @override
  State<CleaningLittleGuy> createState() => _CleaningLittleGuyState();
}

class _CleaningLittleGuyState extends State<CleaningLittleGuy>  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _soapAnimationX;
  late Animation<double> _soapAnimationY;
  late Animation<double> _bubbleOpacityAnimation;
  late Animation<double> _rainFallAnimation;

  // variables used to control the visibility of soap 
  String _currentPetImage = 'assets/images/funnyguy.png';

  void startCleaningAnimation() {
    _controller.forward(from: 0.0);
  }

  @override
  void initState() {
    super.initState();

    widget.trigger.addListener(() {
      if (widget.trigger.value) {
        startCleaningAnimation();
        widget.trigger.value = false; // reset trigger
      }
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  
    _soapAnimationX = TweenSequence(
      [
        TweenSequenceItem(
          tween: Tween(
            begin: -90.0,
            end: 180.0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 180.0,
            end: -180.0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: -180.0,
            end: 90.0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      ]
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.linear)
      )
    );

    _soapAnimationY = Tween(
      begin: -160.0,
      end: 160.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.linear)
      )
    );

    _bubbleOpacityAnimation = TweenSequence(
      [
        TweenSequenceItem(
          tween: Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 3,
        ),
        TweenSequenceItem(
          tween: ConstantTween(1.0),
          weight: 3,
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
      ]
    ).animate(_controller);

    _rainFallAnimation = Tween(
      begin: -360.0,
      end: 180.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.linear)
      )
    );

    _controller.addListener(() {
     setState(() {});
    });
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 360,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pet Image
              Image.asset(_currentPetImage, width: 360),

              // Soap Image and animation
              if (_controller.value < 0.75 && _controller.value > 0.0)
                Transform.translate(
                  offset: Offset(_soapAnimationX.value, _soapAnimationY.value),
                  child: Image.asset('assets/images/hygiene.png', width: 50),
                ),
              
              // Bubble fade in animation
              Opacity(
                opacity: _bubbleOpacityAnimation.value,
                child: Image.asset('assets/images/bubbles.png', width: 360),
              ),

              // Rain falls down animation
              if (_controller.value >= 0.75 && _controller.value < 1.0)
                Transform.translate(
                  offset: Offset(0, _rainFallAnimation.value),
                  child: Image.asset('assets/images/rain.png', width: 360),
                ),
            ]
          )
        )
      ],
    );
  }
}