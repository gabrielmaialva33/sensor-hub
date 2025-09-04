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

// Human Insights Service Provider
final humanInsightsServiceProvider = Provider<HumanInsightsService>((ref) {
  return HumanInsightsService();
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

// ============ Human Insights Providers ============

// Real-time Human Insights Provider
final realTimeInsightsProvider = FutureProvider.family<HumanInsight, List<SensorData>>((
  ref,
  currentData,
) async {
  final humanInsightsService = ref.watch(humanInsightsServiceProvider);
  return await humanInsightsService.generateRealTimeInsight(currentData);
});

// Unusual Pattern Detection Provider
final unusualPatternProvider = FutureProvider.family<HumanInsight?, List<SensorData>>((
  ref,
  recentData,
) async {
  final humanInsightsService = ref.watch(humanInsightsServiceProvider);
  return await humanInsightsService.detectUnusualPatterns(recentData);
});

// Daily Summary Provider with Human Touch
final humanDailySummaryProvider = FutureProvider.family<DailySummary, List<SensorData>>((
  ref,
  dailyData,
) async {
  final humanInsightsService = ref.watch(humanInsightsServiceProvider);
  return await humanInsightsService.generateDailySummary(dailyData);
});

// Weekly Summary Provider with Motivation
final humanWeeklySummaryProvider = FutureProvider.family<WeeklySummary, List<SensorData>>((
  ref,
  weeklyData,
) async {
  final humanInsightsService = ref.watch(humanInsightsServiceProvider);
  return await humanInsightsService.generateWeeklySummary(weeklyData);
});

// Health Recommendations Provider
final healthRecommendationsProvider = FutureProvider.family<List<HealthRecommendation>, Map<String, dynamic>>((
  ref,
  behaviorData,
) async {
  final humanInsightsService = ref.watch(humanInsightsServiceProvider);
  final behaviorPattern = behaviorData['pattern'] as String? ?? 'unknown';
  final healthMetrics = behaviorData['metrics'] as Map<String, double>? ?? {};
  
  return await humanInsightsService.searchHealthRecommendations(behaviorPattern, healthMetrics);
});

// Current Behavior Classification Provider
final currentBehaviorProvider = Provider.family<String, List<SensorData>>((ref, sensorData) {
  if (sensorData.isEmpty) return 'aguardando_dados';
  
  final accelerometerData = sensorData.where((d) => d.sensorType == 'accelerometer').cast<AccelerometerData>();
  final locationData = sensorData.where((d) => d.sensorType == 'location').cast<LocationData>();
  
  if (accelerometerData.isNotEmpty) {
    final avgMovement = accelerometerData.map((d) => d.magnitude).reduce((a, b) => a + b) / accelerometerData.length;
    
    // Check if driving (has location with speed data)
    if (locationData.isNotEmpty) {
      final speeds = locationData.where((d) => d.speed != null && d.speed! > 0).map((d) => d.speed!);
      if (speeds.isNotEmpty) {
        final avgSpeed = speeds.reduce((a, b) => a + b) / speeds.length;
        if (avgSpeed > 15 && avgMovement < 6) return 'dirigindo';
      }
    }
    
    // Classify based on movement
    if (avgMovement > 15) return 'correndo';
    if (avgMovement > 5) return 'caminhando';
    if (avgMovement > 2) return 'movimento_leve';
    return 'parado';
  }
  
  return 'analisando';
});

// Environment Classification Provider
final environmentProvider = Provider.family<String, List<SensorData>>((ref, sensorData) {
  final lightData = sensorData.where((d) => d.sensorType == 'light').cast<LightData>();
  
  if (lightData.isNotEmpty) {
    final avgLight = lightData.map((d) => d.luxValue).reduce((a, b) => a + b) / lightData.length;
    
    if (avgLight < 10) return 'escuro';
    if (avgLight < 200) return 'interno_escuro';
    if (avgLight < 1000) return 'interno_claro';
    if (avgLight < 10000) return 'externo_sombra';
    return 'externo_sol';
  }
  
  return 'ambiente_desconhecido';
});

// Wellness Score Provider (0-10 scale)
final wellnessScoreProvider = Provider.family<int, List<SensorData>>((ref, sensorData) {
  if (sensorData.isEmpty) return 5;
  
  int score = 5; // Start with neutral
  
  // Movement score (0-4 points)
  final behavior = ref.watch(currentBehaviorProvider(sensorData));
  switch (behavior) {
    case 'correndo':
    case 'caminhando':
      score += 3;
      break;
    case 'movimento_leve':
      score += 2;
      break;
    case 'parado':
      score -= 1;
      break;
  }
  
  // Environment score (0-3 points)
  final environment = ref.watch(environmentProvider(sensorData));
  switch (environment) {
    case 'externo_sol':
    case 'interno_claro':
      score += 2;
      break;
    case 'externo_sombra':
      score += 1;
      break;
    case 'escuro':
      score -= 1;
      break;
  }
  
  // Battery correlation (health awareness) (0-1 point)
  final batteryData = sensorData.where((d) => d.sensorType == 'battery').cast<BatteryData>();
  if (batteryData.isNotEmpty) {
    final avgBattery = batteryData.map((d) => d.batteryLevel).reduce((a, b) => a + b) / batteryData.length;
    if (avgBattery > 50) score += 1;
  }
  
  return score.clamp(0, 10);
});

// Insight Display Controller (manages what insights to show and when)
class InsightDisplayNotifier extends StateNotifier<InsightDisplayState> {
  InsightDisplayNotifier() : super(const InsightDisplayState());
  
  void showInsight(HumanInsight insight) {
    state = state.copyWith(
      currentInsight: insight,
      lastShown: DateTime.now(),
    );
  }
  
  void hideInsight() {
    state = state.copyWith(currentInsight: null);
  }
  
  void snoozeInsight(Duration duration) {
    state = state.copyWith(
      snoozedUntil: DateTime.now().add(duration),
    );
  }
}

final insightDisplayProvider = StateNotifierProvider<InsightDisplayNotifier, InsightDisplayState>((ref) {
  return InsightDisplayNotifier();
});

// State class for insight display
class InsightDisplayState {
  final HumanInsight? currentInsight;
  final DateTime? lastShown;
  final DateTime? snoozedUntil;
  
  const InsightDisplayState({
    this.currentInsight,
    this.lastShown,
    this.snoozedUntil,
  });
  
  InsightDisplayState copyWith({
    HumanInsight? currentInsight,
    DateTime? lastShown,
    DateTime? snoozedUntil,
  }) {
    return InsightDisplayState(
      currentInsight: currentInsight ?? this.currentInsight,
      lastShown: lastShown ?? this.lastShown,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }
  
  bool get isSnoozeActive => 
    snoozedUntil != null && DateTime.now().isBefore(snoozedUntil!);
}
