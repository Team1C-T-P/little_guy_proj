Welcome to Little Guy Documentation
=====================================

Little Guy is a Flutter mobile app that uses real-world walking steps as in-game currency to care for a virtual pet, play mini-games, and customise your companion with accessories.

Building
--------

Make sure you have an up to date Flutter SDK.

First begin by cloning the repo::

    git clone https://github.com/Team1C-T-P/little_guy_proj.git

Once this has been done open the terminal in the project directory.

If it's the first time setup run::

    flutter pub get

to retrieve all packages. If packages are out of date, use::

    flutter pub upgrade

Then you can run::

    flutter run

to launch the app on a connected device or emulator.

Dependencies
------------

These are the associated packages that the application interacts with. These will automatically be installed and applied upon running ``pubspec.yaml``. If you are building from the files, you need to make sure your Flutter SDK is up to date and linked to your IDE.

.. code-block:: yaml

    flutter:
      sdk: flutter

    sqflite:         # local SQLite database
    path:            # database path resolution
    provider:        # state management
    flame:           # game engine for pet animations
    pedometer:       # step counting
    latlong2:        # GPS coordinate handling
    # Add remaining packages from pubspec.yaml here

Contents
--------

.. toctree::
   :maxdepth: 2

   backend
   frontend
