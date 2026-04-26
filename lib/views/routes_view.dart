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
import 'package:flutter_flame_playground/views/summary_view.dart';
import 'package:flutter_flame_playground/widgets/button.dart';

