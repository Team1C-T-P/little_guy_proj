import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_flame_playground/models/route_service.dart';

class RoutesView extends StatefulWidget {
  const RoutesView({super.key});

  @override
  State<RoutesView> createState() => _RoutesViewState();
}

class _RoutesViewState extends State<RoutesView> {
  final RouteService _routeService = RouteService();
  List<Map<String, dynamic>> _savedRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 213, 248, 255),
      appBar: AppBar(
        title: const Text('My Saved Routes'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedRoutes.isEmpty
          ? const Center(
              child: Text(
                "You haven't saved any routes yet!\nFinish a walk to save one.",
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
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
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await _routeService.deleteRoute(route['route_id']);
                        if (!mounted) return;
                        _loadRoutes();
                      },
                    ),
                    onTap: () {
                      // Pass the coordinate path back to the map to be highlighted!
                      Navigator.pop(context, route['route_path']);
                    },
                  ),
                );
              },
            ),
    );
  }
}
