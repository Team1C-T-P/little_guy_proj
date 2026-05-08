import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'feed_view.dart';
import 'clean_view.dart';
import 'play_view.dart';
import '../models/pet_maintainance_database.dart';
import '../models/database.dart';
import 'package:flutter_flame_playground/utils/stat_degradation_service.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PetStatsDatabase _petStatsDB;
  late StatDegradation _statDegradation;
  final StepGoalController _goalController = StepGoalController();
  int userId = 1;
  int petId = 1;

  double _hunger = 0;
  double _enjoyment = 0;
  double _hygiene = 0;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _petStatsDB = PetStatsDatabase(db);
      _statDegradation = StatDegradation(
        petStatsDB: _petStatsDB,
        userID: userId,
        petID: petId,
      );
      _loadPetStats();
    });
    _loadGoalData();
  }

  Future<void> _loadPetStats() async {
    await _statDegradation.degradeStats();

    double hunger = await _petStatsDB.getPetStat(petId, 'hunger_level');
    double enjoyment = await _petStatsDB.getPetStat(petId, 'enjoyment_level');
    double hygiene = await _petStatsDB.getPetStat(petId, 'hygiene_level');

    setState(() {
      _hunger = hunger;
      _enjoyment = enjoyment;
      _hygiene = hygiene;
    });
  }

  Future<void> _loadGoalData() async {
    await _goalController.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 24),
            color: Color.fromARGB(255, 213, 248, 255),
            child: Image.asset('assets/images/cloud.png'),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.centerRight,
              child: Image.asset('assets/images/cloud.png'),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: Color.fromARGB(255, 221, 249, 255),
              alignment: Alignment.center,
              child: Image.asset('assets/images/cloud.png'),
            ),
          ),
          Expanded(
            flex: 100,
            child: Container(
              alignment: Alignment.bottomCenter,
              color: Color.fromARGB(255, 221, 249, 255),
              child: Center(child: LittleGuy()),
            ),
          ),
          Container(
            color: Color.fromARGB(219, 150, 242, 176),
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 12, right: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: GreenButton(
                                buttonText: "+250",
                                onPressed: () async {
                                  final newGoal =
                                      _goalController.stepGoal + 250;
                                  await _goalController.updateGoal(newGoal);
                                  // setState(() => _goalController.stepGoal = newGoal);
                                },
                              ),
                            ),
                            Expanded(
                              child: GreenButton(
                                buttonText: "-250",
                                onPressed: () async {
                                  final newGoal =
                                      (_goalController.stepGoal - 250).clamp(
                                        0,
                                        999999,
                                      );
                                  await _goalController.updateGoal(newGoal);
                                  // setState(() => _goalController.stepGoal = newGoal);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Today's Goal",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              "${_goalController.currentSteps} / ${_goalController.stepGoal} steps",
                              style: TextStyle(fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Image.asset('assets/images/clover.png'),
                    Spacer(),

                    SizedBox(
                      width: 150,
                      height: 50,
                      child: FittedBox(
                        child: GreenButton(
                          buttonText: "Feed",
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const FeedScreen(),
                              ),
                            );
                            await _loadPetStats();
                          },
                        ),
                      ),
                    ),

                    Spacer(),
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.only(right: 18),
                      child: Image.asset('assets/images/flowerplant.png'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: <Widget>[
                      Spacer(),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: FittedBox(
                          child: GreenButton(
                            buttonText: "Play",
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const PlayScreen(),
                                ),
                              );
                              await _loadPetStats();
                            },
                          ),
                        ),
                      ),
                      Spacer(),
                      SizedBox(
                        width: 150,
                        height: 50,
                        child: FittedBox(
                          child: GreenButton(
                            buttonText: "Clean",
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const CleanScreen(),
                                ),
                              );
                              await _loadPetStats();
                            },
                          ),
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width,
                    height: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ProgressBar(
                              iconPath: 'assets/images/hunger.png',
                              progress: _hunger,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            ProgressBar(
                              iconPath: 'assets/images/enjoyment.png',
                              progress: _enjoyment,
                            ),

                            Gap(MediaQuery.of(context).size.width * 0.1),

                            ProgressBar(
                              iconPath: 'assets/images/hygiene.png',
                              progress: _hygiene,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
