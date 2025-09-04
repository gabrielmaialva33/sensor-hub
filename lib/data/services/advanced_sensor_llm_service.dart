import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import '../models/sensor_data.dart';
import '../../core/utils/logger.dart';

/// Advanced Sensor-LLM Integration Service
/// Based on latest research (2024-2025) for optimal sensor data processing with LLMs
class AdvancedSensorLLMService {
  static final AdvancedSensorLLMService _instance = AdvancedSensorLLMService._internal();
  factory AdvancedSensorLLMService() => _instance;
  AdvancedSensorLLMService._internal();

  late final Dio _dio;
  static const String _baseUrl = 'https://integrate.api.nvidia.com';
  static const String _apiKey = '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';
  
  // Advanced model configuration
  static const String _primaryModel = 'qwen/qwen3-coder-480b-a35b-instruct';
  static const String _edgeModel = 'meta/llama-3.1-8b-instruct'; // For edge inference
  
  // Context window optimization
  static const int _maxTokens = 4096;
  static const int _slidingWindowMs = 5000; // 5 second window
  // static const int _patchSize = 50; // Samples per patch - Reserved for future use
  
  // Buffers for streaming architecture
  final Map<String, List<SensorData>> _sensorBuffers = {};
  final Map<String, String> _lastSummaries = {};
  Timer? _processingTimer;
  
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
    
    // Start periodic processing for real-time streaming
    _processingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _processBufferedData();
    });
  }

  void dispose() {
    _processingTimer?.cancel();
  }

  // ============================================================================
  // ADVANCED PREPROCESSING TECHNIQUES
  // ============================================================================
  
  /// Generate trend-descriptive text from sensor data
  String _generateTrendDescription(List<SensorData> data, String sensorType) {
    if (data.isEmpty) return '';
    
    final values = <double>[];
    for (var d in data) {
      if (d is AccelerometerData) {
        values.add(d.magnitude);
      } else if (d is GyroscopeData) {
        values.add(sqrt(d.x * d.x + d.y * d.y + d.z * d.z));
      } else if (d is LocationData) {
        values.add(d.speed ?? 0);
      } else if (d is BatteryData) {
        values.add(d.batteryLevel.toDouble());
      } else if (d is LightData) {
        values.add(d.luxValue);
      } else if (d is ProximityData) {
        values.add(d.isNear ? 1.0 : 0.0);
      }
    }
    
    if (values.isEmpty) return '';
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final trend = _calculateTrend(values);
    
    return '''Sensor $sensorType:
- Média: ${mean.toStringAsFixed(2)}
- Máx: ${max.toStringAsFixed(2)}
- Mín: ${min.toStringAsFixed(2)}
- Tendência: $trend
- Amostras: ${values.length}''';
  }
  
  String _calculateTrend(List<double> values) {
    if (values.length < 2) return 'estável';
    
    final firstHalf = values.sublist(0, values.length ~/ 2);
    final secondHalf = values.sublist(values.length ~/ 2);
    
    final firstMean = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondMean = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    final diff = secondMean - firstMean;
    final percentChange = (diff / firstMean * 100).abs();
    
    if (percentChange < 5) return 'estável';
    if (diff > 0) return 'crescente (${percentChange.toStringAsFixed(1)}%)';
    return 'decrescente (${percentChange.toStringAsFixed(1)}%)';
  }
  
  /// Special token injection for structured sensor data
  String _injectSpecialTokens(Map<String, String> sensorDescriptions) {
    final buffer = StringBuffer();
    
    sensorDescriptions.forEach((sensor, description) {
      final token = '<${sensor.toUpperCase()}>';
      buffer.writeln('$token\n$description\n</$token>\n');
    });
    
    return buffer.toString();
  }
  
  /// Patch-based decomposition for efficient tokenization (Reserved for future use)
  // List<String> _createPatches(List<SensorData> data, int patchSize) {
  //   final patches = <String>[];
  //   
  //   for (int i = 0; i < data.length; i += patchSize) {
  //     final end = (i + patchSize < data.length) ? i + patchSize : data.length;
  //     final patch = data.sublist(i, end);
  //     
  //     final patchSummary = StringBuffer();
  //     patchSummary.writeln('Patch ${patches.length + 1}:');
  //     
  //     for (var item in patch) {
  //       if (item is AccelerometerData) {
  //         patchSummary.writeln('ACC: x=${item.x.toStringAsFixed(2)}, y=${item.y.toStringAsFixed(2)}, z=${item.z.toStringAsFixed(2)}');
  //       } else if (item is GyroscopeData) {
  //         patchSummary.writeln('GYRO: x=${item.x.toStringAsFixed(2)}, y=${item.y.toStringAsFixed(2)}, z=${item.z.toStringAsFixed(2)}');
  //       } else if (item is LocationData) {
  //         patchSummary.writeln('GPS: lat=${item.latitude.toStringAsFixed(4)}, lon=${item.longitude.toStringAsFixed(4)}, speed=${item.speed?.toStringAsFixed(1) ?? "0"}');
  //       }
  //     }
  //     
  //     patches.add(patchSummary.toString());
  //   }
  //   
  //   return patches;
  // }
  
  // ============================================================================
  // REAL-TIME STREAMING ARCHITECTURE
  // ============================================================================
  
  /// Buffer sensor data for batch processing
  void bufferSensorData(SensorData data) {
    final key = data.sensorType;
    _sensorBuffers[key] ??= [];
    _sensorBuffers[key]!.add(data);
    
    // Sliding window - keep only recent data
    final cutoffTime = DateTime.now().subtract(Duration(milliseconds: _slidingWindowMs));
    _sensorBuffers[key]!.removeWhere((d) => d.timestamp.isBefore(cutoffTime));
  }
  
  /// Process buffered data periodically
  Future<void> _processBufferedData() async {
    if (_sensorBuffers.isEmpty) return;
    
    final descriptions = <String, String>{};
    
    _sensorBuffers.forEach((sensor, dataList) {
      if (dataList.isNotEmpty) {
        descriptions[sensor] = _generateTrendDescription(dataList, sensor);
      }
    });
    
    if (descriptions.isNotEmpty) {
      await _analyzeWithContextOptimization(descriptions);
    }
  }
  
  // ============================================================================
  // CONTEXT WINDOW OPTIMIZATION
  // ============================================================================
  
  /// Sliding-window summarization with hierarchical context
  Future<Map<String, dynamic>> _analyzeWithContextOptimization(
    Map<String, String> currentDescriptions,
  ) async {
    try {
      // Build hierarchical context
      final contextBuilder = StringBuffer();
      
      // Include previous summaries (older context)
      if (_lastSummaries.isNotEmpty) {
        contextBuilder.writeln('=== Contexto Anterior ===');
        _lastSummaries.forEach((sensor, summary) {
          contextBuilder.writeln('$sensor: $summary');
        });
        contextBuilder.writeln();
      }
      
      // Add current detailed data with special tokens
      contextBuilder.writeln('=== Dados Atuais ===');
      contextBuilder.write(_injectSpecialTokens(currentDescriptions));
      
      // Perform analysis
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': _primaryModel,
          'messages': [
            {
              'role': 'system',
              'content': '''Você é um especialista em análise de sensores IoT em tempo real.
              
              Analise os dados do sensor e forneça:
              1. Detecção de padrões e anomalias
              2. Classificação de atividade atual
              3. Previsões de curto prazo
              4. Recomendações contextuais
              5. Correlações multi-sensor
              
              Responda em JSON com as chaves: patterns, activity, predictions, recommendations, correlations, confidence.'''
            },
            {
              'role': 'user',
              'content': contextBuilder.toString(),
            }
          ],
          'temperature': 0.7,
          'top_p': 0.8,
          'max_tokens': _maxTokens,
        },
      );
      
      // Update summaries for next iteration
      currentDescriptions.forEach((sensor, desc) {
        _lastSummaries[sensor] = _extractSummary(desc);
      });
      
      return response.data;
    } catch (e) {
      Logger.error('Erro na análise otimizada', e);
      return {'error': e.toString()};
    }
  }
  
  String _extractSummary(String description) {
    final lines = description.split('\n');
    if (lines.length > 2) {
      return lines.sublist(0, 2).join(' ');
    }
    return description;
  }
  
  // ============================================================================
  // MULTIMODAL FUSION
  // ============================================================================
  
  /// Fuse multiple sensor modalities with late fusion approach
  Future<Map<String, dynamic>> performMultiModalAnalysis({
    required Map<String, List<SensorData>> sensorData,
    String? imageContext,
    String? audioContext,
  }) async {
    try {
      final modalityDescriptions = StringBuffer();
      
      // Process sensor modalities
      sensorData.forEach((sensor, data) {
        final description = _generateTrendDescription(data, sensor);
        modalityDescriptions.writeln('[$sensor]\n$description\n');
      });
      
      // Add vision context if available
      if (imageContext != null) {
        modalityDescriptions.writeln('[VISÃO]\n$imageContext\n');
      }
      
      // Add audio context if available
      if (audioContext != null) {
        modalityDescriptions.writeln('[ÁUDIO]\n$audioContext\n');
      }
      
      // Multimodal fusion prompt
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': _primaryModel,
          'messages': [
            {
              'role': 'system',
              'content': '''Você é um especialista em fusão multimodal para análise contextual avançada.
              
              Integre dados de múltiplas modalidades (sensores, visão, áudio) para fornecer:
              1. Compreensão holística do contexto
              2. Correlações cross-modal
              3. Detecção de eventos complexos
              4. Recomendações baseadas em contexto completo
              
              Responda em JSON com: context, crossModalCorrelations, detectedEvents, recommendations.'''
            },
            {
              'role': 'user',
              'content': modalityDescriptions.toString(),
            }
          ],
          'temperature': 0.7,
          'max_tokens': _maxTokens,
        },
      );
      
      return response.data;
    } catch (e) {
      Logger.error('Erro na análise multimodal', e);
      return {'error': e.toString()};
    }
  }
  
  // ============================================================================
  // EDGE COMPUTING OPTIMIZATION
  // ============================================================================
  
  /// Lightweight edge inference for local processing
  Future<Map<String, dynamic>> performEdgeInference(List<SensorData> data) async {
    try {
      // Use smaller model for edge
      final compactDescription = _generateCompactDescription(data);
      
      final response = await _dio.post(
        '/v1/chat/completions',
        data: {
          'model': _edgeModel, // Smaller model for edge
          'messages': [
            {
              'role': 'system',
              'content': 'Analise rápida de sensores. Responda brevemente com: activity, alert (se houver), confidence.',
            },
            {
              'role': 'user',
              'content': compactDescription,
            }
          ],
          'temperature': 0.5,
          'max_tokens': 256, // Minimal tokens for edge
        },
      );
      
      return response.data;
    } catch (e) {
      Logger.error('Erro na inferência de borda', e);
      return {'activity': 'desconhecido', 'confidence': 0};
    }
  }
  
  String _generateCompactDescription(List<SensorData> data) {
    final stats = <String, dynamic>{};
    
    for (var d in data) {
      if (d is AccelerometerData) {
        stats['accel_mag'] = d.magnitude;
      } else if (d is GyroscopeData) {
        stats['gyro_rot'] = sqrt(d.x * d.x + d.y * d.y + d.z * d.z);
      } else if (d is BatteryData) {
        stats['battery'] = d.batteryLevel;
      }
    }
    
    return 'Dados: $stats';
  }
  
  // ============================================================================
  // COMPRESSION & FEATURE EXTRACTION
  // ============================================================================
  
  /// Extract statistical features for efficient processing
  Map<String, double> extractStatisticalFeatures(List<SensorData> data) {
    final features = <String, double>{};
    
    if (data.isEmpty) return features;
    
    // Group by sensor type
    final grouped = <String, List<double>>{};
    
    for (var d in data) {
      final key = d.sensorType;
      grouped[key] ??= [];
      
      if (d is AccelerometerData) {
        grouped[key]!.add(d.magnitude);
      } else if (d is GyroscopeData) {
        grouped[key]!.add(sqrt(d.x * d.x + d.y * d.y + d.z * d.z));
      } else if (d is LocationData) {
        grouped[key]!.add(d.speed ?? 0);
      } else if (d is BatteryData) {
        grouped[key]!.add(d.batteryLevel.toDouble());
      } else if (d is LightData) {
        grouped[key]!.add(d.luxValue);
      }
    }
    
    // Calculate features per sensor
    grouped.forEach((sensor, values) {
      if (values.isNotEmpty) {
        // Time-domain features
        features['${sensor}_mean'] = values.reduce((a, b) => a + b) / values.length;
        features['${sensor}_max'] = values.reduce((a, b) => a > b ? a : b);
        features['${sensor}_min'] = values.reduce((a, b) => a < b ? a : b);
        
        // Variance
        final mean = features['${sensor}_mean']!;
        final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
        features['${sensor}_variance'] = variance;
        features['${sensor}_std'] = sqrt(variance);
        
        // Skewness (simplified)
        if (values.length > 2) {
          final skewness = values.map((v) => pow((v - mean) / sqrt(variance), 3)).reduce((a, b) => a + b) / values.length;
          features['${sensor}_skewness'] = skewness;
        }
      }
    });
    
    return features;
  }
  
  /// Adaptive sampling based on activity level
  List<SensorData> adaptiveSample(List<SensorData> data, double activityLevel) {
    // High activity = keep more samples, low activity = downsample
    final samplingRate = activityLevel > 0.7 ? 1 : 
                        activityLevel > 0.3 ? 2 : 4;
    
    final sampled = <SensorData>[];
    for (int i = 0; i < data.length; i += samplingRate) {
      sampled.add(data[i]);
    }
    
    return sampled;
  }
}

// ============================================================================
// ADVANCED DATA MODELS
// ============================================================================

class MultiModalContext {
  final Map<String, List<SensorData>> sensorData;
  final String? imageContext;
  final String? audioContext;
  final DateTime timestamp;
  
  MultiModalContext({
    required this.sensorData,
    this.imageContext,
    this.audioContext,
  }) : timestamp = DateTime.now();
}

class EdgeInferenceResult {
  final String activity;
  final String? alert;
  final double confidence;
  final int processingTimeMs;
  
  EdgeInferenceResult({
    required this.activity,
    this.alert,
    required this.confidence,
    required this.processingTimeMs,
  });
}

class StreamingAnalysisResult {
  final Map<String, dynamic> patterns;
  final String currentActivity;
  final List<String> predictions;
  final List<String> recommendations;
  final Map<String, dynamic> correlations;
  final double confidence;
  
  StreamingAnalysisResult({
    required this.patterns,
    required this.currentActivity,
    required this.predictions,
    required this.recommendations,
    required this.correlations,
    required this.confidence,
  });
}