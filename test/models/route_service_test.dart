// Tests for RouteService — the class that saves, reads back, and deletes
// GPS routes. Routes are stored as JSON strings (the LatLng list is
// serialised into the `route_path` column) so these tests also cover the
// round-trip serialise / deserialise behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_flame_playground/models/route_service.dart';
import '../helpers/test_database.dart';

void main() {
  late Database db;
  late RouteService routeService;

  setUpAll(() => TestDatabase.init());

  setUp(() async {
    db = await TestDatabase.createFresh();
    routeService = RouteService(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UR3 — RouteService', () {

    // saveRoute serialises a List<LatLng> into a JSON string for storage,
    // and getSavedRoutes deserialises it back. We test the round-trip in
    // one go below — and the empty / single-coord boundary cases separately.
    group('saveRoute and round-trip via getSavedRoutes', () {
      test('[TR-RT-01 & TR-RT-03] serializes and deserializes GPS coordinates', () async {
        final fakePath = [const LatLng(50.7, -1.0), const LatLng(50.8, -1.1)];

        await routeService.saveRoute(1, "Campus Walk", fakePath);
        final routes = await routeService.getSavedRoutes(1);

        expect(routes.length, 1);
        expect(routes.first['route_name'], "Campus Walk");

        // After deserialising, route_path should be a List<LatLng> with
        // both points preserved.
        final fetchedPath = routes.first['route_path'] as List<LatLng>;
        expect(fetchedPath.length, 2);
        expect(fetchedPath.first.latitude, 50.7);
      });

      test('[TR-RT-02] handles saving an empty route (zero-length boundary)', () async {
        // The path can be empty (e.g. user hit "save" without moving).
        // We don't want this to throw — it should just save [].
        final emptyPath = <LatLng>[];
        await routeService.saveRoute(1, "Empty Walk", emptyPath);

        final routes = await routeService.getSavedRoutes(1);
        final fetchedPath = routes.first['route_path'] as List<LatLng>;

        expect(fetchedPath.isEmpty, isTrue, reason: 'Failed to handle 0-length boundary');
      });

      test('[TR-RT-04] saves a path with a single coordinate (lower boundary)', () async {
        final singlePath = [const LatLng(50.5, -1.05)];
        await routeService.saveRoute(1, "Single Point", singlePath);

        final routes = await routeService.getSavedRoutes(1);
        final fetchedPath = routes.first['route_path'] as List<LatLng>;

        expect(routes.length, 1);
        expect(fetchedPath.length, 1);
        expect(fetchedPath.first.latitude, 50.5);
        expect(fetchedPath.first.longitude, -1.05);
      });
    });

    // getSavedRoutes is also called when the user has no routes yet, and
    // it should never return another user's routes (the user_id filter).
    group('getSavedRoutes — filtering', () {
      test('[TR-RT-05] returns an empty list when the user has no saved routes', () async {
        final routes = await routeService.getSavedRoutes(1);
        expect(routes, isEmpty, reason: 'Expected empty list for a user with no routes');
      });

      test('[TR-RT-06] only returns routes belonging to the requested user', () async {
        // Save a route as user 2; user 1 should still see nothing.
        await routeService.saveRoute(2, "Other User Route", [const LatLng(50.0, -1.0)]);

        final routesForUser1 = await routeService.getSavedRoutes(1);
        final routesForUser2 = await routeService.getSavedRoutes(2);

        expect(routesForUser1, isEmpty, reason: 'user_id filter leaked other users\' routes');
        expect(routesForUser2.length, 1);
        expect(routesForUser2.first['route_name'], "Other User Route");
      });
    });

    group('deleteRoute', () {
      test('[TR-RT-07] deletes an existing route by id', () async {
        final routeId = await routeService.saveRoute(1, "To Be Deleted", [const LatLng(50.0, -1.0)]);

        await routeService.deleteRoute(routeId);

        final routes = await routeService.getSavedRoutes(1);
        expect(routes, isEmpty, reason: 'Route was not removed from the database');
      });

      test('[TR-RT-08] does not throw when deleting a route id that does not exist', () async {
        // Insert a real route first so we can check it wasn't touched.
        await routeService.saveRoute(1, "Keep Me", [const LatLng(50.0, -1.0)]);

        await routeService.deleteRoute(99999);

        final routes = await routeService.getSavedRoutes(1);
        expect(routes.length, 1, reason: 'Existing route should not have been affected');
        expect(routes.first['route_name'], "Keep Me");
      });
    });
  });
}
