// Tests for StepPointsService — converts walking steps into in-game
// currency. Three top-level operations:
//   - recordSteps: add steps to the user's total and convert any "full"
//     batches of 100 into currency (1 point per 100 steps)
//   - awardBonusPoints: hand the user currency directly (one-off bonus)
//   - getAccountSummary: read the user's totalSteps, unconvertedSteps,
//     and currency for the UI

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/step_points_service.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late StepPointsService service;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    service = StepPointsService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR3 — StepPointsService', () {

    // recordSteps has TWO input guards (steps > 0, user exists) plus the
    // conversion logic itself. Four partitions:
    //   - negative steps -> throws (input guard)
    //   - non-existent user -> throws (existence guard)
    //   - steps below 100 -> no points awarded, accumulate as unconverted
    //   - steps above 100 -> award points, keep leftover as unconverted
    group('recordSteps', () {
      test('[TR-STP-04] throws when steps are negative', () async {
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 0);

        expect(
          () => service.recordSteps(userId: userId, steps: -10),
          throwsArgumentError,
          reason: 'Steps must be > 0',
        );
      });

      test('[TR-STP-05] throws when user does not exist', () async {
        // No user seeded — the existence guard inside recordSteps should fire
        // with a message that interpolates the missing userId.
        expect(
          () => service.recordSteps(userId: 101, steps: 100),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('User with id 101 does not exist'),
            ),
          ),
        );
      });

      test('[TR-STP-06] accumulates as unconverted when below the 100-step threshold', () async {
        // 50 steps shouldn't award any points — it just accumulates.
        // Then another 50 takes us to 100 -> 1 point, 0 unconverted.
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 0);

        final first = await service.recordSteps(userId: userId, steps: 50);
        expect(first.updatedCurrency, 0);
        expect(first.unconvertedSteps, 50);

        final second = await service.recordSteps(userId: userId, steps: 50);
        expect(second.updatedCurrency, 1);
        expect(second.unconvertedSteps, 0);
      });

      test('[TR-STP-07] converts steps to currency and keeps the leftover', () async {
        // 150 steps in one call: 1 point + 50 leftover unconverted.
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 0);

        final result = await service.recordSteps(userId: userId, steps: 150);
        expect(result.updatedCurrency, 1);
        expect(result.unconvertedSteps, 50);
      });
    });

    // awardBonusPoints has two input guards (points > 0, user exists)
    // plus the happy path (add to currency).
    group('awardBonusPoints', () {
      test('[TR-STP-08] awards points to an existing user', () async {
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 0);

        await service.awardBonusPoints(userId: userId, points: 10);

        final rows = await db.query('user', where: 'user_id = ?', whereArgs: [userId]);
        expect(rows.first['currency'], 10);
      });

      test('[TR-STP-09] throws when user does not exist', () async {
        expect(
          () => service.awardBonusPoints(userId: 101, points: 10),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('User with id 101 does not exist'),
            ),
          ),
        );
      });

      test('[TR-STP-10] throws when points are zero or negative', () async {
        // 0 is the boundary value — exactly at the > 0 rejection rule.
        // ArgumentError.message holds the explanatory string the production
        // code passes in; .toString() makes it comparable with contains().
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 0);

        expect(
          () => service.awardBonusPoints(userId: userId, points: 0),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message.toString(),
              'message',
              contains('Points must be greater than 0'),
            ),
          ),
        );
      });
    });

    group('getAccountSummary', () {
      test('[TR-STP-11] throws when user does not exist', () async {
        expect(
          () => service.getAccountSummary(101),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('User with id 101 does not exist'),
            ),
          ),
        );
      });

      test('[TR-STP-12] returns the correct totals after step recording', () async {
        // Walk 250 steps starting with 10 currency.
        // 250 = 2 points + 50 unconverted -> final currency 12.
        final userId = await TestDatabase.seedUser(db, name: 'Test User', currency: 10);

        await service.recordSteps(userId: userId, steps: 250);
        final summary = await service.getAccountSummary(userId);

        expect(summary.totalSteps, 250);
        expect(summary.currency, 12, reason: '10 base + 2 awarded');
        expect(summary.unconvertedSteps, 50);
      });
    });
  });
}
