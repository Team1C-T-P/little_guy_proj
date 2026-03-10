import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';

// Dummy values for the progress bars - will need to be replaced with actual values later on
int hunger = 50;
int enjoyment = 50;
int hygiene = 50;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(child: Text("meow")),
    );
  }
}
