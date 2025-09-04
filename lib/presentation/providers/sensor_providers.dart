import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sensor_data.dart';
import '../../data/services/nvidia_ai_service.dart';
import '../../data/services/sensor_service.dart';
import '../../data/services/supabase_service.dart';

// =============================================================================
// SENSOR SERVICE PROVIDERS
// =============================================================================

/// Provider for the sensor service singleton
final sensorServiceProvider = Provider<SensorService>((ref) {
  return SensorService();
});

/// Provider for monitoring status
final isMonitoringProvider = StateProvider<bool>((ref) => false);

/// Provider for sensor status map
final sensorStatusProvider = StateProvider<Map<String, bool>>((ref) => {});

// =============================================================================
// SENSOR DATA STREAM PROVIDERS
// =============================================================================

/// Accelerometer data stream provider
final accelerometerStreamProvider = StreamProvider<AccelerometerData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.accelerometerStream;
});

/// Gyroscope data stream provider
final gyroscopeStreamProvider = StreamProvider<GyroscopeData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.gyroscopeStream;
});

/// Magnetometer data stream provider
final magnetometerStreamProvider = StreamProvider<MagnetometerData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.magnetometerStream;
});

/// Location data stream provider
final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.locationStream;
});

/// Battery data stream provider
final batteryStreamProvider = StreamProvider<BatteryData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.batteryStream;
});

/// Light sensor data stream provider
final lightStreamProvider = StreamProvider<LightData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.lightStream;
});

/// Proximity sensor data stream provider
final proximityStreamProvider = StreamProvider<ProximityData>((ref) {
  final sensorService = ref.watch(sensorServiceProvider);
  return sensorService.proximityStream;
});

// =============================================================================
// SENSOR DATA HISTORY PROVIDERS
// =============================================================================

/// Provider for maintaining recent sensor data history for charts
final sensorDataHistoryProvider =
    StateNotifierProvider.family<
      SensorDataHistoryNotifier,
      List<SensorData>,
      String
    >((ref, sensorType) {
      return SensorDataHistoryNotifier(sensorType, maxHistory: 50);
    });

/// State notifier for managing sensor data history
class SensorDataHistoryNotifier extends StateNotifier<List<SensorData>> {
  final String sensorType;
  final int maxHistory;

  SensorDataHistoryNotifier(this.sensorType, {this.maxHistory = 50})
    : super([]);

  void addData(SensorData data) {
    final newState = [...state, data];
    if (newState.length > maxHistory) {
      newState.removeRange(0, newState.length - maxHistory);
    }
    state = newState;
  }

  void clearHistory() {
    state = [];
  }

  List<SensorData> getRecentData(int count) {
    if (state.length <= count) return state;
    return state.sublist(state.length - count);
  }
}

// =============================================================================
// CLOUD SERVICE PROVIDERS
// =============================================================================

/// Provider for Supabase service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provider for NVIDIA AI service
final nvidiaAiServiceProvider = Provider<NvidiaAiService>((ref) {
  return NvidiaAiService();
});

// =============================================================================
// AI INSIGHTS PROVIDERS
// =============================================================================

/// Provider for AI insights state
final aiInsightsProvider =
    StateNotifierProvider<AIInsightsNotifier, AIInsightsState>((ref) {
      return AIInsightsNotifier(ref.watch(nvidiaAiServiceProvider));
    });

/// State for AI insights
class AIInsightsState {
  final AIInsight? currentInsight;
  final List<AIInsight> recentInsights;
  final bool isAnalyzing;
  final String? error;

  const AIInsightsState({
    this.currentInsight,
    this.recentInsights = const [],
    this.isAnalyzing = false,
    this.error,
  });

  AIInsightsState copyWith({
    AIInsight? currentInsight,
    List<AIInsight>? recentInsights,
    bool? isAnalyzing,
    String? error,
  }) {
    return AIInsightsState(
      currentInsight: currentInsight ?? this.currentInsight,
      recentInsights: recentInsights ?? this.recentInsights,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error ?? this.error,
    );
  }
}

/// State notifier for AI insights
class AIInsightsNotifier extends StateNotifier<AIInsightsState> {
  final NvidiaAiService _aiService;

  AIInsightsNotifier(this._aiService) : super(const AIInsightsState());

  /// Analyze sensor data and generate insights
  Future<void> analyzeSensorData(List<SensorData> sensorData) async {
    if (sensorData.isEmpty) return;

    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final insight = await _aiService.analyzeSensorData(sensorData);

      final updatedInsights = [insight, ...state.recentInsights];
      if (updatedInsights.length > 10) {
        updatedInsights.removeRange(10, updatedInsights.length);
      }

      state = state.copyWith(
        currentInsight: insight,
        recentInsights: updatedInsights,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, error: e.toString());
    }
  }

  /// Generate activity summary
  Future<void> generateActivitySummary(List<SensorData> dailyData) async {
    if (dailyData.isEmpty) return;

    try {
      final summary = await _aiService.generateActivitySummary(dailyData);
      // Handle activity summary (could be stored separately)
      print('📊 Activity Summary Generated: ${summary.score}/100');
    } catch (e) {
      print('❌ Failed to generate activity summary: $e');
    }
  }

  /// Clear insights
  void clearInsights() {
    state = const AIInsightsState();
  }
}

// =============================================================================
// ANALYTICS PROVIDERS
// =============================================================================

/// Provider for sensor analytics
final sensorAnalyticsProvider = Provider<SensorAnalytics>((ref) {
  return SensorAnalytics();
});

/// Class for sensor data analytics
class SensorAnalytics {
  /// Calculate activity classification based on accelerometer data
  String classifyActivity(List<AccelerometerData> data) {
    if (data.isEmpty) return 'Unknown';

    final avgMagnitude =
        data.map((d) => d.magnitude).reduce((a, b) => a + b) / data.length;

    if (avgMagnitude < 2.0) return 'Stationary';
    if (avgMagnitude < 8.0) return 'Walking';
    if (avgMagnitude < 25.0) return 'Running';
    return 'High Activity';
  }

  /// Calculate environment classification based on light data
  String classifyEnvironment(List<LightData> data) {
    if (data.isEmpty) return 'Unknown';

    final avgLux =
        data.map((d) => d.luxValue).reduce((a, b) => a + b) / data.length;

    if (avgLux < 10) return 'Dark';
    if (avgLux < 500) return 'Indoor';
    if (avgLux < 1000) return 'Dim Light';
    return 'Outdoor/Bright';
  }

  /// Calculate battery health score
  int calculateBatteryHealthScore(List<BatteryData> data) {
    if (data.isEmpty) return 0;

    final recent = data.take(10).toList();
    final avgLevel =
        recent.map((d) => d.batteryLevel).reduce((a, b) => a + b) /
        recent.length;
    final chargingRatio =
        recent.where((d) => d.isCharging).length / recent.length;

    // Simple scoring algorithm
    int score = avgLevel.round();
    if (chargingRatio > 0.7) score -= 10; // Frequent charging penalty
    if (chargingRatio < 0.1) score += 10; // Good battery life bonus

    return score.clamp(0, 100);
  }

  /// Get sensor data statistics
  Map<String, dynamic> getSensorStatistics(List<SensorData> data) {
    if (data.isEmpty) return {};

    final grouped = <String, List<SensorData>>{};
    for (final item in data) {
      grouped.putIfAbsent(item.sensorType, () => []).add(item);
    }

    final stats = <String, dynamic>{};
    grouped.forEach((sensorType, sensorData) {
      stats[sensorType] = {
        'count': sensorData.length,
        'latest': sensorData.last.timestamp,
        'earliest': sensorData.first.timestamp,
        'duration': sensorData.last.timestamp
            .difference(sensorData.first.timestamp)
            .inMinutes,
      };
    });

    return stats;
  }
}

// =============================================================================
// PREFERENCE PROVIDERS
// =============================================================================

/// Provider for user preferences
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, Map<String, dynamic>>((ref) {
      return UserPreferencesNotifier();
    });

/// State notifier for user preferences
class UserPreferencesNotifier extends StateNotifier<Map<String, dynamic>> {
  UserPreferencesNotifier()
    : super({
        'darkMode': false,
        'autoAnalysis': true,
        'samplingRate': 1000, // milliseconds
        'storageRetentionDays': 30,
        'enableNotifications': true,
        'exportFormat': 'json',
      });

  void updatePreference(String key, dynamic value) {
    state = {...state, key: value};
  }

  void resetToDefaults() {
    state = {
      'darkMode': false,
      'autoAnalysis': true,
      'samplingRate': 1000,
      'storageRetentionDays': 30,
      'enableNotifications': true,
      'exportFormat': 'json',
    };
  }
}
