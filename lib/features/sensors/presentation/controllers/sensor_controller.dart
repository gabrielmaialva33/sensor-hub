import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sensor_entity.dart';
import '../../domain/use_cases/stream_sensor_data.dart';

/// Controller Riverpod 2.6+ - 2025 Pattern (sem code generation por enquanto)
class SensorController extends StateNotifier<AsyncValue<SensorState>> {
  SensorController(this.ref, this.type) : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref ref;
  final SensorType type;

  void _init() {
    // TODO: Inject use case via dependency injection quando configurado
    // final useCase = ref.watch(streamSensorDataUseCaseProvider);
    
    // Placeholder implementation por enquanto
    state = const AsyncValue.data(SensorState.initial());
  }
  
  /// Pausar streaming
  void pause() {
    state = const AsyncValue.loading();
  }
  
  /// Retomar streaming
  void resume() {
    _init();
  }
  
  /// Limpar dados
  Future<void> clearData() async {
    // Implementation
    state = const AsyncValue.data(SensorState.initial());
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

/// Provider para o controller
final sensorControllerProvider = StateNotifierProvider.family<
    SensorController, AsyncValue<SensorState>, SensorType>(
  (ref, type) => SensorController(ref, type),
);