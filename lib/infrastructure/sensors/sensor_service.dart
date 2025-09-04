import 'dart:async';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:light_sensor/light_sensor.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:proximity_sensor/proximity_sensor.dart';
import 'package:sensor_hub/core/core.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../features/sensors/data/models/sensor_data.dart';

/// Service for collecting data from all device sensors
class SensorService {
  static final SensorService _instance = SensorService._internal();

  factory SensorService() => _instance;

  SensorService._internal();

  // Stream controllers for different sensor types
  final _accelerometerController =
      StreamController<AccelerometerData>.broadcast();
  final _gyroscopeController = StreamController<GyroscopeData>.broadcast();
  final _magnetometerController =
      StreamController<MagnetometerData>.broadcast();
  final _locationController = StreamController<LocationData>.broadcast();
  final _batteryController = StreamController<BatteryData>.broadcast();
  final _lightController = StreamController<LightData>.broadcast();
  final _proximityController = StreamController<ProximityData>.broadcast();

  // Stream subscriptions
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<BatteryState>? _batterySubscription;
  StreamSubscription<int>? _lightSubscription;
  StreamSubscription<int>? _proximitySubscription;

  // Instances
  final Battery _battery = Battery();
  bool _isMonitoring = false;

  // Mock data generation for web platform
  final Random _random = Random();
  Timer? _mockDataTimer;
  
  // Mock data state
  double _mockAccelBase = 1.0;
  double _mockGyroBase = 0.1;
  double _mockMagnetoBase = 25.0;
  double _mockLocationLat = 37.7749; // San Francisco
  double _mockLocationLng = -122.4194;
  int _mockBatteryLevel = 75;
  double _mockLightLux = 300.0;
  bool _mockProximityNear = false;

  // Stream getters
  Stream<AccelerometerData> get accelerometerStream =>
      _accelerometerController.stream;

  Stream<GyroscopeData> get gyroscopeStream => _gyroscopeController.stream;

  Stream<MagnetometerData> get magnetometerStream =>
      _magnetometerController.stream;

  Stream<LocationData> get locationStream => _locationController.stream;

  Stream<BatteryData> get batteryStream => _batteryController.stream;

  Stream<LightData> get lightStream => _lightController.stream;

  Stream<ProximityData> get proximityStream => _proximityController.stream;

  bool get isMonitoring => _isMonitoring;

  /// Start monitoring all available sensors
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    await _requestPermissions();

    _isMonitoring = true;

    // Start motion sensors
    await _startAccelerometer();
    await _startGyroscope();
    await _startMagnetometer();

    // Start environment sensors
    await _startLocationTracking();
    await _startBatteryMonitoring();
    await _startLightSensor();
    await _startProximitySensor();

    Logger.success('SensorHub: All sensors started monitoring');
  }

  /// Stop monitoring all sensors
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    _magnetometerSubscription?.cancel();
    _locationSubscription?.cancel();
    _batterySubscription?.cancel();
    _lightSubscription?.cancel();
    _proximitySubscription?.cancel();

    _isMonitoring = false;
    Logger.info('SensorHub: All sensors stopped monitoring');
  }

  /// Request necessary permissions
  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.sensors,
    ].request();
  }

  /// Start accelerometer monitoring
  Future<void> _startAccelerometer() async {
    try {
      _accelerometerSubscription = userAccelerometerEventStream().listen(
        (event) {
          final data = AccelerometerData(x: event.x, y: event.y, z: event.z);
          _accelerometerController.add(data);
        },
        onError: (error) {
          Logger.error('Accelerometer error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start accelerometer', e);
    }
  }

  /// Start gyroscope monitoring
  Future<void> _startGyroscope() async {
    try {
      _gyroscopeSubscription = gyroscopeEventStream().listen(
        (event) {
          final data = GyroscopeData(x: event.x, y: event.y, z: event.z);
          _gyroscopeController.add(data);
        },
        onError: (error) {
          Logger.error('Gyroscope error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start gyroscope', e);
    }
  }

  /// Start magnetometer monitoring
  Future<void> _startMagnetometer() async {
    try {
      _magnetometerSubscription = magnetometerEventStream().listen(
        (event) {
          final data = MagnetometerData(x: event.x, y: event.y, z: event.z);
          _magnetometerController.add(data);
        },
        onError: (error) {
          Logger.error('Magnetometer error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start magnetometer', e);
    }
  }

  /// Start location tracking
  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Logger.error('Location services are disabled');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.error('Location permissions are denied');
          return;
        }
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      _locationSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (position) {
              final data = LocationData(
                latitude: position.latitude,
                longitude: position.longitude,
                altitude: position.altitude,
                accuracy: position.accuracy,
                speed: position.speed,
              );
              _locationController.add(data);
            },
            onError: (error) {
              Logger.error('Location error', error);
            },
          );
    } catch (e) {
      Logger.error('Failed to start location tracking', e);
    }
  }

  /// Start battery monitoring
  Future<void> _startBatteryMonitoring() async {
    try {
      // Initial battery level
      final batteryLevel = await _battery.batteryLevel;
      final batteryState = await _battery.batteryState;

      final initialData = BatteryData(
        batteryLevel: batteryLevel,
        batteryState: batteryState.toString(),
        isCharging: batteryState == BatteryState.charging,
      );
      _batteryController.add(initialData);

      // Listen to battery changes
      _batterySubscription = _battery.onBatteryStateChanged.listen(
        (batteryState) async {
          final level = await _battery.batteryLevel;
          final data = BatteryData(
            batteryLevel: level,
            batteryState: batteryState.toString(),
            isCharging: batteryState == BatteryState.charging,
          );
          _batteryController.add(data);
        },
        onError: (error) {
          Logger.error('Battery error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start battery monitoring', e);
    }
  }

  /// Start light sensor monitoring
  Future<void> _startLightSensor() async {
    try {
      _lightSubscription = LightSensor.luxStream().listen(
        (luxValue) {
          final data = LightData(luxValue: luxValue.toDouble());
          _lightController.add(data);
        },
        onError: (error) {
          Logger.error('Light sensor error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start light sensor', e);
    }
  }

  /// Start proximity sensor monitoring
  Future<void> _startProximitySensor() async {
    try {
      _proximitySubscription = ProximitySensor.events.listen(
        (event) {
          final data = ProximityData(
            isNear: event == 0, // 0 means near, > 0 means far
            distance: event.toDouble(),
          );
          _proximityController.add(data);
        },
        onError: (error) {
          Logger.error('Proximity sensor error', error);
        },
      );
    } catch (e) {
      Logger.error('Failed to start proximity sensor', e);
    }
  }

  /// Get current sensor status
  Map<String, bool> getSensorStatus() {
    return {
      'accelerometer': _accelerometerSubscription != null,
      'gyroscope': _gyroscopeSubscription != null,
      'magnetometer': _magnetometerSubscription != null,
      'location': _locationSubscription != null,
      'battery': _batterySubscription != null,
      'light': _lightSubscription != null,
      'proximity': _proximitySubscription != null,
    };
  }

  /// Dispose all resources
  void dispose() {
    stopMonitoring();
    _accelerometerController.close();
    _gyroscopeController.close();
    _magnetometerController.close();
    _locationController.close();
    _batteryController.close();
    _lightController.close();
    _proximityController.close();
  }
}
