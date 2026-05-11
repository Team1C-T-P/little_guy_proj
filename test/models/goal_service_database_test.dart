// Tests for GoalService — the daily-step-goal database layer. Five methods:
//   - setDailyStepGoal: create or update the user's goal
//   - getDailyStepGoal: read the user's current goal target
//   - getCurrentSteps: read the user's progress towards the current goal
//   - hasUserReachedGoal: convenience check (progress >= target?)
//   - resetGoal: reset progress to 0, reset target to 250, and award the
//     completion reward (25 currency)
//
// Note on the is_recurring flag: getDailyStepGoal filters by is_recurring=1
// (only the user's active recurring daily goal is "the" goal). setDailyStepGoal
// always creates new goals with is_recurring=1. The other methods don't filter
// by it, so they work on any goal row that's linked via user_goal.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/goal_service_database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late GoalService service;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    service = GoalService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR5 — GoalService', () {

    // setDailyStepGoal has one decision: does a goal already exist for this
    // user (joined through user_goal)? If yes, update the target on the
    // existing row. If no, create a fresh goal + user_goal row pair.
    group('setDailyStepGoal', () {
      test('[TR-GOAL-01] updates the target on an existing goal', () async {
        // Seed an existing goal at 250 and a user_goal link, then update to 500.
        final userId = await TestDatabase.seedUser(db);
        final existingGoalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(db, userId: userId, goalId: existingGoalId);

        await service.setDailyStepGoal(userId, 500);

        // Verify the same goal row was updated (no new row created).
        final rows = await db.query('goal', where: 'goal_id = ?', whereArgs: [existingGoalId]);
        expect(rows.first['target_goal'], 500);
      });

      test('[TR-GOAL-02] creates a new goal and user_goal when none exists', () async {
        // Fresh user with no existing goal — setDailyStepGoal should create
        // both the goal row and the user_goal link.
        final userId = await TestDatabase.seedUser(db);

        final newGoalId = await service.setDailyStepGoal(userId, 500);

        expect(newGoalId, greaterThan(0));

        final goalRows = await db.query('goal', where: 'goal_id = ?', whereArgs: [newGoalId]);
        expect(goalRows.first['target_goal'], 500);
        expect(goalRows.first['is_recurring'], 1, reason: 'New goals should be recurring');

        final linkRows = await db.query(
          'user_goal',
          where: 'user_id = ? AND goal_id = ?',
          whereArgs: [userId, newGoalId],
        );
        expect(linkRows.length, 1);
        expect(linkRows.first['current_progress'], 0);
      });
    });

    // Simple read — returns the stored target (only recurring goals are
    // considered) or null when no recurring goal exists yet.
    group('getDailyStepGoal', () {
      test('[TR-GOAL-03] returns the stored target when a recurring goal exists', () async {
        // Use setDailyStepGoal as the setup since it's the canonical way
        // to create a recurring goal in production.
        final userId = await TestDatabase.seedUser(db);
        await service.setDailyStepGoal(userId, 500);

        final stored = await service.getDailyStepGoal(userId);

        expect(stored, 500);
      });

      test('[TR-GOAL-04] returns null when the user has no goal', () async {
        // User exists but no goal record at all.
        await TestDatabase.seedUser(db);

        final stored = await service.getDailyStepGoal(1);

        expect(stored, isNull);
      });
    });

    // getCurrentSteps returns the user's progress on the most-recent goal,
    // or 0 if nothing is set up yet (graceful fallback).
    group('getCurrentSteps', () {
      test('[TR-GOAL-05] returns the stored progress when a goal exists', () async {
        final userId = await TestDatabase.seedUser(db);
        final goalId = await TestDatabase.seedGoal(db);
        await TestDatabase.seedUserGoal(
          db,
          userId: userId,
          goalId: goalId,
          currentProgress: 120,
        );

        final progress = await service.getCurrentSteps(userId);

        expect(progress, 120);
      });

      test('[TR-GOAL-06] returns 0 when the user has no goal rows', () async {
        await TestDatabase.seedUser(db);

        final progress = await service.getCurrentSteps(1);

        expect(progress, 0, reason: 'No goal rows should yield a graceful 0');
      });
    });

    // hasUserReachedGoal is a three-way check: reached the target, below
    // the target, or no goal at all (counts as not reached).
    group('hasUserReachedGoal', () {
      test('[TR-GOAL-07] returns true when progress meets or exceeds the target', () async {
        final userId = await TestDatabase.seedUser(db);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(
          db,
          userId: userId,
          goalId: goalId,
          currentProgress: 300,
        );

        expect(await service.hasUserReachedGoal(userId), isTrue);
      });

      test('[TR-GOAL-08] returns false when progress is below the target', () async {
        final userId = await TestDatabase.seedUser(db);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 250);
        await TestDatabase.seedUserGoal(
          db,
          userId: userId,
          goalId: goalId,
          currentProgress: 100,
        );

        expect(await service.hasUserReachedGoal(userId), isFalse);
      });

      test('[TR-GOAL-09] returns false when no goal exists', () async {
        await TestDatabase.seedUser(db);

        expect(await service.hasUserReachedGoal(1), isFalse);
      });
    });

    // resetGoal pays out the fixed 25-currency reward, resets progress to 0,
    // and resets the target back to 250. If there's no goal at all, it
    // gracefully returns 0 (no payout).
    group('resetGoal', () {
      test('[TR-GOAL-10] resets progress and awards 25 currency when a goal exists', () async {
        // Start with 0 currency, 300 progress against a 500 target.
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final goalId = await TestDatabase.seedGoal(db, targetGoal: 500);
        await TestDatabase.seedUserGoal(
          db,
          userId: userId,
          goalId: goalId,
          currentProgress: 300,
        );

        final newCurrency = await service.resetGoal(userId);

        // Reward is fixed at 25 currency.
        expect(newCurrency, 25);
        // Progress reset to 0.
        expect(await service.getCurrentSteps(userId), 0);
        // Target reset to 250 (the default).
        final goalRow = await db.query('goal', where: 'goal_id = ?', whereArgs: [goalId]);
        expect(goalRow.first['target_goal'], 250);
      });

      test('[TR-GOAL-11] returns 0 when no goal exists (no payout)', () async {
        // No goal at all — graceful fallback, no DB writes, no payout.
        await TestDatabase.seedUser(db, currency: 0);

        final newCurrency = await service.resetGoal(1);

        expect(newCurrency, 0);
      });
    });
  });
}
