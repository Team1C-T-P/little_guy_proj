import 'database.dart';

class StepAccountSummary {
  const StepAccountSummary({
    required this.totalSteps,
    required this.unconvertedSteps,
    required this.currency,
  });

  final int totalSteps;
  final int unconvertedSteps;
  final int currency;
}

class StepRecordResult {
  const StepRecordResult({
    required this.recordedSteps,
    required this.pointsAwarded,
    required this.updatedCurrency,
    required this.totalSteps,
    required this.unconvertedSteps,
  });

  final int recordedSteps;
  final int pointsAwarded;
  final int updatedCurrency;
  final int totalSteps;
  final int unconvertedSteps;
}

class StepPointsService {
  StepPointsService({this.stepsPerPoint = 100});

  final int stepsPerPoint;

  Future<void> _ensureStepLedgerTable() async {
    final db = await AppDatabase.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS step_ledger (
        user_id INTEGER PRIMARY KEY,
        total_steps INTEGER NOT NULL DEFAULT 0 CHECK (total_steps >= 0),
        unconverted_steps INTEGER NOT NULL DEFAULT 0 CHECK (unconverted_steps >= 0),
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
      );
    ''');
  }

  Future<void> _ensureLedgerRow(int userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'step_ledger',
      columns: ['user_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (rows.isEmpty) {
      await db.insert('step_ledger', {
        'user_id': userId,
        'total_steps': 0,
        'unconverted_steps': 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<StepRecordResult> recordSteps({
    required int userId,
    required int steps,
  }) async {
    if (steps <= 0) {
      throw ArgumentError.value(steps, 'steps', 'Steps must be greater than 0');
    }

    await _ensureStepLedgerTable();
    await _ensureLedgerRow(userId);

    final db = await AppDatabase.instance.database;

    return db.transaction((txn) async {
      final userRows = await txn.query(
        'user',
        columns: ['currency'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (userRows.isEmpty) {
        throw StateError('User with id $userId does not exist');
      }

      final ledgerRows = await txn.query(
        'step_ledger',
        columns: ['total_steps', 'unconverted_steps'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (ledgerRows.isEmpty) {
        throw StateError('Step ledger missing for user id $userId');
      }

      final currentCurrency = userRows.first['currency'] as int;
      final currentTotalSteps = ledgerRows.first['total_steps'] as int;
      final currentUnconverted = ledgerRows.first['unconverted_steps'] as int;

      final combinedUnconverted = currentUnconverted + steps;
      final pointsAwarded = combinedUnconverted ~/ stepsPerPoint;
      final nextUnconverted = combinedUnconverted % stepsPerPoint;
      final nextCurrency = currentCurrency + pointsAwarded;
      final nextTotalSteps = currentTotalSteps + steps;

      await txn.update(
        'step_ledger',
        {
          'total_steps': nextTotalSteps,
          'unconverted_steps': nextUnconverted,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      await txn.update(
        'user',
        {
          'currency': nextCurrency,
          'last_online': DateTime.now().toIso8601String(),
        },
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // Keep all user goals progressing with each recorded step batch.
      await txn.rawUpdate(
        'UPDATE user_goal SET current_progress = current_progress + ? WHERE user_id = ?',
        [steps, userId],
      );

      return StepRecordResult(
        recordedSteps: steps,
        pointsAwarded: pointsAwarded,
        updatedCurrency: nextCurrency,
        totalSteps: nextTotalSteps,
        unconvertedSteps: nextUnconverted,
      );
    });
  }

  Future<StepAccountSummary> getAccountSummary(int userId) async {
    await _ensureStepLedgerTable();
    await _ensureLedgerRow(userId);

    final db = await AppDatabase.instance.database;

    final userRows = await db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (userRows.isEmpty) {
      throw StateError('User with id $userId does not exist');
    }

    final ledgerRows = await db.query(
      'step_ledger',
      columns: ['total_steps', 'unconverted_steps'],
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (ledgerRows.isEmpty) {
      throw StateError('Step ledger missing for user id $userId');
    }

    return StepAccountSummary(
      totalSteps: ledgerRows.first['total_steps'] as int,
      unconvertedSteps: ledgerRows.first['unconverted_steps'] as int,
      currency: userRows.first['currency'] as int,
    );
  }
}
