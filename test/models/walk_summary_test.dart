// Tests for the walk-summary methods on AppDatabase:
//   - insertWalkSummary: writes a finished walk to the `walk_summary` table
//   - getRecentWalkSummaries: reads back the last 10 by date (descending)
//   - getTopWalkSummaries: reads back the top 3 by step count (descending)
//
// The "recent" cap of 10 and "top" cap of 3 are SQL LIMITs in production, so
// most of these tests are boundary cases around those caps.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
  });

  tearDown(() async {
    await db.close();
  });

  // Small helper to keep the test bodies short — every test seeds at least
  // one walk_summary row and they all have the same lat/lng padding.
  Future<void> insertSummary({
    int userId = 1,
    required String walkDate,
    int totalSteps = 500,
  }) async {
    await AppDatabase.instance.insertWalkSummary({
      'user_id': userId,
      'walk_date': walkDate,
      'total_steps': totalSteps,
      'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
    }, db: db);
  }

  group('UR4 — A user should be able to see summaries of their recent and best walks', () {

    // getRecentWalkSummaries returns up to 10 rows ordered by walk_date DESC.
    // The partitions worth covering are: more than 10 (cap kicks in), fewer
    // than 10 (returns everything), exactly 10 and 11 (boundary), wrong
    // date order (verify ORDER BY), empty DB, and other-user data leaking.
    group('getRecentWalkSummaries', () {
      test('[TR-SUM-01] caps the query at 10 items when more than 10 summaries exist', () async {
        // Insert 12 — only the most recent 10 should come back.
        for (int i = 1; i <= 12; i++) {
          await insertSummary(
            walkDate: DateTime.now().add(Duration(days: i)).toIso8601String(),
          );
        }

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent.length, 10, reason: 'Failed boundary limit of 10');
      });

      test('[TR-SUM-03] returns all rows when the count is below the cap', () async {
        for (int i = 1; i <= 5; i++) {
          await insertSummary(
            walkDate: DateTime.now().add(Duration(days: i)).toIso8601String(),
          );
        }

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent.length, 5, reason: 'Should return everything when below the limit');
      });

      test('[TR-SUM-05] returns all 10 at the inclusive boundary (exactly 10 rows)', () async {
        // Exactly at the cap — every row should still be returned.
        for (int i = 1; i <= 10; i++) {
          await insertSummary(
            walkDate: DateTime.now().add(Duration(days: i)).toIso8601String(),
          );
        }

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent.length, 10, reason: 'Should return all 10 when exactly at the cap');
      });

      test('[TR-SUM-06] still caps at 10 when one over (11 rows)', () async {
        // Just one over the cap — the 11th (oldest) should be excluded.
        for (int i = 1; i <= 11; i++) {
          await insertSummary(
            walkDate: DateTime.now().add(Duration(days: i)).toIso8601String(),
          );
        }

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent.length, 10, reason: '11th summary should have been excluded by LIMIT 10');
      });

      test('[TR-SUM-07] returns rows ordered by walk_date DESC', () async {
        // Insert out of order — the result should still come back sorted.
        await insertSummary(walkDate: '2026-01-01T00:00:00.000');
        await insertSummary(walkDate: '2026-01-03T00:00:00.000');
        await insertSummary(walkDate: '2026-01-02T00:00:00.000');

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);

        expect(recent.length, 3);
        expect(recent[0]['walk_date'], '2026-01-03T00:00:00.000');
        expect(recent[1]['walk_date'], '2026-01-02T00:00:00.000');
        expect(recent[2]['walk_date'], '2026-01-01T00:00:00.000');
      });

      test('[TR-SUM-08] returns an empty list when the database has no walk summaries', () async {
        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent, isEmpty, reason: 'Expected empty list when no summaries exist');
      });

      test('[TR-SUM-09] returns an empty list when only other users have summaries', () async {
        // Insert a summary for user 2 only; querying as user 1 should return nothing.
        await insertSummary(userId: 2, walkDate: DateTime.now().toIso8601String());

        final recent = await AppDatabase.instance.getRecentWalkSummaries(1, db: db);
        expect(recent, isEmpty, reason: 'user_id filter leaked other users\' summaries');
      });
    });

    // getTopWalkSummaries returns up to 3 rows ordered by total_steps DESC.
    // Same shape as the recent query but with a smaller cap and a different
    // sort key.
    group('getTopWalkSummaries', () {
      test('[TR-SUM-02] returns the top 3 by step count when more than 3 exist', () async {
        // Mixed step counts — the top 3 are 1000, 500, 200 (descending).
        final stepCounts = [100, 500, 200, 1000, 50];
        for (int steps in stepCounts) {
          await insertSummary(
            walkDate: DateTime.now().toIso8601String(),
            totalSteps: steps,
          );
        }

        final topWalks = await AppDatabase.instance.getTopWalkSummaries(1, db: db);

        expect(topWalks.length, 3, reason: 'Failed boundary limit of 3');
        expect(topWalks[0]['total_steps'], 1000);
        expect(topWalks[1]['total_steps'], 500);
        expect(topWalks[2]['total_steps'], 200);
      });

      test('[TR-SUM-04] returns all rows sorted when the count is below the cap', () async {
        // Only 2 rows — both come back, sorted highest first.
        final stepCounts = [100, 500];
        for (int steps in stepCounts) {
          await insertSummary(
            walkDate: DateTime.now().toIso8601String(),
            totalSteps: steps,
          );
        }

        final topWalks = await AppDatabase.instance.getTopWalkSummaries(1, db: db);

        expect(topWalks.length, 2, reason: 'Should return everything when below the limit');
        expect(topWalks[0]['total_steps'], 500);
        expect(topWalks[1]['total_steps'], 100);
      });

      test('[TR-SUM-10] returns an empty list when no summaries exist', () async {
        final topWalks = await AppDatabase.instance.getTopWalkSummaries(1, db: db);
        expect(topWalks, isEmpty, reason: 'Expected empty list when no summaries exist');
      });
    });

    // insertWalkSummary just hands the map to sqflite — SQLite enforces the
    // NOT NULL constraints on walk_date and total_steps. These two tests
    // document that those constraints actually fire when the field is missing.
    group('insertWalkSummary — required-field guards', () {
      test('[TR-SUM-11] throws when walk_date is missing', () async {
        // Walk-summary row missing the required walk_date column.
        expect(
          () async => await AppDatabase.instance.insertWalkSummary({
            'user_id': 1,
            'total_steps': 100,
            'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
          }, db: db),
          throwsA(isA<DatabaseException>()),
        );
      });

      test('[TR-SUM-12] throws when total_steps is missing', () async {
        // Walk-summary row missing the required total_steps column.
        expect(
          () async => await AppDatabase.instance.insertWalkSummary({
            'user_id': 1,
            'walk_date': DateTime.now().toIso8601String(),
            'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
          }, db: db),
          throwsA(isA<DatabaseException>()),
        );
      });
    });
  });
}
