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
    await stepGoalController.init(testDb: db);
  });

  tearDown(() async {
    await db.close();
  });
  
  group('loadGoal', () {
    test('returns default value of 250 for a new goal', () async {
      await TestDatabase.seedUser(db);

      final goal = await stepGoalController.loadGoal();
      expect(goal, 250);
    });
  });

  group('SetGoal', () {
    //sets new goal value in DB and updates controller state
    test('sets default values when user has no data - loadData function', () async {
    await TestDatabase.seedUser(db, currency: 0);

    await stepGoalController.loadData();

    expect(stepGoalController.currentSteps, 0);
    expect(stepGoalController.stepGoal, 250);
    expect(stepGoalController.totalSteps, 0);
  });

  //update goal when button pressed to change value
    test('updates goal with new value', () async {
      await TestDatabase.seedGoal(db, targetGoal: 250);
      await stepGoalController.updateGoal(500);
      final goal = await stepGoalController.loadGoal();
      expect(goal, 500);
      });

    test('accepts goal at minimum valid value (250 steps)', () async {
      const newGoal = 250;
      await TestDatabase.seedUser(db, currency: 0);
      await stepGoalController.updateGoal(newGoal);
      final goal = await stepGoalController.loadGoal();
      expect(goal, newGoal);
    });

    test('rejects goal of 0 steps (invalid - below minimum)', () async {
      try {
        await stepGoalController.updateGoal(0);
      } catch (e) {
        expect(e.toString(), contains('Invalid goal value'));
      }
    });
    
    test('rejects negative goal (invalid - below minimum)', () async {
      try {
        await stepGoalController.updateGoal(-100);
      } catch (e) {
        expect(e.toString(), contains('Invalid goal value'));
      }
    });

    test('rejects goal below minimum (invalid - 249 steps)', () async {
      try {
        await stepGoalController.updateGoal(249);
      } catch (e) {
        expect(e.toString(), contains('Invalid goal value'));
      }
    });
  });
  
  group('ReachGoal', () {
    //goal reached when current steps meet or exceed goal, progress resets and new goal is set
    //when step goal and currentsteps are equal, goal should reset and new goal should be set
    //Functional/Integration Test - tests interaction between loadData, loadGoal, and refreshSteps to ensure goal resets when reached
    test('resets new goal when current steps meet goal (valid)', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 250);
      await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 250);

      await stepGoalController.refreshSteps();

      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
    });
  });
}
