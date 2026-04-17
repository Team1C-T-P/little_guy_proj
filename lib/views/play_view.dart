import 'main_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/little%20guy.dart';


class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.only(left: 24),
            color: Color.fromARGB(255, 213, 248, 255),
            child: Image.asset('assets/images/cloud.png')
          ),
          Container(
            color: Color.fromARGB(255, 221, 249, 255),
            alignment: Alignment.centerLeft,
            child: Image.asset('assets/images/cloud.png')
          ),
          Container(
            color: Color.fromARGB(255, 221, 249, 255),
            alignment: Alignment.centerRight,
            child: Image.asset('assets/images/cloud.png')
          ),
          Container(
            alignment: Alignment.bottomCenter,
            color: Color.fromARGB(255, 221, 249, 255),
            child: Center(child: LittleGuy()),
          ),
        ],
      ),
    );
  }
}