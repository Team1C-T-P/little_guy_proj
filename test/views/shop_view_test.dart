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
  });
}
