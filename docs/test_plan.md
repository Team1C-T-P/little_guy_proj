# Backend Test Plan

## Overview

This plan covers automated backend unit tests for the Little Guy app, organised by **User Requirement (UR) → Functional Requirement (FR) → Partition**. UI tests are out of scope (kept as-is in `test/views/`, no additions).

- **6 User Requirements** identified from the app's behaviour
- **~139 partition tests** across **47 backend functions**
- **~87 brand-new tests** + **~29 existing tests** to have `TR-XXX-NN` codes added in-place
- Existing TR codes (`TR-RT`, `TR-SUM`, `TR-STP`, `TR-UI`) preserved unchanged

## User Requirements

| # | User Requirement | TR prefix(es) |
|---|---|---|
| UR1 | A user should be able to have a profile and update it | `TR-PRF` |
| UR2 | A user should be able to have a pet and update its name, stats, level, and hats | `TR-PET`, `TR-LVL`, `TR-DRS` |
| UR3 | A user should be able to track their walks and save GPS routes | `TR-STP`, `TR-RT` |
| UR4 | A user should be able to see summaries of their recent and best walks | `TR-SUM` |
| UR5 | A user should be able to set a daily step goal and earn rewards for completing it | `TR-GOAL` |
| UR6 | A user should be able to buy items from the shop and use them from their inventory | `TR-INV`, `TR-SHOP` |

## Input / output annotation style

Every variable in Input / Expected Output columns is followed by parenthetical meaning so a reader knows **why** that value was chosen, not just **what** it is:

- ✅ `userId = 999 (no row with this id in the user table)`
- ✅ `newName = '' (empty string - signals "keep current value")`
- ❌ `UserID = 999` *(raw value, no meaning given)*

---

## Full test table

| User Requirement | Functional Requirement | Partition | Input | Expected Output | Description | V/I |
|---|---|---|---|---|---|---|
| A user should be able to have a profile and update it | getUserName - get a user's stored name by their id | Valid userId | userId = 1 (seeded test user that exists in the user table) | Returns 'Test User' (the user_name stored for userId 1) | [TR-PRF-01] Verifies getUserName returns the stored username when the userId exists | V |
|  |  | Invalid userId | userId = 999 (no row with this id exists) | Throws Exception('Failed to get user name: User not found') | [TR-PRF-02] Verifies getUserName throws when the userId has no matching row | I |
|  | updateUserName - update a user's stored name | Valid user + non-empty new name | userId = 1 (existing user) \| newName = 'Alice' (non-empty replacement) | user_name column updated to 'Alice' | [TR-PRF-03] Verifies updateUserName writes the new name when both inputs are valid | V |
|  |  | Valid user + empty new name | userId = 1 (existing user) \| newName = '' (empty string - early-return signal) | No change to row; user_name remains 'Test User' (silent no-op via early return) | [TR-PRF-04] Verifies updateUserName treats empty string as "keep current" rather than overwriting | V |
|  |  | Invalid user + non-empty new name | userId = 999 (no such user) \| newName = 'Alice' (non-empty) | Throws Exception('Failed to update user name: User not found') | [TR-PRF-05] Verifies updateUserName throws when no row matches the userId | I |
|  |  | Invalid user + empty new name | userId = 999 (no such user) \| newName = '' (empty string) | Silent no-op - empty-string early return runs before the user existence check | [TR-PRF-06] Verifies the empty-string short-circuit fires even when the userId is invalid (documents current behaviour) | V |
|  | getLastOnlineByUserId - get when a user was last online | Valid userId | userId = 1 (existing user) | Returns '2026-01-01T00:00:00Z' (the last_online ISO string stored for userId 1) | [TR-PRF-07] Verifies getLastOnlineByUserId returns the stored ISO timestamp | V |
|  |  | Invalid userId | userId = 999 (no such user) | Throws Exception('Failed to get last online time: User not found') | [TR-PRF-08] Verifies getLastOnlineByUserId throws when the userId has no matching row | I |
|  | updateLastOnlineByUserId - manually update a user's last-online timestamp | Valid user + valid ISO date | userId = 1 (existing user) \| isoDate = '2026-05-11T12:00:00Z' (valid ISO-8601 string) | last_online column updated to '2026-05-11T12:00:00Z' | [TR-PRF-09] Verifies updateLastOnlineByUserId writes the new timestamp when both inputs are valid | V |
|  |  | Valid user + malformed date | userId = 1 (existing user) \| isoDate = 'not an iso date' (unparseable string) | Throws Exception('Failed to update last online time: Invalid ISO date format') | [TR-PRF-10] Verifies the DateTime.parse guard rejects malformed input | I |
|  |  | Invalid user + valid ISO date | userId = 999 (no such user) \| isoDate = '2026-05-11T12:00:00Z' (valid ISO) | Throws Exception('Failed to update last online time: User not found') | [TR-PRF-11] Verifies updateLastOnlineByUserId throws when no row matches | I |
|  |  | Invalid user + malformed date | userId = 999 (no such user) \| isoDate = 'not an iso date' (unparseable) | Throws Exception('Failed to update last online time: Invalid ISO date format') (parse runs first) | [TR-PRF-12] Verifies the parse guard runs before the user-existence check | I |
|  | LastOnlineUpdater.update - refresh a user's last-online to 'now' | Valid user | userId = 1 (existing user) | last_online column updated to the current ISO timestamp; 1 row affected | [TR-PRF-13] Verifies the static helper updates the user row with DateTime.now() | V |
|  |  | Invalid user | userId = 999 (no such user) | No exception; sqflite update returns 0 (no rows affected) | [TR-PRF-14] Verifies the helper fails silently on a missing user (current behaviour - no exception path) | I |
|  | userExists - check whether any user account exists in the database | User table has rows | (no input) - user table seeded with at least one user | Returns true | [TR-PRF-15] Verifies userExists returns true when the user table is non-empty | V |
|  |  | User table empty | (no input) - user table empty | Returns false | [TR-PRF-16] Verifies userExists returns false when the user table has no rows | V |
| A user should be able to have a pet and update its name, stats, level, and hats | getPetName - get the pet's name | Valid userId | userId = 1 (user with a seeded little_guy row) | Returns 'Buddy' (the little_guy_name for userId 1) | [TR-PET-01] Verifies getPetName returns the stored pet name when the userId has a pet | V |
|  |  | Invalid userId | userId = 999 (no little_guy row for this user) | Throws Exception('Failed to get pet name: Pet not found') | [TR-PET-02] Verifies getPetName throws when the user has no pet | I |
|  | updatePetName - update the pet's name | Valid user + non-empty new name | userId = 1 (existing user) \| newName = 'Sparky' (non-empty replacement) | little_guy_name column updated to 'Sparky' | [TR-PET-03] Verifies updatePetName writes the new pet name when both inputs are valid | V |
|  |  | Valid user + empty new name | userId = 1 (existing user) \| newName = '' (empty - early-return signal) | No change; little_guy_name remains 'Buddy' | [TR-PET-04] Verifies updatePetName treats empty string as "keep current" | V |
|  |  | Invalid user + non-empty new name | userId = 999 (no such user) \| newName = 'Sparky' (non-empty) | Throws Exception('Failed to update pet name: Pet not found') | [TR-PET-05] Verifies updatePetName throws when no row matches | I |
|  |  | Invalid user + empty new name | userId = 999 (no such user) \| newName = '' (empty) | Silent no-op - empty-string early return runs first | [TR-PET-06] Verifies the empty-string short-circuit fires before the existence check (current behaviour) | V |
|  | getPetStat - read one of the pet's stats (hunger / hygiene / enjoyment) | Valid pet + valid stat name | petId = 1 (existing pet) \| stat = 'hunger_level' (one of the allowed stats) | Returns 0.5 (hunger_level stored as 50; method divides by 100) | [TR-PET-07] Verifies getPetStat returns the stat value scaled to 0.0-1.0 | V |
|  |  | Valid pet + invalid stat name | petId = 1 (existing pet) \| stat = 'unknown_stat' (not in the allowed-stats whitelist) | Throws Exception('Stat does not exist') | [TR-PET-08] Verifies the allowed-stats whitelist rejects unknown stat names before querying | I |
|  |  | Invalid pet + valid stat name | petId = 999 (no such pet) \| stat = 'hunger_level' (valid) | Returns 0.0 (graceful fallback when query returns no rows) | [TR-PET-09] Verifies getPetStat returns 0 for missing pet rather than throwing | I |
|  |  | Invalid pet + invalid stat name | petId = 999 (no such pet) \| stat = 'unknown_stat' (invalid) | Throws Exception('Stat does not exist') (whitelist runs first) | [TR-PET-10] Verifies the whitelist runs before the pet lookup | I |
|  | updatePetStat - update one of the pet's stats (clamped to the 0.0-1.0 range) | Valid pet + value in bounds | petId = 1 (existing pet) \| stat = 'hunger_level' (valid) \| value = 0.75 (within 0.0-1.0) | hunger_level column updated to 75 (the 0-100 integer form) | [TR-PET-11] Verifies updatePetStat writes the exact scaled value when inputs are valid | V |
|  |  | Valid pet + value below 0 | petId = 1 (existing pet) \| stat = 'hunger_level' (valid) \| value = -0.5 (below lower bound) | hunger_level clamped to 0 (lower boundary) | [TR-PET-12] Verifies updatePetStat clamps an under-range value to the lower bound rather than throwing | V |
|  |  | Valid pet + value above 1 | petId = 1 (existing pet) \| stat = 'hunger_level' (valid) \| value = 1.5 (above upper bound) | hunger_level clamped to 100 (upper boundary) | [TR-PET-13] Verifies updatePetStat clamps an over-range value to the upper bound rather than throwing | V |
|  |  | Invalid pet + valid stat | petId = 999 (no such pet) \| stat = 'hunger_level' (valid) \| value = 0.5 (in bounds) | Throws Exception('Failed to update pet stat: One or more argument is invalid') | [TR-PET-14] Verifies updatePetStat throws when no pet row matches | I |
|  | degradeStats - decay the pet's stats based on time since the user was last online | Last online less than 2 hours ago | lastOnline = DateTime.now() (<=1 hour ago) \| stats all at 0.5 | Stats unchanged or near-unchanged; small decay (e.g. 0.5 stays approximately 0.5) | [TR-PET-15] Verifies degradeStats applies minimal decay for recent activity | V |
|  |  | Last online 4 hours ago | lastOnline = (4 hours before now) \| stats all at 0.5 | Each stat decayed by 0.2 (0.1 x 4/2); stats now 0.3 | [TR-PET-16] Verifies degradeStats applies the correct linear decay formula | V |
|  |  | Stats clamp to 0 lower bound | lastOnline = (10 hours before now) \| stats all at 0.1 (already near zero) | Stats clamped to 0.0 (cannot go negative) | [TR-PET-17] Verifies degradeStats clamps stats at the lower bound of 0 | V |
|  |  | Last online in future | lastOnline = (1 hour ahead of now) | Throws Exception('Failed to degrade stats: Last online time is in the future') | [TR-PET-18] Verifies degradeStats rejects future timestamps as invalid input | I |
|  | getLevelAndXp - read the pet's current level and xp | Valid userId | userId = 1 (existing pet) | Returns {'level': 3, 'xp': 40} (the stored values) | [TR-LVL-01] Verifies getLevelAndXp returns the stored level and xp | V |
|  |  | Invalid userId | userId = 999 (no pet row) | Returns {'level': 1, 'xp': 0} (graceful default, no throw) | [TR-LVL-02] Verifies getLevelAndXp returns the default starting state when no pet exists | I |
|  | addXp - award xp to the pet (handles level-ups when xp crosses 100) | Total xp stays below 100 | userId = 1 \| starting xp = 30 \| gainedXp = 40 (30+40 < 100) | Returns {'level': unchanged, 'xp': 70, 'leveledUp': 0}; no level-up | [TR-LVL-03] Verifies addXp accumulates xp without levelling when the total is below 100 | V |
|  |  | Total xp reaches exactly 100 | userId = 1 \| starting xp = 60 \| gainedXp = 40 (60+40 = 100) | Returns {'level': +1, 'xp': 0, 'leveledUp': 1}; level up, xp resets | [TR-LVL-04] Verifies addXp levels up and resets xp to 0 at the exact boundary of 100 | V |
|  |  | Total xp exceeds 100 by some amount | userId = 1 \| starting xp = 80 \| gainedXp = 50 (80+50 = 130) | Returns {'level': +1, 'xp': 30, 'leveledUp': 1}; leftover xp preserved | [TR-LVL-05] Verifies addXp levels up once and carries the leftover xp forward | V |
|  |  | Total xp >= 200, multi level-up | userId = 1 \| starting xp = 50 \| gainedXp = 250 (50+250 = 300) | Returns {'level': +3, 'xp': 0, 'leveledUp': 1}; loop levels up three times | [TR-LVL-06] Verifies addXp loops correctly when one gain spans multiple level boundaries | V |
|  | setLevelAndXp - set the pet's level and xp directly (for admin / testing) | Valid update | userId = 1 \| level = 10 \| xp = 50 | little_guy row updated to level=10, xp=50 | [TR-LVL-07] Verifies setLevelAndXp writes the values directly without any branching | V |
|  | getHatsOwnedByUser - list the hats a user owns | User owns hats | userId = 1 (inventory has 3 hat items linked to user 1) | Returns a List<Map> with 3 rows (item_id, item_name, image_path, price, type for each hat) | [TR-DRS-01] Verifies getHatsOwnedByUser returns all hat-type items in the user's inventory | V |
|  |  | User owns no hats | userId = 1 (inventory empty for this user) | Returns an empty list | [TR-DRS-02] Verifies getHatsOwnedByUser returns empty when the user has no hats | V |
|  | equipHat - put a hat on the pet (replacing any current hat) | Pet has no hat equipped | littleGuyId = 1 (no row in little_guy_wearing) \| itemId = 5 (a hat) | little_guy_wearing row inserted with (1, 5) | [TR-DRS-03] Verifies equipHat inserts when nothing is currently equipped | V |
|  |  | Pet has a hat already | littleGuyId = 1 (row exists with itemId=2) \| itemId = 5 (new hat) | Previous row deleted; new row (1, 5) inserted (swap) | [TR-DRS-04] Verifies equipHat removes the existing hat then inserts the new one | V |
|  | unequipHat - take the pet's hat off | Pet has a hat | littleGuyId = 1 (row exists in little_guy_wearing) | Row removed; subsequent getEquippedHat returns null | [TR-DRS-05] Verifies unequipHat removes the equipped row | V |
|  |  | Pet has no hat | littleGuyId = 1 (no row in little_guy_wearing) | No exception; table state unchanged (silent no-op) | [TR-DRS-06] Verifies unequipHat does not throw when nothing is equipped | V |
|  | getEquippedHat - get the hat the pet is currently wearing | Pet has a hat equipped | littleGuyId = 1 (row exists with item 5) | Returns {'item_id': 5, 'image_path': '...'} | [TR-DRS-07] Verifies getEquippedHat returns the equipped hat's id and image_path | V |
|  |  | Pet has no hat | littleGuyId = 1 (no row in little_guy_wearing) | Returns null | [TR-DRS-08] Verifies getEquippedHat returns null when nothing is equipped | V |
|  | countUserHats - count how many hats the user owns | User owns N hats | userId = 1 (inventory has 5 hat rows linked to this user) | Returns 5 (the count) | [TR-DRS-09] Verifies countUserHats returns the correct count of hat-type inventory rows | V |
|  |  | User owns no hats | userId = 1 (no hat rows in inventory) | Returns 0 (graceful, no throw) | [TR-DRS-10] Verifies countUserHats returns 0 when the user owns no hats | V |
| A user should be able to track their walks and save GPS routes | StepCounter.addStep - increment the in-memory step counter by one | Add three steps from zero | starting stepCount = 0 \| addStep() called three times | stepCount = 3; a second reference to the singleton returns the same value | [TR-STP-01] Verifies the StepCounter singleton increments correctly and state persists across references | V |
|  |  | Add 100 steps | starting stepCount = 0 \| addStep() called 100 times | stepCount = 100 | [TR-STP-02] Verifies a large number of increments accumulate correctly | V |
|  |  | Reset to 0 (lower boundary) | starting stepCount = 2 \| stepCount = 0 assigned directly | stepCount = 0; reset visible across singleton references | [TR-STP-03] Verifies the singleton can be reset to its lower boundary | V |
|  | StepPointsService.recordSteps - record steps taken and convert them into currency (1 point per 100 steps) | Negative steps rejected | userId = 1 (existing) \| steps = -10 (negative - below the >0 rule) | Throws ArgumentError (steps must be > 0) | [TR-STP-04] Verifies recordSteps rejects negative input | I |
|  |  | Non-existent user | userId = 101 (no such user) \| steps = 100 (positive) | Throws StateError ('User with id 101 does not exist') | [TR-STP-05] Verifies recordSteps throws when the user does not exist | I |
|  |  | Steps below conversion threshold | userId = 1 \| steps = 50 (less than stepsPerPoint=100, so no points awarded) | unconvertedSteps = 50, updatedCurrency = 0 | [TR-STP-06] Verifies recordSteps accumulates unconverted steps when below the conversion threshold | V |
|  |  | Steps exceed conversion threshold | userId = 1 \| steps = 150 (1 point + 50 leftover) | unconvertedSteps = 50, updatedCurrency = 1 | [TR-STP-07] Verifies recordSteps converts steps to currency at 100:1 with leftover preserved | V |
|  | StepPointsService.awardBonusPoints - award currency directly (e.g. for a one-off bonus) | Valid user + positive points | userId = 1 (existing) \| points = 10 (positive) | currency column on user row increased by 10 | [TR-STP-08] Verifies awardBonusPoints adds points to the user's currency | V |
|  |  | Non-existent user | userId = 101 (no such user) \| points = 10 | Throws StateError ('User with id 101 does not exist') | [TR-STP-09] Verifies awardBonusPoints throws when the user does not exist | I |
|  |  | Zero or negative points rejected | userId = 1 \| points = 0 (boundary - at the > 0 rule) | Throws ArgumentError ('Points must be greater than 0') | [TR-STP-10] Verifies awardBonusPoints rejects non-positive point amounts | I |
|  | StepPointsService.getAccountSummary - get a user's total steps and currency | Non-existent user | userId = 101 (no such user) | Throws StateError ('User with id 101 does not exist') | [TR-STP-11] Verifies getAccountSummary throws when the user does not exist | I |
|  |  | Valid user with data | userId = 1 \| 250 steps recorded, base currency 10 | Returns StepAccountSummary(totalSteps=250, unconvertedSteps=50, currency=12) | [TR-STP-12] Verifies getAccountSummary returns the correct totals after step recording | V |
|  | RouteService.saveRoute - save a GPS route to the database | Valid path with multiple coordinates | userId = 1 \| name = 'Campus' \| path = [LatLng(50.7, -1.0), LatLng(50.8, -1.1)] (2 GPS points) | Row inserted in route table with route_path serialised as JSON string | [TR-RT-01] Verifies saveRoute serialises a list of LatLng coordinates into a JSON string | V |
|  |  | Valid name with empty path | userId = 1 \| name = 'Empty' \| path = [] (zero coordinates) | Row inserted with route_path = '[]' (empty JSON array, no throw) | [TR-RT-02] Verifies the zero-length boundary saves successfully | V |
|  |  | Single coordinate path | userId = 1 \| name = 'Single Point' \| path = [LatLng(50.5, -1.05)] (one coordinate) | Row inserted with one-element JSON array | [TR-RT-04] Verifies the lower-boundary case of a one-coordinate path | V |
|  | RouteService.getSavedRoutes - load all of a user's saved routes | One saved route exists | userId = 1 (one route row exists) | Returns a List of one map; route_path is deserialised back to List<LatLng> | [TR-RT-03] Verifies getSavedRoutes deserialises route_path JSON back into LatLng objects | V |
|  |  | No routes exist | userId = 1 (route table empty) | Returns an empty list | [TR-RT-05] Verifies a clean route table returns an empty list | I |
|  |  | Other user owns routes | userId = 1 (no routes) \| userId = 2 has a route | Returns empty list for userId 1; returns user 2's route when queried as user 2 | [TR-RT-06] Verifies the user_id filter excludes other users' routes | V |
|  | RouteService.deleteRoute - delete one saved route by id | Valid existing route id | routeId = inserted route's id | Row deleted; subsequent getSavedRoutes returns empty | [TR-RT-07] Verifies deleteRoute removes the row matching the id | V |
|  |  | Route id does not exist | routeId = 99999 (no such row) | No exception; existing rows unaffected (silent no-op) | [TR-RT-08] Verifies deleteRoute handles a missing id gracefully | I |
| A user should be able to see summaries of their recent and best walks | insertWalkSummary - record a finished walk into the summary table | Missing walk_date | walkData = {user_id: 1, total_steps: 100, ...} (no walk_date key) | Throws DatabaseException (SQLite NOT NULL constraint on walk_date) | [TR-SUM-11] Verifies the database rejects a summary missing the required walk_date field | I |
|  |  | Missing total_steps | walkData = {user_id: 1, walk_date: '2026-01-01T00:00:00Z', ...} (no total_steps key) | Throws DatabaseException (SQLite NOT NULL constraint on total_steps) | [TR-SUM-12] Verifies the database rejects a summary missing the required total_steps field | I |
|  | getRecentWalkSummaries - get a user's most recent 10 walks | 12 summaries exist (more than cap) | userId = 1 \| 12 walk_summary rows | Returns 10 summaries ordered by walk_date DESC (cap applied) | [TR-SUM-01] Verifies the LIMIT 10 cap so the recent-walks UI never overflows | V |
|  |  | 5 summaries exist (below cap) | userId = 1 \| 5 walk_summary rows | Returns all 5 summaries ordered by walk_date DESC | [TR-SUM-03] Verifies standard retrieval when count is below the limit | V |
|  |  | Exactly 10 summaries (inclusive boundary) | userId = 1 \| 10 walk_summary rows | Returns all 10 | [TR-SUM-05] Verifies the inclusive LIMIT 10 boundary | V |
|  |  | 11 summaries (just over cap) | userId = 1 \| 11 walk_summary rows | Returns 10 (one excluded by LIMIT) | [TR-SUM-06] Verifies the just-over-cap boundary | V |
|  |  | Mixed dates | userId = 1 \| dates 2026-01-01, 03, 02 inserted in that order | Returns rows in DESC order: 01-03, 01-02, 01-01 | [TR-SUM-07] Verifies the ORDER BY walk_date DESC clause | V |
|  |  | Empty database | userId = 1 \| walk_summary table empty | Returns an empty list | [TR-SUM-08] Verifies a clean database returns empty without throwing | I |
|  |  | Other user owns summaries | userId = 1 (no summaries) \| userId = 2 has summaries | Returns empty list for userId 1 | [TR-SUM-09] Verifies the user_id filter excludes other users' summaries | I |
|  | getTopWalkSummaries - get a user's top 3 walks by step count | 5 summaries above cap | userId = 1 \| step counts 100, 500, 200, 1000, 50 | Returns 3 summaries sorted by total_steps DESC: 1000, 500, 200 | [TR-SUM-02] Verifies the ORDER BY total_steps DESC and LIMIT 3 cap | V |
|  |  | 2 summaries below cap | userId = 1 \| step counts 100, 500 | Returns 2 summaries sorted DESC: 500, 100 | [TR-SUM-04] Verifies sorting and retrieval when count is below the limit | V |
|  |  | Empty database | userId = 1 \| walk_summary table empty | Returns an empty list | [TR-SUM-10] Verifies the top-3 query returns empty on a clean database | I |
| A user should be able to set a daily step goal and earn rewards for completing it | GoalService.setDailyStepGoal - set or update the user's daily step goal | Existing goal - update | userId = 1 (already has a goal row) \| stepGoal = 500 | target_goal on existing goal row updated to 500 | [TR-GOAL-01] Verifies setDailyStepGoal updates the existing goal row when one already exists | V |
|  |  | No existing goal - create | userId = 1 (no goal yet) \| stepGoal = 500 | New rows inserted in goal and user_goal; goal_id returned | [TR-GOAL-02] Verifies setDailyStepGoal creates a new goal and user_goal row when none exists | V |
|  | GoalService.getDailyStepGoal - read the user's daily step goal | Goal exists | userId = 1 (recurring goal with target 500 exists) | Returns 500 | [TR-GOAL-03] Verifies getDailyStepGoal returns the stored target | V |
|  |  | No goal | userId = 1 (no goal row for this user) | Returns null | [TR-GOAL-04] Verifies getDailyStepGoal returns null when no goal exists | V |
|  | GoalService.getCurrentSteps - read how far the user is towards today's goal | Goal exists with progress | userId = 1 \| user_goal current_progress = 120 | Returns 120 | [TR-GOAL-05] Verifies getCurrentSteps returns the stored progress | V |
|  |  | No goal rows | userId = 1 (no user_goal row) | Returns 0 (graceful default) | [TR-GOAL-06] Verifies getCurrentSteps returns 0 when no goal exists | V |
|  | GoalService.hasUserReachedGoal - check whether the user has hit their goal | Progress >= target | userId = 1 \| target = 250, progress = 300 | Returns true | [TR-GOAL-07] Verifies hasUserReachedGoal returns true when progress meets or exceeds target | V |
|  |  | Progress < target | userId = 1 \| target = 250, progress = 100 | Returns false | [TR-GOAL-08] Verifies hasUserReachedGoal returns false when below target | V |
|  |  | No goal exists | userId = 1 (no user_goal row) | Returns false (graceful default) | [TR-GOAL-09] Verifies hasUserReachedGoal returns false when no goal exists | V |
|  | GoalService.resetGoal - reset progress and award the completion reward (25 currency) | Has goal - reset | userId = 1 \| existing goal at progress 300, currency 0 | target_goal reset to 250, current_progress reset to 0, currency increased by 25; returns 25 | [TR-GOAL-10] Verifies resetGoal awards 25 currency and resets progress when a goal exists | V |
|  |  | No goal - graceful | userId = 1 (no user_goal row) | Returns 0; no DB changes | [TR-GOAL-11] Verifies resetGoal returns 0 when no goal exists | V |
|  | StepGoalController.loadGoal - load the current goal value (with default fallback to 250) | New user with no goal record | userId = 1 (user seeded but no goal) | Returns 250 (default fallback) | [TR-GOAL-12] Verifies loadGoal falls back to 250 when no goal exists | V |
|  |  | Existing goal with stored value | userId = 1 \| goal target = 500 | Returns 500 | [TR-GOAL-13] Verifies loadGoal returns the stored target | V |
|  |  | User exists but no goal | userId = 1 (user only, no goal row) | Returns 250 (default) | [TR-GOAL-14] Verifies loadGoal returns the default when the user has no goal record | V |
|  | StepGoalController.loadData - load all goal-related data on app start | New user with no data | userId = 1 (seeded user only, no goal, no walk data) | currentSteps = 0, stepGoal = 250, totalSteps = 0 (all defaults) | [TR-GOAL-15] Verifies loadData initialises to defaults when no data exists | V |
|  | StepGoalController.updateGoal - user changes their daily goal value (rejects values at or below 0) | Update existing goal | userId = 1 \| existing goal at 250 \| newGoal = 500 | Goal updated; loadGoal subsequently returns 500 | [TR-GOAL-16] Verifies updateGoal writes the new value to the existing goal | V |
|  |  | Create goal when none exists | userId = 1 (no goal yet) \| newGoal = 750 | Goal created; loadGoal subsequently returns 750 | [TR-GOAL-17] Verifies updateGoal creates a goal when none exists | V |
|  |  | Goal at minimum used value | userId = 1 \| newGoal = 250 (the team's chosen minimum value) | Goal accepted and stored | [TR-GOAL-18] Verifies updateGoal accepts the team's chosen minimum value of 250 | V |
|  |  | Goal at high value | userId = 1 \| newGoal = 20000 | Goal accepted and stored | [TR-GOAL-19] Verifies updateGoal accepts large values | V |
|  |  | Goal of zero rejected | userId = 1 \| newGoal = 0 (boundary - at the <= 0 rejection rule) | Throws Exception('Invalid goal value') | [TR-GOAL-20] Verifies updateGoal rejects 0 | I |
|  |  | Negative goal rejected | userId = 1 \| newGoal = -100 (negative) | Throws Exception('Invalid goal value') | [TR-GOAL-21] Verifies updateGoal rejects negative values | I |
|  |  | Goal just below 250 | userId = 1 \| newGoal = 249 (just below the team's preferred minimum) | Currently accepted by the implementation (only <= 0 is rejected) - existing test masks this with try/catch so it passes regardless. See "Known issues" below. | [TR-GOAL-22] Currently passes via a swallowed try/catch - flagged as a buggy test in the existing suite | I |
|  | StepGoalController.refreshSteps - refresh progress and auto-reset if the goal has been reached | Goal reached exactly | userId = 1 \| target = 250, progress = 250, walk steps = 250 | currentSteps resets to 0, stepGoal stays 250, currency increases (goal reward awarded) | [TR-GOAL-23] Verifies refreshSteps resets progress and awards reward at exact match | V |
|  |  | Goal exceeded | userId = 1 \| target = 250, progress = 300, walk steps = 300 | currentSteps resets to 0, currency increases | [TR-GOAL-24] Verifies refreshSteps resets progress and awards reward when exceeded | V |
|  |  | Below goal - no reset | userId = 1 \| target = 250, progress = 200, walk steps = 200 | currentSteps stays at 200, stepGoal stays 250, no reward awarded | [TR-GOAL-25] Verifies refreshSteps does not reset or award when below target | V |
|  |  | Award currency at exact match | userId = 1 \| target = 250, progress = 250 | currency > 0 after refresh | [TR-GOAL-26] Verifies currency is awarded when goal is reached at exact target | V |
|  |  | Award currency when exceeded | userId = 1 \| target = 250, progress = 300 | currency > 0 after refresh | [TR-GOAL-27] Verifies currency is awarded when goal is exceeded | V |
|  |  | No walk data | userId = 1 (no walk_summary rows) \| target = 250 | currentSteps = 0, stepGoal stays 250 - no reset (nothing happened) | [TR-GOAL-28] Verifies refreshSteps does nothing when no walk data exists | V |
|  | StepGoalController.loadData edge - same loadData function tested with a missing-user edge case | Missing user record | userId = 1 (no user row seeded at all) | Defaults: currentSteps = 0, stepGoal = 250, totalSteps = 0 (errors are swallowed by try/catch in loadData) | [TR-GOAL-29] Verifies loadData defaults gracefully when the user record is missing (catches the StateError internally) | V |
|  | StepGoalController.updateGoal edge - same updateGoal function with a duplicate negative-input scenario | Negative input via validates-input-type test | userId = 1 \| newGoal = -50 (negative) | Throws Exception('Invalid goal value') | [TR-GOAL-30] Duplicate-flavour test of negative input rejection - kept for completeness | I |
|  | StepGoalController.init - initialise the controller with its services | Initialises with test DB | controller.init(testDb: db) called | goalService and stepService both non-null after init | [TR-GOAL-31] Verifies init wires up the GoalService and StepPointsService dependencies | V |
| A user should be able to buy items from the shop and use them from their inventory | InventoryDatabase.getFoodByUserId - list the food a user owns | User has food | userId = 1 \| 2 food rows in inventory | Returns a List<Map> of food rows with item_id, quantity, image_path | [TR-INV-01] Verifies getFoodByUserId returns the user's food inventory | V |
|  |  | User has no food | userId = 1 (no food rows in inventory) | Throws Exception('Failed to get food: User not found') - *note: current behaviour, may be intentional design or a bug per code comments* | [TR-INV-02] Verifies the throw-on-empty behaviour as currently coded | I |
|  | InventoryDatabase.useFood - consume one of a food item (decrement quantity) | Item present with qty > 0 | userId = 1 \| foodId = 5 (in inventory, quantity = 3) | quantity decremented by 1 (now 2) | [TR-INV-03] Verifies useFood decrements quantity when food is available | V |
|  |  | Item present with qty = 0 | userId = 1 \| foodId = 5 (in inventory, quantity = 0) | No change; SQL guard `quantity > 0` prevents going negative | [TR-INV-04] Verifies useFood does not decrement when quantity is already 0 | V |
|  |  | Item not in inventory | userId = 1 \| foodId = 999 (no inventory row for this combo) | Throws Exception('Failed to use food: User or item not found') | [TR-INV-05] Verifies useFood throws when the user does not own the item | I |
|  | ShopDatabase.getItemsByType - list all items of a given type (hat or food) | Type = 'hat' | type = 'hat' (the hat item type) | Returns list of all item rows with type='hat' | [TR-SHOP-01] Verifies getItemsByType returns all hat-type rows | V |
|  |  | Type = 'food' | type = 'food' (the food item type) | Returns list of all item rows with type='food' | [TR-SHOP-02] Verifies getItemsByType returns all food-type rows | V |
|  |  | Unknown type | type = 'unknown' (not a defined type) | Returns an empty list | [TR-SHOP-03] Verifies getItemsByType returns empty for an unknown type | I |
|  | ShopDatabase.getUserCurrency - get a user's current currency balance | Valid user | userId = 1 \| currency = 500 stored | Returns 500 | [TR-SHOP-04] Verifies getUserCurrency returns the stored currency | V |
|  |  | Invalid user | userId = 999 (no user row) | Returns 0 (graceful default, no throw) | [TR-SHOP-05] Verifies getUserCurrency returns 0 when no user exists | I |
|  | ShopDatabase.userOwnsItem - check if a user owns a specific item | User owns item | userId = 1 \| itemId = 5 (in inventory) | Returns true | [TR-SHOP-06] Verifies userOwnsItem returns true when an inventory row exists | V |
|  |  | User does not own item | userId = 1 \| itemId = 99 (not in inventory) | Returns false | [TR-SHOP-07] Verifies userOwnsItem returns false when no inventory row exists | V |
|  | ShopDatabase.purchaseItem - buy an item from the shop (handles currency check and inventory update) | Hat, not owned, sufficient funds | userId = 1 (currency 500) \| itemId = 5 (hat priced 100) | Returns 'success'; currency deducted to 400; inventory row added | [TR-SHOP-08] Verifies purchaseItem succeeds and deducts funds when buying a new hat | V |
|  |  | Food, first time, sufficient funds | userId = 1 (currency 500) \| itemId = 10 (food priced 100, not in inventory) | Returns 'success'; currency deducted to 400; new inventory row with quantity = 1 | [TR-SHOP-09] Verifies purchaseItem inserts a new inventory row when buying food for the first time | V |
|  |  | Food, already in inventory | userId = 1 (currency 500) \| itemId = 10 (food, currently quantity = 2 in inventory) | Returns 'success'; currency deducted; quantity incremented to 3 | [TR-SHOP-10] Verifies purchaseItem increments quantity when food is already in inventory | V |
|  |  | Item not found | userId = 1 \| itemId = 99999 (no item row with this id) | Returns 'Item not found' (string return, not throw); no DB changes | [TR-SHOP-11] Verifies purchaseItem returns the not-found sentinel string | I |
|  |  | Hat already owned | userId = 1 \| itemId = 5 (hat already in inventory) | Returns 'already_owned'; no currency deducted, no inventory change | [TR-SHOP-12] Verifies purchaseItem rejects buying a hat the user already owns | I |
|  |  | Insufficient funds | userId = 1 (currency 50) \| itemId = 5 (hat priced 100) | Returns 'insufficient_funds'; no currency deducted, no inventory change | [TR-SHOP-13] Verifies purchaseItem rejects when the user cannot afford the item | I |
|  | ShopDatabase.getItemQuantity - how many of one item the user owns | Item in inventory | userId = 1 \| itemId = 10 (quantity = 3 in inventory) | Returns 3 | [TR-SHOP-14] Verifies getItemQuantity returns the stored quantity | V |
|  |  | Item not in inventory | userId = 1 \| itemId = 99 (not in inventory) | Returns 0 | [TR-SHOP-15] Verifies getItemQuantity returns 0 when no inventory row exists | V |
|  | ShopDatabase.getUserItemQuantities - all quantities of everything the user owns | User has inventory | userId = 1 \| 2 items in inventory (item 5 qty 1, item 10 qty 3) | Returns {5: 1, 10: 3} | [TR-SHOP-16] Verifies getUserItemQuantities returns a map keyed by item_id | V |
|  |  | Empty inventory | userId = 1 (no inventory rows) | Returns an empty map | [TR-SHOP-17] Verifies getUserItemQuantities returns an empty map when no inventory exists | V |
|  | ShopDatabase.getUserItems - set of all item ids the user owns | User has inventory | userId = 1 \| items 5, 10 in inventory | Returns Set {5, 10} | [TR-SHOP-18] Verifies getUserItems returns a set of owned item ids | V |
|  |  | Empty inventory | userId = 1 (no inventory rows) | Returns an empty set | [TR-SHOP-19] Verifies getUserItems returns an empty set when no inventory exists | V |
|  | ShopDatabase.getTotalShopItems - count of all items available in the shop | Standard call | (no input) | Returns COUNT(*) of the item table as an int | [TR-SHOP-20] Verifies getTotalShopItems returns the total row count of the item table | V |

---

## Totals

| UR | New tests to write | Existing tests to rename | Already in TR format |
|---|---|---|---|
| UR1 Profile | 16 | 0 | 0 |
| UR2 Pet (stats + level + dress) | 35 | 0 | 0 |
| UR3 Track walking | 0 | 9 (StepPointsService) | 11 (TR-RT-01..08 + TR-STP-01..03) |
| UR4 See summaries | 0 | 0 | 12 (TR-SUM-01..12) |
| UR5 Goals | 11 | 20 (StepGoalController) | 0 |
| UR6 Shop + inventory | 25 | 0 | 0 |
| **Total** | **87 new** | **29 renamed** | **23 already done** |

**Grand total tests in scope: 139**

---

## Known issues surfaced by this audit

- **TR-GOAL-22 - buggy existing test.** `step_goal_test.dart` has `'rejects goal just below minimum (249 steps)'` that calls `updateGoal(249)`. The implementation only rejects `newGoal <= 0`, so 249 is silently accepted. The test uses a swallowing `try/catch` that passes regardless of whether the throw actually happens. Keeping it on the plan but flagging it - recommend deciding either to enforce the 250 minimum in code, or to delete this test.

- **TR-INV-02 - design ambiguity.** `getFoodByUserId` throws when the user has no food rows. Per the code comments, this might be intentional (fail-loud) or a bug (the UI is asked to display "no food owned" gracefully). The test is written against current behaviour. Flagging for a product decision.

- **TR-PRF-14 - silent failure path.** `LastOnlineUpdater.update` doesn't throw on a missing user; sqflite update returns 0. Test marked I and documents this. If you want to enforce strict failure, add a row-count check in the helper.

- **map_view.dart not auto-tested.** Map screen relies on live Geolocator + Pedometer streams - out of scope for widget tests. Manual system testing on physical device only.

- **Yesterday's stale-DB bug.** `lib/models/database.dart` opens at `version: 2` with no `onUpgrade`. Tests that use `AppDatabase.instance.initializeDefaultData()` are exposed to this. **Recommendation: switch those tests to the in-memory pattern in `test/helpers/test_database.dart`** (which `step_goal_test.dart` and `database_test.dart` already use). This both fixes the stale-cache issue and isolates tests cleanly.

---

## Implementation order

1. **UR1 Profile** - 16 new tests in `test/models/pet_maintainance_database_test.dart` + `test/utils/last_online_updater_test.dart` + new entries in `test/models/database_test.dart` for `userExists`.
2. **UR2 Pet** - 35 new tests across `pet_maintainance_database_test.dart` (continues from UR1), new `test/services/level_service_test.dart`, new `test/utils/stat_degradation_service_test.dart`, new `test/models/dress_database_test.dart`.
3. **UR5 Goals** - 11 new tests in new `test/models/goal_service_database_test.dart` + 20 renames in `step_goal_test.dart`.
4. **UR6 Shop + inventory** - 25 new tests in new `test/models/shop_database_test.dart` + addition to `pet_maintainance_database_test.dart` for `InventoryDatabase`.
5. **UR3 rename pass** - 9 renames in `step_points_service_test.dart`.

All test files use the existing `test/helpers/test_database.dart` in-memory fresh-DB pattern to side-step the stale-cache bug.
