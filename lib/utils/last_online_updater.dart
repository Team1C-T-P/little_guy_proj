import 'package:flutter_flame_playground/models/database.dart';

class LastOnlineUpdater {
  static Future<void> update(int userId) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'user',
      {'last_online': DateTime.now().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
