import '../entities/sensor_entity.dart';
import '../repositories/sensor_repository.dart';

/// Use case para streaming de dados de sensor - 2025 Clean Architecture
class StreamSensorDataUseCase {
  final SensorRepository _repository;
  
  const StreamSensorDataUseCase(this._repository);
  
  /// Executa o use case
  Stream<SensorResult<List<SensorEntity>>> call(
    StreamSensorParams params,
  ) {
    return _repository.getSensorStream(params.type);
  }
}

/// Parâmetros para o use case
class StreamSensorParams {
  final SensorType type;
  final Duration? throttleDuration;
  final bool enableAIAnalysis;
  
  const StreamSensorParams({
    required this.type,
    this.throttleDuration,
    this.enableAIAnalysis = false,
  });
}

/// Result simplificado enquanto não configuramos dartz
class SensorResult<T> {
  final T? data;
  final SensorFailure? error;
  
  const SensorResult.success(this.data) : error = null;
  const SensorResult.failure(this.error) : data = null;
  
  bool get isSuccess => error == null;
  bool get isFailure => error != null;
}