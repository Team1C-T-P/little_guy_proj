import 'package:flutter/material.dart';
import '../models/dress_database.dart';

class HatState extends ChangeNotifier {
  static final HatState instance = HatState._init();
  HatState._init();

  String? equippedHatPath;

  // load hat from db and notify listeners, which is the little guy.dart
  Future<void> loadFromDb() async {
    final dressDb = DressDatabase();
    final hat = await dressDb.getEquippedHat(1);
    equippedHatPath = hat?['image_path'] as String?;
    notifyListeners();
  }

  // equip hat
  Future<void> equipHat(int itemId, String imagePath) async {
    final dressDb = DressDatabase();
    await dressDb.equipHat(1, itemId);
    equippedHatPath = imagePath;
    notifyListeners();
  }

  // unequip hat
  Future<void> unequipHat() async {
    final dressDb = DressDatabase();
    await dressDb.unequipHat(1);
    equippedHatPath = null;
    notifyListeners();
  }
}
