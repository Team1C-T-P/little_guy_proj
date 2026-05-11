// Tests for DressDatabase — putting hats on the pet, taking them off, and
// listing what the user owns. Also tests AppDatabase.countUserHats at the
// end since it's conceptually a hat-counting query and grouping it here
// keeps all hat-related coverage in one file.
//
// Schema reminder:
//   - `inventory` links a user to the items they own
//   - `little_guy_wearing` links a pet to its currently-equipped hat
//   - At most one row exists in little_guy_wearing per pet
//     (equipHat does delete-then-insert so the row is always replaced)

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/models/dress_database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late DressDatabase dressDb;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    dressDb = DressDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR2 — DressDatabase', () {

    // getHatsOwnedByUser queries the inventory + item tables for any item
    // whose type is "hat". The interesting partitions are: owns one,
    // owns several, owns hats and non-hats (filter check), owns only food,
    // owns nothing, field correctness, and non-existent user.
    group('getHatsOwnedByUser', () {
      test('[TR-DRS-01] returns hats owned by a user with one hat', () async {
        final userId = await TestDatabase.seedUser(db);
        final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats.length, 1);
        expect(hats.first['item_name'], 'Top Hat');
      });

      test('[TR-DRS-02] returns multiple hats when the user owns more than one', () async {
        final userId = await TestDatabase.seedUser(db);
        final hatId1 = await TestDatabase.seedHat(db, name: 'Top Hat');
        final hatId2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId2);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats.length, 2);
      });

      test('[TR-DRS-03] only returns hats, never food', () async {
        // Mixed inventory — the type filter should exclude the food row.
        final userId = await TestDatabase.seedUser(db);
        final hatId = await TestDatabase.seedHat(db, name: 'Top Hat');
        final foodId = await TestDatabase.seedFood(db, name: 'Bread');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats.length, 1);
        expect(hats.first['item_name'], 'Top Hat');
      });

      test('[TR-DRS-04] returns an empty list when the user only owns food', () async {
        final userId = await TestDatabase.seedUser(db);
        final foodId = await TestDatabase.seedFood(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats, isEmpty);
      });

      test('[TR-DRS-05] returns an empty list when the user owns nothing', () async {
        final userId = await TestDatabase.seedUser(db);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats, isEmpty);
      });

      test('[TR-DRS-06] returns the correct hat fields (item_id, name, image_path, price, type)', () async {
        // Sanity check on the SELECT — making sure each field shape is right.
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

      test('[TR-DRS-07] returns an empty list for a non-existent user', () async {
        final hats = await dressDb.getHatsOwnedByUser(999);

        expect(hats, isEmpty);
      });
    });

    // equipHat does delete-then-insert so the wearing row is always replaced.
    // Four partitions cover the no-hat-yet case, the swap case, the
    // "only-one-hat at a time" invariant, and explicit verification that
    // the old row gets removed (not orphaned).
    group('equipHat', () {
      test('[TR-DRS-08] inserts a wearing row when nothing is currently equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);

        await dressDb.equipHat(petId, hatId);

        final equipped = await dressDb.getEquippedHat(petId);
        expect(equipped, isNotNull);
        expect(equipped!['item_id'], hatId);
      });

      test('[TR-DRS-09] swaps to the new hat when one is already equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hat1 = await TestDatabase.seedHat(db, name: 'Hat 1', imagePath: 'a.png');
        final hat2 = await TestDatabase.seedHat(db, name: 'Hat 2', imagePath: 'b.png');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat2);

        await dressDb.equipHat(petId, hat1);
        await dressDb.equipHat(petId, hat2);

        final equipped = await dressDb.getEquippedHat(petId);
        expect(equipped!['item_id'], hat2);
      });

      test('[TR-DRS-10] enforces the one-hat-at-a-time invariant', () async {
        // Even after multiple equipHat calls, the table should hold
        // exactly one wearing row for this pet.
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hat1 = await TestDatabase.seedHat(db, name: 'Hat 1', imagePath: 'a.png');
        final hat2 = await TestDatabase.seedHat(db, name: 'Hat 2', imagePath: 'b.png');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat2);

        await dressDb.equipHat(petId, hat1);
        await dressDb.equipHat(petId, hat2);

        final wearing = await db.query(
          'little_guy_wearing',
          where: 'little_guy_id = ?',
          whereArgs: [petId],
        );
        expect(wearing.length, 1);
      });

      test('[TR-DRS-11] removes the old hat row from little_guy_wearing on swap', () async {
        // Specifically asserts the old hat's row is gone — not just that
        // there's one row total.
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hat1 = await TestDatabase.seedHat(db, name: 'Hat 1', imagePath: 'a.png');
        final hat2 = await TestDatabase.seedHat(db, name: 'Hat 2', imagePath: 'b.png');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat2);

        await dressDb.equipHat(petId, hat1);
        await dressDb.equipHat(petId, hat2);

        final oldHatRows = await db.query(
          'little_guy_wearing',
          where: 'little_guy_id = ? AND item_id = ?',
          whereArgs: [petId, hat1],
        );
        expect(oldHatRows, isEmpty);
      });
    });

    group('unequipHat', () {
      test('[TR-DRS-12] removes the wearing row when one exists', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        await dressDb.equipHat(petId, hatId);

        await dressDb.unequipHat(petId);

        expect(await dressDb.getEquippedHat(petId), isNull);
      });

      test('[TR-DRS-13] is a silent no-op when nothing is equipped', () async {
        // Unequipping with nothing on shouldn't throw — just does nothing.
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

        await dressDb.unequipHat(petId);

        expect(await dressDb.getEquippedHat(petId), isNull);
      });

      test('[TR-DRS-14] is a silent no-op for a non-existent pet', () async {
        // Same graceful behaviour — calling unequipHat on a pet that
        // doesn't exist shouldn't error.
        await expectLater(dressDb.unequipHat(999), completes);
        expect(await dressDb.getEquippedHat(999), isNull);
      });
    });

    group('getEquippedHat', () {
      test('[TR-DRS-15] returns the equipped hat row with item_id and image_path', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(
          db,
          imagePath: 'assets/images/hats/tophat.png',
        );
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        await TestDatabase.seedWearing(db, littleGuyId: petId, itemId: hatId);

        final equipped = await dressDb.getEquippedHat(petId);

        expect(equipped, isNotNull);
        expect(equipped!['item_id'], hatId);
        expect(equipped['image_path'], 'assets/images/hats/tophat.png');
      });

      test('[TR-DRS-16] returns null when no hat is equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

        final equipped = await dressDb.getEquippedHat(petId);

        expect(equipped, isNull);
      });

      test('[TR-DRS-17] returns the most recently equipped hat after a swap', () async {
        // After equipHat(hat2), getEquippedHat should return hat2, not hat1.
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hat1 = await TestDatabase.seedHat(db, name: 'Top Hat');
        final hat2 = await TestDatabase.seedHat(db, name: 'Witch Hat');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat2);
        await dressDb.equipHat(petId, hat1);
        await dressDb.equipHat(petId, hat2);

        final equipped = await dressDb.getEquippedHat(petId);

        expect(equipped!['item_id'], hat2);
      });

      test('[TR-DRS-18] returns null for a non-existent pet', () async {
        final equipped = await dressDb.getEquippedHat(999);

        expect(equipped, isNull);
      });
    });

    // countUserHats lives on AppDatabase rather than DressDatabase, but
    // testing it here keeps all the hat-related coverage together.
    // We pass our in-memory db explicitly so the singleton is never touched.
    group('countUserHats', () {
      test('[TR-DRS-19] returns the correct count of hat-type inventory rows', () async {
        final userId = await TestDatabase.seedUser(db);
        for (int i = 1; i <= 5; i++) {
          final hatId = await TestDatabase.seedHat(db, name: 'Hat $i', imagePath: 'h$i.png');
          await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        }

        final count = await AppDatabase.instance.countUserHats(userId, db: db);

        expect(count, 5);
      });

      test('[TR-DRS-20] returns 0 when the user owns no hats', () async {
        final userId = await TestDatabase.seedUser(db);

        final count = await AppDatabase.instance.countUserHats(userId, db: db);

        expect(count, 0);
      });
    });
  });
}
