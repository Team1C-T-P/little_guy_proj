// import db
import 'database.dart';

class ShopDatabase {
  // get items from database by type
  Future<List<Map<String, dynamic>>> getItemsByType(String type) async {
    final db = await AppDatabase.instance.database;
    return await db.query('item', where: 'type = ?', whereArgs: [type]);
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

    /*
    get item type
    - if hat can buy normally
    - if food, check if in inventory, if yes then increment quantity
    */
    final items = await db.query(
      'item',
      where: 'item_id = ?',
      whereArgs: [itemId],
    );

    if (items.isEmpty) return 'Item not found';

    final itemType = items.first['type'] as String;
    final itemPrice = items.first['price'] as int;

    // check if user already owns a hat
    if (itemType == 'hat' && await userOwnsItem(userId, itemId)) {
      return 'already_owned';
    }

    // get user currency
    final users = await db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final userCurrency = users.first['currency'] as int;

    // check if user has enough money
    if (userCurrency < itemPrice) return 'insufficient_funds';

    // purchase transaction
    await db.transaction((txn) async {
      // deduct money
      await txn.update(
        'user',
        {'currency': userCurrency - itemPrice},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      // add/update inventory
      final exists = await txn.query(
        'inventory',
        where: 'user_id = ? AND item_id = ?',
        whereArgs: [userId, itemId],
      );

      if (exists.isNotEmpty) {
        // food exists in inventory, increment quantity
        final currentQuantity = exists.first['quantity'] as int;
        await txn.update(
          'inventory',
          {'quantity': currentQuantity + 1},
          where: 'user_id = ? AND item_id = ?',
          whereArgs: [userId, itemId],
        );
      } else {
        // new food item - add to inventory
        await txn.insert('inventory', {
          'user_id': userId,
          'item_id': itemId,
          'quantity': 1,
        });
      }
    });

    return 'success';
  }

  // get quantity of specific item user owns
  Future<int> getItemQuantity(int userId, int itemId) async {
    final db = await AppDatabase.instance.database;
    final result = await db.query(
      'inventory',
      columns: ['quantity'],
      where: 'user_id = ? AND item_id = ?',
      whereArgs: [userId, itemId],
    );

    if (result.isEmpty) return 0;
    return result.first['quantity'] as int;
  }

  // get quantities for all user's inventory
  Future<Map<int, int>> getUserItemQuantities(int userId) async {
    final db = await AppDatabase.instance.database;
    final inventory = await db.query(
      'inventory',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    Map<int, int> quantities = {};
    for (var item in inventory) {
      quantities[item['item_id'] as int] = item['quantity'] as int;
    }

    return quantities;
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
}

/*
Need:
- Link items bought to the user
- make sure food items can be bought again after initial purchase
- increment the amount held by the user when bought again

*/
