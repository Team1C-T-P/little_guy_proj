import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/widgets/button.dart';
import 'package:flutter_flame_playground/models/database.dart';

class SummaryScreen extends StatefulWidget {
  final int totalSteps;
  final List<LatLng> route;

  const SummaryScreen({
    super.key,
    required this.totalSteps,
    required this.route,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveWalkToDatabase();
  }

  Future<void> _saveWalkToDatabase() async {
    if (widget.route.isEmpty) return;

    final start = widget.route.first;
    final end = widget.route.last;

    final walkData = {
      'user_id': 1,
      'walk_date': DateTime.now().toIso8601String(),
      'total_steps': widget.totalSteps,
      'start_lat': start.latitude,
      'start_lng': start.longitude,
      'end_lat': end.latitude,
      'end_lng': end.longitude,
    };

    try {
      await AppDatabase.instance.insertWalkSummary(walkData);
      setState(() {
        _isSaved = true;
      });
    } catch (e) {
      debugPrint("Database error: $e");
    }
  }

  String _generateFunFact(int steps) {
    double meters = steps * 0.762;
    int doubleDeckerBuses = (meters / 11.2).round();
    
    if (steps < 100) return "Just getting warmed up!";
    if (steps < 1000) return "You walked the length of $doubleDeckerBuses London buses!";
    return "Amazing! You covered ${meters.toStringAsFixed(1)} meters today!";
  }

  @override
  Widget build(BuildContext context) {
    LatLng mapCenter = widget.route.isNotEmpty 
        ? widget.route.last 
        : const LatLng(50.7989, -1.0912);

    return Scaffold(
      backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      appBar: AppBar(
        title: const Text('Walk Summary'),
        backgroundColor: const Color.fromARGB(219, 150, 242, 176),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: mapCenter,
                    initialZoom: 16.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.flutter_flame_playground',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: widget.route,
                          strokeWidth: 6.0,
                          color: const Color.fromARGB(255, 77, 151, 86),
                        ),
                      ],
                    ),
                    if (widget.route.isNotEmpty)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: widget.route.last,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 250, 255, 251),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Text(
                    "Great Job, Little Guy!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_walk, size: 50, color: Color.fromARGB(255, 77, 151, 86)),
                      const Gap(10),
                      Text(
                        "${widget.totalSteps} Steps",
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        const Text("Fun Fact", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const Gap(5),
                        Text(
                          _generateFunFact(widget.totalSteps),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  if (_isSaved)
                    const Text("✓ Saved to Database", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  GreenButton(
                    buttonText: "Return Home",
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}