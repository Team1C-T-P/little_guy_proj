Backend
=======

database.dart
-------------

``AppDatabase`` is a singleton that manages the SQLite database connection. All other database classes accept an injected ``Database`` instance so they can be tested independently with an in-memory database.

.. code-block:: dart

    static final AppDatabase instance = AppDatabase._init();
    static Database? _database;

    Future<Database> get database async {
      if (_database != null) return _database!;
      _database = await _initDatabase();
      return _database!;
    }

    // Test-only seam — swap in an in-memory DB before any view code runs.
    static void setTestDatabase(Database? db) {
      _database = db;
    }

The singleton pattern ensures only one database connection is active at a time. ``setTestDatabase`` is a test-only hook that lets tests inject an in-memory database without touching the on-disk file. Pass ``null`` in ``tearDown`` to detach it.

The database is versioned (current version: **2**) and the schema is created in ``_createDB``, which sets up all tables including ``user``, ``little_guy``, ``item``, ``inventory``, ``goal``, and more.

.. note::
   Currency is stored in pence — divide by 100 when displaying and multiply by 100 when writing. Timestamps use ISO-8601 UTC strings throughout.

pet_maintainance_database.dart
------------------------------

``PetStatsDatabase`` handles reading and writing the virtual pet's stats and the owning user's profile data.

.. code-block:: dart

    class PetStatsDatabase {
      final Database _db;

      PetStatsDatabase(this._db);

      Future<double> getPetStat(int petId, String stat) async {
        const allowedStats = {'hunger_level', 'hygiene_level', 'enjoyment_level'};
        // ...
      }
    }

Stats are stored as integers (0–100) in the database and returned as normalised doubles (0.0–1.0) by dividing by 100. Allowed stat names are ``hunger_level``, ``hygiene_level``, and ``enjoyment_level`` — passing anything else throws an exception.

.. code-block:: dart

    Future<String?> getLastOnlineByUserId(int userId) async { ... }

``getLastOnlineByUserId`` returns the ISO-8601 timestamp of when the user last opened the app. This is consumed by ``StatDegradationService`` on launch to calculate how much each stat should have decreased while the app was closed.

shop_database.dart
------------------

``ShopDatabase`` manages item browsing, currency checks, and purchase transactions.

.. code-block:: dart

    Future<String> purchaseItem(int userId, int itemId) async {
      // Returns: 'success', 'already_owned', 'insufficient_funds', 'Item not found'
    }

The ``purchaseItem`` method runs atomically inside a database transaction. Hats that the user already owns cannot be purchased again (returns ``'already_owned'``). Food items already in inventory have their quantity incremented rather than creating a duplicate row.

.. code-block:: dart

    Future<int> getUserCurrency(int userId) async { ... }
    Future<bool> userOwnsItem(int userId, int itemId) async { ... }
    Future<Map<int, int>> getUserItemQuantities(int userId) async { ... }

``getUserCurrency`` returns the balance in pence. ``userOwnsItem`` is used by the Shop screen to grey out already-owned hats. ``getUserItemQuantities`` returns a ``{itemId: quantity}`` map for the entire inventory.

dress_database.dart
-------------------

``DressDatabase`` manages hat equipping and the inventory query for the Dress screen.

.. code-block:: dart

    Future<void> equipHat(int littleGuyId, int itemId) async {
      // Removes the currently equipped hat, then inserts the new one.
      await _db.delete('little_guy_wearing', where: 'little_guy_id = ?', whereArgs: [littleGuyId]);
      await _db.insert('little_guy_wearing', {'little_guy_id': littleGuyId, 'item_id': itemId});
    }

The ``little_guy_wearing`` table enforces a one-hat-at-a-time rule: ``equipHat`` always deletes the existing row before inserting the new one. ``unequipHat`` removes the row entirely, leaving the pet bare-headed.

.. code-block:: dart

    Future<Map<String, dynamic>?> getEquippedHat(int littleGuyId) async { ... }
    Future<List<Map<String, dynamic>>> getHatsOwnedByUser(int userId) async { ... }

``getEquippedHat`` returns ``{item_id, image_path}`` or ``null``. ``getHatsOwnedByUser`` returns all hats in the user's inventory for display in the Dress screen grid.

goal_service_database.dart
--------------------------

``GoalService`` creates and updates the user's recurring weekly step goal.

.. code-block:: dart

    Future<int> setDailyStepGoal(int userId, int stepGoal) async {
      // Creates a new goal or updates the existing one. Returns goal_id.
    }

If a goal row already exists for the user, ``setDailyStepGoal`` updates the ``target_goal`` in place rather than inserting a duplicate. New goals are created with a one-week deadline window.

.. code-block:: dart

    Future<int?> getDailyStepGoal(int userId) async { ... }
    Future<int> getCurrentSteps(int userId) async { ... }

``getDailyStepGoal`` returns the current target or ``null`` if none has been set. ``getCurrentSteps`` returns the user's progress toward their goal this week.

step_points_service.dart
------------------------

``StepPointsService`` records steps and converts them to in-game currency using a dedicated ``step_ledger`` table, keeping step tracking separate from the ``user.currency`` column.

.. code-block:: dart

    class StepPointsService {
      final Database _db;
      StepPointsService(this._db, {this.stepsPerPoint = 100});

      final int stepsPerPoint; // 100 steps = 1 coin by default
    }

.. code-block:: dart

    Future<StepRecordResult> recordSteps({required int userId, required int steps}) async {
      // Adds steps, converts whole batches to currency, updates active goal progress.
    }

Every call to ``recordSteps`` accumulates steps in the ledger. Once the running total of unconverted steps reaches ``stepsPerPoint``, whole batches are converted to coins and the remainder carried over. The method also increments the user's active goal progress in the same transaction.

``awardBonusPoints`` adds currency directly, bypassing step conversion — used for goal completion rewards.

route_service.dart
------------------

``RouteService`` saves and retrieves GPS walking routes recorded on the Map screen.

.. code-block:: dart

    RouteService({Database? db})  // pass db for testing; omit for production singleton

    Future<int> saveRoute(int userId, String name, List<LatLng> path) async {
      // Serialises List<LatLng> to JSON and persists it. Returns route_id.
    }

Routes are stored as JSON strings (``[{"lat": 0.0, "lng": 0.0}, ...]``) and decoded back to ``List<LatLng>`` on retrieval. ``deleteRoute`` permanently removes a route by its ID.

temp_model.dart
---------------

.. note::
   Add a description of ``temp_model.dart`` and its purpose here.

.. code-block:: dart

    // Add relevant code snippet here

level_service.dart
------------------

``LevelService`` manages the pet's XP and level progression. Every 100 XP triggers a level-up, with no upper level cap currently enforced.

.. code-block:: dart

    Future<Map<String, int>> addXp(int userId, int gainedXp) async {
      var data = await getLevelAndXp(userId);
      int level = data['level']!;
      int xp = data['xp']! + gainedXp;

      while (xp >= 100) {
        level++;
        xp -= 100;
      }
      // persists to DB and returns {'level', 'xp', 'leveledUp'}
    }

``addXp`` handles multiple simultaneous level-ups in a single call via the ``while`` loop. ``setLevelAndXp`` is a direct setter intended for admin use or testing.

step_goal_controller.dart
--------------------------

``StepGoalController`` is a ``ChangeNotifier`` singleton that bridges the UI with ``GoalService`` and ``StepPointsService``. Widgets listen to it to reactively update step counts, goal progress, and currency displays.

.. code-block:: dart

    static final StepGoalController _instance = StepGoalController._internal();
    factory StepGoalController() => _instance;

    int totalSteps = 0;
    int currentSteps = 0;
    int stepGoal = 250;
    bool goalReached = false;
    int currency = 0;

.. code-block:: dart

    Future<void> loadData() async {
      currentSteps = await goalService!.getCurrentSteps(userId);
      stepGoal = await loadGoal();
      totalSteps = await loadTotalSteps();
      notifyListeners();
    }

``loadData`` refreshes all state properties from the database and triggers a widget rebuild. ``updateGoal`` persists a new step goal and throws if the value is ≤ 0. Pass ``testDb`` to ``init`` to inject a test database.

hat_state.dart
--------------

``HatState`` is a ``ChangeNotifier`` singleton that tracks which hat (if any) is currently equipped on the Little Guy sprite, allowing the game widget to re-render on change.

.. code-block:: dart

    static final HatState instance = HatState._init();

    String? equippedHatPath; // null = no hat equipped

.. code-block:: dart

    Future<void> equipHat(int itemId, String imagePath) async {
      await dressDb.equipHat(1, itemId);
      equippedHatPath = imagePath;
      notifyListeners();
    }

``loadFromDb`` is called on app start to restore the last equipped hat. ``unequipHat`` sets ``equippedHatPath`` to ``null`` and notifies listeners.

step_counter.dart
-----------------

A lightweight singleton that accumulates raw step increments from the platform pedometer before they are flushed to ``StepPointsService``.

.. code-block:: dart

    class StepCounter {
      static final StepCounter _instance = StepCounter._internal();
      factory StepCounter() => _instance;

      int stepCount = 0;

      void addStep() { stepCount++; }
    }

achievement_utils.dart
-----------------------

.. note::
   Add a description of ``achievement_utils.dart`` here — what achievements are available, how they are checked and unlocked.

.. code-block:: dart

    // Add relevant code snippet here

stat_degradation_service.dart
------------------------------

``StatDegradationService`` calculates how much a pet's stats should decrease based on the elapsed time since ``last_online``. It is called once on app start after the last-online timestamp is resolved.

.. note::
   Add a description of the degradation rate formula and which stats are affected here.

.. code-block:: dart

    // Add relevant code snippet here

last_online_updater.dart
------------------------

Updates the ``user.last_online`` column (ISO-8601 UTC string) whenever the app is brought to the foreground or closed, providing the timestamp consumed by ``StatDegradationService``.

.. note::
   Add detail on the lifecycle hooks used (e.g. ``WidgetsBindingObserver``) here.

.. code-block:: dart

    // Add relevant code snippet here

location_service.dart
---------------------

Wraps the platform location API to provide a stream of ``LatLng`` positions used by the Map screen's route recorder.

.. note::
   Add detail on permission handling and the stream interface here.

.. code-block:: dart

    // Add relevant code snippet here

main.dart
---------

``main.dart`` is responsible for bootstrapping the Flutter app, initialising the database, and setting up the provider tree.

.. note::
   Add a description of the widget tree root and any providers registered at startup here.

.. code-block:: dart

    void main() async {
      WidgetsFlutterBinding.ensureInitialized();
      // Add database init and provider setup here
      runApp(const MyApp());
    }
