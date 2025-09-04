import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'SensorHub';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Monitoramento abrangente de sensores com IA';

  // Sensor Types
  static const List<String> availableSensors = [
    'accelerometer',
    'gyroscope',
    'magnetometer',
    'location',
    'battery',
    'light',
    'proximity',
  ];

  // Sensor Display Names
  static const Map<String, String> sensorDisplayNames = {
    'accelerometer': 'Acelerômetro',
    'gyroscope': 'Giroscópio',
    'magnetometer': 'Magnetômetro',
    'location': 'Localização',
    'battery': 'Bateria',
    'light': 'Sensor de Luz',
    'proximity': 'Proximidade',
  };

  // Sensor Icons (Material Icons)
  static const Map<String, IconData> sensorIcons = {
    'accelerometer': Icons.directions_run,
    'gyroscope': Icons.rotate_right,
    'magnetometer': Icons.explore,
    'location': Icons.location_on,
    'battery': Icons.battery_full,
    'light': Icons.light_mode,
    'proximity': Icons.radar,
  };

  // Categories with icons
  static const Map<String, Map<String, dynamic>> sensorCategories = {
    'movement': {
      'label': 'Movimento',
      'icon': Icons.directions_run,
      'sensors': ['accelerometer', 'gyroscope', 'magnetometer'],
      'description': 'Sensores de movimento e orientação',
    },
    'environment': {
      'label': 'Ambiente',
      'icon': Icons.wb_sunny,
      'sensors': ['location', 'light', 'proximity'],
      'description': 'Sensores ambientais e contextuais',
    },
    'system': {
      'label': 'Sistema',
      'icon': Icons.smartphone,
      'sensors': ['battery'],
      'description': 'Estado do sistema e hardware',
    },
  };

  // Sampling Rates (in milliseconds)
  static const Map<String, int> defaultSamplingRates = {
    'accelerometer': 100, // 10Hz
    'gyroscope': 100, // 10Hz
    'magnetometer': 200, // 5Hz
    'location': 5000, // Every 5 seconds
    'battery': 30000, // Every 30 seconds
    'light': 1000, // 1Hz
    'proximity': 500, // 2Hz
  };

  // Storage Configuration
  static const String databaseName = 'sensor_hub.db';
  static const int databaseVersion = 1;
  static const int maxStoredRecords = 10000;
  static const int batchSize = 100;

  // UI Configuration
  static const int maxChartPoints = 50;
  static const double chartAnimationDuration = 300.0;
  static const int refreshIntervalMs = 1000;

  // AI Analysis Configuration
  static const int minDataPointsForAnalysis = 50;
  static const int analysisIntervalMinutes = 15;
  static const int maxAnalysisHistory = 24; // hours

  // Permissions
  static const List<String> requiredPermissions = [
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.CAMERA',
    'android.permission.RECORD_AUDIO',
    'android.permission.WAKE_LOCK',
    'android.permission.FOREGROUND_SERVICE',
  ];

  // Notification Configuration
  static const String notificationChannelId = 'sensor_monitoring';
  static const String notificationChannelName = 'Monitoramento de Sensores';
  static const String notificationChannelDescription =
      'Notificações sobre o status do monitoramento de sensores';

  // Export Configuration
  static const List<String> supportedExportFormats = ['json', 'csv', 'pdf'];
  static const int maxExportRecords = 5000;

  // Activity Classification
  static const Map<String, Map<String, dynamic>> activityThresholds = {
    'stationary': {
      'accelerometer_magnitude': {'min': 0.0, 'max': 2.0},
      'confidence': 0.9,
    },
    'walking': {
      'accelerometer_magnitude': {'min': 2.0, 'max': 8.0},
      'confidence': 0.8,
    },
    'running': {
      'accelerometer_magnitude': {'min': 8.0, 'max': 25.0},
      'confidence': 0.85,
    },
    'driving': {
      'accelerometer_magnitude': {'min': 0.5, 'max': 4.0},
      'location_speed': {'min': 10.0, 'max': 120.0},
      'confidence': 0.75,
    },
  };

  // Environment Classification
  static const Map<String, Map<String, double>> environmentThresholds = {
    'indoor': {'light_lux_max': 500.0, 'confidence': 0.7},
    'outdoor': {'light_lux_min': 1000.0, 'confidence': 0.8},
    'dark': {'light_lux_max': 10.0, 'confidence': 0.9},
    'bright': {'light_lux_min': 5000.0, 'confidence': 0.85},
  };

  // Battery Health Thresholds
  static const Map<String, double> batteryThresholds = {
    'critical': 15.0,
    'low': 30.0,
    'normal': 50.0,
    'high': 80.0,
  };

  // Data Retention
  static const Map<String, int> dataRetentionDays = {
    'sensor_data': 30,
    'ai_insights': 90,
    'activity_summaries': 365,
    'predictions': 7,
  };

  // Performance Limits
  static const int maxConcurrentSensors = 7;
  static const int maxMemoryUsageMB = 100;
  static const int maxCpuUsagePercent = 15;

  // Error Messages
  static const Map<String, String> errorMessages = {
    'permission_denied':
        'Permissão negada. Por favor, conceda as permissões necessárias.',
    'sensor_unavailable': 'Sensor não disponível neste dispositivo.',
    'api_error': 'Serviço de análise de IA temporariamente indisponível.',
    'storage_full':
        'Limite de armazenamento atingido. Por favor, limpe dados antigos.',
    'network_error': 'Conexão de rede necessária para recursos de IA.',
  };

  // Success Messages
  static const Map<String, String> successMessages = {
    'monitoring_started': 'Monitoramento de sensores iniciado com sucesso!',
    'monitoring_stopped': 'Monitoramento de sensores parado.',
    'data_exported': 'Dados exportados com sucesso!',
    'analysis_complete': 'Análise de IA concluída.',
    'backup_complete': 'Backup de dados concluído.',
  };

  // URLs and API Endpoints
  static const String privacyPolicyUrl = 'https://example.com/privacy';
  static const String termsOfServiceUrl = 'https://example.com/terms';
  static const String supportUrl = 'https://example.com/support';
  static const String githubUrl = 'https://github.com/example/sensor-hub';

  // Feature Flags
  static const Map<String, bool> features = {
    'ai_analysis': true,
    'data_export': true,
    'cloud_sync': false, // Disabled by default for privacy
    'background_monitoring': true,
    'voice_commands': false,
    'gesture_control': true,
    'share_insights': true,
  };

  // Tutorial Steps
  static const List<Map<String, String>> tutorialSteps = [
    {
      'title': 'Bem-vindo ao SensorHub',
      'description': 'Seu painel pessoal de monitoramento de sensores com IA',
    },
    {
      'title': 'Conceder Permissões',
      'description':
          'Permitir acesso aos sensores para monitoramento abrangente',
    },
    {
      'title': 'Iniciar Monitoramento',
      'description':
          'Toque no botão de reprodução para começar a coletar dados dos sensores',
    },
    {
      'title': 'Ver Insights',
      'description': 'Obtenha insights de IA sobre suas atividades e padrões',
    },
    {
      'title': 'Explorar Recursos',
      'description': 'Descubra gráficos, opções de exportação e muito mais!',
    },
  ];

  // Human Insights Templates
  static const Map<String, List<String>> humanInsights = {
    'activity_patterns': [
      'Você está mais ativo entre {start_time} e {end_time}',
      'Seus níveis de movimento aumentaram {percentage}% esta semana',
      'Padrão de atividade sugere trabalho {work_type}',
      'Você mantém consistência em seus horários de movimento',
    ],
    'environmental_awareness': [
      'A iluminação sugere que você está {location_type}',
      'Mudanças ambientais detectadas às {time}',
      'Ambiente {brightness_level} pode afetar seu bem-estar',
      'Padrões de localização indicam rotina estabelecida',
    ],
    'health_suggestions': [
      'Seu padrão de movimento indica bons níveis de atividade',
      'Considere fazer uma pausa - você está imóvel há {duration}',
      'Níveis de bateria baixos podem indicar uso intenso',
      'Excelente! Você mantém um bom equilíbrio entre atividade e descanso',
    ],
    'contextual_alerts': [
      'Inatividade incomum detectada por {duration} minutos',
      'Padrão de movimento alterado - novo ambiente?',
      'Seus sensores detectaram uma mudança significativa no ambiente',
      'Atividade consistente com {activity_type} - mantenha o ritmo!',
    ],
  };

  // Activity Recognition Patterns
  static const Map<String, Map<String, dynamic>> activityPatterns = {
    'stationary': {
      'name': 'Parado',
      'description': 'Pouco ou nenhum movimento detectado',
      'icon': Icons.event_seat,
      'color': 0xFF94A3B8, // Slate-400
      'threshold': {'acceleration': 2.0, 'duration': 300}, // 5 minutes
    },
    'walking': {
      'name': 'Caminhando',
      'description': 'Movimento moderado e consistente',
      'icon': Icons.directions_walk,
      'color': 0xFF10B981, // Green
      'threshold': {'acceleration': 8.0, 'step_frequency': 2.0},
    },
    'running': {
      'name': 'Correndo',
      'description': 'Movimento intenso e rápido',
      'icon': Icons.directions_run,
      'color': 0xFFEF4444, // Red
      'threshold': {'acceleration': 25.0, 'step_frequency': 3.5},
    },
    'driving': {
      'name': 'Dirigindo',
      'description': 'Movimento constante com velocidade',
      'icon': Icons.directions_car,
      'color': 0xFF3B82F6, // Blue
      'threshold': {'speed': 15.0, 'acceleration_variance': 4.0},
    },
    'cycling': {
      'name': 'Pedalando',
      'description': 'Movimento rítmico moderado',
      'icon': Icons.directions_bike,
      'color': 0xFF8B5CF6, // Purple
      'threshold': {'acceleration': 12.0, 'rhythm_pattern': 1.5},
    },
  };

  // Environment Detection
  static const Map<String, Map<String, dynamic>> environmentTypes = {
    'indoor_dim': {
      'name': 'Ambiente Interno',
      'description': 'Luz artificial, baixa luminosidade',
      'icon': Icons.home,
      'lux_range': {'min': 0, 'max': 500},
    },
    'indoor_bright': {
      'name': 'Escritório/Loja',
      'description': 'Iluminação artificial intensa',
      'icon': Icons.business,
      'lux_range': {'min': 500, 'max': 1000},
    },
    'outdoor_shade': {
      'name': 'Área Externa Sombreada',
      'description': 'Luz natural indireta',
      'icon': Icons.park,
      'lux_range': {'min': 1000, 'max': 10000},
    },
    'outdoor_sunny': {
      'name': 'Luz Solar Direta',
      'description': 'Ambiente externo ensolarado',
      'icon': Icons.wb_sunny,
      'lux_range': {'min': 10000, 'max': 100000},
    },
  };

  // Health Metrics
  static const Map<String, Map<String, dynamic>> healthMetrics = {
    'movement_score': {
      'excellent': {'min': 8, 'message': 'Excelente nível de atividade!'},
      'good': {'min': 6, 'message': 'Bom equilíbrio entre atividade e descanso'},
      'moderate': {'min': 4, 'message': 'Tente aumentar sua atividade física'},
      'low': {'min': 0, 'message': 'Considere se mover mais ao longo do dia'},
    },
    'consistency_score': {
      'excellent': {'min': 8, 'message': 'Rotina muito consistente'},
      'good': {'min': 6, 'message': 'Boa regularidade nos padrões'},
      'moderate': {'min': 4, 'message': 'Padrões um pouco irregulares'},
      'low': {'min': 0, 'message': 'Rotina bastante variável'},
    },
  };
}
