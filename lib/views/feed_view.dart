import 'package:flutter/material.dart';
// import 'package:flutter_flame_playground/widgets/button.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Feed Screen"
      ),
    );
  }
}