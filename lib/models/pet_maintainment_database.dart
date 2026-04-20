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