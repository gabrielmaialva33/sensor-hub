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

    _isMonitoring = true;

    if (kIsWeb) {
      // Web platform: Start mock data generation
      await _startMockDataGeneration();
      Logger.success('SensorHub: Mock sensors started for web platform');
    } else {
      // Mobile platform: Request permissions and start real sensors
      await _requestPermissions();

      // Start motion sensors
      await _startAccelerometer();
      await _startGyroscope();
      await _startMagnetometer();

      // Start environment sensors
      await _startLocationTracking();
      await _startBatteryMonitoring();
      await _startLightSensor();
      await _startProximitySensor();

      Logger.success('SensorHub: All real sensors started monitoring');
    }
  }

  /// Stop monitoring all sensors
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    if (kIsWeb) {
      // Web platform: Stop mock data generation
      _mockDataTimer?.cancel();
      _mockDataTimer = null;
      Logger.info('SensorHub: Mock sensors stopped');
    } else {
      // Mobile platform: Cancel real sensor subscriptions
      _accelerometerSubscription?.cancel();
      _gyroscopeSubscription?.cancel();
      _magnetometerSubscription?.cancel();
      _locationSubscription?.cancel();
      _batterySubscription?.cancel();
      _lightSubscription?.cancel();
      _proximitySubscription?.cancel();
      Logger.info('SensorHub: All real sensors stopped monitoring');
    }

    _isMonitoring = false;
  }

  /// Request necessary permissions (mobile only)
  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      Logger.info('Permissions not required on web platform');
      return;
    }
    
    try {
      await [
        Permission.location,
        Permission.locationWhenInUse,
        Permission.sensors,
      ].request();
    } catch (e) {
      Logger.error('Failed to request permissions', e);
    }
  }

  /// Start mock data generation for web platform
  Future<void> _startMockDataGeneration() async {
    _mockDataTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _generateMockSensorData();
    });
  }

  /// Generate mock sensor data that simulates realistic sensor behavior
  void _generateMockSensorData() {
    final now = DateTime.now();
    
    // Simulate natural variations
    final time = now.millisecondsSinceEpoch / 1000.0;
    
    // Mock accelerometer (simulate walking/movement)
    final accelVariation = sin(time * 2) * 0.5;
    final accelX = _mockAccelBase + accelVariation + (_random.nextDouble() - 0.5) * 0.2;
    final accelY = _mockAccelBase * 0.8 + cos(time * 1.5) * 0.3 + (_random.nextDouble() - 0.5) * 0.2;
    final accelZ = 9.8 + (_random.nextDouble() - 0.5) * 0.5; // Earth gravity with noise
    
    _accelerometerController.add(AccelerometerData(x: accelX, y: accelY, z: accelZ));
    
    // Mock gyroscope (simulate natural rotation)
    final gyroX = _mockGyroBase * sin(time * 0.8) + (_random.nextDouble() - 0.5) * 0.02;
    final gyroY = _mockGyroBase * cos(time * 0.6) + (_random.nextDouble() - 0.5) * 0.02;
    final gyroZ = _mockGyroBase * sin(time * 1.2) + (_random.nextDouble() - 0.5) * 0.02;
    
    _gyroscopeController.add(GyroscopeData(x: gyroX, y: gyroY, z: gyroZ));
    
    // Mock magnetometer (simulate compass with interference)
    final magX = _mockMagnetoBase + sin(time * 0.3) * 2 + (_random.nextDouble() - 0.5);
    final magY = _mockMagnetoBase * 0.9 + cos(time * 0.4) * 1.5 + (_random.nextDouble() - 0.5);
    final magZ = _mockMagnetoBase * 1.1 + sin(time * 0.2) * 1 + (_random.nextDouble() - 0.5);
    
    _magnetometerController.add(MagnetometerData(x: magX, y: magY, z: magZ));
    
    // Generate data less frequently for other sensors
    if (timer.tick % 50 == 0) { // Every 5 seconds
      // Mock location (simulate slight GPS drift)
      _mockLocationLat += (_random.nextDouble() - 0.5) * 0.00001;
      _mockLocationLng += (_random.nextDouble() - 0.5) * 0.00001;
      
      _locationController.add(LocationData(
        latitude: _mockLocationLat,
        longitude: _mockLocationLng,
        altitude: 50 + (_random.nextDouble() - 0.5) * 10,
        accuracy: 3 + _random.nextDouble() * 2,
        speed: 0.5 + _random.nextDouble() * 2,
      ));
    }
    
    if (timer.tick % 100 == 0) { // Every 10 seconds
      // Mock battery (slowly decrease)
      if (_random.nextDouble() < 0.1) {
        _mockBatteryLevel = max(0, _mockBatteryLevel - 1);
      }
      
      _batteryController.add(BatteryData(
        batteryLevel: _mockBatteryLevel,
        batteryState: _mockBatteryLevel > 20 ? 'discharging' : 'low',
        isCharging: false,
      ));
    }
    
    if (timer.tick % 20 == 0) { // Every 2 seconds
      // Mock light sensor (simulate day/night cycle or indoor changes)
      _mockLightLux += (_random.nextDouble() - 0.5) * 50;
      _mockLightLux = max(0, min(10000, _mockLightLux));
      
      _lightController.add(LightData(luxValue: _mockLightLux));
    }
    
    if (timer.tick % 25 == 0) { // Every 2.5 seconds
      // Mock proximity sensor (random near/far)
      if (_random.nextDouble() < 0.3) {
        _mockProximityNear = !_mockProximityNear;
      }
      
      _proximityController.add(ProximityData(
        isNear: _mockProximityNear,
        distance: _mockProximityNear ? 0.0 : 5.0 + _random.nextDouble() * 10,
      ));
    }
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
    if (kIsWeb) {
      // On web, all sensors are "active" if monitoring is running with mock data
      final isActive = _isMonitoring && _mockDataTimer != null;
      return {
        'accelerometer': isActive,
        'gyroscope': isActive,
        'magnetometer': isActive,
        'location': isActive,
        'battery': isActive,
        'light': isActive,
        'proximity': isActive,
      };
    } else {
      // On mobile, check actual sensor subscriptions
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
