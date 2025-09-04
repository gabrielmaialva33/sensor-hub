import 'dart:async';
import '../../features/sensors/data/models/sensor_data.dart';

/// Represents a life event or significant moment detected from sensor data
class LifeEvent {
  final String id;
  final DateTime timestamp;
  final String eventType;
  final String title;
  final String description;
  final Map<String, dynamic> context;
  final double significance; // 0.0 to 1.0
  final List<String> associatedSensors;

  LifeEvent({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.title,
    required this.description,
    required this.context,
    required this.significance,
    required this.associatedSensors,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'eventType': eventType,
    'title': title,
    'description': description,
    'context': context,
    'significance': significance,
    'associatedSensors': associatedSensors,
  };

  factory LifeEvent.fromJson(Map<String, dynamic> json) => LifeEvent(
    id: json['id'],
    timestamp: DateTime.parse(json['timestamp']),
    eventType: json['eventType'],
    title: json['title'],
    description: json['description'],
    context: Map<String, dynamic>.from(json['context']),
    significance: json['significance'],
    associatedSensors: List<String>.from(json['associatedSensors']),
  );
}

/// Represents a life pattern derived from behavioral data
class LifePattern {
  final String patternType;
  final String description;
  final double confidence;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> characteristics;
  final List<DateTime> occurrences;

  LifePattern({
    required this.patternType,
    required this.description,
    required this.confidence,
    required this.startTime,
    required this.endTime,
    required this.characteristics,
    required this.occurrences,
  });
}

/// Generates human-like life narratives from sensor data
class LifeNarrativeService {
  static final LifeNarrativeService _instance = LifeNarrativeService._internal();
  factory LifeNarrativeService() => _instance;
  LifeNarrativeService._internal();

  final List<LifeEvent> _lifeEvents = [];
  // final List<LifePattern> _detectedPatterns = []; // For future use
  final Map<String, List<SensorData>> _sensorHistory = {};
  final StreamController<LifeEvent> _eventStreamController = StreamController.broadcast();
  final StreamController<String> _narrativeStreamController = StreamController.broadcast();

  Stream<LifeEvent> get lifeEventStream => _eventStreamController.stream;
  Stream<String> get narrativeStream => _narrativeStreamController.stream;

  /// Process new sensor data and detect life events/patterns
  Future<void> processSensorData(List<SensorData> sensorDataList) async {
    for (final sensorData in sensorDataList) {
      _sensorHistory.putIfAbsent(sensorData.sensorType, () => []);
      _sensorHistory[sensorData.sensorType]!.add(sensorData);

      // Keep only recent data for pattern detection
      _cleanupOldData();
    }

    // Detect new patterns and events
    await _detectLifePatterns();
    await _detectSignificantEvents();
    await _generateNarratives();
  }

  /// Generate empathetic life narratives
  Future<List<String>> generateDailyNarratives() async {
    final narratives = <String>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Activity-based narratives
    final activityNarrative = _generateActivityNarrative(today);
    if (activityNarrative.isNotEmpty) narratives.add(activityNarrative);

    // Environment-based narratives
    final environmentNarrative = _generateEnvironmentNarrative(today);
    if (environmentNarrative.isNotEmpty) narratives.add(environmentNarrative);

    // Routine-based narratives
    final routineNarrative = _generateRoutineNarrative(today);
    if (routineNarrative.isNotEmpty) narratives.add(routineNarrative);

    // Memory-based narratives
    final memoryNarrative = _generateMemoryNarrative(today);
    if (memoryNarrative.isNotEmpty) narratives.add(memoryNarrative);

    return narratives;
  }

  /// Generate weekly life insights
  Future<List<String>> generateWeeklyInsights() async {
    final insights = <String>[];
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    // Activity trends
    final activityTrend = _analyzeActivityTrend(weekAgo, now);
    if (activityTrend.isNotEmpty) insights.add(activityTrend);

    // Sleep pattern insights
    final sleepInsights = _analyzeSleepPatterns(weekAgo, now);
    if (sleepInsights.isNotEmpty) insights.add(sleepInsights);

    // Environmental changes
    final environmentChanges = _analyzeEnvironmentalChanges(weekAgo, now);
    if (environmentChanges.isNotEmpty) insights.add(environmentChanges);

    // Behavioral consistency
    final consistencyInsights = _analyzeConsistency(weekAgo, now);
    if (consistencyInsights.isNotEmpty) insights.add(consistencyInsights);

    return insights;
  }

  /// Generate proactive suggestions based on patterns
  Future<List<String>> generateProactiveSuggestions() async {
    final suggestions = <String>[];
    final now = DateTime.now();

    // Energy level predictions
    final energyPrediction = await _predictEnergyLevel(now);
    if (energyPrediction.isNotEmpty) suggestions.add(energyPrediction);

    // Stress risk detection
    final stressRisk = await _detectStressRisk(now);
    if (stressRisk.isNotEmpty) suggestions.add(stressRisk);

    // Routine optimization
    final routineOptimization = await _suggestRoutineOptimization();
    if (routineOptimization.isNotEmpty) suggestions.add(routineOptimization);

    // Weather-based suggestions
    final weatherSuggestion = await _generateWeatherBasedSuggestion();
    if (weatherSuggestion.isNotEmpty) suggestions.add(weatherSuggestion);

    return suggestions;
  }

  /// Get significant life memories
  List<LifeEvent> getLifeMemories({int limit = 10}) {
    final memories = _lifeEvents
        .where((event) => event.significance > 0.7)
        .toList();
    
    memories.sort((a, b) => b.significance.compareTo(a.significance));
    return memories.take(limit).toList();
  }

  /// Generate activity-based narrative
  String _generateActivityNarrative(DateTime date) {
    final accelerometerData = _getSensorDataForDate('accelerometer', date);
    if (accelerometerData.isEmpty) return '';

    final totalActivity = accelerometerData
        .cast<AccelerometerData>()
        .map((data) => data.magnitude)
        .reduce((a, b) => a + b) / accelerometerData.length;

    final activityPeriods = _identifyActivityPeriods(accelerometerData.cast<AccelerometerData>());
    
    if (activityPeriods.isEmpty) {
      return "Today was quite peaceful. You maintained a gentle rhythm, which can be just as important as more active days.";
    }

    final mostActivePeriod = activityPeriods.reduce((a, b) => 
        a['intensity'] > b['intensity'] ? a : b);
    
    final timeOfDay = _formatTimeOfDay(mostActivePeriod['time']);
    
    if (totalActivity > 15) {
      return "What an energetic day! You were particularly active around $timeOfDay. Your body moved with purpose and strength - I can sense the vitality in your movements.";
    } else if (totalActivity > 8) {
      return "You maintained a good balance of movement today. The activity around $timeOfDay stood out - perhaps a walk or some meaningful movement that brought life to your day.";
    } else {
      return "Today called for gentleness, and you honored that. Sometimes our bodies need rest, and there's wisdom in listening to that need.";
    }
  }

  /// Generate environment-based narrative
  String _generateEnvironmentNarrative(DateTime date) {
    final lightData = _getSensorDataForDate('light', date);
    // final locationData = _getSensorDataForDate('location', date); // For future use
    
    if (lightData.isEmpty) return '';

    final environments = _classifyEnvironments(lightData.cast<LightData>());
    final transitions = _detectEnvironmentTransitions(lightData.cast<LightData>());

    if (transitions.length > 5) {
      return "You moved through many different spaces today. I noticed ${transitions.length} environment changes - from ${environments.first} to ${environments.last}. What a dynamic day of exploration!";
    } else if (environments.any((env) => env.contains('sunny'))) {
      return "The sunshine touched your day! I could sense when you stepped into that bright natural light - there's something special about how sunlight changes our experience of the world.";
    } else if (environments.any((env) => env.contains('dim'))) {
      return "You spent time in cozy, dimmer spaces today. There's something comforting about softer lighting - it often means moments of reflection or focused work.";
    }

    return '';
  }

  /// Generate routine-based narrative
  String _generateRoutineNarrative(DateTime date) {
    final routineScore = _calculateRoutineConsistency(date);
    
    if (routineScore > 0.8) {
      return "Your rhythm was beautifully consistent today. There's something deeply satisfying about flowing through familiar patterns - it creates a foundation for everything else.";
    } else if (routineScore < 0.4) {
      return "Today broke from your usual patterns. Sometimes life calls us to step outside our routines - I hope it brought you something new and meaningful.";
    } else {
      return "You found a nice balance between structure and spontaneity today. Your routine provided stability while still leaving room for life's surprises.";
    }
  }

  /// Generate memory-based narrative
  String _generateMemoryNarrative(DateTime date) {
    final similarDays = _findSimilarDays(date, 30);
    
    if (similarDays.isNotEmpty) {
      final daysDiff = date.difference(similarDays.first).inDays;
      
      if (daysDiff <= 7) {
        return "Today reminded me of last week - similar patterns of movement and environment. There's a beautiful consistency in how you navigate your world.";
      } else if (daysDiff <= 30) {
        return "This day echoes one from ${daysDiff} days ago. I notice how certain patterns emerge in your life - like a gentle recurring melody.";
      }
    }

    final uniqueAspects = _identifyUniqueAspects(date);
    if (uniqueAspects.isNotEmpty) {
      return "Today was distinctive - ${uniqueAspects.first}. These unique moments become the threads that weave the tapestry of your experiences.";
    }

    return '';
  }

  /// Predict energy levels
  Future<String> _predictEnergyLevel(DateTime time) async {
    final hour = time.hour;
    final recentActivity = _getRecentActivity(const Duration(hours: 2));
    final sleepQuality = await _estimateSleepQuality();

    if (hour >= 14 && hour <= 16 && sleepQuality < 0.6) {
      return "Based on your movement patterns and sleep, you might feel an energy dip around 3 PM. Consider a 10-minute walk or some light stretching to naturally boost your energy.";
    } else if (recentActivity < 2.0 && hour > 10) {
      return "You've been quite still recently. A gentle movement break could help maintain your energy flow throughout the day.";
    }

    return '';
  }

  /// Detect stress risk patterns
  Future<String> _detectStressRisk(DateTime time) async {
    final irregularPatterns = _detectIrregularPatterns();
    final activitySpikes = _detectActivitySpikes();
    
    if (irregularPatterns > 3 && activitySpikes > 2) {
      return "I've noticed some changes in your usual patterns lately. Life can be unpredictable - remember to be gentle with yourself and perhaps take a moment to breathe deeply.";
    }

    return '';
  }

  /// Suggest routine optimizations
  Future<String> _suggestRoutineOptimization() async {
    final optimalTimes = await _identifyOptimalActivityTimes();
    
    if (optimalTimes.containsKey('walk')) {
      final walkTime = optimalTimes['walk'];
      return "I've noticed you tend to feel most energized for walks around $walkTime. Your body seems to naturally align with this timing - perhaps it's worth honoring that rhythm.";
    }

    return '';
  }

  /// Generate weather-based suggestions
  Future<String> _generateWeatherBasedSuggestion() async {
    // This would integrate with weather API in real implementation
    final hour = DateTime.now().hour;
    final recentOutdoorActivity = _getRecentOutdoorActivity();

    if (recentOutdoorActivity > 0 && hour < 17) {
      return "The afternoon light might be calling you. Based on your patterns, a brief step outside could add a beautiful note to your day.";
    }

    return '';
  }

  // Helper methods for pattern detection and analysis

  List<SensorData> _getSensorDataForDate(String sensorType, DateTime date) {
    final sensorHistory = _sensorHistory[sensorType] ?? [];
    return sensorHistory.where((data) {
      final dataDate = DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
      return dataDate.isAtSameMomentAs(date);
    }).toList();
  }

  List<Map<String, dynamic>> _identifyActivityPeriods(List<AccelerometerData> data) {
    final periods = <Map<String, dynamic>>[];
    // Implementation would analyze data for activity periods
    // This is a simplified version
    if (data.isNotEmpty) {
      periods.add({
        'time': data.first.timestamp,
        'intensity': data.map((d) => d.magnitude).reduce((a, b) => a > b ? a : b),
      });
    }
    return periods;
  }

  String _formatTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  List<String> _classifyEnvironments(List<LightData> lightData) {
    return lightData.map((data) => data.lightCondition).toSet().toList();
  }

  List<DateTime> _detectEnvironmentTransitions(List<LightData> lightData) {
    final transitions = <DateTime>[];
    String? lastCondition;
    
    for (final data in lightData) {
      if (lastCondition != null && lastCondition != data.lightCondition) {
        transitions.add(data.timestamp);
      }
      lastCondition = data.lightCondition;
    }
    
    return transitions;
  }

  double _calculateRoutineConsistency(DateTime date) {
    // Simplified routine consistency calculation
    final allSensorTypes = _sensorHistory.keys.toList();
    double totalConsistency = 0.0;
    
    for (final sensorType in allSensorTypes) {
      final sensorData = _getSensorDataForDate(sensorType, date);
      final previousWeekData = _getSensorDataForDate(sensorType, date.subtract(const Duration(days: 7)));
      
      if (sensorData.isNotEmpty && previousWeekData.isNotEmpty) {
        // Compare patterns (simplified)
        totalConsistency += 0.7; // Placeholder for actual pattern comparison
      }
    }
    
    return totalConsistency / allSensorTypes.length;
  }

  List<DateTime> _findSimilarDays(DateTime targetDate, int searchDays) {
    // Implementation would find days with similar sensor patterns
    return [];
  }

  List<String> _identifyUniqueAspects(DateTime date) {
    // Implementation would identify what made this day unique
    return [];
  }

  double _getRecentActivity(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    final recentData = _sensorHistory['accelerometer']
        ?.where((data) => data.timestamp.isAfter(cutoff))
        .cast<AccelerometerData>()
        .toList() ?? [];
    
    if (recentData.isEmpty) return 0.0;
    
    return recentData.map((data) => data.magnitude).reduce((a, b) => a + b) / recentData.length;
  }

  Future<double> _estimateSleepQuality() async {
    // Implementation would analyze sleep patterns from sensor data
    return 0.7; // Placeholder
  }

  int _detectIrregularPatterns() {
    // Implementation would detect pattern irregularities
    return 0;
  }

  int _detectActivitySpikes() {
    // Implementation would detect unusual activity spikes
    return 0;
  }

  Future<Map<String, String>> _identifyOptimalActivityTimes() async {
    // Implementation would identify optimal times for activities
    return {'walk': '10:30 AM'};
  }

  double _getRecentOutdoorActivity() {
    // Implementation would estimate recent outdoor activity
    return 0.5;
  }

  void _cleanupOldData() {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    _sensorHistory.forEach((sensorType, dataList) {
      dataList.removeWhere((data) => data.timestamp.isBefore(cutoffDate));
    });
  }

  Future<void> _detectLifePatterns() async {
    // Implementation for pattern detection
    // Would analyze sensor data to find recurring patterns
  }

  Future<void> _detectSignificantEvents() async {
    // Implementation for event detection
    // Would identify significant moments from sensor data changes
  }

  Future<void> _generateNarratives() async {
    // Generate and broadcast new narratives
    final dailyNarratives = await generateDailyNarratives();
    for (final narrative in dailyNarratives) {
      _narrativeStreamController.add(narrative);
    }
  }

  String _analyzeActivityTrend(DateTime start, DateTime end) {
    final activityData = <double>[];
    DateTime current = start;
    
    while (current.isBefore(end)) {
      final dayActivity = _getSensorDataForDate('accelerometer', current)
          .cast<AccelerometerData>()
          .map((data) => data.magnitude)
          .fold<double>(0.0, (sum, magnitude) => sum + magnitude);
      
      activityData.add(dayActivity);
      current = current.add(const Duration(days: 1));
    }

    if (activityData.length < 2) return '';

    final trend = (activityData.last - activityData.first) / activityData.length;
    
    if (trend > 2) {
      return "Your activity has been beautifully increasing this week. I can sense the growing energy and movement in your days - your body is responding well to this upward momentum.";
    } else if (trend < -2) {
      return "I've noticed your activity levels have been gentler this week. Sometimes our bodies ask for this slower pace - it might be wisdom calling for rest and restoration.";
    } else {
      return "Your activity has maintained a steady rhythm this week. There's something grounding about this consistency - it creates a reliable foundation for everything else.";
    }
  }

  String _analyzeSleepPatterns(DateTime start, DateTime end) {
    // Analyze sleep patterns based on nighttime activity levels
    final sleepQualityScores = <double>[];
    DateTime current = start;

    while (current.isBefore(end)) {
      final nightData = _sensorHistory['accelerometer']
          ?.where((data) {
            final hour = data.timestamp.hour;
            final dataDate = DateTime(data.timestamp.year, data.timestamp.month, data.timestamp.day);
            final targetDate = DateTime(current.year, current.month, current.day);
            return dataDate.isAtSameMomentAs(targetDate) && (hour >= 22 || hour <= 6);
          })
          .cast<AccelerometerData>()
          .toList() ?? [];

      if (nightData.isNotEmpty) {
        final avgNightActivity = nightData.map((data) => data.magnitude).reduce((a, b) => a + b) / nightData.length;
        // Lower activity at night indicates better sleep
        sleepQualityScores.add(10.0 - avgNightActivity);
      }
      
      current = current.add(const Duration(days: 1));
    }

    if (sleepQualityScores.isEmpty) return '';

    final avgSleepQuality = sleepQualityScores.reduce((a, b) => a + b) / sleepQualityScores.length;
    
    if (avgSleepQuality > 7) {
      return "Your sleep has been wonderfully restorative this week. I can sense the deep stillness in your nighttime hours - your body is truly resting.";
    } else if (avgSleepQuality < 4) {
      return "Your sleep seems to have been more restless lately. Your body has been more active during rest hours - perhaps it's calling for some gentle changes to your evening routine.";
    } else {
      return "Your sleep patterns show a mixed week. Some nights brought deep rest, while others were lighter. This natural variation is part of how our bodies respond to life's rhythms.";
    }
  }

  String _analyzeEnvironmentalChanges(DateTime start, DateTime end) {
    final lightData = _sensorHistory['light']
        ?.where((data) => data.timestamp.isAfter(start) && data.timestamp.isBefore(end))
        .cast<LightData>()
        .toList() ?? [];

    if (lightData.isEmpty) return '';

    final environments = lightData.map((data) => data.lightCondition).toSet();
    
    if (environments.length > 3) {
      return "This week took you through diverse environments - from ${environments.first} to ${environments.last}. Your world has been rich with different lighting and spaces, each offering its own energy.";
    } else if (environments.contains('Very Bright')) {
      return "Bright spaces played a significant role in your week. Whether natural sunlight or vibrant indoor lighting, these energizing environments seem to have been part of your journey.";
    }

    return '';
  }

  String _analyzeConsistency(DateTime start, DateTime end) {
    double totalConsistency = 0.0;
    int days = 0;
    DateTime current = start;

    while (current.isBefore(end)) {
      totalConsistency += _calculateRoutineConsistency(current);
      days++;
      current = current.add(const Duration(days: 1));
    }

    if (days == 0) return '';

    final avgConsistency = totalConsistency / days;
    
    if (avgConsistency > 0.8) {
      return "Your week flowed with beautiful consistency. There's a rhythm to your days that creates harmony - like a gentle, reliable heartbeat that supports everything else.";
    } else if (avgConsistency < 0.4) {
      return "This week brought many changes to your usual patterns. Life sometimes calls us to be flexible and adaptive - I hope these variations brought new experiences and growth.";
    } else {
      return "You found a lovely balance between routine and spontaneity this week. Your patterns provided stability while still leaving space for life's natural unpredictability.";
    }
  }

  void dispose() {
    _eventStreamController.close();
    _narrativeStreamController.close();
  }
}