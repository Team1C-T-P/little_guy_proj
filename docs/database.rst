Database Schema
===============

The app uses a single SQLite database file named ``little_guy.db``, managed by ``AppDatabase`` via the ``sqflite`` package. The schema is created in ``AppDatabase._createDB`` and is versioned (current version: **2**).

Tables
------

user
~~~~

Stores the single local user account.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``user_id``
     - INTEGER PK
     - Auto-increment primary key
   * - ``user_name``
     - TEXT
     - Display name chosen at setup
   * - ``currency``
     - INTEGER
     - Stored in **pence** (divide by 100 to display). Constrained ≥ 0
   * - ``last_online``
     - TEXT
     - ISO-8601 UTC timestamp; used by ``StatDegradationService``

little_guy
~~~~~~~~~~

The virtual pet. One row per user.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``little_guy_id``
     - INTEGER PK
     - Auto-increment primary key
   * - ``user_id``
     - INTEGER FK
     - References ``user.user_id``
   * - ``little_guy_name``
     - TEXT
     - Pet name
   * - ``hunger_level``
     - INTEGER
     - 0–100 (divide by 100 for normalised value)
   * - ``hygiene_level``
     - INTEGER
     - 0–100
   * - ``enjoyment_level``
     - INTEGER
     - 0–100
   * - ``level``
     - INTEGER
     - Pet level (starts at 1)
   * - ``xp``
     - INTEGER
     - XP within current level; level-up at 100

step_ledger
~~~~~~~~~~~

Tracks step accumulation separately from currency to support accurate conversion and partial-step carry-over.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``user_id``
     - INTEGER PK FK
     - One row per user; references ``user.user_id``
   * - ``total_steps``
     - INTEGER
     - Lifetime step count; constrained ≥ 0
   * - ``unconverted_steps``
     - INTEGER
     - Steps not yet converted to currency (< ``stepsPerPoint``); constrained ≥ 0
   * - ``updated_at``
     - TEXT
     - ISO-8601 timestamp of last update

item
~~~~

The shop catalogue.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``item_id``
     - INTEGER PK
     - Auto-increment
   * - ``item_name``
     - TEXT
     -
   * - ``image_path``
     - TEXT
     - Asset path relative to ``assets/``
   * - ``price``
     - INTEGER
     - In pence
   * - ``type``
     - TEXT
     - ``'hat'`` or ``'food'``

inventory
~~~~~~~~~

Items owned by the user.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``user_id``
     - INTEGER FK
     -
   * - ``item_id``
     - INTEGER FK
     -
   * - ``quantity``
     - INTEGER
     - Always ≥ 1; hats are typically quantity 1

little_guy_wearing
~~~~~~~~~~~~~~~~~~

Tracks which hat (if any) is currently equipped. At most one row per pet.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``little_guy_id``
     - INTEGER FK
     -
   * - ``item_id``
     - INTEGER FK
     -

goal
~~~~

Defines a step target (recurring weekly).

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``goal_id``
     - INTEGER PK
     -
   * - ``target_goal``
     - INTEGER
     - Daily step target
   * - ``is_recurring``
     - INTEGER
     - 1 = recurring weekly
   * - ``target_deadline``
     - TEXT
     - ISO-8601 deadline
   * - ``min_allowed_value``
     - INTEGER
     - Minimum valid step count (usually 0)

user_goal
~~~~~~~~~

Links a user to their active goal and tracks progress.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``user_id``
     - INTEGER FK
     -
   * - ``goal_id``
     - INTEGER FK
     -
   * - ``current_progress``
     - INTEGER
     - Steps walked this period
   * - ``reward_claimed``
     - INTEGER
     - 0 or 1
   * - ``week_start_date``
     - TEXT
     - ISO-8601
   * - ``week_end_date``
     - TEXT
     - ISO-8601

achievement / user_achievement
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Stores achievement definitions and per-user unlock records. Included for future development to prevent issues.

**achievement**

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``achievement_id``
     - INTEGER PK
     -
   * - ``name``
     - TEXT
     -
   * - ``description``
     - TEXT
     -
   * - ``target_value``
     - INTEGER
     - Threshold for incremental achievements
   * - ``type``
     - TEXT
     - Category of achievement

**user_achievement**

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``user_id``
     - INTEGER FK
     -
   * - ``achievement_id``
     - INTEGER FK
     -
   * - ``unlocked_at``
     - TEXT
     - ISO-8601 timestamp
   * - ``progress``
     - INTEGER
     - Current progress toward incremental achievements

route
~~~~~

Stores GPS routes recorded on the Map screen.

.. list-table::
   :header-rows: 1
   :widths: 20 15 65

   * - Column
     - Type
     - Notes
   * - ``route_id``
     - INTEGER PK
     -
   * - ``user_id``
     - INTEGER FK
     -
   * - ``route_name``
     - TEXT
     -
   * - ``route_path``
     - TEXT
     - JSON-encoded array of ``{lat, lng}`` objects
