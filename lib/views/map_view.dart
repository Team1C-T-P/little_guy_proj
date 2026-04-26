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
import 'package:flutter_flame_playground/views/routes_view.dart';
import 'package:flutter_flame_playground/views/summary_view.dart';
import 'package:flutter_flame_playground/widgets/button.dart';

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

  StreamSubscription<Position>? _positionStreamSubscription;
  final List<LatLng> _route = [];

  // Track session steps
  int _initialSteps = -1;
  int _sessionSteps = 0;

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
      Position? initialPosition = await LocationService().determinePosition();
      if (initialPosition != null && mounted) {
        setState(() {
          _currentPosition = LatLng(
            initialPosition.latitude,
            initialPosition.longitude,
          );
          _route.add(_currentPosition!);
          _locationDisplay =
              '${initialPosition.latitude.toStringAsFixed(4)}, ${initialPosition.longitude.toStringAsFixed(4)}';
        });
        _mapController.move(_currentPosition!, 16.0);
      }

      _positionStreamSubscription = LocationService().getLocationStream().listen((
        Position position,
      ) {
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _route.add(_currentPosition!);
            _locationDisplay =
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });

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

  Future<void> _openRoutes() async {
    final startedRouteName = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (context) => const RoutesView()),
    );

    if (!mounted || startedRouteName == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$startedRouteName route has been started')),
    );
  }

  void onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps.toString();
      if (_initialSteps == -1) {
        _initialSteps = event.steps;
      }
      _sessionSteps = event.steps - _initialSteps;
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
      granted =
          await Permission.activityRecognition.request() ==
          PermissionStatus.granted;
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
                        initialZoom: 18.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName:
                              'com.example.flutter_flame_playground',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _route,
                              strokeWidth: 5.0,
                              color: const Color.fromARGB(255, 77, 151, 86),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentPosition!,
                              width: 60,
                              height: 60,
                              child: Image.asset('assets/images/funnyguy.png'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),

          Container(
            color: const Color.fromARGB(219, 150, 242, 176),
            width: double.infinity, // fills available space naturally
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
                    width: double
                        .infinity, // fills parent (already inset by padding)
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
                            Expanded(
                              // ADD Expanded so columns share space equally
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.directions_walk,
                                    size: 40,
                                    color: Color.fromARGB(255, 77, 151, 86),
                                  ),
                                  const Gap(5),
                                  const Text(
                                    'Session Steps',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '$_sessionSteps',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              // ADD Expanded here too
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.accessibility_new,
                                    size: 40,
                                    color: Color.fromARGB(255, 77, 151, 86),
                                  ),
                                  const Gap(5),
                                  const Text(
                                    'Global Steps',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '${StepCounter().stepCount}',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Icon(
                                  _status == 'walking'
                                      ? Icons.directions_run
                                      : Icons.man,
                                  size: 40,
                                  color: const Color.fromARGB(255, 77, 151, 86),
                                ),
                                const Gap(5),
                                const Text(
                                  'Status',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _status,
                                  style: const TextStyle(fontSize: 18),
                                ),
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
                              const Icon(
                                Icons.pin_drop,
                                color: Color.fromARGB(255, 77, 151, 86),
                              ),
                              const Gap(10),
                              Text(
                                _locationDisplay,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
                      child: Image.asset(
                        "assets/images/clover.png",
                        height: 80,
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GreenButton(
                              buttonText: "Routes",
                              onPressed: _openRoutes,
                            ),
                            const Gap(12),
                            GreenButton(
                              buttonText: "End Walk",
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SummaryScreen(
                                      totalSteps: _sessionSteps,
                                      route: _route,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.only(right: 18, top: 20),
                      child: Image.asset("assets/images/daisy.png", height: 80),
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
