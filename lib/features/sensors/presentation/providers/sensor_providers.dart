import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_hub/features/sensors/data/models/sensor_data.dart';
import 'package:sensor_hub/infrastructure/infrastructure.dart';

// Sensor Service Provider
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

// NVIDIA AI Service Provider
final nvidiaAiServiceProvider = Provider<NvidiaAiService>((ref) {
  return NvidiaAiService();
});

// Monitoring State Provider
final isMonitoringProvider = StateProvider<bool>((ref) => false);

// Accelerometer Stream Provider
final accelerometerStreamProvider = StreamProvider<AccelerometerData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.accelerometerStream;
});

// Gyroscope Stream Provider
final gyroscopeStreamProvider = StreamProvider<GyroscopeData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.gyroscopeStream;
});

// Magnetometer Stream Provider
final magnetometerStreamProvider = StreamProvider<MagnetometerData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.magnetometerStream;
});

// Location Stream Provider
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.locationStream;
});

// Battery Stream Provider
final batteryStreamProvider = StreamProvider<BatteryData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.batteryStream;
});

// Light Stream Provider
final lightStreamProvider = StreamProvider<LightData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.lightStream;
});

// Proximity Stream Provider
final proximityStreamProvider = StreamProvider<ProximityData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.proximityStream;
});

// Sensor Data History Provider (stores last N readings for each sensor)
class SensorHistoryNotifier
    extends StateNotifier<Map<String, List<SensorData>>> {
  static const int maxHistorySize = 100;

  SensorHistoryNotifier()
    : super({
        'accelerometer': [],
        'gyroscope': [],
        'magnetometer': [],
        'location': [],
        'battery': [],
        'light': [],
        'proximity': [],
      });

  void addData(String sensorType, SensorData data) {
    final currentList = state[sensorType] ?? [];
    final updatedList = [...currentList, data];

    // Keep only the last maxHistorySize items
    if (updatedList.length > maxHistorySize) {
      updatedList.removeAt(0);
    }

    state = {...state, sensorType: updatedList};
  }

  void clearHistory(String sensorType) {
    state = {...state, sensorType: []};
  }

  void clearAllHistory() {
    state = {
      'accelerometer': [],
      'gyroscope': [],
      'magnetometer': [],
      'location': [],
      'battery': [],
      'light': [],
      'proximity': [],
    };
  }
}

final sensorHistoryProvider =
    StateNotifierProvider<SensorHistoryNotifier, Map<String, List<SensorData>>>(
      (ref) {
        return SensorHistoryNotifier();
      },
    );

// AI Insights Provider
final aiInsightsProvider = FutureProvider.family<AIInsight, List<SensorData>>((
  ref,
  sensorData,
) async {
  final aiService = ref.watch(nvidiaAiServiceProvider);
  return await aiService.analyzeSensorData(sensorData);
});

// Activity Summary Provider
final activitySummaryProvider =
    FutureProvider.family<ActivitySummary, List<SensorData>>((
      ref,
      dailyData,
    ) async {
      final aiService = ref.watch(nvidiaAiServiceProvider);
      return await aiService.generateActivitySummary(dailyData);
    });

// Prediction Provider
final sensorPredictionProvider =
    FutureProvider.family<Prediction, List<SensorData>>((
      ref,
      historicalData,
    ) async {
      final aiService = ref.watch(nvidiaAiServiceProvider);
      return await aiService.predictSensorPatterns(historicalData);
    });

// Selected Sensor Category Provider
final selectedSensorCategoryProvider = StateProvider<String>(
  (ref) => '🏃 Movement',
);

// Sensor Status Provider
final sensorStatusProvider = Provider<Map<String, bool>>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.getSensorStatus();
});

// Chart Data Points Provider (for real-time visualization)
class ChartDataNotifier extends StateNotifier<Map<String, List<double>>> {
  static const int maxChartPoints = 50;

  ChartDataNotifier()
    : super({
        'accelerometer': [],
        'gyroscope': [],
        'magnetometer': [],
        'location': [],
        'battery': [],
        'light': [],
        'proximity': [],
      });

  void addDataPoint(String sensorType, double value) {
    final currentList = state[sensorType] ?? [];
    final updatedList = [...currentList, value];

    // Keep only the last maxChartPoints
    if (updatedList.length > maxChartPoints) {
      updatedList.removeAt(0);
    }

    state = {...state, sensorType: updatedList};
  }

  void clearChartData(String sensorType) {
    state = {...state, sensorType: []};
  }
}

final chartDataProvider =
    StateNotifierProvider<ChartDataNotifier, Map<String, List<double>>>((ref) {
      return ChartDataNotifier();
    });

// Export Settings Provider
class ExportSettings {
  final String format;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> selectedSensors;

  const ExportSettings({
    this.format = 'json',
    this.startDate,
    this.endDate,
    this.selectedSensors = const [],
  });

  ExportSettings copyWith({
    String? format,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? selectedSensors,
  }) {
    return ExportSettings(
      format: format ?? this.format,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      selectedSensors: selectedSensors ?? this.selectedSensors,
    );
  }
}

final exportSettingsProvider = StateProvider<ExportSettings>(
  (ref) => const ExportSettings(),
);

// Theme Mode Provider
final themeModeProvider = StateProvider<bool>(
  (ref) => false, // false = light, true = dark
);
