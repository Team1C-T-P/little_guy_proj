import 'package:sqflite/sqflite.dart';

class AchievementService {
  final Database db;
  AchievementService(this.db);

  Future<void> checkAndUnlock(int userId, String type, int currentValue) async {
    final achievement = await db.query(
      'achievement',
      where: 'type = ?',
      whereArgs: [type],
    );
    if (achievement.isEmpty) return;

    final achId = achievement.first['achievement_id'] as int;
    final target = achievement.first['target_value'] as int;

    final existing = await db.query(
      'user_achievement',
      where: 'user_id = ? AND achievement_id = ? AND unlocked_at IS NOT NULL',
      whereArgs: [userId, achId],
    );
    if (existing.isNotEmpty) return;

    if (currentValue >= target) {
      await db.insert('user_achievement', {
        'user_id': userId,
        'achievement_id': achId,
        'unlocked_at': DateTime.now().toIso8601String(),
        'progress': currentValue,
      });
    } else {
      final progressRow = await db.query(
        'user_achievement',
        where: 'user_id = ? AND achievement_id = ?',
        whereArgs: [userId, achId],
      );
      if (progressRow.isEmpty) {
        await db.insert('user_achievement', {
          'user_id': userId,
          'achievement_id': achId,
          'unlocked_at': null,
          'progress': currentValue,
        });
      } else {
        await db.update(
          'user_achievement',
          {'progress': currentValue},
          where: 'user_id = ? AND achievement_id = ?',
          whereArgs: [userId, achId],
        );
      }
    }
  }

  Future<Set<int>> getUnlockedAchievementIds(int userId) async {
    final result = await db.query(
      'user_achievement',
      where: 'user_id = ? AND unlocked_at IS NOT NULL',
      whereArgs: [userId],
    );
    return {for (var row in result) row['achievement_id'] as int};
  }
}
