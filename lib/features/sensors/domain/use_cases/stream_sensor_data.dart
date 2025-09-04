import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../entities/sensor_entity.dart';
import '../repositories/sensor_repository.dart';

/// Use case para streaming de dados de sensor - 2025 Clean Architecture
@injectable
class StreamSensorDataUseCase {
  final SensorRepository _repository;
  
  const StreamSensorDataUseCase(this._repository);
  
  /// Executa o use case
  Stream<Either<SensorFailure, List<SensorEntity>>> call(
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