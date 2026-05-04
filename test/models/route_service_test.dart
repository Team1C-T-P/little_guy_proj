import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_flame_playground/models/database.dart';
import 'package:flutter_flame_playground/models/route_service.dart';

void main() {
  late RouteService routeService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbPath = inMemoryDatabasePath;
    await databaseFactory.deleteDatabase(dbPath);
    await AppDatabase.instance.initializeDefaultData(); 
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
      expect(fetchedPath.first.latitude, 50.7); // Proves Deserialization
    });

    test('[TR-RT-02] Boundary test: Handles saving an empty route', () async {
      final emptyPath = <LatLng>[];
      await routeService.saveRoute(1, "Empty Walk", emptyPath);
      
      final routes = await routeService.getSavedRoutes(1);
      final fetchedPath = routes.first['route_path'] as List<LatLng>;
      
      expect(fetchedPath.isEmpty, isTrue, reason: 'Failed to handle 0-length boundary');
    });
  });
}