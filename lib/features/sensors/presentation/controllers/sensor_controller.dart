import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/use_cases/stream_sensor_data.dart';

part 'sensor_controller.g.dart';

/// Controller Riverpod 2.6+ com code generation - 2025 Pattern
@riverpod
class SensorController extends _$SensorController {
  @override
  Stream<SensorState> build(SensorType type) {
    // Auto-dispose quando não usado
    ref.onDispose(() {
      // Cleanup logic
    });
    
    final useCase = ref.watch(streamSensorDataUseCaseProvider);
    
    return useCase(
      StreamSensorParams(
        type: type,
        enableAIAnalysis: true,
        throttleDuration: const Duration(milliseconds: 100),
      ),
    ).map((either) {
      return either.fold(
        (failure) => SensorState.error(failure.message),
        (data) => SensorState.data(data),
      );
    });
  }
  
  /// Pausar streaming
  void pause() {
    state = const AsyncValue.loading();
  }
  
  /// Retomar streaming
  void resume() {
    ref.invalidateSelf();
  }
  
  /// Limpar dados
  Future<void> clearData() async {
    // Implementation
  }
}

/// Estado do sensor com sealed class (2025 pattern)
sealed class SensorState {
  const SensorState();
  
  const factory SensorState.initial() = InitialSensorState;
  const factory SensorState.loading() = LoadingSensorState;
  const factory SensorState.data(List<SensorEntity> sensors) = DataSensorState;
  const factory SensorState.error(String message) = ErrorSensorState;
}

class InitialSensorState extends SensorState {
  const InitialSensorState();
}

class LoadingSensorState extends SensorState {
  const LoadingSensorState();
}

class DataSensorState extends SensorState {
  final List<SensorEntity> sensors;
  const DataSensorState(this.sensors);
}

class ErrorSensorState extends SensorState {
  final String message;
  const ErrorSensorState(this.message);
}

/// Provider para o use case (seria gerado pelo Injectable)
@riverpod
StreamSensorDataUseCase streamSensorDataUseCase(StreamSensorDataUseCaseRef ref) {
  throw UnimplementedError('Configure dependency injection');
}