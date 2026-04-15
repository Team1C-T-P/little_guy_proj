import 'package:flutter/material.dart';
// import 'package:flutter_flame_playground/widgets/button.dart';


class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Play Screen"
      ),
    );
  }
}