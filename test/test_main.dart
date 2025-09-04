import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../lib/infrastructure/infrastructure.dart';
import '../lib/core/core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize debug helper
  if (kDebugMode) {
    await DebugHelper().initialize();
  }

  runApp(const ProviderScope(child: SensorHubTestApp()));
}

class SensorHubTestApp extends StatelessWidget {
  const SensorHubTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SensorHub Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const TestHomeScreen(),
    );
  }
}

class TestHomeScreen extends ConsumerStatefulWidget {
  const TestHomeScreen({super.key});

  @override
  ConsumerState<TestHomeScreen> createState() => _TestHomeScreenState();
}

class _TestHomeScreenState extends ConsumerState<TestHomeScreen> {
  final SensorService _sensorService = SensorService();
  final PermissionService _permissionService = PermissionService();

  bool _isMonitoring = false;
  Map<String, PermissionStatus> _permissionStatuses = {};

  // ignore: prefer_final_fields
  Map<String, String> _sensorData = {};
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final statuses = await _permissionService.getAllPermissionStatuses();
      setState(() {
        _permissionStatuses = statuses;
      });
    } catch (e) {
      debugPrint('Error checking permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final results = await _permissionService.requestSensorPermissions();
      setState(() {
        _permissionStatuses = results;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions requested: ${results.length} total'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission request failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startMonitoring() async {
    try {
      await _sensorService.startMonitoring();

      // Listen to sensor streams
      _sensorService.accelerometerStream.listen((data) {
        setState(() {
          _sensorData['accelerometer'] =
              'X: ${data.x.toStringAsFixed(2)}, '
              'Y: ${data.y.toStringAsFixed(2)}, '
              'Z: ${data.z.toStringAsFixed(2)}, '
              'Magnitude: ${data.magnitude.toStringAsFixed(2)}';
        });
      });

      _sensorService.batteryStream.listen((data) {
        setState(() {
          _sensorData['battery'] =
              'Level: ${data.batteryLevel}%, '
              'Charging: ${data.isCharging}';
        });
      });

      _sensorService.locationStream.listen((data) {
        setState(() {
          _sensorData['location'] =
              'Lat: ${data.latitude.toStringAsFixed(6)}, '
              'Lng: ${data.longitude.toStringAsFixed(6)}, '
              'Accuracy: ${data.accuracy.toStringAsFixed(1)}m';
        });
      });

      setState(() {
        _isMonitoring = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensor monitoring started'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start monitoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopMonitoring() async {
    try {
      await _sensorService.stopMonitoring();
      setState(() {
        _isMonitoring = false;
        _sensorData.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sensor monitoring stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop monitoring: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateDebugReport() async {
    try {
      final report = await DebugHelper().getDebugReport();
      final jsonString = await DebugHelper().exportDebugReport();

      setState(() {
        _debugInfo =
            'Debug report generated at ${DateTime.now()}\n'
            'Device: ${report['device_info']['platform']}\n'
            'Sensors: ${report['sensor_capabilities'].keys.where((k) => report['sensor_capabilities'][k] == true).join(', ')}\n'
            'Permissions: ${report['permission_status'].keys.length}';
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Debug Report'),
            content: SingleChildScrollView(
              child: Text(
                jsonString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate debug report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SensorHub Test'),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _generateDebugReport,
            icon: const Icon(Icons.bug_report),
            tooltip: 'Generate Debug Report',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permission Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security),
                        const SizedBox(width: 8),
                        Text(
                          'Permissions Status',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _requestPermissions,
                          child: const Text('Request All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_permissionStatuses.isEmpty)
                      const Text('No permissions checked yet')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _permissionStatuses.entries.map((entry) {
                          final isGranted = entry.value.isGranted;
                          return Chip(
                            label: Text(entry.key.split('.').last),
                            backgroundColor: isGranted
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            labelStyle: TextStyle(
                              color: isGranted
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sensor Control Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_isMonitoring ? Icons.sensors : Icons.sensors_off),
                        const SizedBox(width: 8),
                        Text(
                          'Sensor Monitoring',
                          style: theme.textTheme.titleMedium,
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _isMonitoring
                              ? _stopMonitoring
                              : _startMonitoring,
                          child: Text(_isMonitoring ? 'Stop' : 'Start'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!_isMonitoring)
                      const Text('Press Start to begin sensor monitoring')
                    else if (_sensorData.isEmpty)
                      const Text('Waiting for sensor data...')
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _sensorData.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    '${entry.key}:',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Info Card
            if (_debugInfo.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info),
                          const SizedBox(width: 8),
                          Text(
                            'Debug Information',
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _debugInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkPermissions,
        tooltip: 'Refresh Status',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
