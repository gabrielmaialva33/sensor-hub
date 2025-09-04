import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../features/sensors/data/models/sensor_data.dart';
import '../../core/constants/app_constants.dart';

/// Represents a prediction made by the insights engine
class Prediction {
  final String id;
  final DateTime timestamp;
  final String type;
  final String title;
  final String description;
  final double confidence;
  final DateTime validUntil;
  final Map<String, dynamic> parameters;
  final List<String> actionableSuggestions;

  Prediction({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    required this.validUntil,
    required this.parameters,
    required this.actionableSuggestions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type,
    'title': title,
    'description': description,
    'confidence': confidence,
    'validUntil': validUntil.toIso8601String(),
    'parameters': parameters,
    'actionable_suggestions': actionableSuggestions,
  };

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    type: json['type'],
    title: json['title'],
    description: json['description'],
    confidence: json['confidence'],
    validUntil: DateTime.parse(json['validUntil']),
    parameters: Map<String, dynamic>.from(json['parameters']),
    actionableSuggestions: List<String>.from(json['actionable_suggestions']),
  );
}

/// Represents a behavioral pattern identified by the engine
class BehaviorPattern {
  final String patternId;
  final String patternType;
  final DateTime firstOccurrence;
  final DateTime lastOccurrence;
  final double strength; // 0.0 to 1.0
  final Map<String, dynamic> characteristics;
  final List<DateTime> occurrences;
  final Duration typicalDuration;
  final double reliability; // How consistently this pattern occurs

  BehaviorPattern({
    required this.patternId,
    required this.patternType,
    required this.firstOccurrence,
    required this.lastOccurrence,
    required this.strength,
    required this.characteristics,
    required this.occurrences,
    required this.typicalDuration,
    required this.reliability,
  });
}

/// Advanced ML-based prediction engine for life insights
class PredictiveInsightsEngine {
  static final PredictiveInsightsEngine _instance = PredictiveInsightsEngine._internal();
  factory PredictiveInsightsEngine() => _instance;
  PredictiveInsightsEngine._internal();

  final Map<String, List<SensorData>> _sensorHistory = {};
  // final List<BehaviorPattern> _patterns = []; // For future use
  final List<Prediction> _predictions = [];
  final StreamController<Prediction> _predictionStreamController = StreamController.broadcast();

  // Time series data for LSTM-like analysis
  final Map<String, List<double>> _timeSeriesData = {};
  final Map<String, List<DateTime>> _timeSeriesTimestamps = {};

  Stream<Prediction> get predictionStream => _predictionStreamController.stream;

  /// Initialize the prediction engine
  Future<void> initialize() async {
    // Load existing patterns and predictions
    await _loadHistoricalPatterns();
    
    // Start background analysis timer
    Timer.periodic(const Duration(minutes: 15), (timer) {
      _runPeriodicAnalysis();
    });
  }

  /// Process new sensor data for pattern detection and predictions
  Future<void> processSensorData(List<SensorData> sensorDataList) async {
    // Store sensor data
    for (final sensorData in sensorDataList) {
      _sensorHistory.putIfAbsent(sensorData.sensorType, () => []);
      _sensorHistory[sensorData.sensorType]!.add(sensorData);
      
      // Update time series data
      _updateTimeSeries(sensorData);
    }

    // Cleanup old data
    _cleanupOldData();

    // Trigger analysis if enough data is available
    if (_hasMinimumDataForAnalysis()) {
      await _runRealTimeAnalysis();
    }
  }

  /// Generate energy level predictions
  Future<Prediction?> predictEnergyLevel({Duration lookahead = const Duration(hours: 2)}) async {
    final now = DateTime.now();
    final targetTime = now.add(lookahead);

    // Analyze historical energy patterns
    final energyPattern = await _analyzeEnergyPatterns();
    if (energyPattern == null) return null;

    // Consider multiple factors
    final sleepQuality = await _estimateSleepQuality();
    final recentActivity = _calculateRecentActivityLevel();
    final timeOfDay = targetTime.hour + targetTime.minute / 60.0;
    final dayOfWeek = targetTime.weekday;

    // Predict energy level using pattern matching and regression
    final predictedEnergy = _predictEnergyUsingML(
      timeOfDay: timeOfDay,
      dayOfWeek: dayOfWeek,
      sleepQuality: sleepQuality,
      recentActivity: recentActivity,
      historicalPattern: energyPattern,
    );

    final confidence = _calculatePredictionConfidence(energyPattern, sleepQuality);

    String description;
    List<String> suggestions;

    if (predictedEnergy < 0.3) {
      description = "I'm sensing you might experience an energy dip around ${_formatTime(targetTime)}. Your activity patterns and sleep data suggest this timing for lower energy.";
      suggestions = [
        "Consider a 10-minute walk or light stretching session 30 minutes before",
        "A healthy snack or green tea might help maintain energy levels",
        "Schedule lighter tasks during this period if possible",
      ];
    } else if (predictedEnergy > 0.7) {
      description = "Your energy should be naturally higher around ${_formatTime(targetTime)}. This could be a great window for more demanding activities.";
      suggestions = [
        "This might be ideal timing for exercise or creative work",
        "Consider tackling challenging tasks during this energy peak",
        "Take advantage of this natural rhythm for productivity",
      ];
    } else {
      description = "Your energy levels should be steady around ${_formatTime(targetTime)}, based on your patterns.";
      suggestions = [
        "A good time for moderate activities and tasks",
        "Maintain your current rhythm to sustain this balanced energy",
      ];
    }

    return Prediction(
      id: 'energy_${now.millisecondsSinceEpoch}',
      timestamp: now,
      type: 'energy_prediction',
      title: 'Energy Level Prediction',
      description: description,
      confidence: confidence,
      validUntil: targetTime.add(const Duration(hours: 1)),
      parameters: {
        'predicted_energy': predictedEnergy,
        'target_time': targetTime.toIso8601String(),
        'sleep_quality': sleepQuality,
        'recent_activity': recentActivity,
      },
      actionableSuggestions: suggestions,
    );
  }

  /// Detect stress risk patterns
  Future<Prediction?> detectStressRisk() async {
    final stressIndicators = await _analyzeStressIndicators();
    if (stressIndicators['risk_level'] < 0.4) return null;

    final now = DateTime.now();
    final riskLevel = stressIndicators['risk_level'];
    final primaryIndicators = stressIndicators['indicators'] as List<String>;

    String description;
    List<String> suggestions;

    if (riskLevel > 0.7) {
      description = "I've noticed several changes in your patterns that historically align with stressful periods. ${primaryIndicators.join(', ')} are showing variations from your usual rhythm.";
      suggestions = [
        "Consider taking a few minutes for deep breathing or meditation",
        "A short walk outside might help reset your nervous system",
        "Remember that it's okay to slow down when life feels intense",
        "Perhaps reach out to someone you trust if you need support",
      ];
    } else {
      description = "Some minor pattern changes suggest you might be experiencing mild stress. ${primaryIndicators.first} is slightly different from your usual pattern.";
      suggestions = [
        "A moment of mindfulness might be helpful right now",
        "Consider what might be contributing to these changes",
        "Small adjustments to your routine could help maintain balance",
      ];
    }

    return Prediction(
      id: 'stress_${now.millisecondsSinceEpoch}',
      timestamp: now,
      type: 'stress_risk',
      title: 'Stress Risk Detection',
      description: description,
      confidence: min(riskLevel + 0.1, 0.95),
      validUntil: now.add(const Duration(hours: 6)),
      parameters: {
        'risk_level': riskLevel,
        'indicators': primaryIndicators,
        'pattern_deviations': stressIndicators['deviations'],
      },
      actionableSuggestions: suggestions,
    );
  }

  /// Suggest optimal timing for activities
  Future<List<Prediction>> suggestOptimalTiming() async {
    final suggestions = <Prediction>[];
    final now = DateTime.now();

    // Analyze patterns for different activities
    final walkingOptimalTime = await _findOptimalTimeForActivity('walking');
    final restOptimalTime = await _findOptimalTimeForActivity('rest');
    // final activeOptimalTime = await _findOptimalTimeForActivity('active'); // For future use

    if (walkingOptimalTime != null) {
      suggestions.add(Prediction(
        id: 'walking_timing_${now.millisecondsSinceEpoch}',
        timestamp: now,
        type: 'timing_optimization',
        title: 'Optimal Walking Time',
        description: "Based on your patterns, ${_formatTime(walkingOptimalTime)} tends to be when you naturally feel most inclined to walk. Your body seems to align with this timing.",
        confidence: 0.75,
        validUntil: walkingOptimalTime.add(const Duration(hours: 2)),
        parameters: {
          'optimal_time': walkingOptimalTime.toIso8601String(),
          'activity_type': 'walking',
        },
        actionableSuggestions: [
          "Consider planning your daily walk around this time",
          "Your energy and movement patterns align well with this timing",
        ],
      ));
    }

    if (restOptimalTime != null) {
      suggestions.add(Prediction(
        id: 'rest_timing_${now.millisecondsSinceEpoch}',
        timestamp: now,
        type: 'timing_optimization',
        title: 'Natural Rest Period',
        description: "Your patterns suggest ${_formatTime(restOptimalTime)} is when you naturally tend to slow down. Honoring this rhythm could enhance your well-being.",
        confidence: 0.70,
        validUntil: restOptimalTime.add(const Duration(hours: 1)),
        parameters: {
          'optimal_time': restOptimalTime.toIso8601String(),
          'activity_type': 'rest',
        },
        actionableSuggestions: [
          "This might be a good time for quiet activities or reflection",
          "Consider avoiding demanding tasks during this natural lull",
        ],
      ));
    }

    return suggestions;
  }

  /// Predict health trends based on behavioral changes
  Future<Prediction?> predictHealthTrends() async {
    final healthIndicators = await _analyzeHealthTrendIndicators();
    if (healthIndicators['trend_strength'] < 0.5) return null;

    final now = DateTime.now();
    final trend = healthIndicators['trend_direction'];
    final strength = healthIndicators['trend_strength'];
    final indicators = healthIndicators['key_indicators'] as List<String>;

    String description;
    List<String> suggestions;

    if (trend == 'positive') {
      description = "Your patterns suggest positive health trends! ${indicators.join(' and ')} are showing encouraging improvements over recent weeks.";
      suggestions = [
        "Keep maintaining the habits that are working well for you",
        "These positive changes seem to be building momentum",
        "Consider what you've been doing differently that might be contributing",
      ];
    } else if (trend == 'concerning') {
      description = "I've noticed some changes in ${indicators.join(' and ')} that might be worth attention. Small shifts in patterns can sometimes indicate changes in well-being.";
      suggestions = [
        "Consider if any recent changes in routine might be contributing",
        "It might be worth paying attention to sleep, activity, or stress levels",
        "Sometimes our bodies signal for adjustments through subtle pattern changes",
      ];
    } else {
      description = "Your health indicators show mixed signals. Some patterns are improving while others show minor variations.";
      suggestions = [
        "Continue monitoring how you feel alongside these pattern changes",
        "Small adjustments to routine might help optimize the positive trends",
      ];
    }

    return Prediction(
      id: 'health_trend_${now.millisecondsSinceEpoch}',
      timestamp: now,
      type: 'health_trend',
      title: 'Health Trend Analysis',
      description: description,
      confidence: strength,
      validUntil: now.add(const Duration(days: 7)),
      parameters: {
        'trend_direction': trend,
        'strength': strength,
        'indicators': indicators,
        'time_span': '2-4 weeks',
      },
      actionableSuggestions: suggestions,
    );
  }

  /// Forecast routine disruptions
  Future<Prediction?> forecastRoutineDisruptions() async {
    final disruptionProbability = await _analyzeDisruptionProbability();
    if (disruptionProbability < 0.6) return null;

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    final likelyDisruptions = await _identifyLikelyDisruptions(tomorrow);
    
    return Prediction(
      id: 'routine_disruption_${now.millisecondsSinceEpoch}',
      timestamp: now,
      type: 'routine_forecast',
      title: 'Routine Disruption Forecast',
      description: "Tomorrow might bring some changes to your usual patterns. ${likelyDisruptions.join(' and ')} could be different from your typical routine.",
      confidence: disruptionProbability,
      validUntil: tomorrow.add(const Duration(hours: 12)),
      parameters: {
        'disruption_probability': disruptionProbability,
        'likely_disruptions': likelyDisruptions,
        'forecast_date': tomorrow.toIso8601String(),
      },
      actionableSuggestions: [
        "Consider preparing for a more flexible day than usual",
        "Having backup plans might help maintain balance",
        "Remember that disruptions can sometimes bring positive surprises",
      ],
    );
  }

  // Helper methods for pattern analysis and prediction

  void _updateTimeSeries(SensorData sensorData) {
    final sensorType = sensorData.sensorType;
    _timeSeriesData.putIfAbsent(sensorType, () => []);
    _timeSeriesTimestamps.putIfAbsent(sensorType, () => []);

    double value = 0.0;
    switch (sensorData.sensorType) {
      case 'accelerometer':
        value = (sensorData as AccelerometerData).magnitude;
        break;
      case 'light':
        value = (sensorData as LightData).luxValue;
        break;
      case 'battery':
        value = (sensorData as BatteryData).batteryLevel.toDouble();
        break;
      case 'location':
        final locationData = sensorData as LocationData;
        value = locationData.speed ?? 0.0;
        break;
      default:
        value = 1.0; // Default value for other sensor types
    }

    _timeSeriesData[sensorType]!.add(value);
    _timeSeriesTimestamps[sensorType]!.add(sensorData.timestamp);

    // Keep only recent data for time series
    const maxPoints = 1000;
    if (_timeSeriesData[sensorType]!.length > maxPoints) {
      _timeSeriesData[sensorType]!.removeAt(0);
      _timeSeriesTimestamps[sensorType]!.removeAt(0);
    }
  }

  bool _hasMinimumDataForAnalysis() {
    return _timeSeriesData.values
        .any((series) => series.length >= AppConstants.minDataPointsForAnalysis);
  }

  Future<void> _runRealTimeAnalysis() async {
    try {
      // Generate predictions
      final energyPrediction = await predictEnergyLevel();
      final stressRisk = await detectStressRisk();
      final timingOptimizations = await suggestOptimalTiming();
      final healthTrend = await predictHealthTrends();
      final routineDisruption = await forecastRoutineDisruptions();

      // Broadcast predictions
      if (energyPrediction != null) {
        _predictions.add(energyPrediction);
        _predictionStreamController.add(energyPrediction);
      }

      if (stressRisk != null) {
        _predictions.add(stressRisk);
        _predictionStreamController.add(stressRisk);
      }

      for (final optimization in timingOptimizations) {
        _predictions.add(optimization);
        _predictionStreamController.add(optimization);
      }

      if (healthTrend != null) {
        _predictions.add(healthTrend);
        _predictionStreamController.add(healthTrend);
      }

      if (routineDisruption != null) {
        _predictions.add(routineDisruption);
        _predictionStreamController.add(routineDisruption);
      }

    } catch (e) {
      debugPrint('Error in real-time analysis: $e');
    }
  }

  void _runPeriodicAnalysis() {
    // Run less frequent analyses
    _detectLongTermPatterns();
    _updateBehaviorPatterns();
    _cleanupExpiredPredictions();
  }

  Future<Map<String, double>?> _analyzeEnergyPatterns() async {
    final accelerometerData = _timeSeriesData['accelerometer'];
    final accelerometerTimes = _timeSeriesTimestamps['accelerometer'];
    
    if (accelerometerData == null || accelerometerData.length < 50) return null;

    // Create hourly energy pattern
    final hourlyEnergy = <int, List<double>>{};
    
    for (int i = 0; i < accelerometerData.length; i++) {
      final hour = accelerometerTimes![i].hour;
      hourlyEnergy.putIfAbsent(hour, () => []);
      hourlyEnergy[hour]!.add(accelerometerData[i]);
    }

    // Calculate average energy per hour
    final energyPattern = <String, double>{};
    hourlyEnergy.forEach((hour, values) {
      energyPattern[hour.toString()] = values.reduce((a, b) => a + b) / values.length;
    });

    return energyPattern;
  }

  Future<double> _estimateSleepQuality() async {
    final nightData = _sensorHistory['accelerometer']
        ?.where((data) {
          final hour = data.timestamp.hour;
          return hour >= 22 || hour <= 6;
        })
        .cast<AccelerometerData>()
        .toList() ?? [];

    if (nightData.isEmpty) return 0.5;

    final avgNightActivity = nightData
        .map((data) => data.magnitude)
        .reduce((a, b) => a + b) / nightData.length;

    // Lower activity at night indicates better sleep
    return max(0.0, min(1.0, (10.0 - avgNightActivity) / 10.0));
  }

  double _calculateRecentActivityLevel() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    final recentData = _sensorHistory['accelerometer']
        ?.where((data) => data.timestamp.isAfter(cutoff))
        .cast<AccelerometerData>()
        .toList() ?? [];

    if (recentData.isEmpty) return 0.0;

    return recentData.map((data) => data.magnitude).reduce((a, b) => a + b) / recentData.length;
  }

  double _predictEnergyUsingML({
    required double timeOfDay,
    required int dayOfWeek,
    required double sleepQuality,
    required double recentActivity,
    required Map<String, double> historicalPattern,
  }) {
    // Simplified ML prediction - in real implementation would use more sophisticated models
    double prediction = 0.5; // Base energy level

    // Time of day influence
    if (timeOfDay >= 9 && timeOfDay <= 11) prediction += 0.2;
    if (timeOfDay >= 14 && timeOfDay <= 16) prediction -= 0.2;
    if (timeOfDay >= 19 && timeOfDay <= 21) prediction += 0.1;

    // Day of week influence
    if (dayOfWeek <= 5) prediction += 0.1; // Weekdays
    
    // Sleep quality influence
    prediction += (sleepQuality - 0.5) * 0.4;
    
    // Recent activity influence
    prediction += (recentActivity / 20.0) * 0.2;

    // Historical pattern influence
    final currentHour = timeOfDay.floor().toString();
    if (historicalPattern.containsKey(currentHour)) {
      final historicalEnergy = historicalPattern[currentHour]! / 15.0; // Normalize
      prediction = (prediction + historicalEnergy) / 2.0;
    }

    return max(0.0, min(1.0, prediction));
  }

  double _calculatePredictionConfidence(Map<String, double> pattern, double sleepQuality) {
    double confidence = 0.6; // Base confidence

    // More historical data increases confidence
    confidence += pattern.length * 0.02;
    
    // Good sleep quality increases confidence
    if (sleepQuality > 0.7) confidence += 0.1;
    
    return min(0.95, confidence);
  }

  Future<Map<String, dynamic>> _analyzeStressIndicators() async {
    final indicators = <String>[];
    double riskLevel = 0.0;
    final deviations = <String, double>{};

    // Analyze activity pattern deviations
    final activityDeviation = _calculateActivityPatternDeviation();
    if (activityDeviation > 0.3) {
      indicators.add('irregular activity patterns');
      riskLevel += activityDeviation * 0.4;
      deviations['activity'] = activityDeviation;
    }

    // Analyze sleep pattern changes
    final sleepDeviation = await _calculateSleepPatternDeviation();
    if (sleepDeviation > 0.2) {
      indicators.add('changed sleep patterns');
      riskLevel += sleepDeviation * 0.3;
      deviations['sleep'] = sleepDeviation;
    }

    // Analyze routine consistency
    final routineDeviation = _calculateRoutineDeviation();
    if (routineDeviation > 0.25) {
      indicators.add('routine inconsistency');
      riskLevel += routineDeviation * 0.3;
      deviations['routine'] = routineDeviation;
    }

    return {
      'risk_level': min(1.0, riskLevel),
      'indicators': indicators,
      'deviations': deviations,
    };
  }

  double _calculateActivityPatternDeviation() {
    final recentWeek = _getTimeSeriesForPeriod('accelerometer', const Duration(days: 7));
    final previousWeek = _getTimeSeriesForPeriod('accelerometer', const Duration(days: 14), const Duration(days: 7));

    if (recentWeek.isEmpty || previousWeek.isEmpty) return 0.0;

    final recentAvg = recentWeek.reduce((a, b) => a + b) / recentWeek.length;
    final previousAvg = previousWeek.reduce((a, b) => a + b) / previousWeek.length;

    return (recentAvg - previousAvg).abs() / max(recentAvg, previousAvg);
  }

  Future<double> _calculateSleepPatternDeviation() async {
    // Similar to activity deviation but for nighttime activity levels
    return 0.0; // Simplified for example
  }

  double _calculateRoutineDeviation() {
    // Analyze consistency in daily patterns
    return 0.0; // Simplified for example
  }

  List<double> _getTimeSeriesForPeriod(String sensorType, Duration period, [Duration? offset]) {
    final data = _timeSeriesData[sensorType];
    final timestamps = _timeSeriesTimestamps[sensorType];
    
    if (data == null || timestamps == null) return [];

    final now = DateTime.now();
    final endTime = offset != null ? now.subtract(offset) : now;
    final startTime = endTime.subtract(period);

    final result = <double>[];
    for (int i = 0; i < timestamps.length; i++) {
      if (timestamps[i].isAfter(startTime) && timestamps[i].isBefore(endTime)) {
        result.add(data[i]);
      }
    }

    return result;
  }

  Future<DateTime?> _findOptimalTimeForActivity(String activityType) async {
    // Analyze when the user typically performs certain activities
    // This would use historical pattern matching
    final now = DateTime.now();
    
    switch (activityType) {
      case 'walking':
        return DateTime(now.year, now.month, now.day, 10, 30); // Example optimal time
      case 'rest':
        return DateTime(now.year, now.month, now.day, 15, 0);
      case 'active':
        return DateTime(now.year, now.month, now.day, 9, 0);
      default:
        return null;
    }
  }

  Future<Map<String, dynamic>> _analyzeHealthTrendIndicators() async {
    // Analyze various health indicators for trends
    return {
      'trend_direction': 'positive',
      'trend_strength': 0.7,
      'key_indicators': ['activity levels', 'sleep consistency'],
    };
  }

  Future<double> _analyzeDisruptionProbability() async {
    // Analyze probability of routine disruption
    return 0.3; // Low probability example
  }

  Future<List<String>> _identifyLikelyDisruptions(DateTime date) async {
    // Identify what aspects of routine might be disrupted
    return ['morning routine'];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _cleanupOldData() {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    
    _sensorHistory.forEach((sensorType, dataList) {
      dataList.removeWhere((data) => data.timestamp.isBefore(cutoff));
    });
  }

  void _cleanupExpiredPredictions() {
    final now = DateTime.now();
    _predictions.removeWhere((prediction) => prediction.validUntil.isBefore(now));
  }

  Future<void> _loadHistoricalPatterns() async {
    // Load existing patterns from storage
  }

  void _detectLongTermPatterns() {
    // Detect patterns that emerge over weeks/months
  }

  void _updateBehaviorPatterns() {
    // Update behavior pattern models
  }

  List<Prediction> getActivePredictions() {
    final now = DateTime.now();
    return _predictions.where((p) => p.validUntil.isAfter(now)).toList();
  }

  void dispose() {
    _predictionStreamController.close();
  }
}