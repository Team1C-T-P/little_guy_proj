// import db
import 'database.dart';

class ShopDatabase {
  // get items from shop
  Future<List<Map<String, dynamic>>> getShopItems() async {
    final db = await AppDatabase.instance.database;
    return await db.query('item');
  }

  // get user currency
  Future<int> getUserCurrency(int userId) async {
    final db = await AppDatabase.instance.database;
    final users = await db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (users.isEmpty) return 0;
    return users.first['currency'] as int;
  }

  // check if user owns item
  Future<bool> userOwnsItem(int userId, int itemId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'inventory',
      where: 'user_id = ? AND item_id = ?',
      whereArgs: [userId, itemId],
    );
    return result.isNotEmpty;
  }

  // purchase item if not owned
  Future<String> purchaseItem(int userId, int itemId) async {
    final db = await AppDatabase.instance.database;

    // check if user owns item selected
    if (await userOwnsItem(userId, itemId)) {
      return 'You already own this item!';
    }

    // get user and item
    final users = await db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final items = await db.query(
      'item',
      columns: ['price'],
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    if (users.isEmpty || items.isEmpty) {
      return 'User or item not found!';
    }

    // check if user has enough currency
    final userCurrency = users.first['currency'] as int;
    final itemPrice = items.first['price'] as int;
    if (userCurrency < itemPrice) return 'Not enough funds';

    // deduct price from user's currency using transaction
    await db.transaction((txn) async {
      await txn.update(
        'user',
        {'currency': userCurrency - itemPrice},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // add item to user inventory
      await txn.insert('inventory', {
        'user_id': userId,
        'item_id': itemId,
        'quantity': 1,
      });
    });
  return 'Purchase successful!';
  }

  // get lists of items owned by user
  Future<Set<int>> getUserItems(int userId) async {
    final db = await AppDatabase.instance.database;
    final inventory = await db.query(
      'inventory',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return inventory.map((item) => item['item_id'] as int).toSet();  


}
