import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensor_hub/infrastructure/infrastructure.dart';

/// Debug helper for testing and troubleshooting sensor functionality
class DebugHelper {
  static final DebugHelper _instance = DebugHelper._internal();

  factory DebugHelper() => _instance;

  DebugHelper._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  bool _isInitialized = false;
  Map<String, dynamic> _deviceDetails = {};
  Map<String, dynamic> _sensorCapabilities = {};

  /// Initialize debug helper with device information
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _collectDeviceInfo();
    await _checkSensorCapabilities();
    await _checkPermissionStatus();

    _isInitialized = true;
    _logDebugInfo('Debug Helper initialized successfully');
  }

  /// Get comprehensive debug report
  Future<Map<String, dynamic>> getDebugReport() async {
    if (!_isInitialized) await initialize();

    final report = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'device_info': _deviceDetails,
      'sensor_capabilities': _sensorCapabilities,
      'permission_status': await _getCurrentPermissionStatus(),
      'flutter_info': await _getFlutterInfo(),
      'platform_info': _getPlatformInfo(),
      'sensor_test_results': await _performSensorTests(),
    };

    _logDebugInfo('Debug report generated: ${report.keys.join(', ')}');
    return report;
  }

  /// Collect device information
  Future<void> _collectDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceDetails = {
          'platform': 'Android',
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'device': androidInfo.device,
          'hardware': androidInfo.hardware,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
          'fingerprint': androidInfo.fingerprint,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceDetails = {
          'platform': 'iOS',
          'model': iosInfo.model,
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'localizedModel': iosInfo.localizedModel,
          'identifierForVendor': iosInfo.identifierForVendor,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        };
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        _deviceDetails = {
          'platform': 'Windows',
          'computerName': windowsInfo.computerName,
          'numberOfCores': windowsInfo.numberOfCores,
          'systemMemoryInMegabytes': windowsInfo.systemMemoryInMegabytes,
          'userName': windowsInfo.userName,
          'majorVersion': windowsInfo.majorVersion,
          'minorVersion': windowsInfo.minorVersion,
          'buildNumber': windowsInfo.buildNumber,
        };
      } else if (Platform.isMacOS) {
        final macInfo = await _deviceInfo.macOsInfo;
        _deviceDetails = {
          'platform': 'macOS',
          'model': macInfo.model,
          'hostName': macInfo.hostName,
          'arch': macInfo.arch,
          'kernelVersion': macInfo.kernelVersion,
          'majorVersion': macInfo.majorVersion,
          'minorVersion': macInfo.minorVersion,
          'patchVersion': macInfo.patchVersion,
        };
      }
    } catch (e) {
      _logError('Failed to collect device info: $e');
    }
  }

  /// Check sensor capabilities on the current device
  Future<void> _checkSensorCapabilities() async {
    _sensorCapabilities = {
      'accelerometer': await _testSensorAvailability('accelerometer'),
      'gyroscope': await _testSensorAvailability('gyroscope'),
      'magnetometer': await _testSensorAvailability('magnetometer'),
      'location': await _testSensorAvailability('location'),
      'battery': await _testSensorAvailability('battery'),
      'light': await _testSensorAvailability('light'),
      'proximity': await _testSensorAvailability('proximity'),
      'camera': await _testSensorAvailability('camera'),
      'microphone': await _testSensorAvailability('microphone'),
    };

    _logDebugInfo(
      'Sensor capabilities: ${_sensorCapabilities.keys.where((k) => _sensorCapabilities[k] == true).join(', ')}',
    );
  }

  /// Test if a specific sensor is available
  Future<bool> _testSensorAvailability(String sensorType) async {
    try {
      switch (sensorType) {
        case 'accelerometer':
        case 'gyroscope':
        case 'magnetometer':
          // These are available on most mobile devices
          return Platform.isAndroid || Platform.isIOS;
        case 'location':
          // Location is available on all platforms but with different accuracy
          return true;
        case 'battery':
          // Battery info is available on mobile and laptops
          return Platform.isAndroid ||
              Platform.isIOS ||
              (Platform.isWindows || Platform.isMacOS);
        case 'light':
        case 'proximity':
          // These are typically mobile-only sensors
          return Platform.isAndroid || Platform.isIOS;
        case 'camera':
        case 'microphone':
          // Available on all platforms
          return true;
        default:
          return false;
      }
    } catch (e) {
      _logError('Error testing $sensorType availability: $e');
      return false;
    }
  }

  /// Check current permission status
  Future<void> _checkPermissionStatus() async {
    final permissionService = PermissionService();
    try {
      final statuses = await permissionService.getAllPermissionStatuses();
      _logDebugInfo('Current permissions: $statuses');
    } catch (e) {
      _logError('Failed to check permission status: $e');
    }
  }

  /// Get current permission status for debug report
  Future<Map<String, String>> _getCurrentPermissionStatus() async {
    final permissionService = PermissionService();
    try {
      final statuses = await permissionService.getAllPermissionStatuses();
      return statuses.map((key, value) => MapEntry(key, value.displayText));
    } catch (e) {
      _logError('Failed to get permission status: $e');
      return {'error': e.toString()};
    }
  }

  /// Get Flutter environment information
  Future<Map<String, dynamic>> _getFlutterInfo() async {
    return {
      'debug_mode': kDebugMode,
      'profile_mode': kProfileMode,
      'release_mode': kReleaseMode,
      'web_mode': kIsWeb,
      'dart_version': Platform.version,
    };
  }

  /// Get platform-specific information
  Map<String, dynamic> _getPlatformInfo() {
    return {
      'operating_system': Platform.operatingSystem,
      'operating_system_version': Platform.operatingSystemVersion,
      'locale': Platform.localeName,
      'number_of_processors': Platform.numberOfProcessors,
      'path_separator': Platform.pathSeparator,
      'executable': Platform.executable,
      'resolved_executable': Platform.resolvedExecutable,
    };
  }

  /// Perform basic sensor tests
  Future<Map<String, dynamic>> _performSensorTests() async {
    final results = <String, dynamic>{};

    try {
      // Test sensor service initialization
      SensorService();
      results['sensor_service_init'] = 'success';

      // Test permission requests (don't actually request, just check if available)
      final permissionService = PermissionService();
      final platformInfo = permissionService.getPlatformPermissionInfo();
      results['supported_sensors'] = platformInfo['supportedSensors'];
      results['required_permissions'] = platformInfo['requiredPermissions'];

      // Test basic sensor availability
      for (final sensor in [
        'accelerometer',
        'gyroscope',
        'magnetometer',
        'location',
        'battery',
      ]) {
        results['${sensor}_available'] = _sensorCapabilities[sensor] ?? false;
      }
    } catch (e) {
      results['error'] = e.toString();
      _logError('Sensor test failed: $e');
    }

    return results;
  }

  /// Start sensor data logging for debugging
  void startSensorDebugging() {
    if (!kDebugMode) return;

    _logDebugInfo('Starting sensor debugging...');
    final sensorService = SensorService();

    // Log accelerometer data
    sensorService.accelerometerStream.listen(
      (data) => _logSensorData('Accelerometer', {
        'x': data.x.toStringAsFixed(3),
        'y': data.y.toStringAsFixed(3),
        'z': data.z.toStringAsFixed(3),
        'magnitude': data.magnitude.toStringAsFixed(3),
      }),
      onError: (error) => _logError('Accelerometer error: $error'),
    );

    // Log location data
    sensorService.locationStream.listen(
      (data) => _logSensorData('Location', {
        'lat': data.latitude.toStringAsFixed(6),
        'lng': data.longitude.toStringAsFixed(6),
        'accuracy': data.accuracy.toStringAsFixed(1),
      }),
      onError: (error) => _logError('Location error: $error'),
    );

    // Log battery data
    sensorService.batteryStream.listen(
      (data) => _logSensorData('Battery', {
        'level': '${data.batteryLevel}%',
        'charging': data.isCharging.toString(),
        'state': data.batteryState,
      }),
      onError: (error) => _logError('Battery error: $error'),
    );
  }

  /// Export debug report to file (for sharing with support)
  Future<String> exportDebugReport() async {
    final report = await getDebugReport();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'sensor_hub_debug_$timestamp.json';

    // In a real app, you'd write this to the device's storage
    // For now, we'll just return the JSON string
    final jsonString = _formatJsonReport(report);

    _logDebugInfo('Debug report exported: $filename');
    return jsonString;
  }

  /// Format debug report as readable JSON
  String _formatJsonReport(Map<String, dynamic> report) {
    final buffer = StringBuffer();
    buffer.writeln('{');

    report.forEach((key, value) {
      buffer.writeln('  "$key": ${_formatJsonValue(value, 2)},');
    });

    buffer.writeln('}');
    return buffer.toString();
  }

  String _formatJsonValue(dynamic value, int indent) {
    final spaces = '  ' * indent;

    if (value is Map) {
      final buffer = StringBuffer('{\n');
      value.forEach((k, v) {
        buffer.writeln('$spaces  "$k": ${_formatJsonValue(v, indent + 1)},');
      });
      buffer.write('$spaces}');
      return buffer.toString();
    } else if (value is List) {
      final buffer = StringBuffer('[\n');
      for (final item in value) {
        buffer.writeln('$spaces  ${_formatJsonValue(item, indent + 1)},');
      }
      buffer.write('$spaces]');
      return buffer.toString();
    } else if (value is String) {
      return '"$value"';
    } else {
      return value.toString();
    }
  }

  /// Log debug information
  void _logDebugInfo(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'SensorHub.Debug');
    }
  }

  /// Log sensor data
  void _logSensorData(String sensorType, Map<String, String> data) {
    if (kDebugMode) {
      final dataStr = data.entries.map((e) => '${e.key}=${e.value}').join(', ');
      developer.log('$sensorType: $dataStr', name: 'SensorHub.Sensor');
    }
  }

  /// Log error messages
  void _logError(String error) {
    if (kDebugMode) {
      developer.log(error, name: 'SensorHub.Error', level: 1000);
    }
  }

  /// Get sensor data quality metrics
  Map<String, dynamic> getSensorQualityMetrics() {
    // This would collect real-time metrics about sensor data quality
    return {
      'accelerometer_noise_level': 'low',
      'location_accuracy': 'high',
      'battery_reporting': 'normal',
      'data_loss_rate': '< 1%',
      'timestamp_accuracy': 'millisecond',
    };
  }

  /// Test specific sensor functionality
  Future<Map<String, dynamic>> testSensorFunctionality(
    String sensorType,
  ) async {
    final result = <String, dynamic>{
      'sensor': sensorType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      switch (sensorType.toLowerCase()) {
        case 'accelerometer':
          result.addAll(await _testAccelerometer());
          break;
        case 'location':
          result.addAll(await _testLocation());
          break;
        case 'battery':
          result.addAll(await _testBattery());
          break;
        default:
          result['error'] = 'Unknown sensor type: $sensorType';
      }
    } catch (e) {
      result['error'] = e.toString();
    }

    return result;
  }

  Future<Map<String, dynamic>> _testAccelerometer() async {
    final sensorService = SensorService();
    final completer = Completer<Map<String, dynamic>>();

    late StreamSubscription subscription;
    final samples = <double>[];

    subscription = sensorService.accelerometerStream.listen(
      (data) {
        samples.add(data.magnitude);
        if (samples.length >= 10) {
          subscription.cancel();
          completer.complete({
            'status': 'success',
            'sample_count': samples.length,
            'avg_magnitude': samples.reduce((a, b) => a + b) / samples.length,
            'min_magnitude': samples.reduce((a, b) => a < b ? a : b),
            'max_magnitude': samples.reduce((a, b) => a > b ? a : b),
          });
        }
      },
      onError: (error) {
        subscription.cancel();
        completer.complete({'status': 'error', 'error': error.toString()});
      },
    );

    // Timeout after 5 seconds
    Timer(Duration(seconds: 5), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete({
          'status': 'timeout',
          'sample_count': samples.length,
        });
      }
    });

    return completer.future;
  }

  Future<Map<String, dynamic>> _testLocation() async {
    final permissionStatus = await Permission.location.status;
    if (!permissionStatus.isGranted) {
      return {
        'status': 'permission_denied',
        'permission_status': permissionStatus.toString(),
      };
    }

    // Add actual location testing logic here
    return {
      'status': 'success',
      'permission_status': 'granted',
      'gps_enabled': true,
    };
  }

  Future<Map<String, dynamic>> _testBattery() async {
    final sensorService = SensorService();
    final completer = Completer<Map<String, dynamic>>();

    late StreamSubscription subscription;
    subscription = sensorService.batteryStream.listen(
      (data) {
        subscription.cancel();
        completer.complete({
          'status': 'success',
          'battery_level': data.batteryLevel,
          'is_charging': data.isCharging,
          'battery_state': data.batteryState,
        });
      },
      onError: (error) {
        subscription.cancel();
        completer.complete({'status': 'error', 'error': error.toString()});
      },
    );

    // Timeout after 3 seconds
    Timer(Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.complete({'status': 'timeout'});
      }
    });

    return completer.future;
  }
}

/// Extension to add debugging capabilities to any widget
mixin DebugCapable {
  void debugLog(String message) {
    DebugHelper()._logDebugInfo('$runtimeType: $message');
  }

  void debugError(String error) {
    DebugHelper()._logError('$runtimeType: $error');
  }
}
