import 'package:uuid/uuid.dart';

/// Base model for all sensor data
abstract class SensorData {
  final String id;
  final DateTime timestamp;
  final String sensorType;

  SensorData({
    String? id,
    DateTime? timestamp,
    required this.sensorType,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson();
  factory SensorData.fromJson(Map<String, dynamic> json) => throw UnimplementedError();
}

/// Accelerometer sensor data
class AccelerometerData extends SensorData {
  final double x;
  final double y;
  final double z;
  final double magnitude;

  AccelerometerData({
    String? id,
    DateTime? timestamp,
    required this.x,
    required this.y,
    required this.z,
  })  : magnitude = _calculateMagnitude(x, y, z),
        super(id: id, timestamp: timestamp, sensorType: 'accelerometer');

  static double _calculateMagnitude(double x, double y, double z) {
    return (x * x + y * y + z * z).abs();
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'x': x,
    'y': y,
    'z': z,
    'magnitude': magnitude,
  };

  factory AccelerometerData.fromJson(Map<String, dynamic> json) => AccelerometerData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    x: json['x'],
    y: json['y'],
    z: json['z'],
  );
}

/// Gyroscope sensor data
class GyroscopeData extends SensorData {
  final double x;
  final double y;
  final double z;

  GyroscopeData({
    String? id,
    DateTime? timestamp,
    required this.x,
    required this.y,
    required this.z,
  }) : super(id: id, timestamp: timestamp, sensorType: 'gyroscope');

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'x': x,
    'y': y,
    'z': z,
  };

  factory GyroscopeData.fromJson(Map<String, dynamic> json) => GyroscopeData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    x: json['x'],
    y: json['y'],
    z: json['z'],
  );
}

/// Magnetometer sensor data
class MagnetometerData extends SensorData {
  final double x;
  final double y;
  final double z;
  final double fieldStrength;

  MagnetometerData({
    String? id,
    DateTime? timestamp,
    required this.x,
    required this.y,
    required this.z,
  })  : fieldStrength = _calculateFieldStrength(x, y, z),
        super(id: id, timestamp: timestamp, sensorType: 'magnetometer');

  static double _calculateFieldStrength(double x, double y, double z) {
    return (x * x + y * y + z * z).abs();
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'x': x,
    'y': y,
    'z': z,
    'fieldStrength': fieldStrength,
  };

  factory MagnetometerData.fromJson(Map<String, dynamic> json) => MagnetometerData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    x: json['x'],
    y: json['y'],
    z: json['z'],
  );
}

/// Location sensor data
class LocationData extends SensorData {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double? speed;

  LocationData({
    String? id,
    DateTime? timestamp,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    this.speed,
  }) : super(id: id, timestamp: timestamp, sensorType: 'location');

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'accuracy': accuracy,
    'speed': speed,
  };

  factory LocationData.fromJson(Map<String, dynamic> json) => LocationData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    latitude: json['latitude'],
    longitude: json['longitude'],
    altitude: json['altitude'],
    accuracy: json['accuracy'],
    speed: json['speed'],
  );
}

/// Battery sensor data
class BatteryData extends SensorData {
  final int batteryLevel;
  final String batteryState;
  final bool isCharging;

  BatteryData({
    String? id,
    DateTime? timestamp,
    required this.batteryLevel,
    required this.batteryState,
    required this.isCharging,
  }) : super(id: id, timestamp: timestamp, sensorType: 'battery');

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'batteryLevel': batteryLevel,
    'batteryState': batteryState,
    'isCharging': isCharging,
  };

  factory BatteryData.fromJson(Map<String, dynamic> json) => BatteryData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    batteryLevel: json['batteryLevel'],
    batteryState: json['batteryState'],
    isCharging: json['isCharging'],
  );
}

/// Light sensor data
class LightData extends SensorData {
  final double luxValue;
  final String lightCondition;

  LightData({
    String? id,
    DateTime? timestamp,
    required this.luxValue,
  })  : lightCondition = _getLightCondition(luxValue),
        super(id: id, timestamp: timestamp, sensorType: 'light');

  static String _getLightCondition(double lux) {
    if (lux < 10) return 'Dark';
    if (lux < 200) return 'Dim';
    if (lux < 400) return 'Normal';
    if (lux < 1000) return 'Bright';
    return 'Very Bright';
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'luxValue': luxValue,
    'lightCondition': lightCondition,
  };

  factory LightData.fromJson(Map<String, dynamic> json) => LightData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    luxValue: json['luxValue'],
  );
}

/// Proximity sensor data
class ProximityData extends SensorData {
  final bool isNear;
  final double? distance;

  ProximityData({
    String? id,
    DateTime? timestamp,
    required this.isNear,
    this.distance,
  }) : super(id: id, timestamp: timestamp, sensorType: 'proximity');

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'sensorType': sensorType,
    'isNear': isNear,
    'distance': distance,
  };

  factory ProximityData.fromJson(Map<String, dynamic> json) => ProximityData(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    isNear: json['isNear'],
    distance: json['distance'],
  );
}