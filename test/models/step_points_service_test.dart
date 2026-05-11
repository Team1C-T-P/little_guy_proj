import 'package:flutter_flame_playground/models/step_points_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';

void main() {
  // Copied from walk_summary_test
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData();
  });

  setUp(() async {
    final db = await AppDatabase.instance.database;
    await db.delete('user');
  });

  group('awardBonusPoints', () {
    // Successfully award points
    test('Successfully awards points to existing user', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);

      // test user WITH A NAME
      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 0,
      });

      final updatedCurrency = await service.awardBonusPoints(
        userId: userId,
        points: 10,
      );
      //removed redundant check

      final userRows = await db.query(
        'user',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      expect(userRows.first['currency'], 10);
    });
    // Error on non-existent user
    test('Throws error when user does not exist', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);

      expect(
        () => service.awardBonusPoints(userId: 101, points: 10),
        throwsStateError,
        reason: "User with this ID doesn't exist",
      );
    });

    // Error on zero or negative points
    test('Throws error when points are zero or negative', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);

      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 0,
      });

      expect(
        () => service.awardBonusPoints(userId: userId, points: 0),
        throwsArgumentError,
        reason: "Points must be positive",
      );
    });
  });

  group('recordSteps', () {
    // Steps must be 0 or over
    test('Throws error when steps are negative', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);
      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 0,
      });

      expect(
        () => service.recordSteps(userId: userId, steps: -10),
        throwsArgumentError,
        reason: "Steps cannot be negative",
      );
    });

    // User must exist
    test('Throws error when user does not exist', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);

      expect(
        () => service.recordSteps(userId: 101, steps: 100),
        throwsStateError,
        reason: "User with this ID doesn't exist",
      );
    });

    // Step record - 50/100 steps, expect 0 points, 50 unconverted
    test('Correct step record and points award', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);
      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 0,
      });

      final result1 = await service.recordSteps(userId: userId, steps: 50);
      expect(result1.updatedCurrency, 0);
      expect(result1.unconvertedSteps, 50);

      final result2 = await service.recordSteps(userId: userId, steps: 50);
      expect(result2.updatedCurrency, 1);
      expect(result2.unconvertedSteps, 0);
    });

    // Step conversion - 150/100 steps, expect 1 point, 50 unconverted
    test('Correct step conversion with extra steps', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);
      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 0,
      });

      final result = await service.recordSteps(userId: userId, steps: 150);
      expect(result.updatedCurrency, 1);
      expect(result.unconvertedSteps, 50);
    });
  });

  group('getAccountSummary', () {
    // user must exist
    test('Throws error when user does not exist', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);

      expect(
        () => service.getAccountSummary(
          101,
        ), //no positional argument for userId(?)
        throwsStateError,
        reason: "User with this ID doesn't exist",
      );
    });

    // Correct totals after rewarding points
    test('Returns correct summary', () async {
      final db = await AppDatabase.instance.database;
      final service = StepPointsService(db);
      final userId = await db.insert('user', {
        'user_name': 'Test User',
        'currency': 10,
      });

      // redundant points award
      await service.recordSteps(userId: userId, steps: 250);

      // add updatedCurrency check
      final summary = await service.getAccountSummary(userId);
      expect(summary.totalSteps, 250);
      expect(summary.currency, 12); // 10 base + 2 awarded
      expect(summary.unconvertedSteps, 50);
    });
  });
}
