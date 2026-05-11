// Tests for DressDatabase — putting hats on the pet, taking them off, and
// listing what the user owns. Also tests AppDatabase.countUserHats at the
// end since it's conceptually a hat-counting query and keeping it here
// keeps all the hat-related coverage in one file.
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
    group('getHatsOwnedByUser', () {
      test('[TR-DRS-01] returns all hat-type items in the user inventory', () async {
        // Seed three different hats and link them all to this user.
        final userId = await TestDatabase.seedUser(db);
        final hat1 = await TestDatabase.seedHat(db, name: 'Top Hat', imagePath: 'a.png');
        final hat2 = await TestDatabase.seedHat(db, name: 'Band', imagePath: 'b.png');
        final hat3 = await TestDatabase.seedHat(db, name: 'Witch Hat', imagePath: 'c.png');
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat1);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat2);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hat3);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats.length, 3);
        expect(
          hats.map((h) => h['item_name']).toSet(),
          {'Top Hat', 'Band', 'Witch Hat'},
        );
      });

      test('[TR-DRS-02] returns an empty list when the user owns no hats', () async {
        // User exists but has nothing in inventory.
        final userId = await TestDatabase.seedUser(db);

        final hats = await dressDb.getHatsOwnedByUser(userId);

        expect(hats, isEmpty);
      });
    });

    // equipHat does delete-then-insert so the wearing row is always replaced.
    // We verify two states: starting from no hat (insert only) and starting
    // from an already-equipped hat (delete + insert = swap).
    group('equipHat', () {
      test('[TR-DRS-03] inserts a wearing row when nothing is currently equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(db);

        await dressDb.equipHat(petId, hatId);

        final equipped = await dressDb.getEquippedHat(petId);
        expect(equipped, isNotNull);
        expect(equipped!['item_id'], hatId);
      });

      test('[TR-DRS-04] swaps to the new hat when one is already equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hat1 = await TestDatabase.seedHat(db, name: 'Hat 1', imagePath: 'a.png');
        final hat2 = await TestDatabase.seedHat(db, name: 'Hat 2', imagePath: 'b.png');

        await dressDb.equipHat(petId, hat1);
        await dressDb.equipHat(petId, hat2);

        // The new hat should be the one stored,
        final equipped = await dressDb.getEquippedHat(petId);
        expect(equipped!['item_id'], hat2);

        // and exactly one row should exist (we didn't accumulate stale rows).
        final wearingRows = await db.query(
          'little_guy_wearing',
          where: 'little_guy_id = ?',
          whereArgs: [petId],
        );
        expect(wearingRows.length, 1);
      });
    });

    group('unequipHat', () {
      test('[TR-DRS-05] removes the wearing row when one exists', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(db);
        await dressDb.equipHat(petId, hatId);

        await dressDb.unequipHat(petId);

        expect(await dressDb.getEquippedHat(petId), isNull);
      });

      test('[TR-DRS-06] is a silent no-op when nothing is equipped', () async {
        // Unequipping with nothing on shouldn't throw — just does nothing.
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

        await dressDb.unequipHat(petId);

        expect(await dressDb.getEquippedHat(petId), isNull);
      });
    });

    group('getEquippedHat', () {
      test('[TR-DRS-07] returns the equipped hat row with item_id and image_path', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);
        final hatId = await TestDatabase.seedHat(db, imagePath: 'assets/images/hats/tophat.png');
        await dressDb.equipHat(petId, hatId);

        final equipped = await dressDb.getEquippedHat(petId);

        expect(equipped, isNotNull);
        expect(equipped!['item_id'], hatId);
        expect(equipped['image_path'], 'assets/images/hats/tophat.png');
      });

      test('[TR-DRS-08] returns null when no hat is equipped', () async {
        final userId = await TestDatabase.seedUser(db);
        final petId = await TestDatabase.seedLittleGuy(db, userId: userId);

        final equipped = await dressDb.getEquippedHat(petId);

        expect(equipped, isNull);
      });
    });

    // countUserHats lives on AppDatabase rather than DressDatabase, but
    // testing it here keeps all the hat-related coverage together.
    // We pass our in-memory db explicitly so the singleton is never touched.
    group('countUserHats', () {
      test('[TR-DRS-09] returns the correct count of hat-type inventory rows', () async {
        final userId = await TestDatabase.seedUser(db);
        for (int i = 1; i <= 5; i++) {
          final hatId = await TestDatabase.seedHat(db, name: 'Hat $i', imagePath: 'h$i.png');
          await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        }

        final count = await AppDatabase.instance.countUserHats(userId, db: db);

        expect(count, 5);
      });

      test('[TR-DRS-10] returns 0 when the user owns no hats', () async {
        final userId = await TestDatabase.seedUser(db);

        final count = await AppDatabase.instance.countUserHats(userId, db: db);

        expect(count, 0);
      });
    });
  });
}
