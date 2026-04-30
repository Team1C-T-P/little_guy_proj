import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/models/dress_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late Database db;
  late DressDatabase dressDb;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    dressDb = DressDatabase(db);
  });

  // getHatsOwnedByUser
  group('getHatsOwnedByUser', () {
    test('return hats owned by user', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
    });

    test('only returs hats, no food', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
      final foodId = await TestDatabase.seedFood(db, name: 'Bread');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
    });

    test('empty list is returned when only food is owned', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodId = await TestDatabase.seedFood(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats, isEmpty);
    });

    test('return correct hat fields', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(
        db,
        name: 'Top Hat',
        imagePath: 'assets/images/hats/tophat.png',
        price: 350,
      );
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.first['item_id'], hatId);
      expect(hats.first['item_name'], 'Top Hat');
      expect(hats.first['image_path'], 'assets/images/hats/tophat.png');
      expect(hats.first['price'], 350);
      expect(hats.first['type'], 'hat');
    });

    test('return multiple hats when user owns more than one', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 2);
    });

    test('return empty list for a user that doesnt exist', () async {
      final hats = await dressDb.getHatsOwnedByUser(999);
      expect(hats, isEmpty);
    });

    test('return empty list for no hats', () async {
      final userId = await TestDatabase.seedUser(db);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats, isEmpty);
    });
  });

  // getEquippedHat
  group('getEquippedHat', () {
    test('returns equipped hat for little guy', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId = await TestDatabase.seedHat(
        db,
        imagePath: 'assets/images/gats/tophat.png',
      );
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await TestDatabase.seedWearing(
        db,
        littleGuyId: littleGuyId,
        itemId: hatId,
      );
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNotNull);
      expect(equipped!['item_id'], hatId);
      expect(equipped['image_path'], 'assets/images/hats/tophats.png');
    });

    test('return null when little guy has not hat equipped', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNull);
    });

    test('returns correct hat after swapping hats', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped!['item_id'], hatId2);
    });
  });
}
