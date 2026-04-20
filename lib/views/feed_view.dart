import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import '../models/pet_maintainment_database.dart';


class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final PetStatsDatabase _petStatsDB = PetStatsDatabase();

  // Dummy values will be replaced with actual values from the database
  double _hunger = 0;
  
  @override 
  void initState() {
    super.initState();
    _loadPetHunger();
  }

  Future<void> _loadPetHunger() async {
    final hunger = await _petStatsDB.getPetStat(1, 'hunger_level');

    setState(() {
      _hunger = hunger;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: Column(
        children: <Widget>[
          // Decoration for the background
          Expanded(
            flex: 2,
            child: Column(
              children: [
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
                Expanded(
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    color: Color.fromARGB(255, 221, 249, 255),
                    child: Center(child: LittleGuy()),
                  ),
                ),
              ],
            ),
          ),
          // Main content of the page
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              color: const Color.fromARGB(219, 150, 242, 176),
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.center,
              child: 
              Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ProgressBar(
                      iconPath: 'assets/images/hunger.png',
                      progress: _hunger,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(219, 246, 255, 226),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      //child: GridView.builder(
                        //padding: const EdgeInsets.all(8),
                        //gridDelegate: , 
                        //itemBuilder: itemBuilder
                      //)
                    )
                  ),
                  const Gap(16),
                  GreenButton(
                    buttonText: "Feed", 
                    onPressed: (){
                      setState(() {
                      });
                    },
                  )
                ]
              ),
            ),
          ),
        ],
      )
    );
  }
}