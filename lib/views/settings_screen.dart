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
          Column(
            children: [
              // Pet Name Setting
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Pet name',
                    prefixIcon: Icon(Icons.pets),
                  ),
                ),
              ),
              // User Name Setting
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'User name',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
              // Notifications Switch
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable Notifications',
                      style: TextStyle(fontSize: 16),
                    ),
                    Switch(
                      value: true, // You'll need to manage state for this
                      onChanged: (bool value) {
                        // Handle switch change
                      },
                    ),
                  ],
                ),
              ),
              // Volume Slider
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sound Volume', style: TextStyle(fontSize: 16)),
                    Slider(
                      value: 0.5, // You'll need to manage state for this
                      onChanged: (double value) {
                        // Handle slider change
                      },
                      min: 0,
                      max: 1,
                    ),
                  ],
                ),
              ),
            ],
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
