API Reference
=============

This page documents the public classes and methods found in ``lib/``.

.. contents:: Modules
   :local:
   :depth: 2

----

Models
------

AppDatabase
~~~~~~~~~~~

**File:** ``lib/models/database.dart``

Singleton wrapper around the ``sqflite`` database. All other database classes accept an injected ``Database`` instance so they can be tested with an in-memory database.

.. code-block:: dart

   // Production usage
   final db = await AppDatabase.instance.database;

   // Test usage (swap in an in-memory DB before any view code runs)
   AppDatabase.setTestDatabase(testDb);

**Methods**

``Future<Database> get database``
   Returns the singleton ``Database``, initialising it on first access. The database file is named ``little_guy.db`` and stored in the platform's default database directory.

``static void setTestDatabase(Database? db)``
   Test-only seam. Pass an in-memory database to isolate tests from the on-disk file. Pass ``null`` in ``tearDown`` to detach it.

----

PetStatsDatabase
~~~~~~~~~~~~~~~~

**File:** ``lib/models/pet_maintainance_database.dart``

Reads and writes the virtual pet's stats and the owning user's details.

**Constructor**

.. code-block:: dart

   PetStatsDatabase(Database db)

**Methods**

``Future<String?> getUserName(int userId)``
   Returns the user's display name. Throws if the user does not exist.

``Future<String?> getPetName(int userId)``
   Returns the pet's name. Throws if no pet is found for ``userId``.

``Future<double> getPetStat(int petId, String stat)``
   Returns a normalised stat value in the range ``[0.0, 1.0]``. Allowed values for ``stat``: ``hunger_level``, ``hygiene_level``, ``enjoyment_level``. Values are stored as integers (0–100) and divided by 100 on read.

``Future<String?> getLastOnlineByUserId(int userId)``
   Returns the ISO-8601 timestamp of when the user last opened the app. Used by ``StatDegradationService`` to calculate offline stat loss.

----

ShopDatabase
~~~~~~~~~~~~

**File:** ``lib/models/shop_database.dart``

Handles item browsing, currency checks, and purchase transactions.

**Constructor**

.. code-block:: dart

   ShopDatabase(Database db)

**Methods**

``Future<List<Map<String, dynamic>>> getItemsByType(String type)``
   Returns all shop items matching the given ``type`` (e.g. ``'hat'``, ``'food'``).

``Future<int> getUserCurrency(int userId)``
   Returns the user's current currency balance (stored in pence/pennies — divide by 100 to display).

``Future<bool> userOwnsItem(int userId, int itemId)``
   Returns ``true`` if the item is already in the user's inventory.

``Future<String> purchaseItem(int userId, int itemId)``
   Attempts to purchase an item. Returns one of:

   - ``'success'`` — purchase completed.
   - ``'already_owned'`` — the user already owns this hat.
   - ``'insufficient_funds'`` — not enough currency.
   - ``'Item not found'`` — the item ID does not exist.

   Food items already in inventory have their quantity incremented rather than creating a duplicate row.

``Future<int> getItemQuantity(int userId, int itemId)``
   Returns how many of a specific item the user holds.

``Future<Map<int, int>> getUserItemQuantities(int userId)``
   Returns a map of ``{itemId: quantity}`` for all items in the user's inventory.

``Future<Set<int>> getUserItems(int userId)``
   Returns the set of item IDs owned by the user.

``Future<int> getTotalShopItems()``
   Returns the total number of items in the shop (used for testing completeness).

----

DressDatabase
~~~~~~~~~~~~~

**File:** ``lib/models/dress_database.dart``

Manages hat equipping and inventory queries for the Dress screen.

**Constructor**

.. code-block:: dart

   DressDatabase(Database db)

**Methods**

``Future<List<Map<String, dynamic>>> getHatsOwnedByUser(int userId)``
   Returns all hats in the user's inventory with ``item_id``, ``item_name``, ``image_path``, ``price``, and ``type``.

``Future<void> equipHat(int littleGuyId, int itemId)``
   Replaces any currently equipped hat with the specified item. The ``little_guy_wearing`` table holds at most one row per pet.

``Future<void> unequipHat(int littleGuyId)``
   Removes the currently equipped hat, leaving the pet bare-headed.

``Future<Map<String, dynamic>?> getEquippedHat(int littleGuyId)``
   Returns ``{item_id, image_path}`` for the equipped hat, or ``null`` if none is equipped.

----

StepPointsService
~~~~~~~~~~~~~~~~~

**File:** ``lib/models/step_points_service.dart``

Records steps and converts them to in-game currency. Uses a ``step_ledger`` table to track total and unconverted steps independently of the ``user.currency`` column.

**Constructor**

.. code-block:: dart

   StepPointsService(Database db, {int stepsPerPoint = 100})

``stepsPerPoint`` controls the conversion rate. Default: **100 steps = 1 coin**.

**Data classes**

``StepAccountSummary``
   Holds ``totalSteps``, ``unconvertedSteps``, and ``currency`` for a user.

``StepRecordResult``
   Returned by ``recordSteps``; includes ``recordedSteps``, ``pointsAwarded``, ``updatedCurrency``, ``totalSteps``, and ``unconvertedSteps``.

**Methods**

``Future<StepRecordResult> recordSteps({required int userId, required int steps})``
   Adds ``steps`` to the ledger, converts whole batches of ``stepsPerPoint`` into currency, and updates the active user goal's progress. Steps must be > 0.

``Future<int> awardBonusPoints({required int userId, required int points})``
   Directly adds ``points`` to the user's currency balance (used for goal rewards). Points must be > 0.

``Future<StepAccountSummary> getAccountSummary(int userId)``
   Returns the current ledger summary for the user.

----

GoalService
~~~~~~~~~~~

**File:** ``lib/models/goal_service_database.dart``

Creates and updates the user's recurring weekly step goal.

**Constructor**

.. code-block:: dart

   GoalService(Database db)

**Methods**

``Future<int> setDailyStepGoal(int userId, int stepGoal)``
   Creates a new goal row (and associated ``user_goal`` row) if one doesn't exist, or updates the ``target_goal`` of the existing one. Returns the ``goal_id``.

``Future<int?> getDailyStepGoal(int userId)``
   Returns the user's current daily step target, or ``null`` if none has been set.

``Future<int> getCurrentSteps(int userId)``
   Returns the user's current progress toward the goal this week.

----

RouteService
~~~~~~~~~~~~

**File:** ``lib/models/route_service.dart``

Saves and retrieves GPS walking routes recorded on the Map screen.

**Constructor**

.. code-block:: dart

   RouteService({Database? db})

Pass a ``db`` for testing; omit to use the production singleton.

**Methods**

``Future<int> saveRoute(int userId, String name, List<LatLng> path)``
   Serialises the route path to JSON and persists it. Returns the new ``route_id``.

``Future<List<Map<String, dynamic>>> getSavedRoutes(int userId)``
   Returns all saved routes for the user. Each map contains ``route_id``, ``route_name``, and ``route_path`` (a ``List<LatLng>``).

``Future<void> deleteRoute(int routeId)``
   Permanently removes a route.

----

Services
--------

LevelService
~~~~~~~~~~~~

**File:** ``lib/services/level_service.dart``

Manages the pet's XP and level progression. Every 100 XP triggers a level-up.

**Constructor**

.. code-block:: dart

   LevelService(Database db)

**Methods**

``Future<Map<String, int>> getLevelAndXp(int userId)``
   Returns ``{'level': int, 'xp': int}`` for the user's pet.

``Future<Map<String, int>> addXp(int userId, int gainedXp)``
   Adds XP, handles one or more level-ups, persists to the database, and returns ``{'level', 'xp', 'leveledUp'}`` where ``leveledUp`` is ``1`` if a level-up occurred.

``Future<void> setLevelAndXp(int userId, int level, int xp)``
   Directly sets level and XP. Intended for admin use or tests.

----

Controllers
-----------

StepGoalController
~~~~~~~~~~~~~~~~~~

**File:** ``lib/controller/step_goal_controller.dart``

A ``ChangeNotifier`` singleton that bridges the UI with ``GoalService`` and ``StepPointsService``. Widgets listen to this controller to reactively update step and goal displays.

**Singleton access**

.. code-block:: dart

   final controller = StepGoalController();

**State properties**

- ``int totalSteps`` — lifetime step count from the ledger.
- ``int currentSteps`` — steps recorded this goal period.
- ``int stepGoal`` — current daily goal (default: 250).
- ``bool goalReached`` — ``true`` once the goal is met.
- ``int currency`` — cached currency balance.

**Methods**

``Future<void> init({Database? testDb})``
   Initialises ``GoalService`` and ``StepPointsService``. Pass ``testDb`` to inject a test database.

``Future<void> loadData()``
   Refreshes all state properties from the database and calls ``notifyListeners()``.

``Future<void> updateGoal(int newGoal)``
   Persists a new step goal. Throws if ``newGoal ≤ 0``.

----

HatState
~~~~~~~~~

**File:** ``lib/controller/hat_state.dart``

A ``ChangeNotifier`` singleton that tracks which hat (if any) is currently equipped on the Little Guy sprite.

**Singleton access**

.. code-block:: dart

   final hat = HatState.instance;

**State properties**

- ``String? equippedHatPath`` — asset path of the equipped hat image, or ``null``.

**Methods**

``Future<void> loadFromDb()``
   Loads the equipped hat from the database and notifies listeners (triggers re-render of the sprite).

``Future<void> equipHat(int itemId, String imagePath)``
   Persists the new hat to the database and updates ``equippedHatPath``.

``Future<void> unequipHat()``
   Removes the hat from the database and sets ``equippedHatPath`` to ``null``.

----

Utilities
---------

StepCounter
~~~~~~~~~~~

**File:** ``lib/utils/step_counter.dart``

Lightweight singleton that accumulates raw step increments from the platform pedometer before they are flushed to ``StepPointsService``.

.. code-block:: dart

   StepCounter().addStep();      // increment
   int steps = StepCounter().stepCount;

----

AchievementUtils
~~~~~~~~~~~~~~~~

**File:** ``lib/utils/achievement_utils.dart``

Helper functions for checking and unlocking achievements stored in the ``achievement`` and ``user_achievement`` tables.

----

StatDegradationService
~~~~~~~~~~~~~~~~~~~~~~

**File:** ``lib/utils/stat_degradation_service.dart``

Calculates how much a pet's stats should decrease based on the time elapsed since ``last_online``. Called once on app start after ``getLastOnlineByUserId`` is resolved.

----

LastOnlineUpdater
~~~~~~~~~~~~~~~~~

**File:** ``lib/utils/last_online_updater.dart``

Updates the ``user.last_online`` column (ISO-8601 UTC string) whenever the app is brought to the foreground or closed.

----

LocationService
~~~~~~~~~~~~~~~

**File:** ``lib/utils/location_service.dart``

Wraps platform location APIs to provide a stream of ``LatLng`` positions used by the Map screen route recorder.
