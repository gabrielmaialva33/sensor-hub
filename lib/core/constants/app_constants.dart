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

  // Sensor Icons
  static const Map<String, String> sensorIcons = {
    'accelerometer': '🏃',
    'gyroscope': '🔄',
    'magnetometer': '🧭',
    'location': '📍',
    'battery': '🔋',
    'light': '💡',
    'proximity': '📡',
  };

  // Categories
  static const Map<String, List<String>> sensorCategories = {
    '🏃 Movimento': ['accelerometer', 'gyroscope', 'magnetometer'],
    '🌍 Ambiente': ['location', 'light', 'proximity'],
    '🔋 Sistema': ['battery'],
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
    'storage_full': 'Limite de armazenamento atingido. Por favor, limpe dados antigos.',
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
      'description': 'Permitir acesso aos sensores para monitoramento abrangente',
    },
    {
      'title': 'Iniciar Monitoramento',
      'description': 'Toque no botão de reprodução para começar a coletar dados dos sensores',
    },
    {
      'title': 'Ver Insights',
      'description':
          'Obtenha insights de IA sobre suas atividades e padrões',
    },
    {
      'title': 'Explorar Recursos',
      'description': 'Descubra gráficos, opções de exportação e muito mais!',
    },
  ];
}
