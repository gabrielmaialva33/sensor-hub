# 🏗️ Arquitetura Flutter 2025 - SensorHub Ultra

## ❌ Problemas da Estrutura Atual

1. **Mistura de responsabilidades** - `utils` duplicado (lib/utils e lib/core/utils)
2. **Falta camada Domain** - Sem use cases, entities ou repositories abstratos
3. **Providers misturados** - Deveria ter state management separado
4. **Sem organização por features** - Dificulta manutenção em projetos grandes
5. **Falta dependency injection** - Sem GetIt ou Injectable
6. **Sem barrel exports** - Imports desorganizados
7. **Testes fracos** - Apenas test_main.dart solto

## ✅ Estrutura Recomendada 2025

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp principal
│   ├── app_router.dart              # go_router 14.0+
│   └── injection.dart               # GetIt + Injectable setup
│
├── core/                            # Shared/Common
│   ├── constants/
│   ├── extensions/
│   ├── theme/
│   ├── utils/
│   ├── widgets/                     # Widgets reutilizáveis
│   └── core.dart                    # Barrel export
│
├── features/                        # Feature-First Architecture
│   ├── sensors/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/       # Abstract repositories
│   │   │   └── use_cases/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   ├── data_sources/
│   │   │   └── repositories/       # Concrete implementations
│   │   ├── presentation/
│   │   │   ├── controllers/        # Riverpod StateNotifiers
│   │   │   ├── pages/
│   │   │   ├── widgets/
│   │   │   └── providers.dart      # Feature providers
│   │   └── sensors.dart            # Barrel export
│   │
│   ├── ai_analysis/
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── ai_analysis.dart
│   │
│   ├── performance/
│   │   ├── domain/
│   │   ├── data/
│   │   ├── presentation/
│   │   └── performance.dart
│   │
│   └── auth/                       # Se tiver autenticação
│       ├── domain/
│       ├── data/
│       ├── presentation/
│       └── auth.dart
│
├── infrastructure/                  # External services
│   ├── supabase/
│   ├── nvidia_ai/
│   ├── mqtt/
│   ├── local_storage/
│   └── infrastructure.dart
│
└── main.dart                        # Entry point

test/
├── unit/
│   └── features/
├── integration/
├── widget/
└── golden/                          # Visual regression tests
```

## 🚀 Tecnologias 2025

### State Management

```yaml
# Riverpod 2.6+ com code generation
flutter_riverpod: ^2.6.0
riverpod_annotation: ^2.6.0
riverpod_generator: ^2.6.0
```

### Dependency Injection

```yaml
# Injectable + GetIt
get_it: ^8.0.0
injectable: ^2.5.0
injectable_generator: ^2.7.0
```

### Routing

```yaml
# go_router com deep linking
go_router: ^14.6.0
```

### Code Generation

```yaml
# Freezed + JSON serialization
freezed_annotation: ^2.5.0
json_annotation: ^4.9.0
build_runner: ^2.4.0
freezed: ^2.5.0
json_serializable: ^6.8.0
```

### Testing

```yaml
# Testing avançado
mocktail: ^1.0.4
bloc_test: ^9.1.0
golden_toolkit: ^0.15.0
integration_test:
  sdk: flutter
```

## 📁 Exemplo de Feature Completa

### Domain Layer (sensor_entity.dart)

```dart
@freezed
class SensorEntity with _$SensorEntity {
  const factory SensorEntity({
    required String id,
    required SensorType type,
    required double value,
    required DateTime timestamp,
  }) = _SensorEntity;
}
```

### Use Case (get_sensor_data_use_case.dart)

```dart
@injectable
class GetSensorDataUseCase {
  final SensorRepository _repository;
  
  GetSensorDataUseCase(this._repository);
  
  Stream<Either<Failure, List<SensorEntity>>> call(SensorType type) {
    return _repository.getSensorStream(type);
  }
}
```

### Riverpod Provider (sensor_providers.dart)

```dart
@riverpod
class SensorController extends _$SensorController {
  @override
  Future<List<SensorEntity>> build() async {
    final useCase = ref.read(getSensorDataUseCaseProvider);
    return useCase(SensorType.accelerometer);
  }
}
```

## 🎯 Benefícios da Arquitetura 2025

1. **Testabilidade** - 100% testável com mocks
2. **Escalabilidade** - Fácil adicionar features
3. **Manutenibilidade** - Código organizado
4. **Performance** - Lazy loading por feature
5. **Type Safety** - Freezed + code generation
6. **Clean Code** - Separação clara de responsabilidades
7. **CI/CD Ready** - Estrutura pronta para automação

## 🔄 Migração Sugerida

1. Criar estrutura de features
2. Mover código existente gradualmente
3. Implementar dependency injection
4. Adicionar testes para cada camada
5. Configurar code generation
6. Implementar routing modular