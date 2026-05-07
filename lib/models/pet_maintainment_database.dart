import 'database.dart';

class PetStatsDatabase {
  // Select Queries
  Future<String?> getUserName(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'user',
      columns: ['user_name'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) return null;
    return result.first['user_name'] as String;
  }

  Future<String?> getPetName(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'little_guy',
      columns: ['little_guy_name'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) return null;
    return result.first['little_guy_name'] as String;
  }

  Future<double> getPetStat(int petId, String stat) async {
    final db = await AppDatabase.instance.database;
    final stats = await db.query(
      'little_guy',
      columns: [stat],
      where: 'little_guy_id = ?',
      whereArgs: [petId],
    );
    if (stats.isEmpty) return 0;
    return (stats.first[stat] as int).toDouble() / 100;
  }

  Future<String?> getLastOnlineByUserId(int userId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'user',
      columns: ['last_online'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) return null;
    return result.first['last_online'] as String;
  }

  // Update Queries
  Future<void> updateUserName(int userId, String newName) async {
    final db = await AppDatabase.instance.database;
    // if newName is empty, keep the old name. (?)
    if (newName.isEmpty) return; // not tested
    await db.update(
      'user',
      {'user_name': newName},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePetName(int userId, String newName) async {
    final db = await AppDatabase.instance.database;
    // if newName is empty, keep the old name. (?)
    if (newName.isEmpty) return; // not tested
    await db.update(
      'little_guy',
      {'little_guy_name': newName},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updatePetStat(int petId, String stat, double value) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'little_guy',
      {stat: (value * 100).toInt()},
      where: 'little_guy_id = ?',
      whereArgs: [petId],
    );
  }

  Future<void> updateLastOnlineByUserId(int userId, String isoDate) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'user',
      {'last_online': isoDate},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}

class InventoryDatabase {
  // Select Queries
  Future<List<Map<String, dynamic>>> getFoodByUserId(int userId) async {
    final db = await AppDatabase.instance.database;
    final food = await db.rawQuery(
      '''
      SELECT it.item_id, inv.quantity, it.image_path
      FROM inventory inv
      JOIN item it ON inv.item_id = it.item_id
      WHERE inv.user_id = ? AND it.type = ?
    ''',
      [userId, 'food'],
    );
    return food;
  }

  // Update Queries
  Future<void> useFood(int foodId, int userId) async {
    final db = await AppDatabase.instance.database;

    // Decrease quantity in inventory
    await db.rawUpdate(
      '''
      UPDATE inventory
      SET quantity = quantity - 1
      WHERE user_id = ? AND item_id = ? AND quantity > 0
    ''',
      [userId, foodId],
    );
  }
}
