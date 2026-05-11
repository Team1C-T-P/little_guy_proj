import 'package:flutter/material.dart';
import '../models/dress_database.dart';
import '../models/database.dart';

class HatState extends ChangeNotifier {
  static final HatState instance = HatState._init();
  HatState._init();

  String? equippedHatPath;

  // Resolved once from the user_id -> little_guy_id mapping. Was previously
  // hardcoded to 1 alongside user_id; both happen to be 1 in the normal
  // single-user flow today, but if the profile is ever re-created the IDs
  // can diverge and the hat ends up attached to the wrong row.
  int? _littleGuyId;
  static const int _userId = 1;

  Future<int> _resolveLittleGuyId() async {
    if (_littleGuyId != null) return _littleGuyId!;
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'little_guy',
      columns: ['little_guy_id'],
      where: 'user_id = ?',
      whereArgs: [_userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('No little_guy row for user_id $_userId');
    }
    _littleGuyId = rows.first['little_guy_id'] as int;
    return _littleGuyId!;
  }

  // load hat from db and notify listeners, which is the little guy.dart
  Future<void> loadFromDb() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    final hat = await dressDb.getEquippedHat(await _resolveLittleGuyId());
    equippedHatPath = hat?['image_path'] as String?;
    notifyListeners();
  }

  // equip hat
  Future<void> equipHat(int itemId, String imagePath) async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    await dressDb.equipHat(await _resolveLittleGuyId(), itemId);
    equippedHatPath = imagePath;
    notifyListeners();
  }

  // unequip hat
  Future<void> unequipHat() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    await dressDb.unequipHat(await _resolveLittleGuyId());
    equippedHatPath = null;
    notifyListeners();
  }
}
