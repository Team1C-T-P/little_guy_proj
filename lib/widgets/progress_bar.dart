import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  const ProgressBar({
    super.key,
    required this.iconPath,
    required this.progress,
  });

  final double progress;
  final String iconPath;

  @override
  State<ProgressBar> createState() => _ProgressBarState();

}

class _ProgressBarState extends State<ProgressBar> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 40,
          height: 40,
          child: Image.asset(widget.iconPath),
        ),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: widget.progress,
            backgroundColor: Color.fromARGB(255, 248, 255, 233,),
            color: Color.fromARGB(255, 159, 239, 167),
            minHeight: 10,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
        )
      ],
    );
  }
}