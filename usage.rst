Usage
=====

Installation
------------

Prerequisites
~~~~~~~~~~~~~

- Flutter SDK (≥ 3.x)
- Dart SDK
- Android Studio or Xcode (for device deployment)
- A physical or emulated device with a step-counter sensor

Getting Started
~~~~~~~~~~~~~~~

1. Clone the repository::

    git clone https://github.com/Team1C-T-P/little_guy_proj.git
    cd little_guy_proj

2. Install dependencies::

    flutter pub get

3. Run on a connected device::

    flutter run

Granting Permissions
--------------------

When the app first launches you will be prompted to grant **Activity Recognition** (Android) or **Motion & Fitness** (iOS) permissions. These are required for the step counter to function. Without them, steps will not be tracked and no in-game currency will be earned.

Setting Up Your Profile
-----------------------

On first launch you will be taken to the **Setup Profile** screen:

- Enter your username.
- Give your Little Guy a name.
- Set your initial daily step goal (default: 250 steps).

Your profile is stored locally in a SQLite database — no account or internet connection is required.

Core Gameplay Loop
------------------

1. **Walk** — your device's pedometer records steps automatically in the background.
2. **Earn currency** — every 100 steps converts to 1 coin (configurable via ``StepPointsService``).
3. **Care for your pet** — spend currency in the Shop to buy food and keep your Little Guy's hunger, hygiene, and enjoyment stats up.
4. **Level up** — earn XP to level your pet. Every 100 XP grants a new level.
5. **Customise** — buy hats and accessories from the Shop and equip them in the Dress screen.

Daily Step Goal
---------------

You can view and update your daily step goal from the **Settings** screen or **Profile** screen. The goal resets each week. Reaching your goal awards bonus XP.

Navigation
----------

The app uses a bottom navigation bar with the following sections:

- **Home** — pet overview and current stats
- **Map** — record and replay walking routes
- **Shop** — spend coins on food and accessories
- **Community** — social feed and leaderboard
- **Profile** — stats, achievements, and settings

Stat Degradation
----------------

Your pet's stats (hunger, hygiene, enjoyment) degrade automatically over time. The ``StatDegradationService`` runs on app launch and compares the current time against ``last_online`` to calculate how much each stat should decrease. Log in regularly to keep your Little Guy healthy!
