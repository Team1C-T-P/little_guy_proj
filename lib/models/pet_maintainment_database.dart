import 'database.dart';

class PetStatsDatabase {
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
}

class InventoryDatabase {
  Future<List<Map<String, dynamic>>> getFoodByUserId(int userId) async {
    final db = await AppDatabase.instance.database;
    final food = await db.rawQuery('''
      SELECT it.item_id, inv.quantity, it.image_path
      FROM inventory inv
      JOIN item it ON inv.item_id = it.item_id
      WHERE inv.user_id = ? AND it.type = ?
    ''', [userId, 'food']);
    return food;
  }
}