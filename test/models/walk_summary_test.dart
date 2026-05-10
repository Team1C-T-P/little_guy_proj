import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });

  setUp(() async {
    // Hard clear the table so math counts are perfectly isolated
    final db = await AppDatabase.instance.database;
    await db.delete('walk_summary'); 
  });

  group('See Summaries (Limits and Sorting)', () {
    
    test('[TR-SUM-01] Last 10 BVA: Strictly caps query at 10 items', () async {
      for (int i = 1; i <= 12; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 10, reason: 'BVA: Failed boundary limit of 10');
    });

    test('[TR-SUM-02] Top 3 BVA: Returns highest 3 step counts descending', () async {
      final stepCounts = [100, 500, 200, 1000, 50];
      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);
      
      expect(topWalks.length, 3, reason: 'BVA: Failed boundary limit of 3');
      expect(topWalks[0]['total_steps'], 1000);
      expect(topWalks[1]['total_steps'], 500);
      expect(topWalks[2]['total_steps'], 200);
    });

    test('[TR-SUM-03] Last 10 EP: Returns exact amount if below cap', () async {
      for (int i = 1; i <= 5; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 5, reason: 'EP: Failed to return all items when below limit');
    });

    test('[TR-SUM-04] Top 3 EP: Returns exact amount sorted if below cap', () async {
      final stepCounts = [100, 500];

      for (int steps in stepCounts) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'total_steps': steps,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);

      expect(topWalks.length, 2, reason: 'EP: Failed to return all items when below limit');
      expect(topWalks[0]['total_steps'], 500);
      expect(topWalks[1]['total_steps'], 100);
    });

    test('[TR-SUM-05] Last 10 inclusive boundary: Returns all 10 when DB holds exactly 10', () async {
      for (int i = 1; i <= 10; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 10, reason: 'Should return all 10 when exactly at the cap');
    });

    test('[TR-SUM-06] Last 10 just-over boundary: Still caps at 10 when DB holds 11', () async {
      for (int i = 1; i <= 11; i++) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().add(Duration(days: i)).toIso8601String(),
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent.length, 10, reason: '11th summary should have been excluded by LIMIT 10');
    });

    test('[TR-SUM-07] Returns recent summaries in descending date order', () async {
      final dates = [
        '2026-01-01T00:00:00.000',
        '2026-01-03T00:00:00.000',
        '2026-01-02T00:00:00.000',
      ];
      for (final date in dates) {
        await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': date,
          'total_steps': 500,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        });
      }

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);

      expect(recent.length, 3);
      expect(recent[0]['walk_date'], '2026-01-03T00:00:00.000');
      expect(recent[1]['walk_date'], '2026-01-02T00:00:00.000');
      expect(recent[2]['walk_date'], '2026-01-01T00:00:00.000');
    });

    test('[TR-SUM-08] Returns an empty list when the database has no walk summaries', () async {
      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent, isEmpty, reason: 'Expected empty list when no summaries exist');
    });

    test('[TR-SUM-09] Returns an empty list when only other users have summaries', () async {
      await AppDatabase.instance.insertWalkSummary({
        'user_id': 2,
        'walk_date': DateTime.now().toIso8601String(),
        'total_steps': 500,
        'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
      });

      final recent = await AppDatabase.instance.getRecentWalkSummaries(1);
      expect(recent, isEmpty, reason: 'user_id filter leaked other users\' summaries');
    });

    test('[TR-SUM-10] Top 3 returns an empty list when no summaries exist', () async {
      final topWalks = await AppDatabase.instance.getTopWalkSummaries(1);
      expect(topWalks, isEmpty, reason: 'Expected empty list when no summaries exist');
    });

    test('[TR-SUM-11] insertWalkSummary throws when walk_date is missing', () async {
      expect(
        () async => await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'total_steps': 100,
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('[TR-SUM-12] insertWalkSummary throws when total_steps is missing', () async {
      expect(
        () async => await AppDatabase.instance.insertWalkSummary({
          'user_id': 1,
          'walk_date': DateTime.now().toIso8601String(),
          'start_lat': 0.0, 'start_lng': 0.0, 'end_lat': 0.0, 'end_lng': 0.0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });
  });
}