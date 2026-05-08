import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart'; // use step_points_service instead?
import 'package:flutter_flame_playground/models/shop_database.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';
import 'package:flutter_flame_playground/models/dress_database.dart';
import 'package:flutter_flame_playground/services/achievement_service.dart';
import 'package:sqflite/sqflite.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileState();
}

//instead of getting data from pet_maintainment_database can we get it from step points service? - as there is a summary.
class _ProfileState extends State<ProfileScreen> {
  late StepPointsService _stepPointsService;
  final StepGoalController _goalController = StepGoalController();
  int _hatsCollected = 0;
  String _userName = "";
  String _petName = "";
  int _totalSteps = 0;
  int _currency = 0;
  int _leftoverSteps = 0;
  int _currentSteps = 0;
  late PetStatsDatabase _db;
  String _status = '';
  bool _madHatterCompleted = false;
  bool _bigWalkCompleted = false;
  bool _trailBlazerCompleted = false;
  bool _letsPlayCompleted = false;
  bool _mvpCompleted = false;
  final int _userId = 1; // Assuming single user per phone with ID 1

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _stepPointsService = StepPointsService(db);
      _loadData();
    });

    // Listener for any goal controller changes
    _goalController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _loadData() async {
    try {
      print('Big Walk completed: $_bigWalkCompleted');
      print('Trail Blazer completed: $_trailBlazerCompleted');
      print('Let\'s Play completed: $_letsPlayCompleted');
      print('MVP completed: $_mvpCompleted');
      print('Hats collected: $_hatsCollected');
      final summary = await _stepPointsService.getAccountSummary(1);
      await _goalController.loadData();
      final db = await AppDatabase.instance.database;
      final dressDb = DressDatabase(db);
      final ownedHats = await dressDb.getHatsOwnedByUser(_userId);
      _hatsCollected = ownedHats.length;

      final achievementService = AchievementService(db);
      final unlockedIds = await achievementService.getUnlockedAchievementIds(
        _userId,
      );

      await _checkMadHatterAchievement();
      final achievementMap = await _getAchievementIdMap(db);
      if (!mounted) return;
      setState(() {
        _bigWalkCompleted = unlockedIds.contains(achievementMap['steps_total']);
        _trailBlazerCompleted = unlockedIds.contains(
          achievementMap['route_created'],
        );
        _letsPlayCompleted = unlockedIds.contains(achievementMap['play_count']);
        _mvpCompleted = unlockedIds.contains(achievementMap['pet_level']);

        _totalSteps = summary.totalSteps;
        _currency = summary.currency;
        _leftoverSteps = summary.unconvertedSteps;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to load summary: $e';
      });
    }
  }

  Future<Map<String, int>> _getAchievementIdMap(Database db) async {
    final result = await db.query('achievement');
    return {
      for (var row in result)
        row['type'] as String: row['achievement_id'] as int,
    };
  }

  Future<void> _checkMadHatterAchievement() async {
    // Get hat count
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    final ownedHats = await dressDb.getHatsOwnedByUser(_userId);
    final hatCount = ownedHats.length;

    // If target reached (5 or more hats)
    if (hatCount >= 5) {
      // TODO: mark achievement as completed (see options below)
      setState(() {
        _madHatterCompleted = true;
      });
      // Optionally show a congratulatory message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mad Hatter achievement unlocked!')),
      );
    }
  }

  Future<void> _recordTestSteps(int steps) async {
    try {
      final result = await _stepPointsService.recordSteps(
        userId: 1,
        steps: steps,
      );
      await _goalController.refreshSteps();

      // update UI with the new values
      if (!mounted) return;
      setState(() {
        _totalSteps = result.totalSteps;
        _currency = result.updatedCurrency;
        _leftoverSteps = result.unconvertedSteps;
        _currentSteps = _goalController.currentSteps;
        _status =
            'Recorded ${result.recordedSteps} steps | +${result.pointsAwarded} points';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to record steps: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 250, 255, 251),
      // appBar: AppBar(
      //   backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      //   title: const Text('Profile Page'),
      // ),
      body: Column(
        children: <Widget>[
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
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: <Widget>[
                              DefaultTextStyle.merge(
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      child: Text("$_userName | $_petName"),
                                    ),
                                    Container(child: Text(" - ")),
                                    Container(child: Text("£$_currency")),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Total Steps: $_totalSteps"),
                                    Text("Items Collected: $_hatsCollected "),
                                    Text("Little Guy LVL:  "),
                                  ],
                                ),
                              ),
                              Gap(5),
                              Container(
                                child: const Text(
                                  'Achievements',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Gap(5),
                              Row(
                                children: [
                                  Align(
                                    // no const, because even if text is static now, we mix with dynamic
                                    alignment: Alignment.center,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: const [
                                            // keep const for static children
                                            Text(
                                              "Big Walk",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Walk 5K",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // but the third Text cannot be const – we'll replace below
                                          ],
                                        ),
                                        const Gap(10),
                                        Column(
                                          children: const [
                                            Text(
                                              "Trail Blazer",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Set-up a route",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(), // Spacer can stay const
                                  Align(
                                    // no const – contains dynamic _madHatterCompleted
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: const [
                                            Text(
                                              "Socialite",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Get 5 friends. Aww!",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(10),
                                        Column(
                                          children: [
                                            const Text(
                                              "Mad Hatter",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Get 10 Hats",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              // dynamic – cannot be const
                                              _madHatterCompleted
                                                  ? "Completed"
                                                  : "Not completed",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    // no const – contains dynamic _bigWalkCompleted, etc.
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            const Text(
                                              "Let's Play!",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Play 20 times",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              // dynamic
                                              _letsPlayCompleted
                                                  ? "Completed"
                                                  : "Not completed",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Gap(10),
                                        Column(
                                          children: [
                                            const Text(
                                              "Most Valuable Pet",
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Max lvl a pet",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              // dynamic
                                              _mvpCompleted
                                                  ? "Completed"
                                                  : "Not completed",
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
