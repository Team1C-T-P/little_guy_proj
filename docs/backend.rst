Backend
=======

Controllers
-----------

hat_state.dart
~~~~~~~~~~~~~~

``HatState`` is a singleton ``ChangeNotifier`` that tracks which hat is currently equipped on the Little Guy sprite and notifies the UI when it changes.

.. code-block:: dart

    // insert important code

// explain code

step_goal_controller.dart
~~~~~~~~~~~~~~~~~~~~~~~~~

``StepGoalController`` is a singleton ``ChangeNotifier`` that manages the user's step count, goal progress, and currency balance, bridging the UI with the underlying database services.

.. code-block:: dart

    // insert important code

// explain code

Models
------

database.dart
~~~~~~~~~~~~~

``AppDatabase`` is a singleton that manages the SQLite database connection and schema creation, with a test-only hook for injecting an in-memory database.

.. code-block:: dart

    // insert important code

// explain code

dress_database.dart
~~~~~~~~~~~~~~~~~~~

``DressDatabase`` handles querying the user's hat inventory and equipping or unequipping hats on the Little Guy.

.. code-block:: dart

    // insert important code

// explain code

goal_service_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~

``GoalService`` creates and updates the user's recurring weekly step goal, and tracks their progress toward it.

.. code-block:: dart

    // insert important code

// explain code

pet_maintainance_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``pet_maintainance_database`` reads and writes the virtual pet's stats (hunger, hygiene, enjoyment) and the owning user's profile data.

``getUserName``

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

// explain code

``getPetName``

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

// explain code

``getPetStat``

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
      }

// explain code

``getLastOnlineByUserId``

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

// explain code

``updateUserName``

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

// explain code

``updatePetName``

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

// explain code

``updatePetStat``

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

// explain code

``updateLastOnlineByUserId``

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

// explain code

``getFoodByUserId``

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

// explain code

``useFood``

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

// explain code

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

    // insert important code

// explain code

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

    // insert important code

// explain code

Utils
-----

achievement_utils.dart
~~~~~~~~~~~~~~~~~~~~~~

Provides helper functions for checking and unlocking achievements stored in the database.

.. code-block:: dart

    // insert important code

// explain code

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

// This is called whenever loading the main page of the app, it functions to calculate the hours since the user was last online, then degrade each stat by 10% for every 2 hours since the user was last online.

step_counter.dart
~~~~~~~~~~~~~~~~~

A lightweight singleton that accumulates raw step increments from the platform pedometer before they are saved to the database.

.. code-block:: dart

    // insert important code

// explain code
