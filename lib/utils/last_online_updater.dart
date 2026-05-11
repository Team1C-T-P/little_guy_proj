import 'package:flutter_flame_playground/models/database.dart';
import 'package:sqflite/sqflite.dart';

class LastOnlineUpdater {
  static Future<void> update(int userId, {Database? db}) async {
    final database = db ?? await AppDatabase.instance.database;
    await database.update(
      'user',
      {'last_online': DateTime.now().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
