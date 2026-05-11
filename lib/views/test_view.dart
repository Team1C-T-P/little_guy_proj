import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';
import '../models/database.dart';
import 'package:flutter_flame_playground/services/level_service.dart';

// Dummy values for the progress bars - will need to be replaced with actual values later on
int hunger = 50;
int enjoyment = 50;
int hygiene = 50;

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late StepPointsService _stepPointsService;
  final StepGoalController _goalController = StepGoalController();

  int _totalSteps = 0;
  int _currency = 0;
  int _leftoverSteps = 0;
  int _currentSteps = 0;
  String _status = '';

  // Named so dispose() can remove it. An anonymous closure can't be removed,
  // which would leak a listener every time the screen is opened.
  late final VoidCallback _goalListener;

  @override
  void initState() {
    super.initState();
    AppDatabase.instance.database.then((db) {
      _stepPointsService = StepPointsService(db);
      _loadSummary();
    });

    _goalListener = () {
      if (mounted) setState(() {});
    };
    _goalController.addListener(_goalListener);
  }

  @override
  void dispose() {
    _goalController.removeListener(_goalListener);
    super.dispose();
  }

  Future<void> _loadSummary() async {
    try {
      final summary = await _stepPointsService.getAccountSummary(1);
      await _goalController.loadData();

      if (!mounted) return;
      setState(() {
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

  Future<void> _recordTestSteps(int steps) async {
    try {
      final result = await _stepPointsService.recordSteps(
        userId: 1,
        steps: steps,
      );

      // ✅ Grant XP (1 XP per 100 steps)
      final db = await AppDatabase.instance.database;
      final levelService = LevelService(db);
      final levelResult = await levelService.addXp(1, steps ~/ 100);

      await _goalController.refreshSteps();

      if (!mounted) return;
      setState(() {
        _totalSteps = result.totalSteps;
        _currency = result.updatedCurrency;
        _leftoverSteps = result.unconvertedSteps;
        _currentSteps = _goalController.currentSteps;
        _status =
            'Recorded ${result.recordedSteps} steps | +${result.pointsAwarded} points';
      });

      // Show level‑up snackbar if applicable
      if (levelResult['leveledUp'] == 1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🎉 Your Little Guy reached level ${levelResult['level']}! 🎉',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Failed to record steps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Total Steps:', style: TextStyle(fontSize: 24)),
            Text(
              '$_totalSteps',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              'Current Steps: ${_goalController.currentSteps}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: ${_goalController.stepGoal}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text('Currency: $_currency', style: const TextStyle(fontSize: 20)),
            Text(
              'Steps toward next goal: ${(_goalController.stepGoal - _totalSteps).clamp(0, double.infinity).toInt()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _recordTestSteps(1),
              child: const Text('Record 1 Step'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _recordTestSteps(250),
              child: const Text('Record 250 Steps'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = _goalController.stepGoal + 250;
                await _goalController.updateGoal(newGoal);

                setState(() {
                  _goalController.stepGoal = newGoal;
                });
              },
              child: const Text('Increase Goal by 250'),
            ),

            const SizedBox(height: 12),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
