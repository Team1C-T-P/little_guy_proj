import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/widgets/progress_bar.dart';
import 'feed_view.dart';
import 'clean_view.dart';
import 'play_view.dart';
import '../models/pet_maintainment_database.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetStatsDatabase _petStatsDB = PetStatsDatabase();

  double _hunger = 0;
  double _enjoyment = 0;
  double _hygiene = 0;

  @override
  void initState() {
    super.initState();
    _loadPetStats();
    loadGoalData();
  }

  Future<void> _loadPetStats() async {
    double hunger = await _petStatsDB.getPetStat(1, 'hunger_level');
    double enjoyment = await _petStatsDB.getPetStat(1, 'enjoyment_level');
    double hygiene = await _petStatsDB.getPetStat(1, 'hygiene_level');
    String? lastOnlineIso = await _petStatsDB.getLastOnlineByUserId(1);
    lastOnlineIso ??= DateTime.now().toUtc().toIso8601String();

    DateTime lastOnline = DateTime.parse(lastOnlineIso);
    DateTime now = DateTime.now().toUtc();

    int hoursSinceLastOnline = now.difference(lastOnline).inHours;
    double decayBy = 0.1 * (hoursSinceLastOnline / 2);

    hunger = hunger - decayBy > 0 ? hunger - decayBy : 0;
    enjoyment = enjoyment - decayBy > 0 ? enjoyment - decayBy : 0;
    hygiene = hygiene - decayBy > 0 ? hygiene - decayBy : 0;

    await _petStatsDB.updatePetStat(1, 'hunger_level', hunger);
    await _petStatsDB.updatePetStat(1, 'enjoyment_level', enjoyment);
    await _petStatsDB.updatePetStat(1, 'hygiene_level', hygiene);
    await _petStatsDB.updateLastOnlineByUserId(1, now.toIso8601String());

    setState(() {
      _hunger = hunger;
      _enjoyment = enjoyment;
      _hygiene = hygiene;
    });
  }

  final StepGoalController controller = StepGoalController();
  int stepGoal = 0;
  int totalSteps = 0;

  Future<void> loadGoalData() async {
    final goal = await controller.loadGoal();
    final steps = await controller.loadTotalSteps();

    setState(() {
      stepGoal = goal;
      totalSteps = steps;
    });
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
            flex: 10,
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
                                  final newGoal = stepGoal + 250;
                                  await controller.updateGoal(newGoal);
                                  setState(() => stepGoal = newGoal);
                                },
                              ),
                            ),
                            Expanded(
                              child: GreenButton(
                                buttonText: "-250",
                                onPressed: () async {
                                  final newGoal = (stepGoal - 250).clamp(
                                    0,
                                    999999,
                                  );
                                  await controller.updateGoal(newGoal);
                                  setState(() => stepGoal = newGoal);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      // ✅ Text now flexible
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
                              "$totalSteps / $stepGoal steps",
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
