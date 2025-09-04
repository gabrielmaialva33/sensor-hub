import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/sensor_data.dart';
import '../../core/utils/logger.dart';

/// Service for NVIDIA AI integration and analysis
class NvidiaAiService {
  static final NvidiaAiService _instance = NvidiaAiService._internal();
  factory NvidiaAiService() => _instance;
  NvidiaAiService._internal();

  late final Dio _dio;
  static const String _baseUrl = 'https://integrate.api.nvidia.com';
  static const String _apiKey = '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';

  /// Initialize the service
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => Logger.debug('🤖 NVIDIA API: $object'),
    ));
  }

  /// Analyze sensor data patterns using NVIDIA AI
  Future<AIInsight> analyzeSensorData(List<SensorData> sensorData) async {
    try {
      final dataContext = _prepareSensorDataContext(sensorData);
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'meta/llama-3.1-8b-instruct',
          'messages': [
            {
              'role': 'system',
              'content': '''You are SensorHub AI, an expert in analyzing mobile device sensor data to provide insights about user behavior, device health, and environmental patterns. 
              
              Analyze the provided sensor data and provide:
              1. Activity classification (walking, running, sitting, driving, etc.)
              2. Environmental insights (lighting, movement patterns)
              3. Device health analysis
              4. Behavioral patterns
              5. Actionable recommendations
              
              Response format should be JSON with keys: activity, environment, deviceHealth, patterns, recommendations, confidence.'''
            },
            {
              'role': 'user',
              'content': 'Analyze this sensor data and provide comprehensive insights:\n\n$dataContext'
            }
          ],
          'max_tokens': 1024,
          'temperature': 0.7,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseAIResponse(content, sensorData);
    } catch (e) {
      Logger.error('NVIDIA AI analysis error', e);
      return AIInsight.error('Failed to analyze sensor data: ${e.toString()}');
    }
  }

  /// Predict future sensor patterns
  Future<Prediction> predictSensorPatterns(List<SensorData> historicalData) async {
    try {
      final dataContext = _preparePredictionContext(historicalData);
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'meta/llama-3.1-70b-instruct',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a predictive analytics AI specialized in mobile sensor data patterns. 
              
              Based on historical sensor data, predict:
              1. Likely next activities
              2. Battery usage patterns
              3. Movement predictions
              4. Environmental changes
              5. Optimal device usage recommendations
              
              Response should be JSON with keys: nextActivity, batteryPrediction, movementForecast, environmentalChanges, recommendations, confidence.'''
            },
            {
              'role': 'user',
              'content': 'Based on this historical sensor data, predict future patterns:\n\n$dataContext'
            }
          ],
          'max_tokens': 800,
          'temperature': 0.5,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parsePredictionResponse(content);
    } catch (e) {
      Logger.error('NVIDIA prediction error', e);
      return Prediction.error('Failed to predict patterns: ${e.toString()}');
    }
  }

  /// Generate activity summary
  Future<ActivitySummary> generateActivitySummary(List<SensorData> dailyData) async {
    try {
      final summary = _generateDataSummary(dailyData);
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'meta/llama-3.1-8b-instruct',
          'messages': [
            {
              'role': 'system',
              'content': '''You are a health and activity coach AI. Create a comprehensive daily activity summary based on sensor data.
              
              Provide:
              1. Activity breakdown (time spent in different activities)
              2. Movement quality assessment
              3. Environmental exposure summary
              4. Health insights
              5. Personalized recommendations for improvement
              
              Response should be encouraging and actionable. Format as JSON with keys: activities, movement, environment, health, recommendations, score.'''
            },
            {
              'role': 'user',
              'content': 'Create a daily activity summary for this data:\n\n$summary'
            }
          ],
          'max_tokens': 1200,
          'temperature': 0.8,
        },
      );

      final content = response.data['choices'][0]['message']['content'];
      return _parseActivitySummary(content);
    } catch (e) {
      Logger.error('Activity summary error', e);
      return ActivitySummary.error('Failed to generate summary: ${e.toString()}');
    }
  }

  /// Prepare sensor data context for AI analysis
  String _prepareSensorDataContext(List<SensorData> sensorData) {
    final buffer = StringBuffer();
    
    // Group data by sensor type
    final groupedData = <String, List<SensorData>>{};
    for (final data in sensorData) {
      groupedData.putIfAbsent(data.sensorType, () => []).add(data);
    }

    buffer.writeln('📱 SENSOR DATA ANALYSIS:');
    buffer.writeln('Time range: ${sensorData.first.timestamp} to ${sensorData.last.timestamp}');
    buffer.writeln('Total data points: ${sensorData.length}');
    buffer.writeln();

    groupedData.forEach((sensorType, data) {
      buffer.writeln('🔸 ${sensorType.toUpperCase()} (${data.length} readings):');
      
      switch (sensorType) {
        case 'accelerometer':
          final accelData = data.cast<AccelerometerData>();
          final avgMagnitude = accelData.map((d) => d.magnitude).reduce((a, b) => a + b) / accelData.length;
          buffer.writeln('  • Average magnitude: ${avgMagnitude.toStringAsFixed(2)}');
          buffer.writeln('  • Max magnitude: ${accelData.map((d) => d.magnitude).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}');
          break;
        case 'battery':
          final batteryData = data.cast<BatteryData>();
          final avgLevel = batteryData.map((d) => d.batteryLevel).reduce((a, b) => a + b) / batteryData.length;
          final chargingCount = batteryData.where((d) => d.isCharging).length;
          buffer.writeln('  • Average level: ${avgLevel.toStringAsFixed(1)}%');
          buffer.writeln('  • Charging events: $chargingCount');
          break;
        case 'location':
          final locationData = data.cast<LocationData>();
          buffer.writeln('  • Data points: ${locationData.length}');
          if (locationData.isNotEmpty) {
            buffer.writeln('  • Average accuracy: ${locationData.map((d) => d.accuracy).reduce((a, b) => a + b) / locationData.length}m');
          }
          break;
      }
      buffer.writeln();
    });

    return buffer.toString();
  }

  /// Prepare prediction context
  String _preparePredictionContext(List<SensorData> historicalData) {
    return 'Historical patterns from ${historicalData.length} data points over time period: ${historicalData.first.timestamp} to ${historicalData.last.timestamp}';
  }

  /// Generate data summary for activity analysis
  String _generateDataSummary(List<SensorData> dailyData) {
    return 'Daily sensor data summary with ${dailyData.length} total readings across ${dailyData.map((d) => d.sensorType).toSet().length} different sensors';
  }

  /// Parse AI response into structured insight
  AIInsight _parseAIResponse(String content, List<SensorData> originalData) {
    try {
      // Try to extract JSON from response
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch.group(0)!);
        return AIInsight.fromJson(jsonData, originalData);
      }
    } catch (e) {
      Logger.warning('Failed to parse JSON response, using text analysis');
    }

    // Fallback to text parsing
    return AIInsight.fromText(content, originalData);
  }

  /// Parse prediction response
  Prediction _parsePredictionResponse(String content) {
    try {
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch.group(0)!);
        return Prediction.fromJson(jsonData);
      }
    } catch (e) {
      Logger.warning('Failed to parse prediction JSON');
    }

    return Prediction.fromText(content);
  }

  /// Parse activity summary
  ActivitySummary _parseActivitySummary(String content) {
    try {
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(content);
      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch.group(0)!);
        return ActivitySummary.fromJson(jsonData);
      }
    } catch (e) {
      Logger.warning('Failed to parse activity summary JSON');
    }

    return ActivitySummary.fromText(content);
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': 'meta/llama-3.1-8b-instruct',
          'messages': [
            {
              'role': 'user',
              'content': 'Hello, are you working?'
            }
          ],
          'max_tokens': 50,
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      Logger.error('NVIDIA API connection test failed', e);
      return false;
    }
  }
}

/// AI Insight model
class AIInsight {
  final String activity;
  final String environment;
  final String deviceHealth;
  final String patterns;
  final List<String> recommendations;
  final double confidence;
  final bool isError;
  final String? errorMessage;

  AIInsight({
    required this.activity,
    required this.environment,
    required this.deviceHealth,
    required this.patterns,
    required this.recommendations,
    required this.confidence,
    this.isError = false,
    this.errorMessage,
  });

  factory AIInsight.error(String message) => AIInsight(
    activity: 'Unknown',
    environment: 'Unknown',
    deviceHealth: 'Unknown',
    patterns: 'Unknown',
    recommendations: [],
    confidence: 0.0,
    isError: true,
    errorMessage: message,
  );

  factory AIInsight.fromJson(Map<String, dynamic> json, List<SensorData> data) => AIInsight(
    activity: json['activity'] ?? 'Unknown',
    environment: json['environment'] ?? 'Unknown',
    deviceHealth: json['deviceHealth'] ?? 'Good',
    patterns: json['patterns'] ?? 'No patterns detected',
    recommendations: List<String>.from(json['recommendations'] ?? []),
    confidence: (json['confidence'] ?? 0.5).toDouble(),
  );

  factory AIInsight.fromText(String content, List<SensorData> data) => AIInsight(
    activity: 'Mixed Activity',
    environment: 'Variable',
    deviceHealth: 'Good',
    patterns: content.length > 200 ? content.substring(0, 200) + '...' : content,
    recommendations: ['Check detailed analysis', 'Monitor patterns'],
    confidence: 0.7,
  );
}

/// Prediction model
class Prediction {
  final String nextActivity;
  final String batteryPrediction;
  final String movementForecast;
  final String environmentalChanges;
  final List<String> recommendations;
  final double confidence;
  final bool isError;
  final String? errorMessage;

  Prediction({
    required this.nextActivity,
    required this.batteryPrediction,
    required this.movementForecast,
    required this.environmentalChanges,
    required this.recommendations,
    required this.confidence,
    this.isError = false,
    this.errorMessage,
  });

  factory Prediction.error(String message) => Prediction(
    nextActivity: 'Unknown',
    batteryPrediction: 'Unknown',
    movementForecast: 'Unknown',
    environmentalChanges: 'Unknown',
    recommendations: [],
    confidence: 0.0,
    isError: true,
    errorMessage: message,
  );

  factory Prediction.fromJson(Map<String, dynamic> json) => Prediction(
    nextActivity: json['nextActivity'] ?? 'Unknown',
    batteryPrediction: json['batteryPrediction'] ?? 'Stable',
    movementForecast: json['movementForecast'] ?? 'Similar patterns',
    environmentalChanges: json['environmentalChanges'] ?? 'No changes',
    recommendations: List<String>.from(json['recommendations'] ?? []),
    confidence: (json['confidence'] ?? 0.5).toDouble(),
  );

  factory Prediction.fromText(String content) => Prediction(
    nextActivity: 'Predicted Activity',
    batteryPrediction: 'Normal usage',
    movementForecast: 'Continued patterns',
    environmentalChanges: 'Stable environment',
    recommendations: ['Monitor trends'],
    confidence: 0.6,
  );
}

/// Activity Summary model
class ActivitySummary {
  final Map<String, int> activities;
  final String movement;
  final String environment;
  final String health;
  final List<String> recommendations;
  final int score;
  final bool isError;
  final String? errorMessage;

  ActivitySummary({
    required this.activities,
    required this.movement,
    required this.environment,
    required this.health,
    required this.recommendations,
    required this.score,
    this.isError = false,
    this.errorMessage,
  });

  factory ActivitySummary.error(String message) => ActivitySummary(
    activities: {},
    movement: 'Unknown',
    environment: 'Unknown',
    health: 'Unknown',
    recommendations: [],
    score: 0,
    isError: true,
    errorMessage: message,
  );

  factory ActivitySummary.fromJson(Map<String, dynamic> json) => ActivitySummary(
    activities: Map<String, int>.from(json['activities'] ?? {}),
    movement: json['movement'] ?? 'Moderate',
    environment: json['environment'] ?? 'Indoor',
    health: json['health'] ?? 'Good',
    recommendations: List<String>.from(json['recommendations'] ?? []),
    score: json['score'] ?? 75,
  );

  factory ActivitySummary.fromText(String content) => ActivitySummary(
    activities: {'Mixed': 100},
    movement: 'Varied',
    environment: 'Mixed',
    health: 'Good',
    recommendations: ['Stay active'],
    score: 75,
  );
}