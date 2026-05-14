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

// explain code

goal_service_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~

``GoalService`` creates and updates the user's recurring weekly step goal, and tracks their progress toward it.

.. code-block:: dart

    // insert important code

// explain code

pet_maintainance_database.dart
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

``PetStatsDatabase`` reads and writes the virtual pet's stats (hunger, hygiene, enjoyment) and the owning user's profile data.

.. code-block:: dart

    // insert important code

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

    // insert important code

// explain code

step_counter.dart
~~~~~~~~~~~~~~~~~

A lightweight singleton that accumulates raw step increments from the platform pedometer before they are saved to the database.

.. code-block:: dart

    // insert important code

// explain code
