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

The bottom navigation bar that provides access to the app's five main sections: Home, Map, Shop, Community, and Profile.

.. note::
   Add detail on how the selected index is managed and how navigation between pages is handled.

.. code-block:: dart

    // Add relevant code snippet here

header.dart
~~~~~~~~~~~

.. note::
   Add a description of the shared header widget used across screens (e.g. app bar content, step count display, currency display).

.. code-block:: dart

    // Add relevant code snippet here

setup_profile_view.dart
~~~~~~~~~~~~~~~~~~~~~~~

The first screen a new user sees. Allows the user to enter their username, name their Little Guy, and set an initial daily step goal.

.. note::
   Add detail on input validation and how the profile data is persisted on submission.

.. code-block:: dart

    // Add relevant code snippet here

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
