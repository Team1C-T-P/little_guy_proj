import 'package:flutter/material.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';

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
  final StepPointsService _stepPointsService = StepPointsService();
  final StepGoalController _goalController = StepGoalController();
  
  int _totalSteps = 0;
  int _currency = 0;
  int _leftoverSteps = 0;
  int _currentSteps = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadSummary();
  
    // Listener for any goal controller changes
    _goalController.addListener(() {
      if (mounted) {
        setState(() {});
        }
      });
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

      // Load updated steps and goal
      // if (_goalController.currentSteps >= _goalController.stepGoal) {
      //   _status = '🎉 Goal reached! +25 currency awarded';
      // }
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
              'Steps toward next point: $_leftoverSteps',
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
