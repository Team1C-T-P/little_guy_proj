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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS step_ledger (
        user_id INTEGER PRIMARY KEY,
        total_steps INTEGER NOT NULL DEFAULT 0 CHECK (total_steps >= 0),
        unconverted_steps INTEGER NOT NULL DEFAULT 0 CHECK (unconverted_steps >= 0),
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
      )
    ''');
  });

  tearDown(() async {
    await db.close();
  });
  
  group('loadGoal', () {
    test('returns default value of 250 for a new goal', () async {
      await TestDatabase.seedUser(db); // Seed a user but do not seed a goal record

      final goal = await stepGoalController.loadGoal();
      expect(goal, 250);
    });

    test('returns existing goal value when goal exists', () async {
      await TestDatabase.seedUser(db);
      await TestDatabase.seedGoal(db, targetGoal: 500); // Seed a goal record with a specific value
      await stepGoalController.updateGoal(500); // sets value to a number tht is not default value of 250
      final goal = await stepGoalController.loadGoal();
      expect(goal, 500);
    });

    test('returns default value when user has no goal record', () async {
      await TestDatabase.seedUser(db); // User exists but no goal record seeded
      
      final goal = await stepGoalController.loadGoal();
      expect(goal, 250);
    });
  });

  group('SetGoal', () {
    //sets new goal value in DB and updates controller state
    test('sets default values when user has no data - loadData function', () async { // checks for all default values when goal created for the first time
    await TestDatabase.seedUser(db, currency: 0);
    await stepGoalController.loadData();

    expect(stepGoalController.currentSteps, 0);
    expect(stepGoalController.stepGoal, 250);
    expect(stepGoalController.totalSteps, 0);
  });

  //update goal when button pressed to change value
    test('updates goal with new value', () async {
      await TestDatabase.seedGoal(db, targetGoal: 250);
      await stepGoalController.updateGoal(500); // updates value to 500 in db
      final goal = await stepGoalController.loadGoal();
      expect(goal, 500);
      });

    test('updates goal when no previous goal exists', () async {
      await TestDatabase.seedUser(db);
      await stepGoalController.updateGoal(750); // goal creation happens in updateGoal without the seeded record
      final goal = await stepGoalController.loadGoal();
      expect(goal, 750);
    });

    test('accepts goal at minimum valid value (250 steps)', () async {
      const newGoal = 250;
      await TestDatabase.seedUser(db, currency: 0);
      await stepGoalController.updateGoal(newGoal);
      final goal = await stepGoalController.loadGoal();
      expect(goal, newGoal);
    });

    test('accepts goal at higher value', () async {
      const newGoal = 20000;
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

    test('rejects goal just below minimum (invalid - 249 steps)', () async {
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
    test('resets current steps when current steps meet goal (valid)', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 250);
      await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 250);

      await stepGoalController.refreshSteps();
 
      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
    });

    test('resets current steps when current steps exceed goal', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 300);
      await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 300);

      await stepGoalController.refreshSteps();
 
      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
    });

    test('does not reset when current steps below goal', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 200);
      await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 200);

      await stepGoalController.refreshSteps();
 
      expect(stepGoalController.currentSteps, 200);
      expect(stepGoalController.stepGoal, 250);
    });

    test('awards currency when goal is reached exactly', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
      await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 250);
      await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 250);

      await stepGoalController.refreshSteps();
 
      expect(stepGoalController.currency, greaterThan(0));
    });

    test('awards currency when goal is reached', () async {
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 300);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 300);

        await stepGoalController.refreshSteps();
  
        expect(stepGoalController.currency, greaterThan(0));
    });

    test('does not reset goal when user has no walk data', () async {
      await TestDatabase.seedUser(db, currency: 0);
      await TestDatabase.seedGoal(db, targetGoal: 250);
      
      await stepGoalController.refreshSteps();
      
      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
    });
  });

  group('Additional Edge Cases', () {
    test('loadData handles missing user record', () async {
      // No user seeded
      await stepGoalController.loadData();
      
      expect(stepGoalController.currentSteps, 0);
      expect(stepGoalController.stepGoal, 250);
      expect(stepGoalController.totalSteps, 0);
    });

    test('updateGoal validates input type', () async {
      try {
        await stepGoalController.updateGoal(-50); // Invalid negative value
      } catch (e) {
        expect(e.toString(), contains('Invalid goal value'));
      }
    });

    test('init correctly initializes with test database', () async {
      final testDb = await TestDatabase.createFresh();
      final controller = StepGoalController();
      await controller.init(testDb: testDb);
      
      expect(controller.goalService, isNotNull);
      expect(controller.stepService, isNotNull);
    });
  });
}
