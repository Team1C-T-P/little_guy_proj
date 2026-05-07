import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import '../models/database.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    // required this.db? OR
    // required this.userName,
    // required this.petName, ?
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _switchBtn = false;
  double _soundVolume = 0.5;
  //put this up under class declaration?
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  late PetStatsDatabase _db;
  final int _userId = 1; // Assuming single user per phone with ID 1

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _db = PetStatsDatabase(db);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userName = await _db.getUserName(_userId);
    final petName = await _db.getPetName(_userId);

    setState(() {
      _userNameController.text = userName ?? '';
      _petNameController.text = petName ?? '';
    });
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings Screen')),
      backgroundColor: Color.fromARGB(219, 173, 230, 189),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
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
                      Text('Try me', style: TextStyle(fontSize: 16)),
                      Switch(
                        value: _switchBtn,
                        onChanged: (bool value) {
                          setState(() {
                            _switchBtn = value;

                            if (_switchBtn) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '6 7',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
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
                      // if text changed then fix in testing as well
                      Text('probs font size', style: TextStyle(fontSize: 16)),
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
                      Text(
                        _soundVolume.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              child: GreenButton(
                buttonText: "Submit",
                onPressed: () async {
                  // Update database
                  await _db.updateUserName(_userId, _userNameController.text);
                  await _db.updatePetName(_userId, _petNameController.text);

                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Settings saved')));
                  }
                },
              ),
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
