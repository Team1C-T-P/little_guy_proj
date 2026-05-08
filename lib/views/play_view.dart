import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import '../models/pet_maintainance_database.dart';
import '../models/database.dart';

class PlayScreen extends StatefulWidget {
  const PlayScreen({super.key});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  late PetStatsDatabase _petStatsDB;
  final ValueNotifier<bool> _petTrigger = ValueNotifier(false);

  // Dummy values will be replaced with actual values from the database
  double _enjoyment = 0;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _petStatsDB = PetStatsDatabase(db);
      _loadPetStats();
    });
  }

  Future<void> _loadPetStats() async {
    // load pet stats, assuming petId is 1 for now, will be dynamic later
    final enjoyment = await _petStatsDB.getPetStat(1, 'enjoyment_level');

    setState(() {
      _enjoyment = enjoyment;
    });
  }

  Future<void> _playWithPet() async {
    if (_enjoyment >= 1.0) {
      return;
    }
    // Start playing animation
    _petTrigger.value = true;

    // Update pet's enjoyment level in the database after animation starts
    await _petStatsDB.updatePetStat(
      1,
      'enjoyment_level',
      _enjoyment + 0.25 > 1.0 ? 1.0 : _enjoyment + 0.25,
    ); // Update pet's enjoyment level to max of 1.0
    _loadPetStats(); // Refresh data after playing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 0,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 24),
              color: Color.fromARGB(255, 213, 248, 255),
              child: Image.asset(
                'assets/images/cloud.png',
                width: 200,
                height: 100,
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/cloud.png',
                width: 100,
                height: 50,
              ),
            ),
          ),
          Expanded(
            flex: 0,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerRight,
              child: Image.asset(
                'assets/images/cloud.png',
                width: 200,
                height: 100,
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            color: Color.fromARGB(255, 221, 249, 255),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _playWithPet();
                },
                child: SizedBox(
                  width: 300,
                  height: 360,
                  child: PetLittleGuy(trigger: _petTrigger),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              child: Container(
                padding: const EdgeInsets.only(bottom: 50),
                color: Color.fromARGB(219, 150, 242, 176),
                width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(219, 246, 255, 226),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ProgressBar(
                    iconPath: 'assets/images/enjoyment.png',
                    progress: _enjoyment,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
