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

This is the main page that loads up when you have signed in. It contains the little guy, as well as its stats, such as its cleanliness, hunger and enjoyment. There is an area that displays the user's step goal, with buttons to increase or decrease it. There are also buttons to feed, play and clean the pet.

.. code-block:: dart

  late final VoidCallback _goalListener;

``_goalListener`` is used to attach a listener to StepGoalController so that when the steps or goals change, the screen will rebuild itself. 

.. code-block:: dart

  Future<void> _loadPetStats() async {
    try {
      double hunger = await _petStatsDB.getPetStat(petId, 'hunger_level');
      double enjoyment = await _petStatsDB.getPetStat(petId, 'enjoyment_level');
      double hygiene = await _petStatsDB.getPetStat(petId, 'hygiene_level');

      if (!mounted) return;
      setState(() {
        _hunger = hunger;
        _enjoyment = enjoyment;
        _hygiene = hygiene;
      });
    } catch (e) {
      debugPrint('HomeScreen: failed to load pet stats ($e)');
    }
  }

``_loadPetStats`` fetchesthe pets stats from the database, thatis then used tto update the progress bars. If the widget isn't on the screen when the data loads, it returns uwing the ``if (!mounted) return``

.. code-block:: dart

   Expanded(
      child: GreenButton(
         buttonText: "+250",
         onPressed: () async {
            final newGoal =
               _goalController.stepGoal + 250;
            await _goalController.updateGoal(newGoal);
         },
      ),
   ),
   Expanded(
      child: GreenButton(
         buttonText: "-250",
         onPressed: () async {
            final newGoal =
               (_goalController.stepGoal - 250).clamp(
                  0,
                  999999,
               );
            await _goalController.updateGoal(newGoal);

The buttons, here control how much the goal total changes, with a limit of 999999 steps. When they get pressed they call the ``_goalController`` to update the goal and refresh the UI.

.. code-block:: dart

   SizedBox(
      width: 150,
      height: 60,
      child: FittedBox(
         child: GreenButton(
            buttonText: "Clean",
            onPressed: () async {
               await Navigator.of(context).push(
                  MaterialPageRoute(
                     builder: (context) => const CleanScreen(),
                  ),
               );
               await _loadPetStats();
            },
         ),
      ),
   ),

The green buttons that have the "Play", "Clean" and "Feed", that allow you to interact with the little guy all have this layout, where they will load a separate screen, with their own functions, allowing you to interact with the little guy.

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

.. code-block:: dart

  Future<void> _playWithPet() async {
    if (_enjoyment >= 1.0) return;

    // Start playing animation
    _petTrigger.value = true;

    // Calculate new enjoyment value
    final newEnjoyment = _enjoyment + 0.25 > 1.0 ? 1.0 : _enjoyment + 0.25;

    // Update database
    await _petStatsDB.updatePetStat(1, 'enjoyment_level', newEnjoyment);

    // Grant XP (5 XP per play)
    final db = await AppDatabase.instance.database;
    final levelService = LevelService(db);
    final levelResult = await levelService.addXp(1, 5);

    // Refresh UI
    await _loadPetStats();

    // Show level‑up snackbar if needed
    if (levelResult['leveledUp'] == 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your Little Guy reached level ${levelResult['level']}!',
          ),
        ),
      );
    }
  }

Here _playWithPet is used when the user clicks the little guy. If the enjoyment is below 1, it'll start the logic. First starting the animation with _petTrigger.value, calculating the new enjoyment values, updating the DB and granting the xp.

.. code-block:: dart

          Container(
            alignment: Alignment.bottomCenter,
            color: Color.fromARGB(255, 221, 249, 255),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  _playWithPet();
                },
                child: SizedBox(
                  width: 300,
                  height: 360,
                  child: PetLittleGuy(trigger: _petTrigger),
                ),
              ),
            ),
          ),

This is  where _playWithPet(); gets called.

shop_view.dart
~~~~~~~~~~~~~~

The Shop screen where users spend coins on food and accessories It shows:

- user's current coin balance
- a grid of items to buy
- buttons to switch between Food and Clothes

The page is a StatefulWidget, so that it will automatically update when the user changes tabs or buys an item

.. code-block:: dart

  final StepGoalController _goalController = StepGoalController();
  late final VoidCallback _goalListener;

The ``_goalController`` and ``_goalListener`` refreshes the shop view whenever the user's currency balance is updated elsewhere in the app, with the controller being added in the ``initState()`` and removed in ``dispose()`` to avoid memory leaks

.. code-block:: dart

  Future<void> _loadShopData(String type) async {
    // load user currency and shop items from the database
    // Assuming user ID 1 for now

    setState(() {
      _isLoading = true;
    });

    try {
      final currency = await _shopDb.getUserCurrency(1);
      final items = await _shopDb.getItemsByType(type);
      final ownedIds = await _shopDb.getUserItems(1);
      final quantities = await _shopDb.getUserItemQuantities(1);

      if (!mounted) return;
      setState(() {
        _coinBalance = currency;
        _items = items;
        _ownedItemIds = ownedIds.toSet();
        _itemQuantities = quantities;
        _currentType = type;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint('Shop: failed to load shop data ($e)');
    }
  }

This section helps to load all the data thats needed, such as the currenct balance of the user, all items in the shop, the owned item ids of items that the user owns and their quantities for food.

.. code-block:: dart

  void _showPurchaseDialog(Map<String, dynamic> item) {
      final itemId = item['item_id'] as int;
      final itemName = item['item_name'] as String;
      final price = item['price'] as int;
      final itemType = item['type'] as String;
      final alreadyOwned = _ownedItemIds.contains(itemId);
      final quantity = _itemQuantities[itemId] ?? 0;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Purchase $itemName?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price: $price coins'),
              SizedBox(height: 10),
              Text('Your Balance: $_coinBalance coins'),
              SizedBox(height: 10),
              // show quantity of food owned, and owned for hats
              if (itemType == 'food' && quantity > 0)
                Text(
                  'You own: $quantity',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (itemType == 'hat' && alreadyOwned)
                Text(
                  'You already own this item',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (_coinBalance < price)
                Text(
                  'You do not have enough coins to purchase this item.',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            // allow purchase if have enough money if food or new hat
            if (_coinBalance >= price && (itemType == 'food' || !alreadyOwned))
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await _shopDb.purchaseItem(1, itemId);

                  // Guard against the user leaving the Shop tab mid-purchase
                  // — touching context after dispose throws.
                  if (!mounted) return;

                  if (result == 'success') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Purchased $itemName!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadShopData(_currentType);
                  } else if (result == 'already_owned') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('You already own this item'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else if (result == 'insufficient_funds') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Not enough funds to purchase this item'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Buy'),
              ),

This section handles the dialogue and process of buying items, showing different messages based on the scenario. When buying food, it shows the quantity you currently own, if trying to buy a hat you already own, it tells you that, and if you don't have enough currency in your balance, it cancels the transaction and tells you. On a successful purchase, it will tell you that you sucessfully did so.

.. code-block:: dart

                Expanded(
                  child: GreenButton(
                    buttonText: 'Food',
                    onPressed: () {
                      setState(() {
                        _loadShopData('food');
                      });
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: GreenButton(
                    buttonText: 'Clothes',
                    onPressed: () {
                      setState(() {
                        _loadShopData('hat');
                      });
                    },
                  ),
                ),

This section allows you to choose what type of items that you want to purchase, when pressing the buttons, they call the ``_loadShopData`` with the item type, either 'food', or 'hat', and the shop displays the items with that type.

dress_view.dart
~~~~~~~~~~~~~~~

The Dress screen allows the users to equip hats onto the little guy and also displays:

- the little guy,
- a grid of currently owned hats,
- the hat currently equipped to the little guy

When a hat is selected, the database is updated and the little guy gets updated immediately.

.. code-block:: dart

  @override
  void initState() {
    super.initState();
    _loadEquippedHat();
    _hatsFuture = _loadOwnedHats();
  }

The ``initState`` runs when the page is first loaded, fetching the data before anything is displayed on the page

.. code-block:: dart

  Future<void> _loadEquippedHat() async {
    try {
      final db = await AppDatabase.instance.database;
      final dressDb = DressDatabase(db);
      final equipped = await dressDb.getEquippedHat(1);
      if (!mounted) return;
      if (equipped != null) {
        setState(() {
          _selectedHatId = equipped['item_id'] as int;
        });
      }
    } catch (e) {
      debugPrint('DressUp: failed to load equipped hat ($e)');
    }
  }

  Future<List<Map<String, dynamic>>> _loadOwnedHats() async {
    final db = await AppDatabase.instance.database;
    final dressDb = DressDatabase(db);
    return await dressDb.getHatsOwnedByUser(1);
  }

These two functions load up the currently equipped hat and the hats that are owned by the user, and they are used in the initState

.. code_block:: dart

   final hat = snapshot.data![index];
   final isSelected = _selectedHatId == hat['item_id'];
   return IconButton(
      padding: EdgeInsets.all(8.0),
      style: IconButton.styleFrom(
         backgroundColor: isSelected
            ? Colors.green.withValues(
               alpha: 0.3,
              ) // highlight selected hat
            : Colors
                  .transparent, // leaves unselected transparent

This section of the ``GridView`` displayes the currently displayed hat, with the selected hat being higlighted green

.. code-blocks:: dart

   final itemId = hat['item_id'] as int;
   final imagePath = hat['image_path'] as String;

   if (_selectedHatId == itemId) {
      setState(() {
         _selectedHatId = null;
      });
      await HatState.instance.unequipHat();
   } else {
      setState(() {
         _selectedHatId = itemId;
      });
      await HatState.instance.equipHat(
         itemId,
         imagePath,
      );
   }

This section handles the equipping/unequipping of hats, taking the item_id and image_path from the hat object of the hat displayed in the grid, comparing it to the _selectedHatId. If they are the same, it will uses ``unEquipHat()`` from the HatState to unequip the hat and reload the little guy. If they are different, then the opposite happens using ``EquipHat()``. 

clean_view.dart
~~~~~~~~~~~~~~~

This is where the user can clean the little guy. Once they click the button, a short animation is done, and the _hygiene stat is updated.

.. code-block:: dart

  Future<void> _cleanPet() async {
    if (_hygiene >= 1.0) return;

    // Start cleaning animation
    _cleanTrigger.value = true;

    // Update pet's hygiene level to maximum (1.0)
    await _petStatsDB.updatePetStat(1, 'hygiene_level', 1.0);

    // Grant XP (5 XP per cleaning)
    final db = await AppDatabase.instance.database;
    final levelService = LevelService(db);
    final levelResult = await levelService.addXp(1, 5);

    // Refresh data after cleaning
    await _loadPetHygiene();

    // Show level‑up snackbar if needed
    if (levelResult['leveledUp'] == 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your Little Guy reached level ${levelResult['level']}!',
          ),
        ),
      );
    }
  }

This is whats called when the button is clicked. If the hygiene is lower than 1, then the animation plays, it updates the pet's hygine to max, grants xp, and refreshes.

map_view.dart
~~~~~~~~~~~~~


The Map screen allows the user to track a live walk using GPS, record a route, and view previously saved routes. It also integrates step tracking via the pedometer and provides session-based statistics such as steps taken and walking status.

This screen is a `StatefulWidget` because it manages live streams (GPS + pedometer), route state, and UI updates.

Key responsibilities:
- Live GPS tracking and route recording
- Step counting (session + global via `StepCounter`)
- Displaying current position on a map
- Loading and displaying saved routes
- Ending a walk and passing data to the summary screen

---

### Step and Pedestrian Tracking

The screen listens to the device pedometer streams and converts raw step events into session data.

.. code-block:: dart

  void onStepCount(StepCount event) {
    if (!mounted) return;

    setState(() {
      _steps = event.steps.toString();

      if (_initialSteps == -1) {
        _initialSteps = event.steps;
      }

      final currentSessionSteps = event.steps - _initialSteps;
      final newSteps = currentSessionSteps - _sessionSteps;

      for (int i = 0; i < newSteps; i++) {
        StepCounter().addStep();
      }

      _sessionSteps = currentSessionSteps;
    });
  }

This ensures:
- Session steps are calculated relative to app start
- Global step counter is updated incrementally
- UI updates safely only when mounted

---

### GPS Location Tracking

Location updates are handled using a stream from `LocationService`, which continuously updates the user’s position and builds the route.

.. code-block:: dart

  Future<void> _startLocationTracking() async {
    Position? initialPosition = await LocationService().determinePosition();

    if (initialPosition != null && mounted) {
      setState(() {
        _currentPosition = LatLng(
          initialPosition.latitude,
          initialPosition.longitude,
        );
        _route.add(_currentPosition!);
      });
    }

    _positionStreamSubscription =
        LocationService().getLocationStream().listen((Position position) {
      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _route.add(_currentPosition!);
      });
    });
  }

This:
- Gets the initial GPS position
- Subscribes to live location updates
- Appends each position to `_route` for drawing on the map

---

### Route Selection (Saved Routes)

Users can load previously recorded routes from the database and display them as a highlighted overlay.

.. code-block:: dart

  Future<void> _openRoutes() async {
    final selectedRoutePath = await Navigator.push<List<LatLng>?>(
      context,
      MaterialPageRoute(builder: (context) => const RoutesView()),
    );

    if (selectedRoutePath != null && mounted) {
      setState(() {
        _highlightedRoute = selectedRoutePath;
      });
    }
  }

This:
- Opens the saved routes screen
- Receives a selected route back
- Displays it as a “ghost trail” on the map

---

### Ending a Walk

When the user finishes a walk, the session data is passed into the summary screen.

.. code-block:: dart

  void _confirmEndWalk() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('End Walk?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SummaryScreen(
                      totalSteps: _sessionSteps,
                      route: _route,
                    ),
                  ),
                );
              },
              child: const Text('End Walk'),
            ),
          ],
        );
      },
    );
  }

This:
- Confirms user intent
- Stops the session
- Passes steps + route to summary view

---

### Map Rendering Overview

The map is rendered using `flutter_map` with:
- Live route (green polyline)
- Saved route (blue polyline)
- Current position marker

Key idea:
- `_route` = live walk
- `_highlightedRoute` = previously saved route
- `_currentPosition` = player marker


routes_view.dart
~~~~~~~~~~~~~~~~


The Routes screen displays a list of previously saved walking routes and allows the user to either view or delete them. It acts as a simple selection interface that returns a chosen route back to the Map screen for display as a highlighted path.

This screen is a `StatefulWidget` because it loads data from the database and updates dynamically when routes are deleted.

Key responsibilities:
- Load saved routes from the database
- Display route metadata (name + length)
- Allow route deletion
- Return a selected route back to the map

---

### Loading Saved Routes

Routes are fetched from the database when the screen is first opened.

.. code-block:: dart

  Future<void> _loadRoutes() async {
    try {
      final routes = await _routeService.getSavedRoutes(1);

      if (!mounted) return;

      setState(() {
        _savedRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _savedRoutes = [];
        _isLoading = false;
      });

      debugPrint('RoutesView: failed to load routes ($e)');
    }
  }

This:
- Queries saved routes for the user
- Stores them in `_savedRoutes`
- Handles errors safely with fallback empty state
- Prevents UI updates after disposal using `mounted`

---

### Route List Display

Saved routes are displayed using a `ListView.builder`, where each route is shown as a card with metadata and actions.

.. code-block:: dart

  ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _savedRoutes.length,
    itemBuilder: (context, index) {
      final route = _savedRoutes[index];

      return Card(
        child: ListTile(
          leading: const Icon(Icons.map, color: Colors.green),
          title: Text(
            route['route_name'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            '${(route['route_path'] as List).length} coordinate points',
          ),
        ),
      );
    },
  )

Each item shows:
- Route name
- Number of recorded GPS points
- Map icon for visual context

---

### Deleting a Route

Users can remove a saved route directly from the list.

.. code-block:: dart

  trailing: IconButton(
    icon: const Icon(Icons.delete, color: Colors.red),
    onPressed: () async {
      await _routeService.deleteRoute(route['route_id']);

      if (!mounted) return;
      _loadRoutes();
    },
  ),

This:
- Deletes the route from the database
- Refreshes the list after deletion
- Ensures UI consistency after changes

---

### Selecting a Route

When a route is tapped, its coordinate data is passed back to the Map screen.

.. code-block:: dart

  onTap: () {
    Navigator.pop(context, route['route_path']);
  },

This:
- Closes the Routes screen
- Returns the selected route (`List<LatLng>`-like structure)
- Enables the Map screen to display it as a highlighted path

---

### Screen States

The UI handles three states:
- Loading → spinner shown while fetching routes
- Empty → message shown if no routes exist
- Loaded → list of saved routes

This ensures a clean user experience even when no data is available.

summary_view.dart
~~~~~~~~~~~~~~~~~


The Summary screen is shown at the end of a walk session and displays the user’s route, step count, and a summary of their activity. It also allows the user to save the walk as a named route and return to the home screen.

This screen is a `StatefulWidget` because it handles database writes, user input (route naming), and UI state updates such as save confirmation.

Key responsibilities:
- Display completed walk route on a static map
- Show total steps for the session
- Generate a fun fact based on activity
- Save walk summary to database
- Save route with a custom name
- Return user to home screen

---

### Saving Walk Summary

When the screen loads, the walk is automatically saved to the database.

.. code-block:: dart

  Future<void> _saveWalkToDatabase() async {
    if (widget.route.isEmpty) return;

    final start = widget.route.first;
    final end = widget.route.last;

    final walkData = {
      'user_id': 1,
      'walk_date': DateTime.now().toIso8601String(),
      'total_steps': widget.totalSteps,
      'start_lat': start.latitude,
      'start_lng': start.longitude,
      'end_lat': end.latitude,
      'end_lng': end.longitude,
    };

    await AppDatabase.instance.insertWalkSummary(walkData);

    if (mounted) {
      setState(() => _isSaved = true);
    }
  }

This:
- Stores walk metadata (steps + coordinates)
- Records start and end points of the route
- Updates UI once saved successfully

---

### Route Map Display

The completed route is displayed using a static, non-interactive map.

.. code-block:: dart

  PolylineLayer(
    polylines: [
      Polyline(
        points: widget.route,
        strokeWidth: 6.0,
        color: const Color.fromARGB(255, 77, 151, 86),
      ),
    ],
  )

This:
- Draws the full completed route
- Centers the map on the last known position
- Disables interaction for review-only mode

A marker is also shown at the final position:

.. code-block:: dart

  Marker(
    point: widget.route.last,
    child: const Icon(Icons.location_on, color: Colors.red),
  )

---

### Fun Fact Generator

A simple helper function generates a message based on step count.

.. code-block:: dart

  String _generateFunFact(int steps) {
    double meters = steps * 0.762;
    int doubleDeckerBuses = (meters / 11.2).round();

    if (steps < 100) return "Just getting warmed up!";
    if (steps < 1000)
      return "You walked the length of $doubleDeckerBuses London buses!";
    return "Amazing! You covered ${meters.toStringAsFixed(1)} meters today!";
  }

This:
- Converts steps into approximate meters
- Provides contextual achievements based on distance
- Adds lightweight motivational feedback

---

### Route Saving with Name Input

Users can save their walk as a named route for later viewing in `RoutesView`.

.. code-block:: dart

  GreenButton(
    buttonText: "Save as Route",
    onPressed: () async {
      String routeName = '';

      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Name your Route'),
          content: TextField(
            onChanged: (val) => routeName = val,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, routeName),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (name != null && name.isNotEmpty) {
        await RouteService().saveRoute(1, name, widget.route);

        await checkAndUnlockTrailBlazer(context, 1);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Route "$name" saved!')),
          );
        }
      }
    },
  )

This:
- Prompts the user to name their route
- Saves route coordinates + name to database
- Triggers achievement check (`Trail Blazer`)
- Confirms success with a SnackBar

---

### Navigation Back to Home

.. code-block:: dart

  GreenButton(
    buttonText: "Return Home",
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyHomePage(title: 'FLittle Guy'),
        ),
        (route) => false,
      );
    },
  )

This:
- Clears navigation stack
- Returns user to the main app screen
- Prevents back-navigation to summary screen

---

### Screen State

The screen also tracks whether the walk has been saved:

- `_isSaved = true` → shows confirmation message
- `_isSaved = false` → waiting for database write

This provides clear feedback that the walk has been successfully recorded.

community_view.dart
~~~~~~~~~~~~~~~~~~~

The Community screen with a social feed and leaderboard. Currently only has the UI not the backend. The primary way your supposed to add people is by name at the top, then you can see them below the add button. Then development after that can expand on that foundation.

The reason this was cut instead of profile is because it doesnt interact with the core progression of the game (you do steps, you get rewarded).

.. code-block:: dart

  Future<List<Map<String, dynamic>>> _loadFriends() async {
    return [
      {"username": "meowmeowmeowmeowmeowmeow", "steps": "100000"},
      {"username": "BigGamer", "steps": "3000000"},
      {"username": "TotallyTofit", "steps": "0"},
      {"username": "XXX_littlestguy_XXX", "steps": "10"},
      {"username": "XXX_littlestguy_XXX", "steps": "10"},
      {"username": "XXX_littlestguy_XXX", "steps": "10"},
    ];
  }

The way the current code works is first making a list used as a placeholder for the DB. We can replace this later with less hassel then most alternative methods.

.. code-block:: dart

  Expanded(
    child: ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        return Container(
          margin: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 16,
          ),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 200, height: 100, child: LittleGuy()),
              const SizedBox(height: 8),
              Divider(
                color: const Color.fromARGB(255, 213, 248, 255),
                thickness: 1,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  friend['username'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  const Text("Steps: "),
                  Text(
                    friend['steps'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  ),

This is part of the code that uses the above list to show all the users using the usefully named ListView.builder().

feed_view.dart
~~~~~~~~~~~~~~

The feed page is used to allow the user to chose the food they would like to feed the little guy, then to do so.

.. code-block:: dart

  Future<void> _useFood(int foodId, int petId, int userId) async {
    // Look up the food row defensively — if the inventory has changed
    // between render and tap (e.g. a shop purchase mutated _food), we
    // treat a missing entry as "quantity 0" and bail rather than throw.
    final foodItem = _food.firstWhere(
      (item) => item['item_id'] == foodId,
      orElse: () => const <String, dynamic>{'quantity': 0},
    );
    if ((foodItem['quantity'] as int) <= 0 || _hunger >= 1.0) {
      return;
    }

    // Update inventory (consume food)
    await _foodDB.useFood(foodId, userId);

    // Calculate new hunger value (capped at 1.0)
    double newHunger = (_hunger + 0.2) > 1.0 ? 1.0 : _hunger + 0.2;

    // Update pet's hunger in database
    await _petStatsDB.updatePetStat(petId, 'hunger_level', newHunger);

    // Grant XP (5 XP per feeding)
    final db = await AppDatabase.instance.database;
    final levelService = LevelService(db);
    final levelResult = await levelService.addXp(userId, 5);

    // Refresh UI
    await _loadPetHunger();

    // Show level‑up snackbar if needed
    if (levelResult['leveledUp'] == 1 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your Little Guy reached level ${levelResult['level']}!',
          ),
        ),
      );
    }
  }

Here, one of the things _useFood passes through is foodId, so that when the user selects a food, it send to _useFood. await _foodDB.useFood, actually does the decreasing by one of the food, then it calculates the new hunger, and updates the stats using _petStatsDB.updatePetStat.

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

The Settings screen allows the user to update basic profile information such as their username and pet name, as well as adjust simple app preferences like notifications and UI scaling. It is implemented as a `StatefulWidget` because it manages form input state and loads data from the database.

Key responsibilities:
- Load and display user + pet names from database
- Allow editing and saving of profile data
- Toggle simple app settings (notifications, slider preference)
- Persist changes back to SQLite

---

### Loading User and Pet Data

When the screen loads, it fetches existing values from the database and populates the text fields.

.. code-block:: dart

  Future<void> _loadData() async {
    try {
      final userName = await _db.getUserName(_userId);
      final petName = await _db.getPetName(_userId);

      if (!mounted) return;

      setState(() {
        _userNameController.text = userName ?? '';
        _petNameController.text = petName ?? '';
      });
    } catch (e) {
      debugPrint('Settings: could not load user/pet data ($e)');
    }
  }

This:
- Retrieves stored user and pet names
- Safely updates UI after async database calls
- Handles missing data (new user flow) without crashing

---

### Editable Profile Fields

The screen uses `TextField` controllers to allow direct editing of stored values.

.. code-block:: dart

  TextField(
    controller: _petNameController,
    decoration: const InputDecoration(
      labelText: 'Pet name',
      prefixIcon: Icon(Icons.pets),
    ),
  )

  TextField(
    controller: _userNameController,
    decoration: const InputDecoration(
      labelText: 'User name',
      prefixIcon: Icon(Icons.person),
    ),
  )

These fields:
- Reflect current database values
- Allow inline editing before saving
- Are cleared safely using `dispose()`

---

### Notification Toggle

A simple switch is used to enable or disable notifications (UI-only in current implementation).

.. code-block:: dart

  Switch(
    value: _switchBtn,
    onChanged: (bool value) {
      setState(() {
        _switchBtn = value;

        if (_switchBtn) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notifications enabled')),
          );
        }
      });
    },
  )

This:
- Toggles local boolean state
- Provides immediate user feedback via SnackBar
- Does not yet persist to database (future improvement point)

---

### Slider Setting (UI Preference)

A slider is used for adjusting a UI preference value (currently labelled as font size/volume depending on implementation).

.. code-block:: dart

  Slider(
    value: _soundVolume,
    min: 0,
    max: 1,
    onChanged: (double value) {
      setState(() {
        _soundVolume = value;
      });
    },
  )

This:
- Updates a continuous value in real time
- Provides immediate visual feedback
- Currently stored only in local state

---

### Saving Settings to Database

When the user taps “Submit”, updated values are written back to SQLite.

.. code-block:: dart

  GreenButton(
    buttonText: "Submit",
    onPressed: () async {
      await _db.updateUserName(_userId, _userNameController.text);
      await _db.updatePetName(_userId, _petNameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    },
  )

This:
- Persists user and pet name changes
- Updates database records via `PetStatsDatabase`
- Confirms success with feedback message

---

### Screen State Management

The screen manages three main types of state:
- Text controllers → user/pet names
- `_switchBtn` → notification toggle
- `_soundVolume` → slider value

It also ensures:
- Controllers are disposed properly
- Async database updates do not trigger UI after disposal (`mounted` checks)

---

If you want, I can next:
- make all your View docs consistent in tone/length (so they look like one polished dissertation section)
- or compress everything into a “final submission-ready” version

test_view.dart
~~~~~~~~~~~~~~

Test view is only for developers testing steps and the goal, without this there wouldn't be a way to add steps beyond, taking a walk.

It is also used to test the level up system, since it a step gives xp.

.. code-block:: dart
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Total Steps:', style: TextStyle(fontSize: 24)),
            Text(
              '$_totalSteps',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              'Current Steps: ${_goalController.currentSteps}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: ${_goalController.stepGoal}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text('Currency: $_currency', style: const TextStyle(fontSize: 20)),
            Text(
              'Steps toward next goal: ${(_goalController.stepGoal - _totalSteps).clamp(0, double.infinity).toInt()}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _recordTestSteps(1),
              child: const Text('Record 1 Step'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _recordTestSteps(250),
              child: const Text('Record 250 Steps'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newGoal = _goalController.stepGoal + 250;
                await _goalController.updateGoal(newGoal);

                setState(() {
                  _goalController.stepGoal = newGoal;
                });
              },
              child: const Text('Increase Goal by 250'),
            ),

            const SizedBox(height: 12),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

Widgets
-------

progress_bar.dart
~~~~~~~~~~~~~~~~~

A reusable widget that renders a filled progress bar, used to display the pet's hunger, hygiene, and enjoyment stats.

Widget Parameters
^^^^^^^^^^^^^^^^^

The progress_bar constructor requires two parameters:

- progress: the current progress for bar.
- iconPath: the image used for the left side of the row.


Code
^^^^
.. code-block:: dart

  class _ProgressBarState extends State<ProgressBar> {
    @override
    Widget build(BuildContext context) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Image.asset(widget.iconPath),
          ),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: Color.fromARGB(255, 248, 255, 233,),
              color: Color.fromARGB(255, 159, 239, 167),
              minHeight: 10,
              borderRadius: const BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          )
        ],
      );
    }
  }

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

Usage Example
^^^^^^^^^^^^^

.. code-block:: dart
  
  child: ProgressBar(
    iconPath: 'assets/images/enjoyment.png',
    progress: _enjoyment,
  ),

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

The Little Guy file contains the core animated character system used throughout the app. It defines the main idle walking pet, as well as two interaction animations: cleaning and petting.

This file is built around Flutter’s animation system (`AnimationController` + `TweenSequence`) and responds to external state changes such as equipped hats via `HatState`.

Key responsibilities:
- Render the main Little Guy character
- Animate idle walking movement
- Display equipped hats on top of the character
- Provide cleaning animation (soap, bubbles, rain)
- Provide petting animation (scale bounce effect)

---

## Little Guy (Idle Character + Hat System)

The main `LittleGuy` widget is the default animated pet shown across screens.

It listens to `HatState` so that any hat changes immediately update the rendered character.

.. code-block:: dart

  void _onHatChanged() => setState(() {});

  @override
  void initState() {
    super.initState();

    HatState.instance.addListener(_onHatChanged);
    HatState.instance.loadFromDb();
  }

This:
- Subscribes to hat updates globally
- Reloads equipped hat from database on startup
- Triggers rebuild when hat changes

---

### Idle Walking Animation

The character continuously moves left and right using a repeating animation controller.

.. code-block:: dart

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  _walkAnimation = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 30.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(30.0), weight: 10),
    TweenSequenceItem(
      tween: Tween(begin: 30.0, end: -30.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 25,
    ),
    TweenSequenceItem(tween: ConstantTween(-30.0), weight: 10),
    TweenSequenceItem(
      tween: Tween(begin: -30.0, end: 0.0)
          .chain(CurveTween(curve: Curves.easeInOut)),
      weight: 30,
    ),
  ]).animate(_controller);

This creates a smooth looping walk cycle across the screen.

---

### Character Rendering + Hat Overlay

The character is drawn using a `Stack`, with an optional hat rendered above it.

.. code-block:: dart

  final hatPath = HatState.instance.equippedHatPath;

  Stack(
    alignment: Alignment.center,
    children: [
      Image.asset('assets/images/funnyguy.png', width: 180),

      if (hatPath != null)
        Positioned(
          top: -20,
          child: Image.asset(hatPath, width: 90),
        ),
    ],
  )

This:
- Renders base pet sprite
- Overlays equipped hat (if any)
- Keeps hat aligned above head position

---

## Cleaning Animation (CleaningLittleGuy)

The `CleaningLittleGuy` widget plays a multi-stage animation when the pet is cleaned:
- Soap movement
- Bubble fade-in/out
- Rain wash effect

It is triggered externally using a `ValueNotifier<bool>`.

---

### Trigger System

.. code-block:: dart

  void _onTrigger() {
    if (widget.trigger.value) {
      startCleaningAnimation();
      widget.trigger.value = false;
    }
  }

This:
- Listens for external trigger events
- Starts animation once
- Resets trigger to prevent repeats

---

### Cleaning Animation Controller

The cleaning animation is split into timed phases using intervals:

.. code-block:: dart

  _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

This drives:
- Soap movement across the screen
- Bubble opacity changes
- Rain effect at the end

---

### Visual Effects

Soap movement:

.. code-block:: dart

  Transform.translate(
    offset: Offset(_soapAnimationX.value, _soapAnimationY.value),
    child: Image.asset('assets/images/hygiene.png', width: 50),
  )

Bubbles fade in/out:

.. code-block:: dart

  Opacity(
    opacity: _bubbleOpacityAnimation.value,
    child: Image.asset('assets/images/bubbles.png', width: 360),
  )

Rain effect:

.. code-block:: dart

  Transform.translate(
    offset: Offset(0, _rainFallAnimation.value),
    child: Image.asset('assets/images/rain.png', width: 360),
  )

This creates a full “wash cycle” animation.

---

## Petting Animation (PetLittleGuy)

The `PetLittleGuy` widget handles interaction when the user taps the pet. It creates a simple bounce/scale animation.

---

### Pet Trigger System

.. code-block:: dart

  void _onTrigger() {
    if (widget.trigger.value) {
      startPettingAnimation();
      widget.trigger.value = false;
    }
  }

This:
- Listens for tap events from parent screen
- Triggers animation once per tap
- Resets trigger flag

---

### Pet Animation

.. code-block:: dart

  _petAnimation = TweenSequence([
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.7),
      weight: 3,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 0.7, end: 1.1),
      weight: 2,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.1, end: 1.0),
      weight: 1,
    ),
  ]).animate(_controller);

This produces a:
- Squash effect (down)
- Stretch effect (up)
- Return to normal size

---

### Final Output

The pet is rendered using scale transformation:

.. code-block:: dart

  Transform.scale(
    scaleY: _petAnimation.value,
    child: Image.asset('assets/images/funnyguy.png', width: 360),
  )

---

## Summary

This file acts as the **core visual engine of the app’s mascot system**, handling:
- Idle movement
- Equipment overlays (hats)
- Interaction animations (cleaning + petting)

It is designed to be fully reactive, meaning all visual changes are driven by state (`HatState` + triggers) rather than manual UI refresh calls.
