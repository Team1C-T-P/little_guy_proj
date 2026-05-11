import 'package:flutter_flame_playground/models/database.dart';
import 'package:sqflite/sqflite.dart';

class PetStatsDatabase {
  final Database _db;

  /* Accept an injected Database instance.
  In production, pass: PetStatsDatabase(await AppDatabase.instance.database)
  In tests, pass the in-memory DB from TestDatabase.createFresh()*/
  PetStatsDatabase(this._db);

  // Select Queries
  Future<String?> getUserName(int userId) async {
    final result = await _db.query(
      'user',
      columns: ['user_name'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) throw Exception('Failed to get user name: User not found');
    return result.first['user_name'] as String;
  }

  Future<String?> getPetName(int userId) async {
    final result = await _db.query(
      'little_guy',
      columns: ['little_guy_name'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) throw Exception('Failed to get pet name: Pet not found');
    return result.first['little_guy_name'] as String;
  }

  Future<double> getPetStat(int petId, String stat) async {
    const allowedStats = {'hunger_level', 'hygiene_level', 'enjoyment_level'};

    if (!allowedStats.contains(stat)) {
      throw Exception('Stat does not exist');
    }

    final stats = await _db.query(
      'little_guy',
      columns: [stat],
      where: 'little_guy_id = ?',
      whereArgs: [petId],
    );
    if (stats.isEmpty) return 0;
    return (stats.first[stat] as int).toDouble() / 100;
  }

  Future<String?> getLastOnlineByUserId(int userId) async {
    final result = await _db.query(
      'user',
      columns: ['last_online'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result.isEmpty) {
      throw Exception('Failed to get last online time: User not found');
    };
    return result.first['last_online'] as String;
  }

  // Update Queries
  Future<void> updateUserName(int userId, String newName) async {

    // if newName is empty, keep the old name. (?)
    if (newName.isEmpty) return;
    final result = await _db.update(
      'user',
      {'user_name': newName},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result == 0) {
      throw Exception('Failed to update user name: User not found');
    }
  }

  Future<void> updatePetName(int userId, String newName) async {

    // if newName is empty, keep the old name. (?)
    if (newName.isEmpty) return; 
    final result = await _db.update(
      'little_guy',
      {'little_guy_name': newName},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (result == 0) {
      throw Exception('Failed to update pet name: Pet not found');
    }
  }

  Future<void> updatePetStat(int petId, String stat, double value) async {
    final roundedValue = value.clamp(0.0, 1.0);

    final result = await _db.update(
      'little_guy',
      {stat: (roundedValue * 100).toInt()},
      where: 'little_guy_id = ?',
      whereArgs: [petId],
    );

    if (result == 0) {
      // If no rows were updated, throw an error
      throw Exception('Failed to update pet stat: One or more argument is invalid');
    }
  }

  Future<void> updateLastOnlineByUserId(int userId, String isoDate) async {

    try {
      DateTime.parse(isoDate);
    } catch (e) {
      throw Exception('Failed to update last online time: Invalid ISO date format');
    }

    final result = await _db.update(
      'user',
      {'last_online': isoDate},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (result == 0) {
      throw Exception('Failed to update last online time: User not found');
    }
  }
}

class InventoryDatabase {
  final Database _db;

    /* Accept an injected Database instance.
  In production, pass: InventoryDatabase(await AppDatabase.instance.database)
  In tests, pass the in-memory DB from TestDatabase.createFresh()*/
  InventoryDatabase(this._db);

  // Select Queries
    Future<List<Map<String, dynamic>>> getFoodByUserId(int userId) async {
      final food = await _db.rawQuery(
      '''
      SELECT it.item_id, inv.quantity, it.image_path
      FROM inventory inv
      JOIN item it ON inv.item_id = it.item_id
      WHERE inv.user_id = ? AND it.type = ?
    ''',
      [userId, 'food'],
    );
    if (food.isEmpty) {
      throw Exception('Failed to get food: User not found');
    } //This exception is causing the app to pause when the user has no food, which is expected for new users.
    //Should we handle this case gracefully in the UI instead of throwing an exception?
    //If we want it to be shown in the UI as "No food owned yet!" when the list is empty, then we should not throw an exception here and just return an empty list and then check for an empty list in the tests instead.
    return food;
  }

  // Update Queries
  Future<void> useFood(int foodId, int userId) async {
    // First check if the item exists for this user
    final itemExists = await _db.rawQuery(
      '''
      SELECT item_id FROM inventory
      WHERE user_id = ? AND item_id = ?
    ''',
      [userId, foodId],
    );
    
    if (itemExists.isEmpty) {
      throw Exception('Failed to use food: User or item not found');
    }
    
    // Decrease quantity in inventory if available
    await _db.rawUpdate(
      '''
      UPDATE inventory
      SET quantity = quantity - 1
      WHERE user_id = ? AND item_id = ? AND quantity > 0
    ''',
      [userId, foodId],
    );
  }
}
