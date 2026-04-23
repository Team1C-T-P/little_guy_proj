import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gap/gap.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';
import 'package:flutter_flame_playground/utils/location_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';
  
  // Map and Location State
  String _locationDisplay = 'Locating GPS...';
  LatLng? _currentPosition;
  final MapController _mapController = MapController();
  
  // NEW: Variables for real-time tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _route = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    try {
      // 1. Get initial position and permissions
      Position? initialPosition = await LocationService().determinePosition();
      if (initialPosition != null && mounted) {
        setState(() {
          _currentPosition = LatLng(initialPosition.latitude, initialPosition.longitude);
          _route.add(_currentPosition!);
          _locationDisplay = '${initialPosition.latitude.toStringAsFixed(4)}, ${initialPosition.longitude.toStringAsFixed(4)}';
        });
        _mapController.move(_currentPosition!, 16.0);
      }

      // 2. Start listening to the live stream
      _positionStreamSubscription = LocationService().getLocationStream().listen((Position position) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _route.add(_currentPosition!); // Add new coordinate to the trail
            _locationDisplay = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
          
          // Optionally center the camera on the user as they walk
          _mapController.move(_currentPosition!, _mapController.camera.zoom);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationDisplay = 'Location Error';
        });
      }
    }
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
    });
  }

  void onPedestrianStatusChanged(PedestrianStatus event) {
    setState(() {
      _status = event.status;
    });
  }

  void onPedestrianStatusError(error) {
    setState(() {
      _status = 'Status not available';
    });
  }

  void onStepCountError(error) {
    setState(() {
      _steps = 'Unavailable';
    });
  }

  Future<bool> _checkActivityRecognitionPermission() async {
    bool granted = await Permission.activityRecognition.isGranted;
    if (!granted) {
      granted = await Permission.activityRecognition.request() == PermissionStatus.granted;
    }
    return granted;
  }

  Future<void> initPlatformState() async {
    bool granted = await _checkActivityRecognitionPermission();
    if (!granted) {
      setState(() {
        _status = 'Permission denied';
      });
    }

    _pedestrianStatusStream = Pedometer.pedestrianStatusStream;
    _pedestrianStatusStream
        .listen(onPedestrianStatusChanged)
        .onError(onPedestrianStatusError);

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepCount).onError(onStepCountError);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(219, 150, 242, 176),
      body: Column(
        children: [
          // Top Area containing the Live Map
          Expanded(
            flex: 10,
            child: Container(
              color: const Color.fromARGB(255, 221, 249, 255),
              child: _currentPosition == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          Gap(10),
                          Text('Finding your Little Guy...'),
                        ],
                      ),
                    )
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition!,
                        initialZoom: 18.0, // Zoomed in closer for walking
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.flutter_flame_playground',
                        ),
                        // NEW: Draws the trail behind the user
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route,
                              strokeWidth: 5.0,
                              color: const Color.fromARGB(255, 77, 151, 86), // App's green theme
                            ),
                          ],
                        ),
                        // Custom sprite at current location
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 60,
                              height: 60,
                              child: Image.asset('images/funnyguy.png'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
          
          // Bottom Stats Area
          Container(
            color: const Color.fromARGB(219, 150, 242, 176),
            width: MediaQuery.of(context).size.width,
            child: Column(
              children: [
                const Gap(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(219, 246, 255, 226),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Walking Stats',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.directions_walk, size: 40, color: Color.fromARGB(255, 77, 151, 86)),
                                const Gap(5),
                                const Text('Device Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(_steps, style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.accessibility_new, size: 40, color: Color.fromARGB(255, 77, 151, 86)),
                                const Gap(5),
                                const Text('Global Steps', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('${StepCounter().stepCount}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(_status == 'walking' ? Icons.directions_run : Icons.man, size: 40, color: const Color.fromARGB(255, 77, 151, 86)),
                                const Gap(5),
                                const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(_status, style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ],
                        ),
                        const Gap(15),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(219, 150, 242, 176),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.pin_drop, color: Color.fromARGB(255, 77, 151, 86)),
                              const Gap(10),
                              Text(
                                _locationDisplay,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Stack(
                  children: <Widget>[
                    Container(
                      alignment: Alignment.centerLeft,
                      child: Image.asset("images/clover.png", height: 80),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.only(right: 18, top: 20),
                      child: Image.asset("images/daisy.png", height: 80),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}