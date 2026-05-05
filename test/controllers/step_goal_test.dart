
import 'package:flutter_flame_playground/controller/step_goal_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late StepGoalController stepGoalController;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    stepGoalController = StepGoalController();
  });

  tearDown(() async {
    await db.close();
  });

  group('loadData', () {
    test('loads current steps, goal, and total steps from database', () async {
      await TestDatabase.seedUser(db, currency: 100);
      
      // Create a goal
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 750);
      
      // Link user to goal with current progress
      await TestDatabase.seedUserGoal(db, userId: 1, goalId: goalId, currentProgress: 500);
      
      await stepGoalController.loadData();
      
      expect(stepGoalController.currentSteps, 500);
      expect(stepGoalController.stepGoal, 750);
      expect(stepGoalController.totalSteps, 500);
    });

    test('sets default values when user has no data', () async {
      await TestDatabase.seedUser(db, currency: 0);
      
      await stepGoalController.loadData();
      
      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
      expect(stepGoalController.totalSteps, 0);
    });

    // 'loadGoal should return default value of 250 when no goal exists or goal has already been reached and reset'
    group('loadGoal', () {
      test('returns goal from DB if it exists', () async {
        final userId = await TestDatabase.seedUser(db);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 750);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 500);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 750);
      });

      test('returns default value of 250 when no goal exists', () async {
        await TestDatabase.seedUser(db);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 250);
      });
    });

    // loadTotalSteps should return total steps from stepService
    // group('loadTotalSteps', () {
    //   test('returns total steps from stepService', () async {
    //     final userId = await TestDatabase.seedUser(db);
    //     await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 1000);
    //     await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 500);

    //     final totalSteps = await stepGoalController.loadTotalSteps();
    //     expect(totalSteps, 1500);
    //   });
    // });

    // updateGoal
    // group('updateGoal', () {
    //   test('updates goal in database and controller', () async {
    //     final userId = await TestDatabase.seedUser(db);
    //     await TestDatabase.seedGoal(db, targetGoal: 300);

    //     await stepGoalController.updateGoal(400);

    //     final newGoal = await TestDatabase.seedGoal(db, targetGoal: 400);
    //     expect(newGoal, 400);
    //     expect(stepGoalController.stepGoal, 400);
    //   });
    // });

    // refreshSteps
    // group('refreshSteps', () {
    //   test('updates all step data necessary for goal tracking', () async {
    //     final userId = await TestDatabase.seedUser(db, currency: 100);
    //     final goalId = await TestDatabase.seedGoal(db, targetGoal: 750);
    //     await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 500);
    //     await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 1000);
    //     await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 500);

    //     await stepGoalController.refreshSteps();

    //     expect(stepGoalController.currentSteps, 500);
    //     expect(stepGoalController.stepGoal, 750);
    //     expect(stepGoalController.totalSteps, 1500);
    //     expect(stepGoalController.currency, 100);
    //   });

    //   test('resets goal when current steps meet or exceed goal', () async {
    //     final userId = await TestDatabase.seedUser(db, currency: 100);
    //     final goalId = await TestDatabase.seedGoal(db, targetGoal: 750);
    //     await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 750);
    //     await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 750);

    //     await stepGoalController.refreshSteps();

    //     expect(stepGoalController.currentSteps, 0);
    //     expect(stepGoalController.stepGoal, 250);
    //   });
    // });
  });
}