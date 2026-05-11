import 'package:flutter_flame_playground/models/database.dart';
import 'package:sqflite/sqflite.dart';

class LastOnlineUpdater {
  // Bumps the user's last_online column to the current timestamp.
  //
  // [db] is optional and defaults to the production singleton database.
  // Tests pass an in-memory database here so they don't share state with
  // the on-disk app DB.
  static Future<void> update(int userId, {Database? db}) async {
    final database = db ?? await AppDatabase.instance.database;
    // Always write as UTC so readers (e.g. StatDegradation) that compare
    // against DateTime.now().toUtc() see a consistent timezone. Mixing
    // local + UTC writes was producing hour-sized errors when the user
    // was in BST.
    await database.update(
      'user',
      {'last_online': DateTime.now().toUtc().toIso8601String()},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
