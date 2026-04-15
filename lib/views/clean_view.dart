import 'package:flutter/material.dart';
// import 'package:flutter_flame_playground/widgets/button.dart';


class CleanScreen extends StatefulWidget {
  const CleanScreen({super.key});

  @override
  State<CleanScreen> createState() => _CleanScreenState();
}

class _CleanScreenState extends State<CleanScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Clean Screen"
      ),
    );
  }
}