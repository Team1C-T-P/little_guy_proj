import 'package:flutter/foundation.dart';
import '../models/goal_service.dart';
import '../models/step_points_service.dart';

class StepGoalController extends ChangeNotifier {
  final GoalService goalService = GoalService();
  final StepPointsService stepService = StepPointsService();

  int totalSteps = 0;     // DB total steps
  int currentSteps = 0; // steps since last goal reset
  int stepGoal = 0;       // user’s daily goal
  bool goalReached = false;

  final int userId = 1;

  Future<void> loadData() async {
    stepGoal = await loadGoal();
    totalSteps = await loadTotalSteps();       // lifetime steps
    currentSteps = await goalService.getCurrentSteps(userId); // resettable steps
    notifyListeners();
  }

  // Load goal from DB
  Future<int> loadGoal() async {
    goalReached = false;
    final goal = await goalService.getDailyStepGoal(userId);
    return goal ?? 0;
  }

  // Load total steps from DB
  Future<int> loadTotalSteps() async {
    final summary = await stepService.getAccountSummary(userId);
    return summary.totalSteps;
  }

  // Update the user's daily goal
  Future<void> updateGoal(int newGoal) async {
    goalReached = false;
    await goalService.setDailyStepGoal(userId, newGoal);
    stepGoal = newGoal;
    notifyListeners();
  }

  Future<void> refreshSteps() async {
    totalSteps = await loadTotalSteps();
    currentSteps = await goalService.getCurrentSteps(userId);
    final reached = currentSteps >= stepGoal;

    if (reached && !goalReached) {
      await goalService.resetGoal(userId);
      currentSteps = 0;
      stepGoal = 250;
      goalReached = true;

      notifyListeners();
      return;
    }
    notifyListeners();
  }

  Future<void> onGoalReached() async {
    print("🎉 Goal reached!");
    // celebration logic only
  }
}
