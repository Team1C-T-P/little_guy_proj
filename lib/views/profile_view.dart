import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little_guy.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';
import 'package:flutter_flame_playground/models/dress_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_flame_playground/services/level_service.dart';
import 'package:flutter_flame_playground/utils/achievement_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileState();
}

class _ProfileState extends State<ProfileScreen> {
  late StepPointsService _stepPointsService;
  final StepGoalController _goalController = StepGoalController();
  int _currentLevel = 1;
  int _currentXp = 0;
  double _xpProgress = 0.0;
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
        _mvpCompleted = prefs.getBool('mvpClaimed') ?? false;
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

      final userResult = await db.query(
        'user',
        where: 'user_id = ?',
        whereArgs: [_userId],
      );
      if (userResult.isNotEmpty) {
        _userName = userResult.first['user_name'] as String;
      }

      final petResult = await db.query(
        'little_guy',
        where: 'user_id = ?',
        whereArgs: [_userId],
      );
      if (petResult.isNotEmpty) {
        _petName = petResult.first['little_guy_name'] as String;
      }

      final dressDb = DressDatabase(db);
      final ownedHats = await dressDb.getHatsOwnedByUser(_userId);
      _hatsCollected = ownedHats.length;

      // Check achivements
      await _checkMadHatterAchievement();
      await _checkBigWalkAchievement(summary.totalSteps);
      await _checkWealthyAchievement(summary.currency);
      await _checkTrailBlazerAchievement();
      await _checkMVPAchievement(_currentLevel);

      final levelService = LevelService(db);
      final levelData = await levelService.getLevelAndXp(_userId);
      final currentLevel = levelData['level']!;
      await _checkMVPAchievement(currentLevel);
      if (mounted) {
        setState(() {
          _currentLevel = levelData['level']!;
          _currentXp = levelData['xp']!;
          _xpProgress = _currentXp / 100.0;
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

  Future<void> _checkMVPAchievement(int currentLevel) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('mvpClaimed') ?? false;

    if (alreadyClaimed) {
      if (!_mvpCompleted) setState(() => _mvpCompleted = true);
      return;
    }

    if (currentLevel >= 5) {
      setState(() => _mvpCompleted = true);
      await prefs.setBool('mvpClaimed', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Most Valuable Pet achievement unlocked. Level 5 reached.',
            ),
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 250, 255, 251),
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
                                    const SizedBox(height: 8),
                                    Text("Little Guy LVL: $_currentLevel"),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: _xpProgress,
                                            backgroundColor: Colors.grey[300],
                                            color: Colors.green,
                                            minHeight: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text("$_currentXp / 100"),
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
                                    alignment: Alignment.center,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          children: [
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
                                  const Spacer(),
                                  Align(
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
                                                  "Get to LVL 5",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
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
