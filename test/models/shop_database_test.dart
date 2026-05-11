// Tests for ShopDatabase — the in-game shop's database layer. Eight methods:
//   - getItemsByType:        list all items of a type ('hat' or 'food')
//   - getUserCurrency:       look up the user's current currency balance
//   - userOwnsItem:          check if the user has a row for this item
//   - purchaseItem:          buy an item (the big one — many partitions)
//   - getItemQuantity:       how many of one item the user owns
//   - getUserItemQuantities: map of item_id -> quantity for the user
//   - getUserItems:          set of item_ids the user owns
//   - getTotalShopItems:     count of all items in the shop's item table
//
// purchaseItem is the most interesting method — it handles hat purchases
// (one-shot, fails if already owned), food purchases (stackable, increments
// quantity if already owned), affordability checks, and unknown-item lookups.
// Twenty partitions below cover those branches plus several boundary cases.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_flame_playground/models/shop_database.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late ShopDatabase shopDb;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    shopDb = ShopDatabase(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR6 — ShopDatabase', () {

    // Three partitions: user has currency > 0, user has currency = 0,
    // and user doesn't exist (graceful 0 fallback).
    group('getUserCurrency', () {
      test('[TR-SHOP-01] returns the correct currency for an existing user', () async {
        await TestDatabase.seedUser(db, currency: 500);

        final currency = await shopDb.getUserCurrency(1);

        expect(currency, 500);
      });

      test('[TR-SHOP-02] returns 0 when the user has no currency', () async {
        await TestDatabase.seedUser(db, currency: 0);

        final currency = await shopDb.getUserCurrency(1);

        expect(currency, 0);
      });

      test('[TR-SHOP-03] returns 0 when the user does not exist', () async {
        // No throw — returns 0 as a graceful default.
        final currency = await shopDb.getUserCurrency(999);

        expect(currency, 0);
      });
    });

    // getItemsByType is a thin wrapper around a WHERE type = ? query.
    // Six partitions cover both valid types, multiple matches, no matches,
    // empty table, and unknown type.
    group('getItemsByType', () {
      test('[TR-SHOP-04] returns only hats when type is "hat"', () async {
        await TestDatabase.seedHat(db, name: 'Top Hat');
        await TestDatabase.seedFood(db, name: 'Bread');

        final hats = await shopDb.getItemsByType('hat');

        expect(hats.length, 1);
        expect(hats.first['item_name'], 'Top Hat');
        expect(hats.first['type'], 'hat');
      });

      test('[TR-SHOP-05] returns only food when type is "food"', () async {
        await TestDatabase.seedHat(db, name: 'Top Hat');
        await TestDatabase.seedFood(db, name: 'Bread');

        final food = await shopDb.getItemsByType('food');

        expect(food.length, 1);
        expect(food.first['item_name'], 'Bread');
        expect(food.first['type'], 'food');
      });

      test('[TR-SHOP-06] returns all matches when several items share a type', () async {
        await TestDatabase.seedHat(db, name: 'Top Hat');
        await TestDatabase.seedHat(db, name: 'Witch Hat');
        await TestDatabase.seedHat(db, name: 'Sun Hat');

        final hats = await shopDb.getItemsByType('hat');

        expect(hats.length, 3);
      });

      test('[TR-SHOP-07] returns an empty list when no items of the requested type exist', () async {
        await TestDatabase.seedHat(db);

        final food = await shopDb.getItemsByType('food');

        expect(food, isEmpty);
      });

      test('[TR-SHOP-08] returns an empty list when the item table is empty', () async {
        final result = await shopDb.getItemsByType('hat');

        expect(result, isEmpty);
      });

      test('[TR-SHOP-09] returns an empty list for an unrecognised type', () async {
        await TestDatabase.seedHat(db);
        await TestDatabase.seedFood(db);

        final result = await shopDb.getItemsByType('weapon');

        expect(result, isEmpty);
      });
    });

    // userOwnsItem is a boolean check — does the user have an inventory
    // row for this item? Two partitions.
    group('userOwnsItem', () {
      test('[TR-SHOP-10] returns true when the user has the item in inventory', () async {
        final userId = await TestDatabase.seedUser(db);
        final itemId = await TestDatabase.seedHat(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);

        final owns = await shopDb.userOwnsItem(userId, itemId);

        expect(owns, isTrue);
      });

      test('[TR-SHOP-11] returns false when the user does not have the item', () async {
        final userId = await TestDatabase.seedUser(db);
        final itemId = await TestDatabase.seedHat(db);
        // No inventory row inserted.

        final owns = await shopDb.userOwnsItem(userId, itemId);

        expect(owns, isFalse);
      });
    });

    // getUserItems returns a Set<int> of item_ids the user owns. Four
    // partitions: owns multiple, owns one, owns nothing, user doesn't exist.
    group('getUserItems', () {
      test('[TR-SHOP-12] returns a set of item ids for a user with multiple items', () async {
        final userId = await TestDatabase.seedUser(db);
        final hatId = await TestDatabase.seedHat(db);
        final foodId = await TestDatabase.seedFood(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
        await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);

        final items = await shopDb.getUserItems(userId);

        expect(items, containsAll([hatId, foodId]));
        expect(items.length, 2);
      });

      test('[TR-SHOP-13] returns a single-element set when the user owns one item', () async {
        final userId = await TestDatabase.seedUser(db);
        final itemId = await TestDatabase.seedHat(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId, quantity: 1);

        final items = await shopDb.getUserItems(userId);

        expect(items.length, 1);
        expect(items.contains(itemId), isTrue);
      });

      test('[TR-SHOP-14] returns an empty set when the user owns nothing', () async {
        final userId = await TestDatabase.seedUser(db);

        final items = await shopDb.getUserItems(userId);

        expect(items, isEmpty);
      });

      test('[TR-SHOP-15] returns an empty set when the user does not exist', () async {
        final items = await shopDb.getUserItems(99);

        expect(items, isEmpty);
      });
    });

    // getUserItemQuantities returns a Map<int, int> of item_id -> quantity.
    // Three partitions.
    group('getUserItemQuantities', () {
      test('[TR-SHOP-16] returns a quantity map for a user with multiple items', () async {
        final userId = await TestDatabase.seedUser(db);
        final foodId = await TestDatabase.seedFood(db);
        final hatId = await TestDatabase.seedHat(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: foodId, quantity: 3);
        await TestDatabase.seedInventory(db, userId: userId, itemId: hatId, quantity: 1);

        final quantities = await shopDb.getUserItemQuantities(userId);

        expect(quantities[foodId], 3);
        expect(quantities[hatId], 1);
      });

      test('[TR-SHOP-17] returns an empty map when the user owns nothing', () async {
        final userId = await TestDatabase.seedUser(db);

        final quantities = await shopDb.getUserItemQuantities(userId);

        expect(quantities, isEmpty);
      });

      test('[TR-SHOP-18] returns an empty map when the user does not exist', () async {
        final quantities = await shopDb.getUserItemQuantities(99);

        expect(quantities, isEmpty);
      });
    });

    // getItemQuantity returns the user's quantity for one specific item,
    // or 0 if they don't own it.
    group('getItemQuantity', () {
      test('[TR-SHOP-19] returns the stored quantity when the user owns the item', () async {
        final userId = await TestDatabase.seedUser(db);
        final foodId = await TestDatabase.seedFood(db);
        await TestDatabase.seedInventory(db, userId: userId, itemId: foodId, quantity: 3);

        final qty = await shopDb.getItemQuantity(userId, foodId);

        expect(qty, 3);
      });

      test('[TR-SHOP-20] returns 0 when the user does not own the item', () async {
        final userId = await TestDatabase.seedUser(db);
        final foodId = await TestDatabase.seedFood(db);
        // No inventory row inserted.

        final qty = await shopDb.getItemQuantity(userId, foodId);

        expect(qty, 0);
      });
    });

    // purchaseItem is the big one. Branches it covers (and the partitions
    // below test each one):
    //   - hat, not owned, sufficient funds   -> 'success' (TR-SHOP-21..23)
    //   - food, first time, sufficient funds -> 'success' + qty=1 (TR-SHOP-24..25)
    //   - food, already owned                -> 'success' + qty++ (TR-SHOP-26..27)
    //   - currency = price exactly           -> 'success' (TR-SHOP-28)
    //   - hat already owned                  -> 'already_owned' (TR-SHOP-29..30)
    //   - insufficient funds                 -> 'insufficient_funds' (TR-SHOP-31..34)
    //   - item not found                     -> 'Item not found' (TR-SHOP-35)
    //   - BVA cases                          -> (TR-SHOP-36..40)
    group('purchaseItem', () {
      test('[TR-SHOP-21] returns "success" when buying an unowned hat with enough funds', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });

      test('[TR-SHOP-22] deducts the correct currency after a hat purchase', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getUserCurrency(userId), 400);
      });

      test('[TR-SHOP-23] adds the hat to inventory after a successful purchase', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.userOwnsItem(userId, itemId), isTrue);
      });

      test('[TR-SHOP-24] returns "success" when buying food for the first time', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });

      test('[TR-SHOP-25] inserts food into inventory with quantity 1 the first time', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getItemQuantity(userId, itemId), 1);
      });

      test('[TR-SHOP-26] returns "success" when buying a food the user already owns', () async {
        // Food is stackable — repurchasing increments quantity instead of failing.
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId, quantity: 2);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });

      test('[TR-SHOP-27] increments food quantity when food is already in inventory', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId, quantity: 2);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getItemQuantity(userId, itemId), 3);
      });

      test('[TR-SHOP-28] succeeds when the user has exactly enough currency (boundary)', () async {
        // Boundary: currency == price.
        final userId = await TestDatabase.seedUser(db, currency: 100);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });

      test('[TR-SHOP-29] returns "already_owned" when buying a hat already in inventory', () async {
        // Hats are one-shot — can't buy the same hat twice.
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'already_owned');
      });

      test('[TR-SHOP-30] does not deduct currency when the hat is already owned', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getUserCurrency(userId), 500);
      });

      test('[TR-SHOP-31] returns "insufficient_funds" when the user cannot afford a hat', () async {
        final userId = await TestDatabase.seedUser(db, currency: 50);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'insufficient_funds');
      });

      test('[TR-SHOP-32] returns "insufficient_funds" when the user cannot afford food', () async {
        final userId = await TestDatabase.seedUser(db, currency: 50);
        final itemId = await TestDatabase.seedFood(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'insufficient_funds');
      });

      test('[TR-SHOP-33] does not deduct currency when the purchase fails for insufficient funds', () async {
        final userId = await TestDatabase.seedUser(db, currency: 50);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getUserCurrency(userId), 50);
      });

      test('[TR-SHOP-34] does not add the item to inventory when the purchase fails', () async {
        final userId = await TestDatabase.seedUser(db, currency: 50);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.userOwnsItem(userId, itemId), isFalse);
      });

      test('[TR-SHOP-35] returns "Item not found" when the item id does not exist', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);

        final result = await shopDb.purchaseItem(userId, 999);

        expect(result, 'Item not found');
      });

      // BVA: just above the price boundary.
      test('[TR-SHOP-36] succeeds when currency is 1 above price (just-above boundary)', () async {
        final userId = await TestDatabase.seedUser(db, currency: 101);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });

      test('[TR-SHOP-37] deducts exactly the price when currency was 1 above', () async {
        final userId = await TestDatabase.seedUser(db, currency: 101);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getUserCurrency(userId), 1);
      });

      // BVA: food quantity goes 1 -> 2 (smallest non-trivial increment).
      test('[TR-SHOP-38] increments food quantity from 1 to 2 when re-bought', () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId, quantity: 1);

        await shopDb.purchaseItem(userId, itemId);

        expect(await shopDb.getItemQuantity(userId, itemId), 2);
      });

      // BVA: lower boundary of currency.
      test('[TR-SHOP-39] cannot purchase when currency is 0 (lower boundary)', () async {
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final itemId = await TestDatabase.seedHat(db, price: 100);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'insufficient_funds');
      });

      // BVA: lower boundary of item price — free items should always succeed.
      test('[TR-SHOP-40] successfully purchases a free item (price = 0)', () async {
        final userId = await TestDatabase.seedUser(db, currency: 0);
        final itemId = await TestDatabase.seedHat(db, price: 0);

        final result = await shopDb.purchaseItem(userId, itemId);

        expect(result, 'success');
      });
    });

    group('getTotalShopItems', () {
      test('[TR-SHOP-41] returns the count of all rows in the item table', () async {
        await TestDatabase.seedHat(db, name: 'Top Hat');
        await TestDatabase.seedHat(db, name: 'Witch Hat');
        await TestDatabase.seedFood(db, name: 'Bread');

        final count = await shopDb.getTotalShopItems();

        expect(count, 3);
      });
    });
  });
}
