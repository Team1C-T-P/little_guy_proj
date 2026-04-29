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
}
