// import db
import 'database.dart';

class DressDatabase {
  final db = AppDatabase.instance.database;

  // return items owned by user
  Future<List<Map<String, dynamic>>> getHatsOwnedByUser(int userId) async {
    final database = await db;

    return await database.rawQuery(
      '''
      SELECT
        item.item_id,
        item.item_name,
        item.image_path,
        item.price,
        item.type
      FROM inventory
      JOIN item on inventory.item_id = item.item_id
      WHERE inventory.user_id = ?
      AND item.type = 'hat'
  ''',
      [userId],
    );
  }

  // equip hat to the db
  Future<void> equipHat(int littleGuyId, int itemId) async {
    final database = await db;

    // remove currently equipped hat
    await database.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );

    // equip new hat
    await database.insert('little_guy_wearing', {
      'little_guy_id': littleGuyId,
      'item_id': itemId,
    });
  }

  // unequip hat to the db
  Future<void> unequipHat(int littleGuyId) async {
    final database = await db;
    await database.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );
  }

  // get equipped hat from db
  Future<Map<String, dynamic>?> getEquippedHat(int littleGuyId) async {
    final database = await db;

    final result = await database.rawQuery(
      '''
    SELECT item.item_id, item.image_path
    FROM little_guy_wearing
    JOIN item ON item.item_id = little_guy_wearing.item_id
    WHERE little_guy_wearing.little_guy_id = ?
    LIMIT 1
  ''',
      [littleGuyId],
    );

    if (result.isEmpty) return null;
    return result.first;
  }
}
