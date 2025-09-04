import '../entities/sensor_entity.dart';
import '../use_cases/stream_sensor_data.dart';

/// Repository abstrato - Domain Layer (2025 Clean Architecture)
abstract class SensorRepository {
  /// Stream de dados do sensor em tempo real
  Stream<SensorResult<List<SensorEntity>>> getSensorStream(SensorType type);

  /// Obter dados históricos do sensor
  Future<SensorResult<List<SensorEntity>>> getHistoricalData({
    required SensorType type,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  });

  /// Salvar dados do sensor
  Future<SensorResult<void>> saveSensorData(SensorEntity data);

  /// Limpar dados antigos
  Future<SensorResult<int>> clearOldData({required Duration olderThan});

  /// Exportar dados
  Future<SensorResult<String>> exportData({
    required SensorType type,
    required ExportFormat format,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Análise com IA
  Future<SensorResult<SensorAnalysis>> analyzeWithAI(List<SensorEntity> data);
}

/// Formatos de exportação
enum ExportFormat { json, csv, pdf, excel }

/// Análise de sensor com IA
class SensorAnalysis {
  final String summary;
  final Map<String, dynamic> insights;
  final List<String> recommendations;
  final double confidence;
  final DateTime timestamp;

  const SensorAnalysis({
    required this.summary,
    required this.insights,
    required this.recommendations,
    required this.confidence,
    required this.timestamp,
  });
}

/// Falhas específicas do domínio de sensores
abstract class SensorFailure {
  final String message;

  const SensorFailure(this.message);
}

class SensorPermissionFailure extends SensorFailure {
  const SensorPermissionFailure(super.message);
}

class SensorNotAvailableFailure extends SensorFailure {
  const SensorNotAvailableFailure(super.message);
}

class SensorDataFailure extends SensorFailure {
  const SensorDataFailure(super.message);
}

class NetworkFailure extends SensorFailure {
  const NetworkFailure(super.message);
}

class AIAnalysisFailure extends SensorFailure {
  const AIAnalysisFailure(super.message);
}
