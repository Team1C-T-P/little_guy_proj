import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/models/route_service.dart';

void main() {
  // FIX 1: Wake up the Flutter asset bundle for testing
  TestWidgetsFlutterBinding.ensureInitialized();

  late RouteService routeService;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.instance.initializeDefaultData(); 
  });

  setUp(() async {
    // FIX 2: Explicitly clear the table so data doesn't bleed between tests
    final db = await AppDatabase.instance.database;
    await db.delete('route');
    
    routeService = RouteService();
  });

  group('Create / See Routes', () {
    test('[TR-RT-01 & TR-RT-03] Serializes and deserializes GPS coordinates', () async {
      final fakePath = [const LatLng(50.7, -1.0), const LatLng(50.8, -1.1)];
      
      await routeService.saveRoute(1, "Campus Walk", fakePath);
      final routes = await routeService.getSavedRoutes(1);
      
      expect(routes.length, 1);
      expect(routes.first['route_name'], "Campus Walk");
      
      final fetchedPath = routes.first['route_path'] as List<LatLng>;
      expect(fetchedPath.length, 2);
      expect(fetchedPath.first.latitude, 50.7); 
    });

    test('[TR-RT-02] Boundary test: Handles saving an empty route', () async {
      final emptyPath = <LatLng>[];
      await routeService.saveRoute(1, "Empty Walk", emptyPath);

      final routes = await routeService.getSavedRoutes(1);
      final fetchedPath = routes.first['route_path'] as List<LatLng>;

      expect(fetchedPath.isEmpty, isTrue, reason: 'Failed to handle 0-length boundary');
    });

    test('[TR-RT-04] Saves a path with a single coordinate', () async {
      final singlePath = [const LatLng(50.5, -1.05)];
      await routeService.saveRoute(1, "Single Point", singlePath);

      final routes = await routeService.getSavedRoutes(1);
      final fetchedPath = routes.first['route_path'] as List<LatLng>;

      expect(routes.length, 1);
      expect(fetchedPath.length, 1);
      expect(fetchedPath.first.latitude, 50.5);
      expect(fetchedPath.first.longitude, -1.05);
    });

    test('[TR-RT-05] Returns an empty list when the user has no saved routes', () async {
      final routes = await routeService.getSavedRoutes(1);
      expect(routes, isEmpty, reason: 'Expected empty list for a user with no routes');
    });

    test('[TR-RT-06] Only returns routes belonging to the requested user', () async {
      await routeService.saveRoute(2, "Other User Route", [const LatLng(50.0, -1.0)]);

      final routesForUser1 = await routeService.getSavedRoutes(1);
      final routesForUser2 = await routeService.getSavedRoutes(2);

      expect(routesForUser1, isEmpty, reason: 'user_id filter leaked other users\' routes');
      expect(routesForUser2.length, 1);
      expect(routesForUser2.first['route_name'], "Other User Route");
    });

    test('[TR-RT-07] Deletes an existing route by id', () async {
      final routeId = await routeService.saveRoute(1, "To Be Deleted", [const LatLng(50.0, -1.0)]);

      await routeService.deleteRoute(routeId);

      final routes = await routeService.getSavedRoutes(1);
      expect(routes, isEmpty, reason: 'Route was not removed from the database');
    });

    test('[TR-RT-08] Does not throw when deleting a route id that does not exist', () async {
      await routeService.saveRoute(1, "Keep Me", [const LatLng(50.0, -1.0)]);

      // Attempt to delete a route that was never created
      await routeService.deleteRoute(99999);

      final routes = await routeService.getSavedRoutes(1);
      expect(routes.length, 1, reason: 'Existing route should not have been affected');
      expect(routes.first['route_name'], "Keep Me");
    });
  });
}