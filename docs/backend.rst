Backend
=======

Controllers
-----------

hat_state.dart
~~~~~~~~~~~~~~

``HatState`` is a singleton ``ChangeNotifier`` that tracks which hat is currently equipped on the Little Guy sprite and notifies the UI when it changes.

.. code-block:: dart

  Future<int> _resolveLittleGuyId() async {
    if (_littleGuyId != null) return _littleGuyId!;
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'little_guy',
      columns: ['little_guy_id'],
      where: 'user_id = ?',
      whereArgs: [_userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('No little_guy row for user_id $_userId');
    }
    _littleGuyId = rows.first['little_guy_id'] as int;
    return _littleGuyId!;
  }

``_resolveLittleGuyId`` looks up the little_guy_id for the current user from the database and cachine the result in _littleGuyId and is reused, so that when it is called again, it doesn't have to use the database. It is used by equipHat, unEquipHat and loadFromDb so that hat changes are correctly applied to the little guy

.. code-block:: dart

  // load hat from db and notify listeners, which is the little guy.dart
  Future<void> loadFromDb() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    final hat = await dressDb.getEquippedHat(await _resolveLittleGuyId());
    equippedHatPath = hat?['image_path'] as String?;
    notifyListeners();
  }

``loadFromDb`` queries the database to fetch the currently equipped hat using the getEquippedHat function in dress_database.dart. On startup its called to restore the gat the user equipped in the last session.

.. code-block:: dart

  // equip hat
  Future<void> equipHat(int itemId, String imagePath) async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    await dressDb.equipHat(await _resolveLittleGuyId(), itemId);
    equippedHatPath = imagePath;
    notifyListeners();
  }

``equipHat`` saves the chosen hat to the database and updates the equippedHatPath to the new hat path. It then notifies little_guy.dart to re-render the little guy with the new equipped hat.

.. code-block:: dart

  // unequip hat
  Future<void> unequipHat() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    await dressDb.unequipHat(await _resolveLittleGuyId());
    equippedHatPath = null;
    notifyListeners();
  }

``unequipHat`` removes the equipped hat from the database, and also clears the cached hat path. It then notifies the little_guy.dart to re-render the little guy without the hat.

step_goal_controller.dart
~~~~~~~~~~~~~~~~~~~~~~~~~

``StepGoalController`` manages the user's step count, goal progress, and currency balance when reaching a goal, it is called in the main page for the UI.

.. code-block:: dart

    Future<void> loadData() async {
    try {
      if (goalService == null || stepService == null) await init();
      currentSteps = await goalService!.getCurrentSteps(userId);
      stepGoal = await loadGoal();
      totalSteps = await loadTotalSteps();
      goalReached = false;
      notifyListeners();
    } catch (e) {
      print('Error refreshing stats: $e');
    }
  }
// This is the initiial loading of data when main page is clicked on to, it is also used when a goal has been reached and the UI needs to be refreshed with the new values. The function first checks if the tables used for goals and steps exist, causing it to be initiated if not. The variables are assigned by calling from other files or this class. An error is thrown if there is an issue that occurs.

.. code-block:: dart

  // Load goal from DB
  Future<int> loadGoal() async {
    goalReached = false;
    final goal = await goalService!.getDailyStepGoal(userId);
    return goal ?? 250;
  }
// This function is called when the goal value needs to be refreshed, it defines goalReached boolean as false to start or restart a goal, gets the target goal from goal service and returns a value (250 if it is new)

.. code-block:: dart

  // Load total steps from DB
  Future<int> loadTotalSteps() async {
    final summary = await stepService!.getAccountSummary(userId);
    return summary.totalSteps;
  }
// This function loads the total steps a user has made into a local variable from stepService returning its value

.. code-block:: dart

  // Update the user's daily goal
  Future<void> updateGoal(int newGoal) async {
    if (newGoal <= 0) {
      throw Exception('Invalid goal value');
    }
    await goalService!.setDailyStepGoal(userId, newGoal);
    stepGoal = newGoal;
    goalReached = false;
    notifyListeners();
  }

.. code-block:: dart

  Future<void> refreshSteps() async {
    try {
      // Load from both services
      final summary = await stepService!.getAccountSummary(userId);
      totalSteps = summary.totalSteps;
      currency = summary.currency;
      leftoverSteps = summary.unconvertedSteps;

      currentSteps = await goalService!.getCurrentSteps(userId);
      stepGoal = await loadGoal();

      if (currentSteps >= stepGoal && stepGoal > 0 && !goalReached) {
        currency = await goalService!.resetGoal(userId);
        currentSteps = 0;
        stepGoal = 250;
        goalReached = true;
      }


Models
------

database.dart
~~~~~~~~~~~~~

``AppDatabase`` is a singleton that manages the SQLite database connection and schema creation, with a test-only hook for injecting an in-memory database. Most of this file just contains create tables statements with a few statements that will populate the tables upon app initialization

.. code-block:: dart

  Future<void> _autoAddItemsFromAssets() async {
    final db = await database;

    // Check if items already exist
    final existingItems = await db.query('item', limit: 1);
    if (existingItems.isNotEmpty) return;

    // Scan for all images in hats and food
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final hatImages = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/hats/') &&
              (path.endsWith('.png') || path.endsWith('.jpg')),
        )
        .toList();

    final foodImages = manifest
        .listAssets()
        .where(
          (path) =>
              path.startsWith('assets/images/food/') &&
              (path.endsWith('.png') || path.endsWith('.jpg')),
        )
        .toList();

This function helps to automatically add hats and food to the database without having to manually add the image paths and names of each item, using the file path to the item and adding them to a list. 

.. code-block:: dart

    // Add food
    for (var imagePath in foodImages) {
      final fileName = imagePath.split('/').last.split('.').first.toLowerCase();
      final itemName = _formatItemName(fileName);
      final price = foodPrices[fileName] ?? 100; // Default 100 for food

      await db.insert('item', {
        'item_name': itemName,
        'image_path': imagePath,
        'quantity': 1,
        'price': price,
        'type': 'food',
      });
    }

This section creates the item names of the food using the fileName and then inserts that into the database without, and providing the standard food price

.. code-block:: dart

  String _formatItemName(String fileName) {
    // Convert filename to nice name
    final formatted = fileName
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}')
        .trim();

    if (formatted.isEmpty) return fileName;

    return formatted[0].toUpperCase() + formatted.substring(1);
  }

This function takes the filename provided in the previous section of code and formats them properly and returns it to the function where it was called, which was in ``_autoAddItemsFromAssets()``

dress_database.dart
~~~~~~~~~~~~~~~~~~~

``DressDatabase`` handles querying the user's hat inventory and equipping or unequipping hats on the Little Guy.

.. code-block:: dart

    Future<List<Map<String, dynamic>>> getHatsOwnedByUser(int userId) async {
    return await _db.rawQuery(
      '''
      SELECT
        item.item_id,
        item.item_name,
        item.image_path,
        item.price,
        item.type
      FROM inventory
      JOIN item on inventory.item_id = item.item_id
      WHERE inventory.user_id = ?
      AND item.type = 'hat'
  ''',
      [userId],
    );
  }

``getHatsOwnedByUser`` uses the userId which is 1, to return information on the hat, such as its name, id, image path and type so that when the dress_view.dart is intialised, those variables are saved to a Map, containing that information to be used when other functions are called. THis is then used to populate the grid where the user can select a hat to wear

.. code-block:: dart

    Future<void> equipHat(int littleGuyId, int itemId) async {
    // remove currently equipped hat
    await _db.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );

    // equip new hat
    await _db.insert('little_guy_wearing', {
      'little_guy_id': littleGuyId,
      'item_id': itemId,
    });
  }

``equipHat`` equips a hat to the little guy by first deleting the little_guy_id from the little_guy_wearing table, this is done because there can be only 1 pet per person, hence the choice to delete the record. Then to equip the hat, the function performs an insertion query to the little_guy_wearing table with the item_id, which is the hat. The itemId is provided from the dress_view.dart using the Map variable called hat, which has item_id stored to being called when the user taps a hat in the dress_view.dart

.. code-block:: dart

  // unequip hat to the db
  Future<void> unequipHat(int littleGuyId) async {
    await _db.delete(
      'little_guy_wearing',
      where: 'little_guy_id = ?',
      whereArgs: [littleGuyId],
    );
  }

``unequipHat`` takes the littleGuyId provided by the Map variable hat when called in the dress_view.dart when the user taps a selected hat and queries the database to delete the record matching with the little_guy_id, removing the record of the hat being equipped to the little guy. 

.. code_block:: dart

  // get equipped hat from db
  Future<Map<String, dynamic>?> getEquippedHat(int littleGuyId) async {
    final result = await _db.rawQuery(
      '''
    SELECT item.item_id, item.image_path
    FROM little_guy_wearing
    JOIN item ON item.item_id = little_guy_wearing.item_id
    WHERE little_guy_wearing.little_guy_id = ?
    LIMIT 1
  ''',
      [littleGuyId],
    );

    if (result.isEmpty) return null;
    return result.first;
  }

``getEquippedHat`` returns the hat being worn by the little guy for use in the hat_state.dart. The function performs a select query on the database using the littleGuyId provided in hat_state.dart and returns the item_id and image_path from little_guy_wearing, so that the hat_state can use the hat selected and display the selected hat onto the UI.

goal_service_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~

``GoalService`` creates and updates the user's recurring weekly step goal, and tracks their progress toward it.

.. code-block:: dart

    // insert important code

// explain code

pet_maintainance_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``pet_maintainance_database`` reads and writes the virtual pet's stats (hunger, hygiene, enjoyment) and the owning user's profile data.

``getUserName`` returns the name of the user from a given user ID

.. code-block:: dart

    Future<String?> getUserName(int userId) async {
        final result = await _db.query(
          'user',
          columns: ['user_name'],
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (result.isEmpty) throw Exception('Failed to get user name: User not found');
        return result.first['user_name'] as String;
    }

``getPetName`` returns the name of the user's pet from a given user ID

.. code-block:: dart

    Future<String?> getPetName(int userId) async {
        final result = await _db.query(
          'little_guy',
          columns: ['little_guy_name'],
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (result.isEmpty) throw Exception('Failed to get pet name: Pet not found');
        return result.first['little_guy_name'] as String;
      }

``getPetStat`` returns the value for a given statistic which is namely used for updating and degrading the pets stats 

.. code-block:: dart

    Future<double> getPetStat(int petId, String stat) async {
        const allowedStats = {'hunger_level', 'hygiene_level', 'enjoyment_level'};

        if (!allowedStats.contains(stat)) {
          throw Exception('Stat does not exist');
        }

        final stats = await _db.query(
          'little_guy',
          columns: [stat],
          where: 'little_guy_id = ?',
          whereArgs: [petId],
        );
        // Throw on missing pet to match the rest of this class (getUserName,
        // getPetName, getLastOnlineByUserId all throw). Returning 0 silently
        // masked the missing-row case at every call site.
        if (stats.isEmpty) {
          throw Exception('Failed to get pet stat: Pet not found');
        }
        return (stats.first[stat] as int).toDouble() / 100;
      )

``getLastOnlineByUserId`` Returns the ISO date which was the last online of a given user

.. code-block:: dart

    Future<String?> getLastOnlineByUserId(int userId) async {
        final result = await _db.query(
          'user',
          columns: ['last_online'],
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (result.isEmpty) {
          throw Exception('Failed to get last online time: User not found');
        };
        return result.first['last_online'] as String;
      }

``updateUserName`` Updates the user's name by an id, unless it is empty, or user does not exist

.. code-block:: dart

    Future<void> updateUserName(int userId, String newName) async {

        // if newName is empty, keep the old name. (?)
        if (newName.isEmpty) return;
        final result = await _db.update(
          'user',
          {'user_name': newName},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (result == 0) {
          throw Exception('Failed to update user name: User not found');
        }
      }

``updatePetName`` Updates the user's pet' name by an id, unless it is empty, or user does not exist

.. code-block:: dart

    Future<void> updatePetName(int userId, String newName) async {

        // if newName is empty, keep the old name. (?)
        if (newName.isEmpty) return; 
        final result = await _db.update(
          'little_guy',
          {'little_guy_name': newName},
          where: 'user_id = ?',
          whereArgs: [userId],
        );
        if (result == 0) {
          throw Exception('Failed to update pet name: Pet not found');
        }
      }

``updatePetStat`` Updates a given stat for a given pet, ensuring that the entered value is between 0.0, and 1.0

.. code-block:: dart

    Future<void> updatePetStat(int petId, String stat, double value) async {
        final roundedValue = value.clamp(0.0, 1.0);

        final result = await _db.update(
          'little_guy',
          {stat: (roundedValue * 100).toInt()},
          where: 'little_guy_id = ?',
          whereArgs: [petId],
        );

        if (result == 0) {
          // If no rows were updated, throw an error
          throw Exception('Failed to update pet stat: One or more argument is invalid');
        }
      }


``updateLastOnlineByUserId`` Updates a given user's last online ISO date, ensuring that it is a valid iso date

.. code-block:: dart

    Future<void> updateLastOnlineByUserId(int userId, String isoDate) async {

        try {
          DateTime.parse(isoDate);
        } catch (e) {
          throw Exception('Failed to update last online time: Invalid ISO date format');
        }

        final result = await _db.update(
          'user',
          {'last_online': isoDate},
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        if (result == 0) {
          throw Exception('Failed to update last online time: User not found');
        }
      }

``getFoodByUserId`` returns a list of food items tthat the user owns, along  wth their quantity, and the image path for said food.

.. code-block:: dart

    Future<List<Map<String, dynamic>>> getFoodByUserId(int userId) async {
        final food = await _db.rawQuery(
          '''
          SELECT it.item_id, inv.quantity, it.image_path
          FROM inventory inv
          JOIN item it ON inv.item_id = it.item_id
          WHERE inv.user_id = ? AND it.type = ?
        ''',
          [userId, 'food'],
        );
        return food;
      }

``useFood`` decreases the quantity of a given food type for a given user by 1

.. code-block:: dart

    Future<void> useFood(int foodId, int userId) async {
        // First check if the item exists for this user
        final itemExists = await _db.rawQuery(
          '''
          SELECT item_id FROM inventory
          WHERE user_id = ? AND item_id = ?
        ''',
          [userId, foodId],
        );
        
        if (itemExists.isEmpty) {
          throw Exception('Failed to use food: User or item not found');
        }
    
        // Decrease quantity in inventory if available
        await _db.rawUpdate(
          '''
          UPDATE inventory
          SET quantity = quantity - 1
          WHERE user_id = ? AND item_id = ? AND quantity > 0
        ''',
          [userId, foodId],
        );
      }

route_service.dart
~~~~~~~~~~~~~~~~~~

``RouteService`` saves, retrieves, and deletes GPS walking routes recorded on the Map screen.

.. code-block:: dart

    // insert important code

// explain code

shop_database.dart
~~~~~~~~~~~~~~~~~~

``ShopDatabase`` manages item browsing, currency checks, and purchase transactions.

.. code-block:: dart

  Future<List<Map<String, dynamic>>> getItemsByType(String type) async {
    return await _db.query('item', where: 'type = ?', whereArgs: [type]);
  }

``getItemsByType`` queries the database for all the items in the database, which are food and hats, returining a list of items with the type 'food' or 'hat. This function is called in the shop_view.dart when the user switches between buying food and clothes to load the relevant items. 

.. code-block::dart

  // get user currency
  Future<int> getUserCurrency(int userId) async {
    final users = await _db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (users.isEmpty) return 0;
    return users.first['currency'] as int;
  }

``getUserCurrency`` queries the database using the userId provided when called from the shop_view.dart. This returns the total amount of currency as an int, which the user has from the database. The use for this is so that when purchasing items, the user can see if they have enough money before buying an item

.. code_block:: dart

  // check if user owns item
  Future<bool> userOwnsItem(int userId, int itemId) async {
    final result = await _db.query(
      'inventory',
      where: 'user_id = ? AND item_id = ?',
      whereArgs: [userId, itemId],
    );
    return result.isNotEmpty;
  }

``userOwnsItems`` checks for items owned by the user. This performs a select query on the inventory table, where the userId and an itemId and returns a .isNotEmpty result to show that there is an item that matches that item_id. This is used when purchasing a hat and it checks if they already own that hat, to prevent them from buying two of the same hat

.. code-block:: dart

  // purchase item if not owned
  Future<String> purchaseItem(int userId, int itemId) async {
    /*
    get item type
    - if hat can buy normally
    - if food, check if in inventory, if yes then increment quantity
    */
    final items = await _db.query(
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
    final users = await _db.query(
      'user',
      columns: ['currency'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    final userCurrency = users.first['currency'] as int;

    // check if user has enough money
    if (userCurrency < itemPrice) return 'insufficient_funds';

    // purchase transaction
    await _db.transaction((txn) async {
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

``purchaseItem`` allows a user to purchase an item, whether it is a hat or food. It takes the itemId, which is taken from the shop_view.dart when the function is called, and queires the database to check if the item can be found and returns an items variable. If the item can be found, the item type and currency are saved into separate variables, itemType and itemPrice. The function then checks if the user already owns an item using the userOwnsItem function defined earlier, and if they do it returns 'already_owned'. The function then retrieves the userCurrency using the userId, where it then compares the itemPrice to the userCurrency, and returns 'insufficient_funds' if the userCurrency is lower than the itemPrice. The function then performs a transaction, where the itemPrice is deducted from the user table. A query is then performed to check if a food item is in the user's inventory. If the food is in the inventory, a transaction is executed to increment the quantity in the inventory table using the userId and itemId, otherwise if there isn't any food, then the food item is inserted into the table with the userId, item_id and a quantity of 1. The funciton returns a 'success' message so that the UI can confirm that the item was purchased

.. code-block:: dart

  // get quantities for all user's inventory
  Future<Map<int, int>> getUserItemQuantities(int userId) async {
    final inventory = await _db.query(
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

``getUserItemQuantities`` returns a Map of quantities, that contains the item_id of an item and its quantity. It does this by querying the inventory table for items using the userId. If the user doesn't own anything, it will return an empty map. This map is used in shop_view.dart in _loadShopData and storing it in _itemQuantities.

.. code-block:: dart

  Future<int> getTotalShopItems() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as count FROM item');
    return (result.first['count'] as int);
  }

``getTotalShopItems`` counts and returns the total number of items in the shop's item table as an integer, this function is mainly used for testing.


step_points_service.dart
~~~~~~~~~~~~~~~~~~~~~~~~

``StepPointsService`` is a core backend service responsible for converting real-world step data into in-game currency, tracking raw step accumulation, and maintaining a persistent step ledger per user.

It also ensures that step progress contributes to the active weekly goal and keeps the user’s currency balance synchronised with physical activity.

This service operates directly on the SQLite database and uses transactions to guarantee consistency when updating multiple tables.

---

StepAccountSummary
^^^^^^^^^^^^^^^^^^

``StepAccountSummary`` is a data model representing the user’s aggregated step and currency state, including total steps, unconverted steps, and current currency balance.

.. code-block:: dart

    const StepAccountSummary({
      required this.totalSteps,
      required this.unconvertedSteps,
      required this.currency,
    });

This model is used to return a snapshot of the user's step ledger and currency state.
It is primarily used for profile dashboards and UI summaries.

---

StepRecordResult
^^^^^^^^^^^^^^^^

``StepRecordResult`` represents the result of processing a batch of recorded steps, including currency conversion and updated ledger values.

.. code-block:: dart

    const StepRecordResult({
      required this.recordedSteps,
      required this.pointsAwarded,
      required this.updatedCurrency,
      required this.totalSteps,
      required this.unconvertedSteps,
    });

This model is returned after steps are processed.
It provides both raw input (recordedSteps) and computed outputs (currency conversion + ledger updates).

---

StepPointsService Constructor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Initialises the service with a SQLite database reference and a configurable conversion rate.

.. code-block:: dart

    StepPointsService(this._db, {this.stepsPerPoint = 100});

This constructor sets up the service with a database connection.
`stepsPerPoint` defines how many steps are required to earn 1 currency point.

---

awardBonusPoints
^^^^^^^^^^^^^^^^

``awardBonusPoints`` directly adds currency to a user without step conversion, typically used for rewards or administrative grants.

.. code-block:: dart

    Future<int> awardBonusPoints({
      required int userId,
      required int points,
    }) async {
      if (points <= 0) {
        throw ArgumentError.value(
          points,
          'points',
          'Points must be greater than 0',
        );
      }

      return _db.transaction((txn) async {
        final userRows = await txn.query(
          'user',
          columns: ['currency'],
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );

        if (userRows.isEmpty) {
          throw StateError('User with id $userId does not exist');
        }

        final currentCurrency = userRows.first['currency'] as int;
        final nextCurrency = currentCurrency + points;

        await txn.update(
          'user',
          {
            'currency': nextCurrency,
            'last_online': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        return nextCurrency;
      });
    }

This function safely updates the user's currency balance inside a transaction.
It checks input, retrieves the current balance, applies the bonus, and persists the update.
It also updates `last_online` to reflect activity.

---

_ensureStepLedgerTable
^^^^^^^^^^^^^^^^^^^^^^

Ensures that the step ledger table exists in the database.

.. code-block:: dart

    Future<void> _ensureStepLedgerTable() async {
      await _db.execute('''
        CREATE TABLE IF NOT EXISTS step_ledger (
          user_id INTEGER PRIMARY KEY,
          total_steps INTEGER NOT NULL DEFAULT 0 CHECK (total_steps >= 0),
          unconverted_steps INTEGER NOT NULL DEFAULT 0 CHECK (unconverted_steps >= 0),
          updated_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES user(user_id) ON DELETE CASCADE
        );
      ''');
    }

This function guarantees the existence of the step_ledger table.
It is safe to call multiple times.

---

_ensureLedgerRow
^^^^^^^^^^^^^^^^

Ensures a ledger row exists for a given user.

.. code-block:: dart

    Future<void> _ensureLedgerRow(int userId) async {
      final rows = await _db.query(
        'step_ledger',
        columns: ['user_id'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (rows.isEmpty) {
        await _db.insert('step_ledger', {
          'user_id': userId,
          'total_steps': 0,
          'unconverted_steps': 0,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    }

This function makes sure each user has a corresponding ledger row.
It prevents null ledger states before step processing begins.

---

recordSteps
^^^^^^^^^^^

``recordSteps`` processes incoming step data, converts steps into currency, updates the ledger, and progresses active user goals.

.. code-block:: dart

    Future<StepRecordResult> recordSteps({
      required int userId,
      required int steps,
    }) async {
      if (steps <= 0) {
        throw ArgumentError.value(steps, 'steps', 'Steps must be greater than 0');
      }

      await _ensureStepLedgerTable();
      await _ensureLedgerRow(userId);

      return _db.transaction((txn) async {
        final userRows = await txn.query(
          'user',
          columns: ['currency'],
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );

        if (userRows.isEmpty) {
          throw StateError('User with id $userId does not exist');
        }

        final ledgerRows = await txn.query(
          'step_ledger',
          columns: ['total_steps', 'unconverted_steps'],
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 1,
        );

        if (ledgerRows.isEmpty) {
          throw StateError('Step ledger missing for user id $userId');
        }

        final currentCurrency = userRows.first['currency'] as int;
        final currentTotalSteps = ledgerRows.first['total_steps'] as int;
        final currentUnconverted = ledgerRows.first['unconverted_steps'] as int;

        final combinedUnconverted = currentUnconverted + steps;
        final pointsAwarded = combinedUnconverted ~/ stepsPerPoint;
        final nextUnconverted = combinedUnconverted % stepsPerPoint;
        final nextCurrency = currentCurrency + pointsAwarded;
        final nextTotalSteps = currentTotalSteps + steps;

        await txn.update(
          'step_ledger',
          {
            'total_steps': nextTotalSteps,
            'unconverted_steps': nextUnconverted,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.update(
          'user',
          {
            'currency': nextCurrency,
            'last_online': DateTime.now().toUtc().toIso8601String(),
          },
          where: 'user_id = ?',
          whereArgs: [userId],
        );

        await txn.rawUpdate(
          '''
          UPDATE user_goal 
          SET current_progress = current_progress + ? 
          WHERE user_id = ? 
          AND goal_id = (
            SELECT goal_id FROM user_goal 
            WHERE user_id = ? 
            ORDER BY goal_id DESC 
            LIMIT 1
          )
          ''',
          [steps, userId, userId],
        );

        return StepRecordResult(
          recordedSteps: steps,
          pointsAwarded: pointsAwarded,
          updatedCurrency: nextCurrency,
          totalSteps: nextTotalSteps,
          unconvertedSteps: nextUnconverted,
        );
      });
    }

This function is the core pipeline of the service.
It converts raw steps into currency, updates the ledger, updates the user balance,
and increments the latest user goal.

---

getAccountSummary
^^^^^^^^^^^^^^^^^

``getAccountSummary`` retrieves the user’s current step ledger state and currency balance.

.. code-block:: dart

    Future<StepAccountSummary> getAccountSummary(int userId) async {
      await _ensureStepLedgerTable();
      await _ensureLedgerRow(userId);

      final userRows = await _db.query(
        'user',
        columns: ['currency'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      final ledgerRows = await _db.query(
        'step_ledger',
        columns: ['total_steps', 'unconverted_steps'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      return StepAccountSummary(
        totalSteps: ledgerRows.first['total_steps'] as int,
        unconvertedSteps: ledgerRows.first['unconverted_steps'] as int,
        currency: userRows.first['currency'] as int,
      );
    }

This function provides a snapshot of the user's progress.
It is used to display steps, progress, and currency balance.

---

Services
--------

level_service.dart
~~~~~~~~~~~~~~~~~~

``LevelService`` manages the pet's XP and level progression, handling level-ups automatically when XP reaches the threshold.

.. code-block:: dart

    Future<Map<String, int>> getLevelAndXp(int userId) async {
      final result = await db.query(
        'little_guy',
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (result.isEmpty) return {'level': 1, 'xp': 0};
      return {
        'level': result.first['level'] as int,
        'xp': result.first['xp'] as int,
      };
    }

Here, the database is queried to see what the users current level is, storing it inside result. If the result is empty, the level is returned at 1 with no xp. It it has contents it'll set both as what was given by the db.

.. code-block:: dart

  Future<Map<String, int>> addXp(int userId, int gainedXp) async {
    var data = await getLevelAndXp(userId);
    int level = data['level']!;
    int xp = data['xp']! + gainedXp;

    bool leveledUp = false;
    while (xp >= 100) {
      level++;
      xp -= 100;
      leveledUp = true;
    }

    // Update database
    await db.update(
      'little_guy',
      {'level': level, 'xp': xp},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return {'level': level, 'xp': xp, 'leveledUp': leveledUp ? 1 : 0};

This part gets called throughout the code, when a user does something that gains xp. It also deals with level ups, doing so when xp is over or equals to 100.

Utils
-----

achievement_utils.dart
~~~~~~~~~~~~~~~~~~~~~~

Provides helper functions for checking achivements. This only does so for the Trail Blazer achivement, since its the only one needed outside profile page (i can't import the entire page, since it would be inefficent)

.. code-block:: dart

  Future<void> checkAndUnlockTrailBlazer(BuildContext context, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('trailBlazerClaimed') ?? false;
    if (alreadyClaimed) return;

    final db = await AppDatabase.instance.database;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM route WHERE user_id = ?', [
            userId,
          ]),
        ) ??
        0;

    if (count >= 1) {
      await prefs.setBool('trailBlazerClaimed', true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Trail Blazer achievement unlocked! You saved your first route!',
            ),
          ),
        );
      }
    }
  }

This basically works like the other achivements. Checks if something is true, if it is, trailBlazerClaimed is true.

last_online_updater.dart
~~~~~~~~~~~~~~~~~~~~~~~~

Updates the user's ``last_online`` timestamp in the database whenever the app is opened or closed.

.. code-block:: dart

    // insert important code

// explain code

location_service.dart
~~~~~~~~~~~~~~~~~~~~~

Wraps the platform location API to provide a stream of GPS coordinates used by the Map screen's route recorder.

.. code-block:: dart

    // insert important code

// explain code

stat_degradation_service.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Calculates how much the pet's stats should decrease based on the time elapsed since the user was last online.

.. code-block:: dart

    Future<void> degradeStats() async {
    double hunger = await petStatsDB.getPetStat(petID, 'hunger_level');
    double enjoyment = await petStatsDB.getPetStat(petID, 'enjoyment_level');
    double hygiene = await petStatsDB.getPetStat(petID, 'hygiene_level');
    String? lastOnlineIso = await petStatsDB.getLastOnlineByUserId(userID);
    lastOnlineIso ??= DateTime.now().toUtc().toIso8601String();

    DateTime lastOnline = DateTime.parse(lastOnlineIso);
    DateTime now = DateTime.now().toUtc();

    if (lastOnline.isAfter(now)) {
      throw Exception(
        'Failed to degrade stats: Last online time is in the future',
      );
    }

    int hoursSinceLastOnline = now.difference(lastOnline).inHours;
    double decayBy = 0.1 * (hoursSinceLastOnline / 2);

    hunger = hunger - decayBy;
    enjoyment = enjoyment - decayBy;
    hygiene = hygiene - decayBy;

    await petStatsDB.updatePetStat(petID, 'hunger_level', hunger);
    await petStatsDB.updatePetStat(petID, 'enjoyment_level', enjoyment);
    await petStatsDB.updatePetStat(petID, 'hygiene_level', hygiene);
    await petStatsDB.updateLastOnlineByUserId(userID, now.toIso8601String());
  }

This is called whenever loading the main page of the app, it functions to calculate the hours since the user was last online, then degrade each stat by 10% for every 2 hours since the user was last online.

step_counter.dart
~~~~~~~~~~~~~~~~~

A lightweight singleton that accumulates raw step increments from the platform pedometer before they are saved to the database.

.. code-block:: dart

    // insert important code

// explain code
