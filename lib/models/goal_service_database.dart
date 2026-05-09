import 'package:sqflite/sqflite.dart';


class GoalService {
  final Database _db;
  GoalService(this._db);
  Future<int> setDailyStepGoal(int userId, int stepGoal) async {
    // Check if user already has a goal
    final existing = await _db.rawQuery(
      '''
      SELECT g.goal_id
      FROM goal g
      JOIN user_goal ug ON ug.goal_id = g.goal_id
      WHERE ug.user_id = ?
      LIMIT 1
    ''',
      [userId],
    );

    if (existing.isNotEmpty) {
      final goalId = existing.first['goal_id'] as int;

      // Update existing goal
      await _db.update(
        'goal',
        {'target_goal': stepGoal},
        where: 'goal_id = ?',
        whereArgs: [goalId],
      );

      return goalId;
    }

    // Otherwise create a new goal
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day);
    final weekEnd = weekStart.add(Duration(days: 7));

    final goalId = await _db.insert('goal', {
      'target_goal': stepGoal,
      'is_recurring': 1,
      'target_deadline': now.toIso8601String(),
      'min_allowed_value': 0,
    });

    await _db.insert('user_goal', {
      'user_id': userId,
      'goal_id': goalId,
      'current_progress': 0,
      'reward_claimed': 0,
      'week_start_date': weekStart.toIso8601String(),
      'week_end_date': weekEnd.toIso8601String(),
    });

    return goalId;
  }

  Future<int?> getDailyStepGoal(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT g.target_goal
      FROM goal g
      JOIN user_goal ug ON ug.goal_id = g.goal_id
      WHERE ug.user_id = ?
        AND g.is_recurring = 1
      ORDER BY g.goal_id DESC
      LIMIT 1
    ''',
      [userId],
    );

    if (rows.isNotEmpty) {
      return rows.first['target_goal'] as int;
    } else {
      return null;
    }
  }

  Future<int> getCurrentSteps(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT ug.current_progress
      FROM user_goal ug
      JOIN goal g ON g.goal_id = ug.goal_id
      WHERE ug.user_id = ?
      ORDER BY g.goal_id DESC
      LIMIT 1
    ''',
      [userId],
    );

    if (rows.isEmpty) return 0;

    return rows.first['current_progress'] as int;
  }

  Future<bool> hasUserReachedGoal(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT g.target_goal, ug.current_progress
      FROM goal g
      JOIN user_goal ug ON ug.goal_id = g.goal_id
      WHERE ug.user_id = ?
      LIMIT 1
    ''',
      [userId],
    );

    if (rows.isEmpty) return false;

    final target = rows.first['target_goal'] as int;
    final current = rows.first['current_progress'] as int;

    return current >= target;
  }

  Future<void> resetGoal(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT g.goal_id
      FROM goal g
      JOIN user_goal ug ON ug.goal_id = g.goal_id
      WHERE ug.user_id = ?
      ORDER BY g.goal_id DESC
      LIMIT 1
    ''',
      [userId],
    );

    if (rows.isEmpty) return;

    final goalId = rows.first['goal_id'] as int;
    const int goalReward = 25;

    await _db.rawUpdate(
      '''
      UPDATE user
      SET currency = currency + ?
      WHERE user_id = ?
      ''',
      [goalReward, userId],
    );

    await _db.update(
      'goal',
      {'target_goal': 250},
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );

    await _db.update(
      'user_goal',
      {'current_progress': 0},
      where: 'goal_id = ? AND user_id = ?',
      whereArgs: [goalId, userId],
    );
  }
}
