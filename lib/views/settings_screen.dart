import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(219, 173, 230, 189),
      body: Column(
        children: <Widget>[
          Text('Settings', style: TextStyle(fontSize: 32)),
          Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(right: 18),
            child: Image.asset("images/clover.png"),
          ),
          Container(
            alignment: Alignment.bottomRight,
            padding: const EdgeInsets.only(right: 18),
            child: Image.asset("images/daisy.png"),
          ),
        ],
      ),
    );
  }
}
