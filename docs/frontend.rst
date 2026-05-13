Frontend
========

Overview
--------

The front end of this application has been standardised across screens with a consistent design language. This page covers design choices and the inner workings of each view and widget file.

Fonts
~~~~~

.. note::
   Add the font family and version used in the app here (e.g. Google Fonts package, custom assets).

Colours
~~~~~~~

.. note::
   Add the colour palette for both light and dark mode here, including primary, secondary, background, and error colours in hex or ARGB format.

Iconography
~~~~~~~~~~~

Icons in the application are taken from Flutter's default ``material.dart`` iconography package.

.. note::
   Add details of any custom icons or assets used (e.g. pet sprites, hat images, achievement badges) and where they are stored in ``assets/``.

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

The Shop screen where users spend coins on food and accessories. Items are fetched from the database and displayed in a grid, with owned items marked accordingly.

.. note::
   Add detail on how the purchase flow is triggered and how the UI updates after a successful purchase.

.. code-block:: dart

    // Add relevant code snippet here

dress_view.dart
~~~~~~~~~~~~~~~

The Dress screen where users equip and unequip hats and accessories on their Little Guy. Changes are reflected immediately on the pet sprite via ``HatState``.

.. note::
   Add detail on how the hat grid is built and how ``HatState.equipHat`` / ``HatState.unequipHat`` are called.

.. code-block:: dart

    // Add relevant code snippet here

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

The Profile screen showing the user's lifetime stats, achievements, and settings shortcuts.

.. note::
   Add detail on which stats are shown, how achievements are displayed, and what navigation options are available.

.. code-block:: dart

    // Add relevant code snippet here

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

A reusable styled button widget used throughout the app to maintain a consistent button appearance without duplicating code.

.. note::
   Add detail on the parameters accepted (e.g. label, onPressed callback, style variant) and usage examples.

.. code-block:: dart

    // Add relevant code snippet here

little_guy.dart
~~~~~~~~~~~~~~~

The core Flame game widget that renders the animated Little Guy sprite, including any equipped hat overlay.

.. note::
   Add detail on the Flame component structure, how animations are triggered, and how ``HatState`` changes cause a re-render.

.. code-block:: dart

    // Add relevant code snippet here
