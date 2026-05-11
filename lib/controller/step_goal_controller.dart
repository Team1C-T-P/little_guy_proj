import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../models/goal_service_database.dart';
import '../models/step_points_service.dart';
import '../models/database.dart';

class StepGoalController extends ChangeNotifier {
  static final StepGoalController _instance = StepGoalController._internal();
  factory StepGoalController() => _instance;
  StepGoalController._internal();

  GoalService? goalService;
  StepPointsService? stepService;

  int totalSteps = 0; // DB total steps
  int currentSteps = 0; // steps since last goal reset
  int stepGoal = 250; // user’s daily goal
  bool goalReached = false;
  int currency = 0;
  int leftoverSteps = 0;

  final int userId = 1;

  Future<void> init({Database? testDb}) async {
    final db = testDb ?? await AppDatabase.instance.database;
    goalService = GoalService(db);
    stepService = StepPointsService(db);
  }

  Future<void> loadData() async {
    try {
      if (goalService == null || stepService == null) await init();
      currentSteps = await goalService!.getCurrentSteps(userId);
      stepGoal = await loadGoal();
      totalSteps = await loadTotalSteps();
      goalReached = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing stats: $e');
    }
  }

  // Load goal from DB
  Future<int> loadGoal() async {
    goalReached = false;
    final goal = await goalService!.getDailyStepGoal(userId);
    return goal ?? 250;
  }

  // Load total steps from DB
  Future<int> loadTotalSteps() async {
    final summary = await stepService!.getAccountSummary(userId);
    return summary.totalSteps;
  }

  // Update the user's daily goal
  Future<void> updateGoal(int newGoal) async {
    if (newGoal <= 0) {
      throw Exception('Invalid goal value');
    }
    await goalService!.setDailyStepGoal(userId, newGoal);
    stepGoal = newGoal;
    goalReached = false;
    notifyListeners();
  }

  Future<void> refreshSteps() async {
    try {
      // Load from both services
      final summary = await stepService!.getAccountSummary(userId);
      totalSteps = summary.totalSteps;
      currency = summary.currency;
      leftoverSteps = summary.unconvertedSteps;

      currentSteps = await goalService!.getCurrentSteps(userId);
      stepGoal = await loadGoal();

      if (currentSteps >= stepGoal && stepGoal > 0 && !goalReached) {
        currency = await goalService!.resetGoal(userId);
        currentSteps = 0;
        stepGoal = 250;
        goalReached = true;
      }

      notifyListeners();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }
}
