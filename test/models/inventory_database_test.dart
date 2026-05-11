// Tests for InventoryDatabase — the food-inventory layer that lives in
// pet_maintainance_database.dart alongside PetStatsDatabase. Two methods:
//   - getFoodByUserId: list the food rows in a user's inventory
//   - useFood: decrement a food item's quantity by 1 when "consumed"

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/pet_maintainance_database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late InventoryDatabase inventoryDb;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    inventoryDb = InventoryDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR6 — InventoryDatabase', () {

    // getFoodByUserId returns the user's food rows (joined to items). Note
    // the current behaviour: if the user has *no* food at all, it throws
    // rather than returning an empty list. This is flagged in docs as a
    // design ambiguity worth revisiting.
    group('getFoodByUserId', () {
      test('[TR-INV-01] returns food with quantities for a user that owns multiple items', () async {
        final userId = await TestDatabase.seedUser(db);
        final breadId = await TestDatabase.seedFood(db);
        final pastaId = await TestDatabase.seedFood(
          db,
          name: 'Pasta',
          imagePath: 'assets/images/food/Pasta.png',
        );
        await TestDatabase.seedInventory(db, userId: userId, itemId: breadId, quantity: 5);
        await TestDatabase.seedInventory(db, userId: userId, itemId: pastaId, quantity: 3);

        final food = await inventoryDb.getFoodByUserId(userId);

        expect(food.length, 2);
        expect(food[0]['item_id'], breadId);
        expect(food[0]['quantity'], 5);
        expect(food[0]['image_path'], 'assets/images/food/bread.png');
        expect(food[1]['item_id'], pastaId);
        expect(food[1]['quantity'], 3);
      });

      test('[TR-INV-02] returns a row even when its quantity is 0', () async {
        // Inventory rows can sit at quantity 0 (user used them all) — they
        // still come back from the query, just with quantity 0.
        final userId = await TestDatabase.seedUser(db);
        final breadId = await TestDatabase.seedFood(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: breadId, quantity: 0);

        final food = await inventoryDb.getFoodByUserId(userId);

        expect(food.length, 1);
        expect(food[0]['quantity'], 0);
      });

      test('[TR-INV-03] returns an empty list when the user has no food rows', () async {
        // Resolved a previous design ambiguity: getFoodByUserId now returns
        // [] for an empty inventory instead of throwing. This matches what
        // FeedScreen already wants ("No food owned yet!" empty state).
        final food = await inventoryDb.getFoodByUserId(999);
        expect(food, isEmpty);
      });
    });

    // useFood drops the quantity of one inventory row by 1 (but never below
    // 0 — SQL guard `quantity > 0`). Four partitions: valid+quantity>0,
    // valid+quantity=0 (no-op), invalid user, invalid food item.
    group('useFood', () {
      test('[TR-INV-04] decrements quantity by 1 when the item is owned and has stock', () async {
        // Seed two foods so we can also check that only the right one drops.
        final userId = await TestDatabase.seedUser(db);
        final breadId = await TestDatabase.seedFood(db);
        final pastaId = await TestDatabase.seedFood(
          db,
          name: 'Pasta',
          imagePath: 'assets/images/food/Pasta.png',
        );
        await TestDatabase.seedInventory(db, userId: userId, itemId: breadId, quantity: 5);
        await TestDatabase.seedInventory(db, userId: userId, itemId: pastaId, quantity: 3);

        // Bread: 5 -> 4. Pasta: 3 -> 2 -> 1.
        await inventoryDb.useFood(breadId, userId);
        await inventoryDb.useFood(pastaId, userId);
        await inventoryDb.useFood(pastaId, userId);

        final food = await inventoryDb.getFoodByUserId(userId);
        expect(food[0]['quantity'], 4);
        expect(food[1]['quantity'], 1);
      });

      test('[TR-INV-05] does not decrement when quantity is already 0', () async {
        // SQL guard `quantity > 0` prevents going negative.
        final userId = await TestDatabase.seedUser(db);
        final breadId = await TestDatabase.seedFood(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: breadId, quantity: 0);

        await inventoryDb.useFood(breadId, userId);

        final food = await inventoryDb.getFoodByUserId(userId);
        expect(food[0]['quantity'], 0);
      });

      test('[TR-INV-06] throws when the user does not own the food item (invalid user)', () async {
        // userId 999 has no inventory rows at all.
        final foodId = await TestDatabase.seedFood(db);

        expect(
          () => inventoryDb.useFood(foodId, 999),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to use food: User or item not found'),
            ),
          ),
        );
      });

      test('[TR-INV-07] throws when the food item does not exist for the user (invalid item)', () async {
        // User exists, but they don't own foodId 999.
        final userId = await TestDatabase.seedUser(db);

        expect(
          () => inventoryDb.useFood(999, userId),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to use food: User or item not found'),
            ),
          ),
        );
      });
    });
  });
}
