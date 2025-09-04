import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing all app permissions across platforms
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();

  factory PermissionService() => _instance;

  PermissionService._internal();

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Check and request all necessary permissions for sensor monitoring
  Future<Map<String, PermissionStatus>> requestSensorPermissions() async {
    final Map<String, PermissionStatus> results = {};

    // Core sensor permissions (available on all platforms)
    final corePermissions = <Permission>[
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.locationWhenInUse,
    ];

    // Platform-specific permissions
    if (Platform.isAndroid) {
      corePermissions.addAll([
        Permission.sensors,
        Permission.storage,
        await _getAndroidStoragePermission(),
      ]);
    }

    if (Platform.isIOS) {
      corePermissions.addAll([
        Permission.locationAlways,
        Permission.photos,
        Permission.speech,
        Permission.bluetooth,
      ]);
    }

    // Request permissions in batches to avoid overwhelming the user
    final Map<Permission, PermissionStatus> statuses = await corePermissions
        .request();

    // Convert to string keys for easier access
    for (final entry in statuses.entries) {
      results[entry.key.toString()] = entry.value;
    }

    return results;
  }

  /// Get the appropriate storage permission based on Android SDK version
  Future<Permission> _getAndroidStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // For Android 11+ (API 30+), use MANAGE_EXTERNAL_STORAGE
      if (androidInfo.version.sdkInt >= 30) {
        return Permission.manageExternalStorage;
      } else {
        return Permission.storage;
      }
    }
    return Permission.storage;
  }

  /// Check if a specific permission is granted
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  /// Check if any permission is permanently denied
  Future<bool> hasPermissionsPermanentlyDenied(
    List<Permission> permissions,
  ) async {
    for (final permission in permissions) {
      final status = await permission.status;
      if (status.isPermanentlyDenied) {
        return true;
      }
    }
    return false;
  }

  /// Get permission status for all sensor-related permissions
  Future<Map<String, PermissionStatus>> getAllPermissionStatuses() async {
    final Map<String, PermissionStatus> statuses = {};

    final permissions = <Permission>[
      Permission.camera,
      Permission.microphone,
      Permission.location,
      Permission.locationWhenInUse,
    ];

    if (Platform.isAndroid) {
      permissions.addAll([
        Permission.sensors,
        await _getAndroidStoragePermission(),
      ]);
    }

    if (Platform.isIOS) {
      permissions.addAll([
        Permission.locationAlways,
        Permission.photos,
        Permission.speech,
        Permission.bluetooth,
      ]);
    }

    for (final permission in permissions) {
      statuses[permission.toString()] = await permission.status;
    }

    return statuses;
  }

  /// Request location permissions with proper handling for different use cases
  Future<PermissionStatus> requestLocationPermission({
    bool backgroundLocation = false,
  }) async {
    PermissionStatus status;

    if (Platform.isAndroid) {
      // On Android, first request regular location permission
      status = await Permission.location.request();

      // If background location is needed and regular location is granted
      if (backgroundLocation && status.isGranted) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Background location permission only needed for Android 10+ (API 29+)
        if (androidInfo.version.sdkInt >= 29) {
          status = await Permission.locationAlways.request();
        }
      }
    } else if (Platform.isIOS) {
      // On iOS, request the appropriate permission based on use case
      if (backgroundLocation) {
        status = await Permission.locationAlways.request();
      } else {
        status = await Permission.locationWhenInUse.request();
      }
    } else {
      // For desktop platforms, request basic location
      status = await Permission.location.request();
    }

    return status;
  }

  /// Request camera permission with detailed error handling
  Future<CameraPermissionResult> requestCameraPermission() async {
    final status = await Permission.camera.request();

    switch (status) {
      case PermissionStatus.granted:
        return CameraPermissionResult(
          isGranted: true,
          shouldShowRationale: false,
          message: 'Camera access granted',
        );
      case PermissionStatus.denied:
        return CameraPermissionResult(
          isGranted: false,
          shouldShowRationale:
              await Permission.camera.shouldShowRequestRationale,
          message:
              'Camera access denied. Please allow camera access to capture sensor data.',
        );
      case PermissionStatus.permanentlyDenied:
        return CameraPermissionResult(
          isGranted: false,
          shouldShowRationale: false,
          message:
              'Camera access permanently denied. Please enable it in app settings.',
          shouldOpenSettings: true,
        );
      case PermissionStatus.restricted:
        return CameraPermissionResult(
          isGranted: false,
          shouldShowRationale: false,
          message: 'Camera access restricted by device policy.',
        );
      default:
        return CameraPermissionResult(
          isGranted: false,
          shouldShowRationale: false,
          message: 'Unknown camera permission status',
        );
    }
  }

  /// Request microphone permission
  Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }

  /// Request storage permission for data export
  Future<PermissionStatus> requestStoragePermission() async {
    if (Platform.isAndroid) {
      return await _getAndroidStoragePermission().then(
        (permission) => permission.request(),
      );
    } else if (Platform.isIOS) {
      return await Permission.photos.request();
    }
    return PermissionStatus
        .granted; // Desktop platforms don't need storage permission
  }

  /// Open app settings when permission is permanently denied
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Check if location services are enabled (Android/iOS specific)
  Future<bool> isLocationServiceEnabled() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await Permission.location.serviceStatus.isEnabled;
    }
    return true; // Assume enabled for desktop platforms
  }

  /// Get user-friendly permission names
  String getPermissionDisplayName(Permission permission) {
    switch (permission) {
      case Permission.camera:
        return 'Camera';
      case Permission.microphone:
        return 'Microphone';
      case Permission.location:
        return 'Location';
      case Permission.locationWhenInUse:
        return 'Location (When in Use)';
      case Permission.locationAlways:
        return 'Location (Always)';
      case Permission.storage:
        return 'Storage';
      case Permission.manageExternalStorage:
        return 'File Management';
      case Permission.photos:
        return 'Photos';
      case Permission.sensors:
        return 'Sensors';
      case Permission.speech:
        return 'Speech Recognition';
      case Permission.bluetooth:
        return 'Bluetooth';
      default:
        return permission
            .toString()
            .replaceAll('Permission.', '')
            .toUpperCase();
    }
  }

  /// Get platform-specific permission requirements info
  Map<String, dynamic> getPlatformPermissionInfo() {
    return {
      'platform': Platform.operatingSystem,
      'isAndroid': Platform.isAndroid,
      'isIOS': Platform.isIOS,
      'isWindows': Platform.isWindows,
      'isMacOS': Platform.isMacOS,
      'isLinux': Platform.isLinux,
      'supportedSensors': _getSupportedSensors(),
      'requiredPermissions': _getRequiredPermissions(),
    };
  }

  List<String> _getSupportedSensors() {
    if (Platform.isAndroid || Platform.isIOS) {
      return [
        'accelerometer',
        'gyroscope',
        'magnetometer',
        'location',
        'battery',
        'light',
        'proximity',
        'camera',
        'microphone',
      ];
    } else {
      // Desktop platforms have limited sensor support
      return [
        'camera',
        'microphone',
        'battery', // Limited battery info available
      ];
    }
  }

  List<String> _getRequiredPermissions() {
    final permissions = <String>['camera', 'microphone'];

    if (Platform.isAndroid || Platform.isIOS) {
      permissions.addAll(['location', 'storage']);
    }

    if (Platform.isAndroid) {
      permissions.addAll(['sensors', 'wake_lock', 'foreground_service']);
    }

    if (Platform.isIOS) {
      permissions.addAll([
        'background_location',
        'photos',
        'speech',
        'bluetooth',
      ]);
    }

    return permissions;
  }
}

/// Result class for camera permission requests
class CameraPermissionResult {
  final bool isGranted;
  final bool shouldShowRationale;
  final String message;
  final bool shouldOpenSettings;

  CameraPermissionResult({
    required this.isGranted,
    required this.shouldShowRationale,
    required this.message,
    this.shouldOpenSettings = false,
  });
}

/// Extension to add custom status checks
extension PermissionStatusExtension on PermissionStatus {
  bool get isGrantedOrRestricted =>
      this == PermissionStatus.granted || this == PermissionStatus.restricted;

  String get displayText {
    switch (this) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }
}
