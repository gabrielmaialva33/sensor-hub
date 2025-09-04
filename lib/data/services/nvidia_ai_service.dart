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
  
  // Model constants
  static const String _primaryModel = 'qwen/qwen3-coder-480b-a35b-instruct';
  static const String _fallbackModel = 'meta/llama-3.1-8b-instruct';
  static const String _predictionModel = 'qwen/qwen3-coder-480b-a35b-instruct';

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

  /// Make API call with fallback model support
  Future<Response> _makeApiCall(Map<String, dynamic> requestData) async {
    try {
      // Try primary model first
      return await _dio.post('/v1/chat/completions', data: requestData);
    } catch (e) {
      Logger.warning('Primary model failed, trying fallback model', e);
      
      // Try fallback model
      final fallbackData = Map<String, dynamic>.from(requestData);
      fallbackData['model'] = _fallbackModel;
      
      return await _dio.post('/v1/chat/completions', data: fallbackData);
    }
  }

  /// Analyze sensor data patterns using NVIDIA AI
  Future<AIInsight> analyzeSensorData(List<SensorData> sensorData) async {
    try {
      final dataContext = _prepareSensorDataContext(sensorData);
      
      final requestData = {
        'model': _primaryModel,
        'messages': [
          {
            'role': 'system',
            'content': '''Você é o SensorHub AI, um especialista em analisar dados de sensores de dispositivos móveis para fornecer insights sobre comportamento do usuário, saúde do dispositivo e padrões ambientais.
              
              Analise os dados dos sensores fornecidos e forneça:
              1. Classificação de atividade (caminhando, correndo, sentado, dirigindo, etc.)
              2. Insights ambientais (iluminação, padrões de movimento)
              3. Análise de saúde do dispositivo
              4. Padrões comportamentais
              5. Recomendações acionáveis
              
              O formato da resposta deve ser JSON com as chaves: activity, environment, deviceHealth, patterns, recommendations, confidence.
              
              Responda SEMPRE em português brasileiro.'''
          },
          {
            'role': 'user',
            'content': 'Analise estes dados dos sensores e forneça insights abrangentes:\n\n$dataContext'
          }
        ],
        'max_tokens': 4096,
        'temperature': 0.7,
        'top_p': 0.8,
        'frequency_penalty': 0,
        'presence_penalty': 0,
      };

      final response = await _makeApiCall(requestData);
      final content = response.data['choices'][0]['message']['content'];
      return _parseAIResponse(content, sensorData);
    } catch (e) {
      Logger.error('NVIDIA AI analysis error', e);
      return AIInsight.error('Falha ao analisar dados dos sensores: ${e.toString()}');
    }
  }

  /// Predict future sensor patterns
  Future<Prediction> predictSensorPatterns(List<SensorData> historicalData) async {
    try {
      final dataContext = _preparePredictionContext(historicalData);
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': _predictionModel,
          'messages': [
            {
              'role': 'system',
              'content': '''Você é uma IA de análise preditiva especializada em padrões de dados de sensores móveis.
              
              Baseado nos dados históricos dos sensores, preveja:
              1. Próximas atividades prováveis
              2. Padrões de uso da bateria
              3. Previsões de movimento
              4. Mudanças ambientais
              5. Recomendações de uso otimizado do dispositivo
              
              A resposta deve ser JSON com as chaves: nextActivity, batteryPrediction, movementForecast, environmentalChanges, recommendations, confidence.
              
              Responda SEMPRE em português brasileiro.'''
            },
            {
              'role': 'user',
              'content': 'Com base nestes dados históricos dos sensores, preveja padrões futuros:\n\n$dataContext'
            }
          ],
          'max_tokens': 4096,
          'temperature': 0.5,
          'top_p': 0.8,
          'frequency_penalty': 0,
          'presence_penalty': 0,
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
          'model': _primaryModel,
          'messages': [
            {
              'role': 'system',
              'content': '''Você é uma IA coach de saúde e atividade. Crie um resumo diário abrangente de atividades baseado nos dados dos sensores.
              
              Forneça:
              1. Detalhamento das atividades (tempo gasto em diferentes atividades)
              2. Avaliação da qualidade do movimento
              3. Resumo da exposição ambiental
              4. Insights de saúde
              5. Recomendações personalizadas para melhoria
              
              A resposta deve ser encorajadora e acionável. Formate como JSON com as chaves: activities, movement, environment, health, recommendations, score.
              
              Responda SEMPRE em português brasileiro.'''
            },
            {
              'role': 'user',
              'content': 'Crie um resumo diário de atividades para estes dados:\n\n$summary'
            }
          ],
          'max_tokens': 4096,
          'temperature': 0.8,
          'top_p': 0.8,
          'frequency_penalty': 0,
          'presence_penalty': 0,
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

    buffer.writeln('📱 ANÁLISE DE DADOS DOS SENSORES:');
    buffer.writeln('Intervalo de tempo: ${sensorData.first.timestamp} até ${sensorData.last.timestamp}');
    buffer.writeln('Total de pontos de dados: ${sensorData.length}');
    buffer.writeln();

    groupedData.forEach((sensorType, data) {
      buffer.writeln('🔸 ${sensorType.toUpperCase()} (${data.length} leituras):');
      
      switch (sensorType) {
        case 'accelerometer':
          final accelData = data.cast<AccelerometerData>();
          final avgMagnitude = accelData.map((d) => d.magnitude).reduce((a, b) => a + b) / accelData.length;
          buffer.writeln('  • Magnitude média: ${avgMagnitude.toStringAsFixed(2)}');
          buffer.writeln('  • Magnitude máxima: ${accelData.map((d) => d.magnitude).reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}');
          break;
        case 'battery':
          final batteryData = data.cast<BatteryData>();
          final avgLevel = batteryData.map((d) => d.batteryLevel).reduce((a, b) => a + b) / batteryData.length;
          final chargingCount = batteryData.where((d) => d.isCharging).length;
          buffer.writeln('  • Nível médio: ${avgLevel.toStringAsFixed(1)}%');
          buffer.writeln('  • Eventos de carregamento: $chargingCount');
          break;
        case 'location':
          final locationData = data.cast<LocationData>();
          buffer.writeln('  • Pontos de dados: ${locationData.length}');
          if (locationData.isNotEmpty) {
            buffer.writeln('  • Precisão média: ${locationData.map((d) => d.accuracy).reduce((a, b) => a + b) / locationData.length}m');
          }
          break;
      }
      buffer.writeln();
    });

    return buffer.toString();
  }

  /// Prepare prediction context
  String _preparePredictionContext(List<SensorData> historicalData) {
    return 'Padrões históricos de ${historicalData.length} pontos de dados durante o período: ${historicalData.first.timestamp} até ${historicalData.last.timestamp}';
  }

  /// Generate data summary for activity analysis
  String _generateDataSummary(List<SensorData> dailyData) {
    return 'Resumo diário dos dados dos sensores com ${dailyData.length} leituras totais em ${dailyData.map((d) => d.sensorType).toSet().length} sensores diferentes';
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
      Logger.warning('Falha ao analisar resposta JSON, usando análise de texto');
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
      Logger.warning('Falha ao analisar JSON de previsão');
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
      Logger.warning('Falha ao analisar JSON do resumo de atividade');
    }

    return ActivitySummary.fromText(content);
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': _primaryModel,
          'messages': [
            {
              'role': 'user',
              'content': 'Olá, você está funcionando?'
            }
          ],
          'max_tokens': 50,
          'top_p': 0.8,
          'frequency_penalty': 0,
          'presence_penalty': 0,
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
    patterns: content.length > 200 ? '${content.substring(0, 200)}...' : content,
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