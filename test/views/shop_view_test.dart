import 'package:flutter_flame_playground/models/shop_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  // test getUserCurrency
  group('getUserCurrency', () {
    // Partition: user has currency > 0
    test('returns correct currency for a user', () async {
      await TestDatabase.seedUser(db, currency: 500);
      final currency = await shopDb.getUserCurrency(1);
      expect(currency, 500);
    });

    // Partition: user has currency = 0
    test('returns 0 currency as the user is broke', () async {
      await TestDatabase.seedUser(db, currency: 0);
      final currency = await shopDb.getUserCurrency(1);
      expect(currency, 0);
    });

    // Partition: user does not exist
    test('returns 0 when user does not exist', () async {
      final currency = await shopDb.getUserCurrency(999);
      expect(currency, 0);
    });
  });

  // test getItemsByType
  group('getItemsByType', () {
    // Partition: valid type, exactly one match
    test('return only hats when selected type is hat', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedFood(db, name: 'Bread');
      final hats = await shopDb.getItemsByType('hat');
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
      expect(hats.first['type'], 'hat');
    });

    // Partition: valid type, exactly one match (food)
    test('returns only food when selected type is food', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedFood(db, name: 'Bread');
      final food = await shopDb.getItemsByType('food');
      expect(food.length, 1);
      expect(food.first['item_name'], 'Bread');
      expect(food.first['type'], 'food');
    });

    // Partition: valid type, multiple matches
    test('return multiple items with the same type', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedHat(db, name: 'Sun Hat');
      final hats = await shopDb.getItemsByType('hat');
      expect(hats.length, 3);
    });

    // Partition: valid type, no items of that type exist
    test('returns empty list when no items of selected type exists', () async {
      await TestDatabase.seedHat(db);
      final food = await shopDb.getItemsByType('food');
      expect(food, isEmpty);
    });

    // Partition: table is empty
    test('return empty list when item table is empty', () async {
      final result = await shopDb.getItemsByType('hat');
      expect(result, isEmpty);
    });

    // Partition: unknown/invalid type
    test('returns empty list for an unrecognised type', () async {
      await TestDatabase.seedHat(db);
      await TestDatabase.seedFood(db);
      final result = await shopDb.getItemsByType('weapon');
      expect(result, isEmpty);
    });
  });

  group('getUserItems', () {
    // Partition: user owns multiple items
    test('returns set of item ids owned by user', () async {
      final userId = await TestDatabase.seedUser(db);
      final hatId = await TestDatabase.seedHat(db);
      final foodId = await TestDatabase.seedFood(db);
      await TestDatabase.seedInventory(db, userId: userId, itemId: hatId);
      await TestDatabase.seedInventory(db, userId: userId, itemId: foodId);
      final items = await shopDb.getUserItems(userId);
      expect(items, containsAll([hatId, foodId]));
      expect(items.length, 2);
    });

    // Partition: user owns one item
    test('returns no duplicates even with multiple inventory rows', () async {
      final userId = await TestDatabase.seedUser(db);
      final itemId = await TestDatabase.seedHat(db);
      await TestDatabase.seedInventory(
        db,
        userId: userId,
        itemId: itemId,
        quantity: 1,
      );
      final items = await shopDb.getUserItems(userId);
      expect(items.length, 1);
      expect(items.contains(itemId), isTrue);
    });

    // Partition: user exists but owns nothing
    test('returns empty set when user has no inventory', () async {
      final userId = await TestDatabase.seedUser(db);
      final items = await shopDb.getUserItems(userId);
      expect(items, isEmpty);
    });

    // Partition: user does not exist
    test('returns empty set when user does not exist', () async {
      final items = await shopDb.getUserItems(99);
      expect(items, isEmpty);
    });
  });

  group('getUserItemQuantities', () {
    // Partition: user has multiple items with varying quantities
    test('returns a map of all item quantities for a user', () async {
      final userId = await TestDatabase.seedUser(db);
      final foodId = await TestDatabase.seedFood(db);
      final hatId = await TestDatabase.seedHat(db);
      await TestDatabase.seedInventory(
        db,
        userId: userId,
        itemId: foodId,
        quantity: 3,
      );
      await TestDatabase.seedInventory(
        db,
        userId: userId,
        itemId: hatId,
        quantity: 1,
      );
      final quantities = await shopDb.getUserItemQuantities(userId);
      expect(quantities[foodId], 3);
      expect(quantities[hatId], 1);
    });

    // Partition: user exists, no inventory
    test('returns empty map when user has no inventory', () async {
      final userId = await TestDatabase.seedUser(db);
      final quantities = await shopDb.getUserItemQuantities(userId);
      expect(quantities, isEmpty);
    });

    // Partition: user doesn't exist
    test('returns empty map when user doesnt exist', () async {
      final quantities = await shopDb.getUserItemQuantities(99);
      expect(quantities, isEmpty);
    });
  });

  group('purchaseItem', () {
    // Partition: currency > price, hat not yet owned
    test('successfully purchases a hat user does not own', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });

    test('deducts correct currency after hat purchase', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      await shopDb.purchaseItem(userId, itemId);
      final currency = await shopDb.getUserCurrency(userId);
      expect(currency, 400);
    });

    test('adds hat to inventory after successful purchase', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      await shopDb.purchaseItem(userId, itemId);
      final owns = await shopDb.userOwnsItem(userId, itemId);
      expect(owns, isTrue);
    });

    // Partition: currency > price, food not yet owned
    test('successfully purchases food item not yet owned', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedFood(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });

    test(
      'adds food to inventory with quantity 1 when not previously owned',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await shopDb.purchaseItem(userId, itemId);
        final quantity = await shopDb.getItemQuantity(userId, itemId);
        expect(quantity, 1);
      },
    );

    // Partition: currency > price, food already owned
    test(
      'successfully purchases food item already owned (increments quantity)',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await TestDatabase.seedInventory(
          db,
          userId: userId,
          itemId: itemId,
          quantity: 2,
        );
        final result = await shopDb.purchaseItem(userId, itemId);
        expect(result, 'success');
      },
    );

    test(
      'increments food quantity when food is already in inventory',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedFood(db, price: 100);
        await TestDatabase.seedInventory(
          db,
          userId: userId,
          itemId: itemId,
          quantity: 2,
        );
        await shopDb.purchaseItem(userId, itemId);
        final quantity = await shopDb.getItemQuantity(userId, itemId);
        expect(quantity, 3);
      },
    );

    // Partition: currency = price exactly
    test('purchase works when user has exactly enough currency', () async {
      final userId = await TestDatabase.seedUser(db, currency: 100);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });

    // Partition: hat already owned
    test(
      'returns already_owned when purchasing a hat already in inventory',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 500);
        final itemId = await TestDatabase.seedHat(db, price: 100);
        await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);
        final result = await shopDb.purchaseItem(userId, itemId);
        expect(result, 'already_owned');
      },
    );

    test('does not deduct currency when hat is already owned', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      await TestDatabase.seedInventory(db, userId: userId, itemId: itemId);
      await shopDb.purchaseItem(userId, itemId);
      final currency = await shopDb.getUserCurrency(userId);
      expect(currency, 500);
    });

    // Partition: currency < price, hat
    test('returns insufficient_funds when user cannot afford hat', () async {
      final userId = await TestDatabase.seedUser(db, currency: 50);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'insufficient_funds');
    });

    // Partition: currency < price, food
    test('returns insufficient_funds when user cannot afford food', () async {
      final userId = await TestDatabase.seedUser(db, currency: 50);
      final itemId = await TestDatabase.seedFood(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'insufficient_funds');
    });

    test(
      'does not deduct currency when purchase fails due to insufficient funds',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 50);
        final itemId = await TestDatabase.seedHat(db, price: 100);
        await shopDb.purchaseItem(userId, itemId);
        final currency = await shopDb.getUserCurrency(userId);
        expect(currency, 50);
      },
    );

    test('does not add item to inventory when purchase fails', () async {
      final userId = await TestDatabase.seedUser(db, currency: 50);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      await shopDb.purchaseItem(userId, itemId);
      final owns = await shopDb.userOwnsItem(userId, itemId);
      expect(owns, isFalse);
    });

    // Partition: item does not exist
    test('returns Item not found for non-existent item', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final result = await shopDb.purchaseItem(userId, 999);
      expect(result, 'Item not found');
    });

    // BVA: currency = price + 1
    test(
      'BVA - successfully purchases when currency is 1 above price',
      () async {
        final userId = await TestDatabase.seedUser(db, currency: 101);
        final itemId = await TestDatabase.seedHat(db, price: 100);
        final result = await shopDb.purchaseItem(userId, itemId);
        expect(result, 'success');
      },
    );

    test('BVA - deducts correct currency when 1 above price', () async {
      final userId = await TestDatabase.seedUser(db, currency: 101);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      await shopDb.purchaseItem(userId, itemId);
      final currency = await shopDb.getUserCurrency(userId);
      expect(currency, 1);
    });

    // BVA: food quantity incremtes from 1 to 2 (lower boundary)
    test('BVA - increments food quantity from 1 to 2 when owned', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedFood(db, price: 100);
      await TestDatabase.seedInventory(
        db,
        userId: userId,
        itemId: itemId,
        quantity: 1,
      );
      await shopDb.purchaseItem(userId, itemId);
      final quantity = await shopDb.getItemQuantity(userId, itemId);
      expect(quantity, 2);
    });

    // BVA: currency = 0 (lower boundary of currency)
    test('BVA - cannot purchase when currency is 0', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'insufficient_funds');
    });

    // BVA: price = 0 (lower boundary of item price)
    test('BVA - successfully purchases free item when price is 0', () async {
      final userId = await TestDatabase.seedUser(db, currency: 0);
      final itemId = await TestDatabase.seedHat(db, price: 0);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });
  });
}
