import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'database.dart';

class RouteService {
  Future<int> saveRoute(int userId, String name, List<LatLng> path) async {
    final db = await AppDatabase.instance.database;
    // Convert complex LatLng objects into a simple JSON string
    final pathList = path
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();
    final jsonString = jsonEncode(pathList);

    return await db.insert('route', {
      'user_id': userId,
      'route_name': name,
      'route_path': jsonString,
    });
  }

  Future<List<Map<String, dynamic>>> getSavedRoutes(int userId) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'route',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // Decode the JSON back into LatLng lists so the map can read them
    return rows.map((row) {
      final decoded = jsonDecode(row['route_path'] as String) as List;
      final path = decoded.map((e) => LatLng(e['lat'], e['lng'])).toList();

      return {
        'route_id': row['route_id'],
        'route_name': row['route_name'],
        'route_path': path,
      };
    }).toList();
  }

  Future<void> deleteRoute(int routeId) async {
    final db = await AppDatabase.instance.database;
    await db.delete('route', where: 'route_id = ?', whereArgs: [routeId]);
  }
}
