import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gap/gap.dart';
import 'package:flutter_flame_playground/little%20guy.dart';
import 'package:flutter_flame_playground/utils/step_counter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Stream<StepCount> _stepCountStream;
  late Stream<PedestrianStatus> _pedestrianStatusStream;
  String _status = '?', _steps = '?';

  @override
  void initState() {
    super.initState();
    initPlatformState();
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
          // Top Area containing the LittleGuy (Map Placeholder)
          Expanded(
            flex: 10,
            child: Container(
              alignment: Alignment.bottomCenter,
              color: const Color.fromARGB(255, 221, 249, 255),
              child: const Center(child: LittleGuy()),
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
                            // Device Pedometer Stats
                            Column(
                              children: [
                                const Icon(
                                  Icons.directions_walk,
                                  size: 40,
                                  color: Color.fromARGB(255, 77, 151, 86),
                                ),
                                const Gap(5),
                                const Text(
                                  'Device Steps',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _steps,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            
                            // App Global Steps
                            Column(
                              children: [
                                const Icon(
                                  Icons.accessibility_new,
                                  size: 40,
                                  color: Color.fromARGB(255, 77, 151, 86),
                                ),
                                const Gap(5),
                                const Text(
                                  'Global Steps',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${StepCounter().stepCount}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            
                            // Current Status
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
                      ],
                    ),
                  ),
                ),
                
                // Bottom row with decorators
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