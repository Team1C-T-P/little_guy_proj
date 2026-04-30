// import db
import 'package:sqflite/sqflite.dart';

class DressDatabase {
  final Database _db;

  DressDatabase(this._db);

  // return items owned by user
  Future<List<Map<String, dynamic>>> getHatsOwnedByUser(int userId) async {
    return await _db.rawQuery(
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
    // remove currently equipped hat
    await _db.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );

    // equip new hat
    await _db.insert('little_guy_wearing', {
      'little_guy_id': littleGuyId,
      'item_id': itemId,
    });
  }

  // unequip hat to the db
  Future<void> unequipHat(int littleGuyId) async {
    await _db.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );
  }

  // get equipped hat from db
  Future<Map<String, dynamic>?> getEquippedHat(int littleGuyId) async {
    final result = await _db.rawQuery(
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
