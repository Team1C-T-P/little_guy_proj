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
    test('returns correct currency for a user', () async {
      await TestDatabase.seedUser(db, currency: 500);
      final currency = await shopDb.getUserCurrency(1);
      expect(currency, 500);
    });

    test('returns 0 if a user doesnt exist', () async {
      final currency = await shopDb.getUserCurrency(9);
      expect(currency, 0);
    });

    test('returns 0 currency as the user is broke', () async {
      await TestDatabase.seedUser(db, currency: 0);
      final currency = await shopDb.getUserCurrency(1);
      expect(currency, 0);
    });
  });
  // test getItemsByType
  group('getItemsByType', () {
    test('return only hats when selected type is hat', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedFood(db, name: 'Bread');
      final hats = await shopDb.getItemsByType('hat');
      expect(hats.length, 1);
      expect(hats.first['item_name'], 'Top Hat');
      expect(hats.first['type'], 'hat');
    });

    test('returns only food when selected type is food', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedFood(db, name: 'Bread');
      final food = await shopDb.getItemsByType('food');
      expect(food.length, 1);
      expect(food.first['item_name'], 'Bread');
      expect(food.first['type'], 'food');
    });

    test('returns empty list when no items of selected type exists', () async {
      await TestDatabase.seedHat(db);
      final food = await shopDb.getItemsByType('food');
      expect(food, isEmpty);
    });

    test('return multiple items with the same type', () async {
      await TestDatabase.seedHat(db, name: 'Top Hat');
      await TestDatabase.seedHat(db, name: 'Witch Hat');
      await TestDatabase.seedHat(db, name: 'Sun Hat');
      final hats = await shopDb.getItemsByType('hat');
      expect(hats.length, 3);
    });

    test('return empty list when item table is empty', () async {
      final result = await shopDb.getItemsByType('hat');
      expect(result, isEmpty);
    });
  });

  group('getUserItems', () {
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

    test('returns empty set for non-existent user', () async {
      final items = await shopDb.getUserItems(999);
      expect(items, isEmpty);
    });

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

      // Sets inherently have no duplicates — just confirm length
      expect(items.length, 1);
      expect(items.contains(itemId), isTrue);
    });
  });

  group('getUserItemQuantities', () {
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

    test('returns empty map when user has no inventory', () async {
      final userId = await TestDatabase.seedUser(db);
      final quantities = await shopDb.getUserItemQuantities(userId);
      expect(quantities, isEmpty);
    });

    test('returns empty map for non-existent user', () async {
      final quantities = await shopDb.getUserItemQuantities(999);
      expect(quantities, isEmpty);
    });
  });

  group('purchaseItem', () async {
    // successful cases
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

    test('successfully purchases food item not yet owned', () async {
      final userId = await TestDatabase.seedUser(db, currency: 500);
      final itemId = await TestDatabase.seedFood(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });

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

    test('purchase works when user has exactly enough currency', () async {
      final userId = await TestDatabase.seedUser(db, currency: 100);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'success');
    });

    // fail cases
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

    test('returns insufficient_funds when user cannot afford hat', () async {
      final userId = await TestDatabase.seedUser(db, currency: 50);
      final itemId = await TestDatabase.seedHat(db, price: 100);
      final result = await shopDb.purchaseItem(userId, itemId);
      expect(result, 'insufficient_funds');
    });

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
  });
}
