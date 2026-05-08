import 'package:sqflite/sqflite.dart';
import 'package:flutter_flame_playground/models/database.dart';

class LevelService {
  final Database db;
  LevelService(this.db);

  // Get current level and XP for a user
  Future<Map<String, int>> getLevelAndXp(int userId) async {
    final result = await db.query(
      'little_guy',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) return {'level': 1, 'xp': 0};
    return {
      'level': result.first['level'] as int,
      'xp': result.first['xp'] as int,
    };
  }

  // Add XP, handle level-ups, and return new level/xp
  Future<Map<String, int>> addXp(int userId, int gainedXp) async {
    var data = await getLevelAndXp(userId);
    int level = data['level']!;
    int xp = data['xp']! + gainedXp;

    bool leveledUp = false;
    while (xp >= 100) {
      level++;
      xp -= 100;
      leveledUp = true;
    }

    // Update database
    await db.update(
      'little_guy',
      {'level': level, 'xp': xp},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return {'level': level, 'xp': xp, 'leveledUp': leveledUp ? 1 : 0};
  }

  // Set specific level/xp (for testing or admin)
  Future<void> setLevelAndXp(int userId, int level, int xp) async {
    await db.update(
      'little_guy',
      {'level': level, 'xp': xp},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
