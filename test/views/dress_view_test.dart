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
    // Partition: user owns one hat
    test('return hats owned by user', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
    });

    // Partition: user owns multiple hats
    test('return multiple hats when user owns more than one', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 2);
    });

    // Partition: user owns hats and food (filter check)
    test('only returns hats, no food', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
      final foodId = await TestDatabase.seedFood(db, name: 'Bread');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
    });

    // Partition: user owns only food
    test('empty list is returned when only food is owned', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodId = await TestDatabase.seedFood(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats, isEmpty);
    });

    // Partition: user owns nothing
    test('return empty list for no hats', () async {
      final userId = await TestDatabase.seedUser(db);
      final hats = await dressDb.getHatsOwnedByUser(userId);
      expect(hats, isEmpty);
    });

    // Partition: correct fields are returned
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

    // Partition: user does not exist
    test('returns empty list for non-existent user', () async {
      final hats = await dressDb.getHatsOwnedByUser(999);
      expect(hats, isEmpty);
    });
  });

  // getEquippedHat
  group('getEquippedHat', () {
    // Partition: little guy has a hat equipped
    test('returns equipped hat for little guy', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId = await TestDatabase.seedHat(
        db,
        imagePath: 'assets/images/hats/tophat.png',
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
      expect(equipped['image_path'], 'assets/images/hats/tophat.png');
    });

    // Partition: little guy has nothing equipped
    test('return null when little guy has no hat equipped', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNull);
    });

    // Partition: hat has been swapped (most recent is returned)
    test('returns correct hat after swapping hats', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      await dressDb.equipHat(littleGuyId, hatId1);
      await dressDb.equipHat(littleGuyId, hatId2);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped!['item_id'], hatId2);
    });

    // Partition: little guy does not exist
    test('returns null for a little guy that does not exist', () async {
      final equipped = await dressDb.getEquippedHat(999);
      expect(equipped, isNull);
    });
  });

  // equipHat
  group('equipHat', () {
    // Partition: no hat previously equipped
    test('equip hat to little guy', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId = await TestDatabase.seedHat(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await dressDb.equipHat(littleGuyId, hatId);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNotNull);
      expect(equipped!['item_id'], hatId);
    });

    // Partition: hat already equipped (replace)
    test('replace previously equipped hat with new hat', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      await dressDb.equipHat(littleGuyId, hatId1);
      await dressDb.equipHat(littleGuyId, hatId2);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped!['item_id'], hatId2);
    });

    // Partition: one-hat constraint enforced
    test('little guy can only wear one hat at a time', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
      final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
      await dressDb.equipHat(littleGuyId, hatId1);
      await dressDb.equipHat(littleGuyId, hatId2);
      final wearing = await db.query(
        'little_guy_wearing',
        where: 'little_guy_id = ?',
        whereArgs: [littleGuyId],
      );
      expect(wearing.length, 1);
    });

    // Partition: previous hat is removed from little_guy_wearing after equipping new hat
    test(
      'old hat is deleted from little_guy_wearing when new hat is equipped',
      () async {
        final userId = await TestDatabase.seedUser(db);
        final littleGuyId = await TestDatabase.seedLittleGuy(
          db,
          userId: userId,
        );
        final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
        final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);
        await dressDb.equipHat(littleGuyId, hatId1);
        await dressDb.equipHat(littleGuyId, hatId2);
        final wearing = await db.query(
          'little_guy_wearing',
          where: 'little_guy_id = ? AND item_id = ?',
          whereArgs: [littleGuyId, hatId1],
        );
        expect(wearing, isEmpty);
      },
    );
  });

  // unequipHat
  group('unEquip', () {
    // Partition: hat is equipped
    test('removes equipped hat from little guy', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      final hatId = await TestDatabase.seedHat(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await dressDb.equipHat(littleGuyId, hatId);
      await dressDb.unequipHat(littleGuyId);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNull);
    });

    // Partition: nothing equipped (no-op)
    test('does nothing if no hat is equipped to little guy', () async {
      final userId = await TestDatabase.seedUser(db);
      final littleGuyId = await TestDatabase.seedLittleGuy(db, userId: userId);
      await dressDb.unequipHat(littleGuyId);
      final equipped = await dressDb.getEquippedHat(littleGuyId);
      expect(equipped, isNull);
    });

    // Partition: little guy does not exist
    test('does nothing if little guy does not exist', () async {
      await expectLater(dressDb.unequipHat(999), completes);
      final equipped = await dressDb.getEquippedHat(999);
      expect(equipped, isNull);
    });
  });
}
