import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_entity.freezed.dart';

/// Entidade de domínio para dados de sensor - 2025 Clean Architecture
@freezed
class SensorEntity with _$SensorEntity {
  const factory SensorEntity({
    required String id,
    required SensorType type,
    required DateTime timestamp,
    required Map<String, dynamic> values,
    @Default(false) bool isProcessing,
    String? aiAnalysis,
    double? confidence,
  }) = _SensorEntity;
  
  const SensorEntity._();
  
  /// Magnitude para sensores de movimento
  double? get magnitude {
    if (type == SensorType.accelerometer || 
        type == SensorType.gyroscope || 
        type == SensorType.magnetometer) {
      final x = values['x'] as double?;
      final y = values['y'] as double?;
      final z = values['z'] as double?;
      if (x != null && y != null && z != null) {
        return (x * x + y * y + z * z).sqrt();
      }
    }
    return null;
  }
  
  /// Classificação de atividade baseada em IA
  String get activityClassification {
    if (aiAnalysis != null) return aiAnalysis!;
    
    if (type == SensorType.accelerometer) {
      final mag = magnitude ?? 0;
      if (mag < 10.5) return 'Parado';
      if (mag < 12) return 'Caminhando';
      if (mag < 20) return 'Correndo';
      return 'Veículo';
    }
    
    return 'Desconhecido';
  }
}

enum SensorType {
  accelerometer,
  gyroscope,
  magnetometer,
  gps,
  light,
  proximity,
  battery,
  pressure,
  temperature,
  humidity,
}

/// Extension para converter tipos de sensor
extension SensorTypeX on SensorType {
  String get displayName {
    switch (this) {
      case SensorType.accelerometer:
        return 'Acelerômetro';
      case SensorType.gyroscope:
        return 'Giroscópio';
      case SensorType.magnetometer:
        return 'Magnetômetro';
      case SensorType.gps:
        return 'GPS';
      case SensorType.light:
        return 'Luz';
      case SensorType.proximity:
        return 'Proximidade';
      case SensorType.battery:
        return 'Bateria';
      case SensorType.pressure:
        return 'Pressão';
      case SensorType.temperature:
        return 'Temperatura';
      case SensorType.humidity:
        return 'Umidade';
    }
  }
  
  String get icon {
    switch (this) {
      case SensorType.accelerometer:
        return '📊';
      case SensorType.gyroscope:
        return '🔄';
      case SensorType.magnetometer:
        return '🧭';
      case SensorType.gps:
        return '📍';
      case SensorType.light:
        return '💡';
      case SensorType.proximity:
        return '📏';
      case SensorType.battery:
        return '🔋';
      case SensorType.pressure:
        return '🌡️';
      case SensorType.temperature:
        return '🌡️';
      case SensorType.humidity:
        return '💧';
    }
  }
}