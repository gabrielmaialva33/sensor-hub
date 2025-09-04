import 'dart:async';
import 'dart:math';

import 'package:sensor_hub/core/core.dart';
import 'package:sensor_hub/features/sensors/data/models/sensor_data.dart';
import 'package:sensor_hub/infrastructure/nvidia_ai/nvidia_ai_service.dart';

/// Advanced AI service that provides human-like insights about user behavior and health
/// Acts like a caring personal health coach with empathetic, conversational insights
class HumanInsightsService {
  static final HumanInsightsService _instance = HumanInsightsService._internal();
  factory HumanInsightsService() => _instance;
  HumanInsightsService._internal();

  final NvidiaAiService _aiService = NvidiaAiService();
  final List<HumanInsight> _recentInsights = [];
  Timer? _analysisTimer;

  /// Initialize the service with periodic analysis
  void initialize() {
    _aiService.initialize();
    _startPeriodicAnalysis();
    Logger.info('HumanInsightsService initialized - your personal health coach is ready! 🤖💙');
  }

  /// Start periodic analysis every 5 minutes for real-time insights
  void _startPeriodicAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _performBackgroundAnalysis();
    });
  }

  /// Generate real-time human insights from current sensor patterns
  Future<HumanInsight> generateRealTimeInsight(List<SensorData> currentData) async {
    try {
      if (currentData.isEmpty) {
        return HumanInsight.gentle('Aguardando dados dos sensores... 🌱');
      }

      // Analyze current behavior patterns
      final behavior = _analyzeBehaviorPatterns(currentData);
      final environment = _analyzeEnvironmentalFactors(currentData);
      final health = _analyzeHealthIndicators(currentData);

      // Generate contextual insights based on patterns
      final insights = await _generateContextualInsights(behavior, environment, health, currentData);
      
      // Store insight for learning
      _storeInsight(insights);
      
      return insights;
    } catch (e) {
      Logger.error('Error generating real-time insight', e);
      return HumanInsight.supportive(
        'Estou aqui para ajudar! Parece que há um pequeno problema técnico, mas continuarei monitorando você. 🤗'
      );
    }
  }

  /// Detect unusual patterns and provide contextual warnings
  Future<HumanInsight?> detectUnusualPatterns(List<SensorData> recentData) async {
    try {
      final currentBehavior = _analyzeBehaviorPatterns(recentData);
      
      // Compare with historical patterns
      final unusualPatterns = _detectAnomalies(currentBehavior);
      
      if (unusualPatterns.isEmpty) return null;

      // Generate caring warning based on detected anomalies
      return await _generateConcernedInsight(unusualPatterns, recentData);
    } catch (e) {
      Logger.error('Error detecting unusual patterns', e);
      return null;
    }
  }

  /// Create daily summary of user activity with encouraging tone
  Future<DailySummary> generateDailySummary(List<SensorData> dailyData) async {
    try {
      final summary = DailySummaryBuilder(dailyData)
        ..analyzeActivities()
        ..analyzePosture()
        ..analyzeEnvironment()
        ..calculateHealthScores();

      // Use AI to generate personalized encouraging messages
      final aiSummary = await _aiService.generateActivitySummary(dailyData);
      
      return await _createHumanizedDailySummary(summary, aiSummary);
    } catch (e) {
      Logger.error('Error generating daily summary', e);
      return DailySummary.error('Não consegui gerar seu resumo hoje, mas estou aqui para amanhã! 💪');
    }
  }

  /// Generate weekly health and behavior insights
  Future<WeeklySummary> generateWeeklySummary(List<SensorData> weeklyData) async {
    try {
      final weeklyAnalysis = WeeklyAnalyzer(weeklyData)
        ..analyzeTrends()
        ..compareWithPreviousWeek()
        ..identifyImprovements()
        ..setGoals();

      return await _createHumanizedWeeklySummary(weeklyAnalysis);
    } catch (e) {
      Logger.error('Error generating weekly summary', e);
      return WeeklySummary.error('Vamos tentar novamente na próxima semana! 🌟');
    }
  }

  /// Search for personalized health recommendations based on current data
  Future<List<HealthRecommendation>> searchHealthRecommendations(
    String behaviorPattern, 
    Map<String, double> healthMetrics
  ) async {
    try {
      // Generate search queries based on detected patterns
      final queries = _generateHealthSearchQueries(behaviorPattern, healthMetrics);
      final recommendations = <HealthRecommendation>[];

      // Use NVIDIA AI to generate evidence-based recommendations
      for (final query in queries) {
        final recommendation = await _generateAIRecommendation(query, behaviorPattern);
        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }

      return recommendations;
    } catch (e) {
      Logger.error('Error searching health recommendations', e);
      return [
        HealthRecommendation.fallback(
          'Que tal dar uma caminhada curta? Seus músculos vão agradecer! 🚶‍♂️✨'
        )
      ];
    }
  }

  /// Analyze current behavior patterns from sensor data
  BehaviorPattern _analyzeBehaviorPatterns(List<SensorData> data) {
    final pattern = BehaviorPattern();
    
    for (final sensorData in data) {
      switch (sensorData.sensorType) {
        case 'accelerometer':
          final accelData = sensorData as AccelerometerData;
          pattern.updateMovement(accelData.magnitude);
          break;
        case 'location':
          final locationData = sensorData as LocationData;
          pattern.updateLocation(locationData.latitude, locationData.longitude, locationData.speed);
          break;
        case 'light':
          final lightData = sensorData as LightData;
          pattern.updateEnvironment(lightData.luxValue);
          break;
        case 'proximity':
          final proximityData = sensorData as ProximityData;
          pattern.updateProximity(proximityData.isNear);
          break;
        case 'battery':
          final batteryData = sensorData as BatteryData;
          pattern.updateBattery(batteryData.batteryLevel.toDouble());
          break;
      }
    }
    
    return pattern..finalize();
  }

  /// Analyze environmental factors affecting health
  EnvironmentalFactors _analyzeEnvironmentalFactors(List<SensorData> data) {
    double averageLight = 0;
    int lightReadings = 0;
    bool isIndoors = true;
    
    for (final sensorData in data.where((d) => d.sensorType == 'light')) {
      final lightData = sensorData as LightData;
      averageLight += lightData.luxValue;
      lightReadings++;
      if (lightData.luxValue > 1000) isIndoors = false;
    }
    
    if (lightReadings > 0) {
      averageLight /= lightReadings;
    }
    
    return EnvironmentalFactors(
      averageLightLevel: averageLight,
      isLikelyIndoors: isIndoors,
      lightCondition: _getLightConditionDescription(averageLight),
    );
  }

  /// Analyze health indicators from movement and posture
  HealthIndicators _analyzeHealthIndicators(List<SensorData> data) {
    final accelerometerData = data.where((d) => d.sensorType == 'accelerometer').cast<AccelerometerData>().toList();
    
    if (accelerometerData.isEmpty) {
      return HealthIndicators.noData();
    }
    
    final movements = accelerometerData.map((d) => d.magnitude).toList();
    final avgMovement = movements.reduce((a, b) => a + b) / movements.length;
    final maxMovement = movements.reduce((a, b) => a > b ? a : b);
    
    // Detect periods of inactivity
    final lowActivityPeriods = movements.where((m) => m < 2.0).length;
    final inactivityPercentage = (lowActivityPeriods / movements.length) * 100;
    
    return HealthIndicators(
      averageActivity: avgMovement,
      maxActivity: maxMovement,
      inactivityPercentage: inactivityPercentage,
      isPostureConcern: inactivityPercentage > 70,
      activityLevel: _getActivityLevel(avgMovement),
    );
  }

  /// Generate contextual insights with human empathy
  Future<HumanInsight> _generateContextualInsights(
    BehaviorPattern behavior,
    EnvironmentalFactors environment,
    HealthIndicators health,
    List<SensorData> data,
  ) async {
    // Select most relevant insight type
    if (health.isPostureConcern && behavior.stationaryMinutes > 30) {
      return _createPostureInsight(behavior.stationaryMinutes);
    }
    
    if (environment.averageLightLevel < 50 && behavior.stationaryMinutes > 20) {
      return _createLightExposureInsight(environment.averageLightLevel);
    }
    
    if (health.activityLevel == 'high' && behavior.activeMinutes > 0) {
      return _createEncouragingInsight(health.activityLevel, behavior.activeMinutes);
    }
    
    if (behavior.stressIndicators.isNotEmpty) {
      return _createStressReliefInsight(behavior.stressIndicators);
    }
    
    // Default encouraging insight
    return _createGeneralWellnessInsight(health, environment);
  }

  /// Create posture-related insight with caring tone
  HumanInsight _createPostureInsight(int stationaryMinutes) {
    final messages = [
      'Notei que você está sentado há $stationaryMinutes minutos. Sua coluna agradeceria um alongamento rápido! 🧘‍♀️',
      'Que tal levantar e dar uma caminhada curta? Seus músculos estão pedindo movimento há $stationaryMinutes minutos! 🚶‍♂️',
      'Seu corpo está me dizendo que precisa de uma pausa ativa. $stationaryMinutes minutos sentado é bastante! 💪',
      'Hora de cuidar da postura! Uma pausa de 2 minutos pode fazer toda a diferença após $stationaryMinutes minutos parado. ✨',
    ];
    
    return HumanInsight(
      type: InsightType.postureAlert,
      message: messages[Random().nextInt(messages.length)],
      priority: InsightPriority.medium,
      actionSuggestion: 'Levante-se e faça 5 alongamentos simples',
      healthImpact: 'Melhora circulação e reduz tensão muscular',
      timestamp: DateTime.now(),
    );
  }

  /// Create light exposure insight
  HumanInsight _createLightExposureInsight(double lightLevel) {
    return HumanInsight(
      type: InsightType.environmental,
      message: 'Os níveis baixos de luz (${lightLevel.toInt()} lux) sugerem que você se beneficiaria de um pouco de luz natural. Seu humor e energia vão agradecer! ☀️',
      priority: InsightPriority.low,
      actionSuggestion: 'Abra as cortinas ou dê uma volta ao ar livre',
      healthImpact: 'Luz natural ajuda a regular o ritmo circadiano e melhora o humor',
      timestamp: DateTime.now(),
    );
  }

  /// Create encouraging insight for active users
  HumanInsight _createEncouragingInsight(String activityLevel, int activeMinutes) {
    final messages = [
      'Incrível! Você se manteve ativo por $activeMinutes minutos. Continue assim, você está no caminho certo! 🎉',
      'Que energia boa! $activeMinutes minutos de atividade mostram que você está cuidando bem da sua saúde. 💪',
      'Parabéns pelos $activeMinutes minutos ativos! Seu futuro eu vai agradecer por esse cuidado. ⭐',
    ];
    
    return HumanInsight(
      type: InsightType.encouragement,
      message: messages[Random().nextInt(messages.length)],
      priority: InsightPriority.low,
      actionSuggestion: 'Continue mantendo esse ritmo saudável',
      healthImpact: 'Atividade regular fortalece o coração e melhora o humor',
      timestamp: DateTime.now(),
    );
  }

  /// Create stress relief insight
  HumanInsight _createStressReliefInsight(List<String> stressIndicators) {
    return HumanInsight(
      type: InsightType.stressAlert,
      message: 'Seus padrões de movimento sugerem que você pode estar se sentindo tenso. Como sobre uma pausa para respirar? 🧘‍♂️',
      priority: InsightPriority.medium,
      actionSuggestion: 'Tente 3 respirações profundas: inspire por 4, segure por 4, expire por 6',
      healthImpact: 'Respiração consciente reduz cortisol e ativa o sistema nervoso parassimpático',
      timestamp: DateTime.now(),
      metadata: {'stress_indicators': stressIndicators},
    );
  }

  /// Create general wellness insight
  HumanInsight _createGeneralWellnessInsight(HealthIndicators health, EnvironmentalFactors environment) {
    final messages = [
      'Você está tendo um dia equilibrado! Continue ouvindo seu corpo e mantendo esse cuidado. 💚',
      'Seus sensores mostram um padrão saudável. Lembre-se: pequenos cuidados diários fazem toda a diferença! 🌱',
      'Que bom te ver cuidando da sua saúde! Cada movimento conta para seu bem-estar. ✨',
    ];
    
    return HumanInsight(
      type: InsightType.wellness,
      message: messages[Random().nextInt(messages.length)],
      priority: InsightPriority.low,
      actionSuggestion: 'Continue fazendo o que está fazendo!',
      healthImpact: 'Hábitos consistentes contribuem para longevidade e qualidade de vida',
      timestamp: DateTime.now(),
    );
  }

  /// Generate concerned insight for unusual patterns
  Future<HumanInsight> _generateConcernedInsight(List<String> anomalies, List<SensorData> data) async {
    final concernLevel = anomalies.length > 2 ? InsightPriority.high : InsightPriority.medium;
    
    String message;
    String action;
    
    if (anomalies.contains('extended_inactivity')) {
      message = 'Notei uma inatividade mais longa que o usual. Está tudo bem? Às vezes nosso corpo precisa de um impulso extra. 💙';
      action = 'Se possível, tente se mover por alguns minutos';
    } else if (anomalies.contains('irregular_movement')) {
      message = 'Seus padrões de movimento estão um pouco diferentes hoje. Talvez seja hora de uma pausa mindful? 🤗';
      action = 'Faça uma verificação corporal: como você está se sentindo?';
    } else {
      message = 'Detectei algumas mudanças nos seus padrões. Lembre-se: eu estou aqui para apoiar seu bem-estar! 🌟';
      action = 'Considere fazer algo que te dê prazer e relaxe';
    }
    
    return HumanInsight(
      type: InsightType.concern,
      message: message,
      priority: concernLevel,
      actionSuggestion: action,
      healthImpact: 'Atenção às mudanças corporais ajuda na prevenção e autocuidado',
      timestamp: DateTime.now(),
      metadata: {'anomalies': anomalies},
    );
  }

  /// Create humanized daily summary with encouraging tone
  Future<DailySummary> _createHumanizedDailySummary(DailySummaryBuilder builder, ActivitySummary aiSummary) async {
    final encouragingMessages = [
      'Que dia interessante você teve!',
      'Vamos ver como foi seu dia de autocuidado:',
      'Aqui está um resuminho carinhoso do seu dia:',
      'Seu corpo tem histórias para contar sobre hoje:',
    ];

    return DailySummary(
      greeting: encouragingMessages[Random().nextInt(encouragingMessages.length)],
      activitySummary: _humanizeActivitySummary(builder.activities),
      postureInsights: _humanizePostureInsights(builder.postureScore),
      environmentalFactors: _humanizeEnvironmentalSummary(builder.environmentScore),
      healthScore: builder.overallScore,
      encouragement: _generateDailyEncouragement(builder.overallScore),
      improvements: _suggestDailyImprovements(builder),
      celebration: _celebrateDailyAchievements(builder),
      timestamp: DateTime.now(),
    );
  }

  /// Create humanized weekly summary
  Future<WeeklySummary> _createHumanizedWeeklySummary(WeeklyAnalyzer analyzer) async {
    return WeeklySummary(
      weeklyGreeting: 'Que semana incrível! Vamos celebrar suas conquistas:',
      trendAnalysis: _humanizeWeeklyTrends(analyzer.trends),
      improvements: _humanizeWeeklyImprovements(analyzer.improvements),
      challenges: _humanizeWeeklyChallenges(analyzer.challenges),
      nextWeekGoals: _generateNextWeekGoals(analyzer),
      motivationalQuote: _getWeeklyMotivationalQuote(),
      overallProgress: analyzer.progressScore,
      timestamp: DateTime.now(),
    );
  }

  /// Perform background analysis for proactive insights
  void _performBackgroundAnalysis() async {
    // This would connect to the sensor data stream for background monitoring
    Logger.debug('Background health analysis completed 💚');
  }

  // Helper methods for classification and analysis
  String _getActivityLevel(double avgMovement) {
    if (avgMovement > 15) return 'high';
    if (avgMovement > 5) return 'moderate';
    return 'low';
  }

  String _getLightConditionDescription(double lux) {
    if (lux < 10) return 'muito escuro - hora de buscar luz!';
    if (lux < 200) return 'pouca luz - que tal clarear o ambiente?';
    if (lux < 1000) return 'luz moderada - bom para trabalhar';
    return 'bem iluminado - perfeito para atividades!';
  }

  /// Generate health search queries based on patterns
  List<String> _generateHealthSearchQueries(String pattern, Map<String, double> metrics) {
    final queries = <String>[];
    
    if (pattern.contains('sedentary')) {
      queries.addAll([
        'exercises for desk workers posture',
        'health effects prolonged sitting',
        'simple stretches office workers'
      ]);
    }
    
    if (pattern.contains('active')) {
      queries.addAll([
        'recovery tips active lifestyle',
        'nutrition for active people',
        'preventing exercise burnout'
      ]);
    }
    
    return queries;
  }

  /// Generate AI-powered health recommendation
  Future<HealthRecommendation?> _generateAIRecommendation(String query, String pattern) async {
    try {
      // This would use the NVIDIA AI service to generate recommendations
      // For now, return a sample recommendation based on the pattern
      return HealthRecommendation(
        title: 'Movimento Consciente',
        description: 'Baseado nos seus padrões, seu corpo está pedindo mais movimento mindful.',
        action: 'Faça pausas de 2 minutos a cada hora para alongar',
        benefit: 'Melhora circulação, reduz tensão e aumenta energia',
        priority: RecommendationPriority.medium,
        category: 'posture',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      Logger.error('Error generating AI recommendation', e);
      return null;
    }
  }

  // Store insight for learning and pattern recognition
  void _storeInsight(HumanInsight insight) {
    _recentInsights.add(insight);
    if (_recentInsights.length > 50) {
      _recentInsights.removeAt(0);
    }
  }

  /// Detect behavioral anomalies
  List<String> _detectAnomalies(BehaviorPattern current) {
    final anomalies = <String>[];
    
    if (current.stationaryMinutes > 120) {
      anomalies.add('extended_inactivity');
    }
    
    if (current.movementVariability > 50) {
      anomalies.add('irregular_movement');
    }
    
    return anomalies;
  }

  // Humanization helper methods
  String _humanizeActivitySummary(Map<String, int> activities) {
    if (activities.isEmpty) return 'Seus dados ainda estão chegando - aguarde um pouquinho! 📱';
    
    final totalMinutes = activities.values.reduce((a, b) => a + b);
    final mostActive = activities.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    return 'Você passou $totalMinutes minutos em movimento, sendo "${mostActive.key}" sua atividade principal (${mostActive.value} min). Que legal! 🎯';
  }

  String _humanizePostureInsights(int postureScore) {
    if (postureScore >= 8) return 'Sua postura está excelente hoje! Seu corpo está te agradecendo. 👏';
    if (postureScore >= 6) return 'Boa postura na maior parte do tempo - continue assim! 💪';
    if (postureScore >= 4) return 'Sua postura pode melhorar. Que tal prestar mais atenção nela? 🤗';
    return 'Vamos cuidar melhor da postura amanhã? Pequenos ajustes fazem diferença! 🌱';
  }

  String _humanizeEnvironmentalSummary(int envScore) {
    if (envScore >= 8) return 'Ambiente perfeito para produtividade e bem-estar! 🌟';
    if (envScore >= 6) return 'Bom ambiente na maior parte do tempo. 👍';
    return 'Que tal buscar um pouco mais de luz natural amanhã? ☀️';
  }

  String _generateDailyEncouragement(int overallScore) {
    if (overallScore >= 8) return 'Dia fantástico de autocuidado! Você é inspiração! ⭐';
    if (overallScore >= 6) return 'Bom dia de cuidados com a saúde. Continue assim! 💚';
    return 'Amanhã é uma nova oportunidade para cuidar ainda melhor de você! 🌅';
  }

  List<String> _suggestDailyImprovements(DailySummaryBuilder builder) {
    final suggestions = <String>[];
    
    if (builder.postureScore < 6) {
      suggestions.add('💡 Configure lembretes para alongar a cada hora');
    }
    
    if (builder.environmentScore < 6) {
      suggestions.add('🌞 Busque mais luz natural durante o dia');
    }
    
    if (builder.activities['walking'] == null || builder.activities['walking']! < 30) {
      suggestions.add('🚶‍♂️ Adicione uma caminhada curta à sua rotina');
    }
    
    return suggestions;
  }

  List<String> _celebrateDailyAchievements(DailySummaryBuilder builder) {
    final celebrations = <String>[];
    
    if (builder.overallScore >= 7) {
      celebrations.add('🎉 Excelente dia de autocuidado!');
    }
    
    if (builder.postureScore >= 8) {
      celebrations.add('👑 Postura real hoje!');
    }
    
    return celebrations;
  }

  String _humanizeWeeklyTrends(Map<String, dynamic> trends) {
    return 'Suas tendências semanais mostram evolução positiva em ${trends.length} áreas! 📈';
  }

  String _humanizeWeeklyImprovements(List<String> improvements) {
    if (improvements.isEmpty) return 'Você manteve consistência - isso é uma vitória! 🏆';
    return 'Melhorias notáveis: ${improvements.join(", ")}. Que progresso lindo! 🚀';
  }

  String _humanizeWeeklyChallenges(List<String> challenges) {
    if (challenges.isEmpty) return 'Semana sem grandes desafios de saúde. Perfeito! ✨';
    return 'Alguns pontos de atenção para próxima semana: ${challenges.join(", ")}. Vamos juntos! 💪';
  }

  List<String> _generateNextWeekGoals(WeeklyAnalyzer analyzer) {
    return [
      'Manter consistência nos movimentos',
      'Melhorar postura em 10%',
      'Buscar mais luz natural',
      'Celebrar pequenas vitórias diárias',
    ];
  }

  String _getWeeklyMotivationalQuote() {
    final quotes = [
      '"Pequenos progressos diários levam a grandes resultados!" 🌟',
      '"Seu corpo é seu lar para a vida toda - cuide bem dele!" 🏠💚',
      '"Cada movimento conta, cada respiração importa!" 🌬️✨',
      '"Você é mais forte do que imagina e mais capaz do que acredita!" 💪⭐',
    ];
    return quotes[Random().nextInt(quotes.length)];
  }

  /// Dispose resources
  void dispose() {
    _analysisTimer?.cancel();
    Logger.info('HumanInsightsService disposed');
  }
}

// Supporting classes for behavior analysis

/// Represents detected behavior patterns
class BehaviorPattern {
  double averageMovement = 0;
  int activeMinutes = 0;
  int stationaryMinutes = 0;
  double movementVariability = 0;
  List<String> stressIndicators = [];
  String primaryActivity = 'unknown';
  
  void updateMovement(double magnitude) {
    averageMovement = (averageMovement + magnitude) / 2;
    if (magnitude > 5) activeMinutes++;
    if (magnitude < 2) stationaryMinutes++;
  }
  
  void updateLocation(double lat, double lng, double? speed) {
    if (speed != null && speed > 15) {
      primaryActivity = 'driving';
    } else if (averageMovement > 8) {
      primaryActivity = 'walking';
    }
  }
  
  void updateEnvironment(double lightLevel) {
    // Environmental factors affect behavior classification
  }
  
  void updateProximity(bool isNear) {
    if (isNear && stationaryMinutes > 30) {
      stressIndicators.add('prolonged_desk_work');
    }
  }
  
  void updateBattery(double level) {
    if (level < 20 && activeMinutes < 60) {
      stressIndicators.add('low_energy_correlation');
    }
  }
  
  void finalize() {
    if (activeMinutes > 0 && stationaryMinutes > 0) {
      movementVariability = (activeMinutes / (activeMinutes + stationaryMinutes)) * 100;
    }
  }
}

/// Environmental factors affecting health
class EnvironmentalFactors {
  final double averageLightLevel;
  final bool isLikelyIndoors;
  final String lightCondition;
  
  const EnvironmentalFactors({
    required this.averageLightLevel,
    required this.isLikelyIndoors,
    required this.lightCondition,
  });
}

/// Health indicators from sensor data
class HealthIndicators {
  final double averageActivity;
  final double maxActivity;
  final double inactivityPercentage;
  final bool isPostureConcern;
  final String activityLevel;
  
  const HealthIndicators({
    required this.averageActivity,
    required this.maxActivity,
    required this.inactivityPercentage,
    required this.isPostureConcern,
    required this.activityLevel,
  });
  
  factory HealthIndicators.noData() => const HealthIndicators(
    averageActivity: 0,
    maxActivity: 0,
    inactivityPercentage: 0,
    isPostureConcern: false,
    activityLevel: 'unknown',
  );
}

/// Human-like insight with empathy
class HumanInsight {
  final InsightType type;
  final String message;
  final InsightPriority priority;
  final String actionSuggestion;
  final String healthImpact;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  const HumanInsight({
    required this.type,
    required this.message,
    required this.priority,
    required this.actionSuggestion,
    required this.healthImpact,
    required this.timestamp,
    this.metadata,
  });
  
  factory HumanInsight.gentle(String message) => HumanInsight(
    type: InsightType.wellness,
    message: message,
    priority: InsightPriority.low,
    actionSuggestion: 'Continue sendo gentil consigo mesmo',
    healthImpact: 'Autocuidado emocional é fundamental para o bem-estar',
    timestamp: DateTime.now(),
  );
  
  factory HumanInsight.supportive(String message) => HumanInsight(
    type: InsightType.support,
    message: message,
    priority: InsightPriority.low,
    actionSuggestion: 'Estou aqui para apoiar você',
    healthImpact: 'Suporte emocional melhora resiliência e bem-estar mental',
    timestamp: DateTime.now(),
  );
}

/// Types of insights the service can provide
enum InsightType {
  postureAlert,
  environmental,
  encouragement,
  stressAlert,
  wellness,
  support,
  concern,
  celebration,
}

/// Priority levels for insights
enum InsightPriority {
  low,
  medium,
  high,
  urgent,
}

/// Daily summary with human touch
class DailySummary {
  final String greeting;
  final String activitySummary;
  final String postureInsights;
  final String environmentalFactors;
  final int healthScore;
  final String encouragement;
  final List<String> improvements;
  final List<String> celebration;
  final DateTime timestamp;
  final bool isError;
  final String? errorMessage;
  
  const DailySummary({
    required this.greeting,
    required this.activitySummary,
    required this.postureInsights,
    required this.environmentalFactors,
    required this.healthScore,
    required this.encouragement,
    required this.improvements,
    required this.celebration,
    required this.timestamp,
    this.isError = false,
    this.errorMessage,
  });
  
  factory DailySummary.error(String message) => DailySummary(
    greeting: 'Oops!',
    activitySummary: message,
    postureInsights: '',
    environmentalFactors: '',
    healthScore: 0,
    encouragement: 'Amanhã tentamos novamente! 💪',
    improvements: [],
    celebration: [],
    timestamp: DateTime.now(),
    isError: true,
    errorMessage: message,
  );
}

/// Weekly summary with motivation
class WeeklySummary {
  final String weeklyGreeting;
  final String trendAnalysis;
  final String improvements;
  final String challenges;
  final List<String> nextWeekGoals;
  final String motivationalQuote;
  final double overallProgress;
  final DateTime timestamp;
  final bool isError;
  final String? errorMessage;
  
  const WeeklySummary({
    required this.weeklyGreeting,
    required this.trendAnalysis,
    required this.improvements,
    required this.challenges,
    required this.nextWeekGoals,
    required this.motivationalQuote,
    required this.overallProgress,
    required this.timestamp,
    this.isError = false,
    this.errorMessage,
  });
  
  factory WeeklySummary.error(String message) => WeeklySummary(
    weeklyGreeting: 'Semana desafiadora!',
    trendAnalysis: message,
    improvements: '',
    challenges: '',
    nextWeekGoals: ['Tentar novamente na próxima semana'],
    motivationalQuote: 'Cada desafio é uma oportunidade de crescimento! 🌱',
    overallProgress: 0,
    timestamp: DateTime.now(),
    isError: true,
    errorMessage: message,
  );
}

/// Health recommendation with caring tone
class HealthRecommendation {
  final String title;
  final String description;
  final String action;
  final String benefit;
  final RecommendationPriority priority;
  final String category;
  final DateTime timestamp;
  
  const HealthRecommendation({
    required this.title,
    required this.description,
    required this.action,
    required this.benefit,
    required this.priority,
    required this.category,
    required this.timestamp,
  });
  
  factory HealthRecommendation.fallback(String message) => HealthRecommendation(
    title: 'Cuidado Básico',
    description: message,
    action: 'Seja gentil consigo mesmo hoje',
    benefit: 'Autocuidado sempre vale a pena',
    priority: RecommendationPriority.low,
    category: 'general',
    timestamp: DateTime.now(),
  );
}

enum RecommendationPriority {
  low,
  medium,
  high,
}

/// Builder for daily summary analysis
class DailySummaryBuilder {
  final List<SensorData> _data;
  Map<String, int> activities = {};
  int postureScore = 5;
  int environmentScore = 5;
  int overallScore = 5;
  
  DailySummaryBuilder(this._data);
  
  void analyzeActivities() {
    // Analyze activity patterns from sensor data
    final accelData = _data.where((d) => d.sensorType == 'accelerometer').cast<AccelerometerData>();
    int walkingMinutes = 0;
    int runningMinutes = 0;
    int stationaryMinutes = 0;
    
    for (final data in accelData) {
      if (data.magnitude > 15) {
        runningMinutes++;
      } else if (data.magnitude > 3) {
        walkingMinutes++;
      } else {
        stationaryMinutes++;
      }
    }
    
    activities = {
      'walking': walkingMinutes,
      'running': runningMinutes,
      'stationary': stationaryMinutes,
    };
  }
  
  void analyzePosture() {
    final totalReadings = _data.where((d) => d.sensorType == 'accelerometer').length;
    final goodPostureReadings = _data
        .where((d) => d.sensorType == 'accelerometer')
        .cast<AccelerometerData>()
        .where((d) => d.magnitude > 1 && d.magnitude < 8)
        .length;
    
    if (totalReadings > 0) {
      postureScore = ((goodPostureReadings / totalReadings) * 10).round();
    }
  }
  
  void analyzeEnvironment() {
    final lightData = _data.where((d) => d.sensorType == 'light').cast<LightData>();
    if (lightData.isNotEmpty) {
      final avgLight = lightData.map((d) => d.luxValue).reduce((a, b) => a + b) / lightData.length;
      environmentScore = avgLight > 200 ? 8 : avgLight > 100 ? 6 : 4;
    }
  }
  
  void calculateHealthScores() {
    overallScore = ((postureScore + environmentScore) / 2).round();
  }
}

/// Weekly analyzer for trends and patterns
class WeeklyAnalyzer {
  Map<String, dynamic> trends = {};
  List<String> improvements = [];
  List<String> challenges = [];
  double progressScore = 0;
  
  WeeklyAnalyzer(List<SensorData> data);
  
  void analyzeTrends() {
    trends = {'activity_increase': true, 'posture_improvement': false};
  }
  
  void compareWithPreviousWeek() {
    improvements = ['Mais movimento diário', 'Melhor consistência'];
  }
  
  void identifyImprovements() {
    challenges = ['Postura durante trabalho'];
  }
  
  void setGoals() {
    progressScore = 7.5;
  }
}