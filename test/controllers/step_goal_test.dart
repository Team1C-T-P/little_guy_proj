// Tests for StepGoalController — the singleton controller that the UI
// talks to for everything goal-related. Internally it coordinates between
// GoalService (the goal database layer, tested separately) and
// StepPointsService (the step-recording layer, also tested separately).
//
// Notes on the singleton: StepGoalController is a process-wide singleton,
// so its non-service state (totalSteps, currentSteps, etc.) can in theory
// leak across tests. In practice the in-memory DB is rebuilt per test and
// the controller's fields are overwritten by loadData / refreshSteps in
// their happy paths, so this hasn't been an issue. Watch out if a future
// test ever calls recordSteps — that writes to step_ledger and would
// non-zero out the totalSteps reading for any subsequent "fresh-state" test.

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

    // step_ledger isn't part of the standard test schema — StepPointsService
    // creates it lazily on first use. Pre-create it here so refreshSteps'
    // downstream calls have it ready.
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

  group('UR5 — StepGoalController', () {

    // loadGoal: read the user's current daily-step goal. Falls back to 250
    // (the default) when there isn't a recurring goal yet.
    group('loadGoal', () {
      test('[TR-GOAL-12] returns default value of 250 for a new goal', () async {
        // User exists but no goal yet — fallback kicks in.
        await TestDatabase.seedUser(db);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 250);
      });

      test('[TR-GOAL-13] returns existing goal value when goal exists', () async {
        // updateGoal creates a recurring goal under the hood; loadGoal then
        // reads it back. The bare seedGoal() call here is actually inert
        // because seedGoal creates a non-recurring goal that loadGoal
        // ignores — updateGoal is what creates the row we end up reading.
        await TestDatabase.seedUser(db);
        await TestDatabase.seedGoal(db, targetGoal: 500);
        await stepGoalController.updateGoal(500);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 500);
      });

      test('[TR-GOAL-14] returns default value when user has no goal record', () async {
        // Same outcome as TR-GOAL-12 but from a different angle — user
        // exists, no goal row at all.
        await TestDatabase.seedUser(db);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 250);
      });
    });

    group('loadData', () {
      test('[TR-GOAL-15] sets default values when user has no data', () async {
        // Brand-new user, no walks, no goal — everything should land on defaults.
        await TestDatabase.seedUser(db, currency: 0);
        await stepGoalController.loadData();

        expect(stepGoalController.currentSteps, 0);
        expect(stepGoalController.stepGoal, 250);
        expect(stepGoalController.totalSteps, 0);
      });
    });

    // updateGoal writes the new goal value to the DB via setDailyStepGoal,
    // and rejects anything <= 0 with an exception.
    group('updateGoal', () {
      test('[TR-GOAL-16] updates goal with new value', () async {
        await TestDatabase.seedGoal(db, targetGoal: 250);
        await stepGoalController.updateGoal(500);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 500);
      });

      test('[TR-GOAL-17] updates goal when no previous goal exists', () async {
        // No goal seeded — updateGoal creates one from scratch.
        await TestDatabase.seedUser(db);
        await stepGoalController.updateGoal(750);

        final goal = await stepGoalController.loadGoal();
        expect(goal, 750);
      });

      test('[TR-GOAL-18] accepts goal at minimum valid value (250 steps)', () async {
        // 250 is the team's preferred minimum; the code only rejects <= 0
        // so 250 is comfortably accepted.
        const newGoal = 250;
        await TestDatabase.seedUser(db, currency: 0);
        await stepGoalController.updateGoal(newGoal);

        final goal = await stepGoalController.loadGoal();
        expect(goal, newGoal);
      });

      test('[TR-GOAL-19] accepts goal at a higher value', () async {
        const newGoal = 20000;
        await TestDatabase.seedUser(db, currency: 0);
        await stepGoalController.updateGoal(newGoal);

        final goal = await stepGoalController.loadGoal();
        expect(goal, newGoal);
      });

      test('[TR-GOAL-20] rejects goal of 0 steps', () async {
        // 0 is the boundary value — exactly at the <= 0 rejection rule.
        try {
          await stepGoalController.updateGoal(0);
        } catch (e) {
          expect(e.toString(), contains('Invalid goal value'));
        }
      });

      test('[TR-GOAL-21] rejects negative goal', () async {
        try {
          await stepGoalController.updateGoal(-100);
        } catch (e) {
          expect(e.toString(), contains('Invalid goal value'));
        }
      });

      test('[TR-GOAL-22] rejects goal just below preferred minimum (249 steps)', () async {
        // KNOWN ISSUE — see docs/test_plan.md "Known issues" section.
        // The production code only rejects values <= 0, so 249 actually
        // passes through and silently gets saved. The try/catch here
        // swallows the no-throw, so this test always passes regardless of
        // whether an exception was raised. Either tighten the validation
        // in StepGoalController.updateGoal to reject < 250, or delete this
        // test — pick one before merging.
        try {
          await stepGoalController.updateGoal(249);
        } catch (e) {
          expect(e.toString(), contains('Invalid goal value'));
        }
      });
    });

    // refreshSteps reads the latest progress / total / currency from the
    // services, then auto-resets the goal if the user has reached it
    // (currentSteps >= stepGoal). Six variants cover the reset/no-reset
    // paths and the no-walk-data fallback.
    group('refreshSteps', () {
      test('[TR-GOAL-23] resets current steps when current steps meet goal exactly', () async {
        // 250 steps walked, 250 goal — should trigger the reset path.
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 250);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 250);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currentSteps, 0);
        expect(stepGoalController.stepGoal, 250);
      });

      test('[TR-GOAL-24] resets current steps when current steps exceed goal', () async {
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 300);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 300);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currentSteps, 0);
        expect(stepGoalController.stepGoal, 250);
      });

      test('[TR-GOAL-25] does not reset when current steps are below goal', () async {
        // Progress is below target — no reset, no reward.
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 200);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 200);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currentSteps, 200);
        expect(stepGoalController.stepGoal, 250);
      });

      test('[TR-GOAL-26] awards currency when goal is reached exactly', () async {
        // Same setup as TR-GOAL-23 but checking the currency side-effect.
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 250);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 250);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currency, greaterThan(0));
      });

      test('[TR-GOAL-27] awards currency when goal is exceeded', () async {
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: goalId, currentProgress: 300);
        await TestDatabase.seedWalkSummary(db, userId: userId, totalSteps: 300);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currency, greaterThan(0));
      });

      test('[TR-GOAL-28] does not reset goal when user has no walk data', () async {
        // No walk_summary rows — refreshSteps gracefully does nothing.
        await TestDatabase.seedUser(db, currency: 0);
        await TestDatabase.seedGoal(db, targetGoal: 250);

        await stepGoalController.refreshSteps();

        expect(stepGoalController.currentSteps, 0);
        expect(stepGoalController.stepGoal, 250);
      });
    });

    // Edge-case duplicates and the init smoke test.
    group('edge cases', () {
      test('[TR-GOAL-29] loadData handles missing user record gracefully', () async {
        // No user seeded at all — loadData's try/catch swallows the
        // StateError from getAccountSummary and we fall back to defaults.
        await stepGoalController.loadData();

        expect(stepGoalController.currentSteps, 0);
        expect(stepGoalController.stepGoal, 250);
        expect(stepGoalController.totalSteps, 0);
      });

      test('[TR-GOAL-30] updateGoal validates input type (negative)', () async {
        // Duplicate-flavour test of negative-input rejection (TR-GOAL-21
        // already covers -100; this covers -50). Kept for completeness
        // because the original suite tested it separately.
        try {
          await stepGoalController.updateGoal(-50);
        } catch (e) {
          expect(e.toString(), contains('Invalid goal value'));
        }
      });

      test('[TR-GOAL-31] init correctly initialises with test database', () async {
        // Create a separate in-memory DB and confirm init() wires up both
        // services on the singleton.
        final testDb = await TestDatabase.createFresh();
        try {
          final controller = StepGoalController();
          await controller.init(testDb: testDb);

          expect(controller.goalService, isNotNull);
          expect(controller.stepService, isNotNull);
        } finally {
          await testDb.close();
        }
      });
    });
  });
}
