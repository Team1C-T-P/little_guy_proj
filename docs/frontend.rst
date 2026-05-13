Frontend
========

Overview
--------

The front end of this application has been standardised across screens with a consistent design language. This page covers design choices and the inner workings of each view and widget file.

Fonts
~~~~~

Google Fonts: Jua

Colours
~~~~~~~

The primary colours where chosen for their friendly look, fitting with the theme of the app.

Primary: A0F2BB

Secondary: EAFEDD

Teriary/Background colour: D4F7FD

Iconography
~~~~~~~~~~~

Icons in the application are taken from Flutter's default ``material.dart`` iconography package.

Little Guy character was made by Bethany Hall

Pages
-----

main_page_view.dart
~~~~~~~~~~~~~~~~~~~

.. note::
   Add a description of the main page layout and how it ties together the bottom navigation bar and child views.

.. code-block:: dart

    // Add relevant code snippet here

nav_bar.dart
~~~~~~~~~~~~

The bottom navigation bar provides persistent navigation across the five main sections of the application:

- Little Guy (Home)
- Map
- Dress
- Shop
- Profile

It is implemented as a reusable widget called ``MainNavBar`` using Flutter’s built-in ``BottomNavigationBar`` widget. This navigation bar is designed to be controlled externally by the parent view, meaning it does not manage state internally.

The widget requires two parameters:

- ``currentIndex``: determines which tab is currently active
- ``onTap``: a callback triggered when the user selects a new tab

This design allows the main screen controller (e.g. ``main_page_view.dart``) to handle navigation and page switching logic.

The navigation bar is styled consistently using custom theme colours:

- Background colour: ``Color.fromARGB(219, 150, 242, 176)``
- Selected item colour: ``Color.fromARGB(255, 77, 151, 86)``

Each navigation item uses an icon and label to represent the linked page.

.. code-block:: dart

    import 'package:flutter/material.dart';

    class MainNavBar extends StatelessWidget {
      const MainNavBar({
        super.key,
        required this.currentIndex,
        required this.onTap,
      });

      final int currentIndex;
      final ValueChanged<int> onTap;

      @override
      Widget build(BuildContext context) {
        return BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: const Color.fromARGB(219, 150, 242, 176),
          selectedItemColor: const Color.fromARGB(255, 77, 151, 86),
          onTap: onTap,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.spa),
              label: 'Little Guy',
              backgroundColor: Color.fromARGB(219, 150, 242, 176),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: 'Map',
              backgroundColor: Color.fromARGB(219, 150, 242, 176),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom),
              label: 'Dress',
              backgroundColor: Color.fromARGB(219, 150, 242, 176),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.tag),
              label: 'Shop',
              backgroundColor: Color.fromARGB(219, 150, 242, 176),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
              backgroundColor: Color.fromARGB(219, 150, 242, 176),
            ),
          ],
        );
      }
    }

header.dart
~~~~~~~~~~~

The header widget provides a consistent top app bar across all screens. It is implemented as a reusable widget called ``MainHeader`` and is inserted into screens using the ``Scaffold(appBar: ...)`` property.

The widget extends ``StatelessWidget`` and implements ``PreferredSizeWidget`` so it can be used directly as an ``AppBar``. The height is standardised to Flutter's default toolbar height (``kToolbarHeight``).

The AppBar is styled using a fixed background colour:

- ``Color.fromARGB(255, 213, 248, 255)``

The title is intentionally left blank (``Text('')``) to keep the header minimal and consistent across pages.

The header contains navigation buttons as AppBar actions:

- A developer-only Test Screen button (``Icons.bug_report``)
- A Community button (``Icons.diversity_1``)
- A Settings button (``Icons.settings``)

The Test Screen button is only shown in debug builds using ``kDebugMode``. This prevents the cheat/debug panel from appearing during production or demo builds.

Each button navigates using ``Navigator.push`` with a ``MaterialPageRoute`` to the relevant view.

.. code-block:: dart

    import 'package:flutter/foundation.dart';
    import 'package:flutter/material.dart';

    import 'community_view.dart';
    import 'settings_view.dart';
    import 'test_view.dart';

    class MainHeader extends StatelessWidget implements PreferredSizeWidget {
      const MainHeader({super.key});

      @override
      Size get preferredSize => const Size.fromHeight(kToolbarHeight);

      @override
      Widget build(BuildContext context) {
        return AppBar(
          title: const Text(''),
          backgroundColor: const Color.fromARGB(255, 213, 248, 255),
          actions: [
            if (kDebugMode)
              IconButton(
                icon: const Icon(Icons.bug_report),
                tooltip: 'Test Screen',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TestScreen()),
                  );
                },
              ),
            IconButton(
              icon: const Icon(Icons.diversity_1),
              tooltip: 'Community',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CommunityScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
          ],
        );
      }
    }

setup_profile_view.dart
~~~~~~~~~~~~~~~~~~~~~~~

The Setup Profile screen is the first screen displayed to new users when no profile exists in the database. It allows the user to create their account by entering:

- A username
- A name for their Little Guy (pet)

This screen is implemented as a ``StatefulWidget`` because it manages input controllers, loading state, and error handling.

The widget accepts a callback function:

- ``onProfileCreated``: triggered once profile creation is successful, allowing the parent widget to transition into the main application.

Input Handling and Validation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Two ``TextEditingController`` objects are used:

- ``_usernameController``
- ``_petNameController``

Before saving, the inputs are validated. If either field is empty, the screen displays an error message:

``Please enter both username and pet name``

Database Integration
^^^^^^^^^^^^^^^^^^^^

The profile is saved using the local SQLite database via ``AppDatabase.instance.database``.

When the user taps the Create Profile button, the following database inserts occur:

1. A record is inserted into the ``user`` table, containing:

   - ``user_name`` (trimmed username input)
   - ``currency`` initialised to 0
   - ``last_online`` stored as a UTC ISO8601 timestamp

2. The returned auto-generated ``user_id`` is stored and used as a foreign key
   when inserting the Little Guy into the ``little_guy`` table.

3. A record is inserted into the ``little_guy`` table containing:

   - ``user_id`` (FK from inserted user)
   - ``little_guy_name`` (trimmed pet name input)
   - ``hygiene_level`` initialised to 50
   - ``hunger_level`` initialised to 50
   - ``enjoyment_level`` initialised to 50

This design avoids hardcoding a fixed user id and ensures correct linking between user and pet records.

Loading and Error Behaviour
^^^^^^^^^^^^^^^^^^^^^^^^^^^

During profile creation, the UI enters a loading state:

- Input fields are disabled
- The Create Profile button is disabled
- A circular progress indicator is displayed inside the button

If an exception occurs during database insertion, an error message is displayed in red and the loading state is cleared.

To avoid calling UI updates after disposal, the code checks ``mounted`` before triggering the callback or updating state.

UI Design
^^^^^^^^^

The screen uses a green gradient background to match the application's theme.
The layout is centered and scrollable using ``SingleChildScrollView`` to prevent overflow on smaller screens.

The Create Profile button spans the full width of the form and uses a consistent rounded design.

.. code-block:: dart

    import 'package:flutter/material.dart';
    import '../models/database.dart';

    class SetupProfileScreen extends StatefulWidget {
      final Function() onProfileCreated;

      const SetupProfileScreen({
        super.key,
        required this.onProfileCreated,
      });

      @override
      State<SetupProfileScreen> createState() => _SetupProfileScreenState();
    }

    class _SetupProfileScreenState extends State<SetupProfileScreen> {
      final _usernameController = TextEditingController();
      final _petNameController = TextEditingController();
      bool _isLoading = false;
      String? _errorMessage;

      @override
      void dispose() {
        _usernameController.dispose();
        _petNameController.dispose();
        super.dispose();
      }

      Future<void> _saveProfile() async {
        if (_usernameController.text.isEmpty || _petNameController.text.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter both username and pet name';
          });
          return;
        }

        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });

        try {
          final db = await AppDatabase.instance.database;

          final userId = await db.insert('user', {
            'user_name': _usernameController.text.trim(),
            'currency': 0,
            'last_online': DateTime.now().toUtc().toIso8601String(),
          });

          await db.insert('little_guy', {
            'user_id': userId,
            'little_guy_name': _petNameController.text.trim(),
            'hygiene_level': 50,
            'hunger_level': 50,
            'enjoyment_level': 50,
          });

          if (!mounted) return;
          widget.onProfileCreated();
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Error saving profile: $e';
            _isLoading = false;
          });
        }
      }

      @override
      Widget build(BuildContext context) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.shade100,
                  Colors.green.shade50,
                ],
              ),
            ),
          ),
        );
      }
    }

play_view.dart
~~~~~~~~~~~~~~

The main Home screen where the Little Guy is displayed. Shows the pet's current stats (hunger, hygiene, enjoyment) and allows the user to interact with their pet.

.. note::
   Add detail on how the Flame game widget is embedded, how stat bars are rendered, and what interactions are available.

.. code-block:: dart

    // Add relevant code snippet here

shop_view.dart
~~~~~~~~~~~~~~

The Shop screen where users spend coins on food and accessories It shows:

- user's current coin balance
- a grid of items to buy
- buttons to switch between Food and Clothes

The page is a StatefulWidget, so that it will automatically update when the user changes tabs or buys an item

.. code-block:: dart

   int _coinBalance = 0;
   List<Map<String, dynamic>> _items = [];
   Set<int> _ownedItemIds = {};
   Map<int, int> _itemQuantities = {};
   bool _isLoading = true;
   String _currentType = 'hat';

These variabes store the current state of the shop:

- ``_coinBalance`` holds the user's coins
- ``_items`` stores the items shown on screen
- ``_ownedItemIds`` keeps track of owned hats
- ``_itemQuantities`` stores the quantity of food the user owns
- ``_isLoading`` shows a loding spinner while the data loads
- ``_currentType`` tracks whether the user is viewing food or hats

.. code-block:: dart

   Future<void> _loadShopData(String type) async {
      final currency = await _shopDb.getUserCurrency(1);
      final items = await _shopDb.getItemsByType(type);
      final ownedIds = await _shopDb.getUserItems(1);
      final quantities = await _shopDb.getUserItemQuantities(1);
      ...
   }

``_loadShopData`` loads all the shop information from the database, retrieving:

- the user's balance
- the current items
- owned items,
- item quantities

This method is called when the page first opens, the user changes category from Food/Hat, or when a purchase is completed

.. code-block:: dart

   _goalListener = () {
       if (mounted) _loadShopData(_currentType);
   };
   _goalController.addListener(_goalListener);

This listener allows the shop to listen for updates from StepGoalController, so if the user earns coins somewhere else in the app, the shop refreshes automatically. It's added in ``initState`` and removed in ``dispose`` to avoid memory leaks

.. code-block:: dart

   if (itemType == 'food' && quantity > 0)
      Text('You own: $quantity', ...)
   else if (itemType == 'hat' && alreadyOwned)
      Text('You already own this item', ...)
   if (_coinBalance < price)
      Text('You do not have enough coins to purchase this item.', ...)

The purchase dialogue will show different messages based on different situations:

- Food items showing how many the user owns
- Hats showing a warning if the user owns it already
- A red warning appears if the user doesn't have enough coins 

These messages will then help the user understand why they can/can't purcahase an item.


dress_view.dart
~~~~~~~~~~~~~~~

The Dress screen allows the users to equip hats onto the little guy and also displays:

- the little guy,
- a grid of currently owned hats,
- the hat currently equipped to the little guy

When a hat is selected, the database is updated and the little guy gets updated immediately.

.. code-block:: dart

   List<Map<String, dynamic>> _ownedHats = [];
   int? _equippedHatId;
   bool _isLoading = true;

These variables store the state of the dress_view screen:

- ``_ownedHats`` stores all hats owned by user
- ``_equippedHatId`` stores the currently equipped hat
- ``_isLoading`` controls the loading spinner

.. code_block:: dart

   Future<void> _loadDressData() async {
      final hats = await _dressDb.getOwnedHats(1);
      final equipped = await _dressDb.getEquippedHat(1);
      ...
   }

``_loadDressData`` loads the owned hats and equipped hat from the database, and it's called when the page opens or the equipped hat changes, keeping the UI synced with the database.

.. code-blocks:: dart

   await _dressDb.equipHat(userId, hatId);
   setState(() {
      _equippedHatId = hatId;
   });

When the user equips a hat, the database is updated, the equipped hat ID changes and refreshed the UI, so the little guy updates without having to reopen the page.

clean_view.dart
~~~~~~~~~~~~~~~

.. note::
   Add a description of the Clean screen — what the user does here and how the hygiene stat is updated.

.. code-block:: dart

    // Add relevant code snippet here

map_view.dart
~~~~~~~~~~~~~

The Map screen where users can record GPS walking routes and replay past routes.

.. note::
   Add detail on how the map widget is set up, how route recording starts and stops, and how saved routes are displayed.

.. code-block:: dart

    // Add relevant code snippet here

routes_view.dart
~~~~~~~~~~~~~~~~

.. note::
   Add a description of the Routes screen — how saved routes are listed and what actions are available (view, delete).

.. code-block:: dart

    // Add relevant code snippet here

summary_view.dart
~~~~~~~~~~~~~~~~~

.. note::
   Add a description of the Summary screen — what stats or history it shows the user.

.. code-block:: dart

    // Add relevant code snippet here

community_view.dart
~~~~~~~~~~~~~~~~~~~

The Community screen with a social feed and leaderboard.

.. note::
   Add detail on how community data is fetched and displayed, and what interactions are available.

.. code-block:: dart

    // Add relevant code snippet here

feed_view.dart
~~~~~~~~~~~~~~

.. note::
   Add a description of the Feed view — what posts or activity entries it shows and how they are loaded.

.. code-block:: dart

    // Add relevant code snippet here

profile_view.dart
~~~~~~~~~~~~~~~~~

The Profile screen shows the Achiveements, Lvl (xp and level) and account details such as steps, items (hats) collected, and the name of both the user and pet.

The code is a mix of backend logic and frontend code. There are also some testing only functions here for the profile, to make sure that it works properly, since this is the core of the progression of the game. (giving feedback for walking and interacting with the app)

The core is SharedPreferences, it uses a simple Key/Value pair as local storage outside of the DB, providing simple implimentation. However future development will replace this with the achivement and user_achivements table, thats in the database.dart file currently. (This is since for deployment, it's best to have an empty table then no table, preventing issues.)

.. code-block:: dart

    AppDatabase.instance.database.then((db) async {
      if (!mounted) return;
      _stepPointsService = StepPointsService(db);
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _madHatterCompleted = prefs.getBool('madHatterClaimed') ?? false;
        _bigWalkCompleted = prefs.getBool('bigWalkClaimed') ?? false;
        _wealthyCompleted = prefs.getBool('wealthyClaimed') ?? false;
        _mvpCompleted = prefs.getBool('mvpClaimed') ?? false;
        _letsPlayCompleted = prefs.getBool('letsPlayClaimed') ?? false;
      });
      _loadData();
    });

This code first uses the database to get the step points service up, needed to provide the steps for the user. Then on mass the code declares all of the achivements outside of Let's Play, that does not work in this version using the SharedPreferences.getInstance() to get the boolian here.

.. code-block:: dart

  Future<void> _loadData() async {
    try {
      final summary = await _stepPointsService.getAccountSummary(1);
      await _goalController.loadData();

      final db = await AppDatabase.instance.database;

      final userResult = await db.query(
        'user',
        where: 'user_id = ?',
        whereArgs: [_userId],
      );
      if (userResult.isNotEmpty) {
        _userName = userResult.first['user_name'] as String;
      }

      final petResult = await db.query(
        'little_guy',
        where: 'user_id = ?',
        whereArgs: [_userId],
      );
      if (petResult.isNotEmpty) {
        _petName = petResult.first['little_guy_name'] as String;
      }

      final dressDb = DressDatabase(db);
      final ownedHats = await dressDb.getHatsOwnedByUser(_userId);
      _hatsCollected = ownedHats.length;

      // Check achievements. MVP requires the freshly-fetched level, so
      // we read levelData first and only call _checkMVPAchievement after.
      await _checkMadHatterAchievement();
      await _checkBigWalkAchievement(summary.totalSteps);
      await _checkWealthyAchievement(summary.currency);
      await _checkTrailBlazerAchievement();

      final levelService = LevelService(db);
      final levelData = await levelService.getLevelAndXp(_userId);
      final currentLevel = levelData['level']!;
      await _checkMVPAchievement(currentLevel);
      if (mounted) {
        setState(() {
          _currentLevel = levelData['level']!;
          _currentXp = levelData['xp']!;
          _xpProgress = _currentXp / 100.0;
          _totalSteps = summary.totalSteps;
          _currency = summary.currency;
          _leftoverSteps = summary.unconvertedSteps;
          _currentSteps = _goalController.currentSteps;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _status = 'Failed to load summary: $e');
    }
  }

As you can guess, loadData, gets all the data needed.

We will only cover one of the achivements for time, MadHattedAchievement. All of them have the same logic, other then the bespoke checks for each.

.. code-block:: dart

    Future<void> _checkMadHatterAchievement() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyClaimed = prefs.getBool('madHatterClaimed') ?? false;

    if (alreadyClaimed) {
      if (!_madHatterCompleted && mounted) {
        setState(() => _madHatterCompleted = true);
      }
      return;
    }

    if (_hatsCollected >= 5) {
      if (!mounted) return;
      setState(() => _madHatterCompleted = true);
      await prefs.setBool('madHatterClaimed', true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mad Hatter achievement unlocked!')),
        );
      }
    }
  }

This uses the same idea as before, using SharedPreferences to check the madHatterClaimed boolean. If its true, then, great, make the _madHatterCompleted varible true. Then, check if _HatsCollected is at or more than 5, if it is, set the boolean to true and send a SnackBar message.

.. code-block:: dart

  Align(
    alignment: Alignment.topLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Total Steps: $_totalSteps"),
          Text("Items Collected: $_hatsCollected "),
          const SizedBox(height: 8),
          Text("Little Guy LVL: $_currentLevel"),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _xpProgress,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                  minHeight: 12,
                ),
              ),
              const SizedBox(width: 8),
              Text("$_currentXp / 100"),
            ],
          ),
        ],
      ),
    ),

This showcases the level up bar and the value. LinearProgressIndicator uses _xpProgress (currentXp / 100.00) for the level up bar.

.. code-block:: dart
  Column(
    children: [
      const Text(
        "Mad Hatter",
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
      const Text(
        "Get 5 Hats",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        _madHatterCompleted
            ? "Completed"
            : "Not completed",
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
        ),
      ),
    ],
  ),

Here is the achivement UI, where _madHatterCompleted is checked. If true, it'll show completed, if not, not completed. The same idea is used for all other achivements.

settings_view.dart
~~~~~~~~~~~~~~~~~~

The Settings screen where users can update their daily step goal and other preferences.

.. note::
   Add detail on what settings are available and how changes are persisted.

.. code-block:: dart

    // Add relevant code snippet here

test_view.dart
~~~~~~~~~~~~~~

.. note::
   Add a description of ``test_view.dart`` — whether this is a developer debug screen or has another purpose, and whether it is accessible in production builds.

.. code-block:: dart

    // Add relevant code snippet here

Widgets
-------

progress_bar.dart
~~~~~~~~~~~~~~~~~

A reusable widget that renders a filled progress bar, used to display the pet's hunger, hygiene, and enjoyment stats.

.. note::
   Add detail on the parameters the widget accepts (e.g. current value, max value, colour) and how it is used across screens.

.. code-block:: dart

    // Add relevant code snippet here

button.dart
~~~~~~~~~~~

A reusable styled button widget used throughout the application to maintain a consistent primary action appearance without duplicating styling code.

This widget is implemented as a stateless wrapper around Flutter’s ``ElevatedButton`` and is named ``GreenButton``.

It is designed to standardise the app’s primary action buttons (e.g. submit actions, purchase actions, confirmations) by enforcing a consistent colour and text style.

Widget Parameters
^^^^^^^^^^^^^^^^^

The ``GreenButton`` constructor requires two parameters:

- ``buttonText``: The label displayed inside the button
- ``onPressed``: A callback function triggered when the button is tapped

Styling
^^^^^^^

The button uses a fixed green colour defined using:

``Color.fromARGB(255, 159, 239, 167)``

This aligns with the app’s overall soft green theme used across UI elements such as gradients and navigation accents.

The text styling is derived from the current theme using:

- ``DefaultTextStyle.of(context).style``

This ensures the button text remains consistent with surrounding typography while allowing scalable sizing via ``fontSizeFactor``.

Behaviour
^^^^^^^^^

- The button triggers the provided ``onPressed`` callback when tapped
- It does not manage internal state
- It is fully stateless and reusable across all screens

Usage Example
^^^^^^^^^^^^^

The widget is typically used in forms and action panels where a single primary action is required.

.. code-block:: dart

    GreenButton(
      buttonText: 'Create Profile',
      onPressed: _saveProfile,
    )

Code
^^^^

.. code-block:: dart

    import 'package:flutter/material.dart';

    class GreenButton extends StatelessWidget {
      const GreenButton({
        super.key,
        required this.buttonText,
        required this.onPressed,
      });

      final String buttonText;
      final VoidCallback onPressed;

      @override
      Widget build(BuildContext context) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 159, 239, 167),
          ),
          onPressed: onPressed,
          child: Text(
            buttonText,
            style: DefaultTextStyle.of(context).style.apply(fontSizeFactor: 1),
          ),
        );
      }
    }

little_guy.dart
~~~~~~~~~~~~~~~

The core Flame game widget that renders the animated Little Guy sprite, including any equipped hat overlay.

.. note::
   Add detail on the Flame component structure, how animations are triggered, and how ``HatState`` changes cause a re-render.

.. code-block:: dart

    // Add relevant code snippet here
