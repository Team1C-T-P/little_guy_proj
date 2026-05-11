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

``StepPointsService`` records steps and converts them into in-game currency at a configurable rate, tracking totals in a dedicated ledger table.

.. code-block:: dart

    // insert important code

// explain code

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
