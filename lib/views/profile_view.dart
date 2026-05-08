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
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_flame_playground/widgets/progress_bar.dart';

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
  bool _wealthyCompleted = false;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) async {
      _stepPointsService = StepPointsService(db);
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _madHatterCompleted = prefs.getBool('madHatterClaimed') ?? false;
        _bigWalkCompleted = prefs.getBool('bigWalkClaimed') ?? false;
        _wealthyCompleted = prefs.getBool('wealthyClaimed') ?? false;
      });
      _loadData();
    });
    _goalController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadData() async {
    try {
      final summary = await _stepPointsService.getAccountSummary(1);
      await _goalController.loadData();

      final db = await AppDatabase.instance.database;
      final dressDb = DressDatabase(db);
      final ownedHats = await dressDb.getHatsOwnedByUser(_userId);
      _hatsCollected = ownedHats.length;

      // Check Mad Hatter (and later other achievements)
      await _checkMadHatterAchievement();
      await _checkBigWalkAchievement(summary.totalSteps);
      await _checkWealthyAchievement(summary.currency);
      await _checkTrailBlazerAchievement();

      if (mounted) {
        setState(() {
          _totalSteps = summary.totalSteps;
          _currency = summary.currency;
          _leftoverSteps = summary.unconvertedSteps;
          _currentSteps = _goalController.currentSteps;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed to load summary: $e');
    }
  }

  Future<void> _checkTrailBlazerAchievement() async {
    final prefs = await SharedPreferences.getInstance();
    final claimed = prefs.getBool('trailBlazerClaimed') ?? false;
    if (claimed != _trailBlazerCompleted) {
      setState(() => _trailBlazerCompleted = claimed);
    }
  }

  Future<void> checkAndUnlockTrailBlazer(
    BuildContext context,
    int userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('trailBlazerClaimed') ?? false;
    if (alreadyClaimed) return;

    final db = await AppDatabase.instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM route WHERE user_id = ?', [
            userId,
          ]),
        ) ??
        0;

    if (count >= 1) {
      await prefs.setBool('trailBlazerClaimed', true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Trail Blazer achievement unlocked! You saved your first route!',
            ),
          ),
        );
      }
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
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('madHatterClaimed') ?? false;

    if (alreadyClaimed) {
      if (!_madHatterCompleted) {
        setState(() => _madHatterCompleted = true);
      }
      return;
    }

    if (_hatsCollected >= 5) {
      setState(() => _madHatterCompleted = true);
      await prefs.setBool('madHatterClaimed', true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mad Hatter achievement unlocked!')),
      );
    }
  }

  Future<void> _checkWealthyAchievement(int currency) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('wealthyClaimed') ?? false;

    if (alreadyClaimed) {
      if (!_wealthyCompleted) setState(() => _wealthyCompleted = true);
      return;
    }

    if (currency >= 5000) {
      setState(() => _wealthyCompleted = true);
      await prefs.setBool('wealthyClaimed', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wealthy achievement unlocked! 5000 currency!'),
          ),
        );
      }
    }
  }

  Future<void> _checkBigWalkAchievement(int totalSteps) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('bigWalkClaimed') ?? false;

    if (alreadyClaimed) {
      if (!_bigWalkCompleted) setState(() => _bigWalkCompleted = true);
      return;
    }

    if (totalSteps >= 5000) {
      setState(() => _bigWalkCompleted = true);
      await prefs.setBool('bigWalkClaimed', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Big Walk achievement unlocked! Walked 5,000 steps total!',
            ),
          ),
        );
      }
    }
  }

  Future<void> _recordTestSteps(int steps) async {
    try {
      final result = await _stepPointsService.recordSteps(
        userId: 1,
        steps: steps,
      );
      await _goalController.refreshSteps();
      await _checkBigWalkAchievement(result.totalSteps);
      await _checkWealthyAchievement(result.updatedCurrency);

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
                                    Text("Current Lvl:"),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: <Widget>[
                                        Text("Lvl progress:"),
                                        ProgressBar(
                                          iconPath: 'assets/images/lvl.png',
                                          progress: 0.5,
                                        ),
                                      ],
                                    ),
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
                                          children: [
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
                                            Text(
                                              // dynamic
                                              _bigWalkCompleted
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
                                            Text(
                                              _trailBlazerCompleted
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
                                  const Spacer(), // Spacer can stay const
                                  Align(
                                    // no const – contains dynamic _madHatterCompleted
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              "Wealthy",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Get 5K",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              // dynamic – cannot be const
                                              _wealthyCompleted
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
                                              "Mad Hatter",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              "Get 5 Hats",
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
