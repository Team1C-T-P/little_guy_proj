Architecture Overview
=====================

Little Guy follows a lightweight layered architecture suited to a small Flutter team:

.. code-block:: text

   ┌──────────────────────────────────────────────┐
   │                  Views (UI)                  │
   │  main_page_view, play_view, shop_view, …     │
   └───────────────┬──────────────────────────────┘
                   │  reads / notifies
   ┌───────────────▼──────────────────────────────┐
   │             Controllers                       │
   │   StepGoalController   HatState              │
   │   (ChangeNotifier singletons)                │
   └───────────────┬──────────────────────────────┘
                   │  calls
   ┌───────────────▼──────────────────────────────┐
   │          Models / Services                   │
   │  PetStatsDatabase  ShopDatabase              │
   │  StepPointsService GoalService               │
   │  DressDatabase     RouteService              │
   │  LevelService                                │
   └───────────────┬──────────────────────────────┘
                   │  SQL via sqflite
   ┌───────────────▼──────────────────────────────┐
   │           SQLite (little_guy.db)             │
   └──────────────────────────────────────────────┘

Layer Responsibilities
----------------------

**Views** (``lib/views/``)
   Flutter widgets. They listen to controller ``ChangeNotifier``\s via ``Provider`` or direct singleton access, and call model methods directly for one-shot reads (e.g. loading shop items on page open).

**Controllers** (``lib/controller/``)
   Singleton ``ChangeNotifier``\s that hold UI-facing state. They call into models and then ``notifyListeners()`` so all dependent widgets rebuild.

**Models** (``lib/models/``) and **Services** (``lib/services/``)
   Plain Dart classes that accept an injected ``Database``. They contain all SQL queries and business logic (currency conversion, level-up calculation, etc.). No Flutter imports — fully unit-testable.

**Utilities** (``lib/utils/``)
   Stateless helpers and thin wrappers around platform APIs (pedometer, GPS, stat degradation calculation).

Dependency Injection Pattern
-----------------------------

Every model class accepts a ``Database`` parameter in its constructor. This single convention makes the whole data layer testable without mocking:

.. code-block:: dart

   // Production
   final db = await AppDatabase.instance.database;
   final shop = ShopDatabase(db);

   // Test
   final db = await openDatabase(inMemoryDatabasePath, onCreate: createSchema, version: 1);
   final shop = ShopDatabase(db);

For controllers that lazily initialise their dependencies, a ``testDb`` parameter is available:

.. code-block:: dart

   await StepGoalController().init(testDb: inMemoryDb);

State Management
----------------

The project uses Flutter's built-in ``ChangeNotifier`` / ``ListenableBuilder`` pattern rather than a third-party state management library. The two main notifiers are:

- ``StepGoalController`` — step counts, goal progress, currency balance.
- ``HatState`` — currently equipped hat asset path.

Both are singletons accessed as ``StepGoalController()`` and ``HatState.instance`` respectively.
