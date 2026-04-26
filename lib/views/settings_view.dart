import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  double _soundVolume = 0.5;
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();

  @override
  void dispose() {
    _petNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(219, 173, 230, 189),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Padding(padding: const EdgeInsets.all(16.0)),
            // settings title
            Text('Settings', style: TextStyle(fontSize: 32)),
            // clover image
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(right: 18),
              child: Image.asset("assets/images/clover.png"),
            ),
            Column(
              children: [
                // Pet Name Setting
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _petNameController,
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
                    controller: _userNameController,
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
                        value: _notificationsEnabled,
                        onChanged: (bool value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
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
                        value: _soundVolume,
                        onChanged: (double value) {
                          setState(() {
                            _soundVolume = value;
                          });
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
              child: Image.asset("assets/images/daisy.png"),
            ),
          ],
        ),
      ),
    );
  }
}
