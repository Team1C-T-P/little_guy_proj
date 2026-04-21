import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import '../models/pet_maintainment_database.dart';


class CleanScreen extends StatefulWidget {
  const CleanScreen({super.key});

  @override
  State<CleanScreen> createState() => _CleanScreenState();
}

class _CleanScreenState extends State<CleanScreen> {
  final PetStatsDatabase _petStatsDB = PetStatsDatabase();
  
  // Dummy values will be replaced with actual values from the database
  double _hygiene = 0;

  @override
  void initState() {
    super.initState();
    _loadPetHygiene();
  }

  Future<void> _loadPetHygiene() async {
    // load pet stats, assuming petId is 1 for now, will be dynamic later
    final hygiene = await _petStatsDB.getPetStat(1, 'hygiene_level');

    setState(() {
      _hygiene = hygiene;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(left: 24),
              color: Color.fromARGB(255, 213, 248, 255),
              child: Image.asset('assets/images/cloud.png')
            )
          ),
          Expanded(
            flex: 1,
            child: 
            Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerLeft,
              child: Image.asset('assets/images/cloud.png')
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerRight,
              child: Image.asset('assets/images/cloud.png')
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: CleaningLittleGuy()),
            ),
          ),
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: Color.fromARGB(219, 150, 242, 176),
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ProgressBar(
                      iconPath: 'assets/images/hygiene.png',
                      progress: _hygiene,
                    ),
                  ),
                  const Gap(16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: IconButton(
                      icon: Image.asset('assets/images/hygiene.png'),
                      iconSize: 50,
                      onPressed: () {
                      },
                    )
                  )
                ]
              ),
            )
          ),
        ],
      ),
    );
  }
}