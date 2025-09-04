import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sensor_hub/core/core.dart' hide Prediction;
import 'package:sensor_hub/features/sensors/data/models/sensor_data.dart';
import 'package:sensor_hub/infrastructure/infrastructure.dart';
import '../providers/sensor_providers.dart';

class AIInsightsPanel extends ConsumerStatefulWidget {
  const AIInsightsPanel({super.key});

  @override
  ConsumerState<AIInsightsPanel> createState() => _AIInsightsPanelState();
}

class _AIInsightsPanelState extends ConsumerState<AIInsightsPanel> {
  bool _isAnalyzing = false;
  AIInsight? _currentInsight;
  Prediction? _currentPrediction;
  ActivitySummary? _activitySummary;

  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final sensorHistory = ref.watch(sensorHistoryProvider);
    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(context, isDark),
            const SizedBox(height: AppTheme.paddingLG),
            // Quick Stats
            _buildQuickStats(context, isDark, sensorHistory),
            // AI Analysis Section
            _buildAIAnalysisSection(context, isDark),
            // Predictions Section
            _buildPredictionsSection(context, isDark),
            // Activity Summary
            _buildActivitySummarySection(context, isDark),
            // Recommendations
            _buildRecommendationsSection(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🤖 Insights de IA',
          style: Theme
              .of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingXS),
        'Desenvolvido com NVIDIA AI',
        style: Theme
            .of(
          context,
        )
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppTheme.mutedText),
      ],
    ),
    ElevatedButton.icon(
    onPressed: _isAnalyzing ? null : () => _performAnalysis(),
    icon: _isAnalyzing
    ? const SizedBox(
    width: 16,
    height: 16,
    child: CircularProgressIndicator(strokeWidth: 2),
    )
        : const Icon(Icons.psychology),
    label: Text(_isAnalyzing ? 'Analisando...' : 'Analisar Agora'),
    style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    ],
    Widget _buildQuickStats(
    BuildContext context,
    bool isDark,
    Map<String, List<SensorData>> sensorHistory,
    ) {
    final totalDataPoints = sensorHistory.values.fold(
    0,
    (sum, list) => sum + list.length,
    final activeSensors = sensorHistory.values
        .where((list) => list.isNotEmpty)
        .length;
    child: _buildStatCard(
    context,
    isDark,
    '📊',
    'Pontos de Dados',
    totalDataPoints.toString(),
    AppTheme.primaryColor,
    const SizedBox(width: AppTheme.paddingMD),
    '📡',
    'Sensores Ativos',
    '$activeSensors/7',
    AppTheme.secondaryColor,
    '⚡',
    'Status da IA',
    _currentInsight != null ? 'Pronto' : 'Inativo',
    _currentInsight != null
    ? AppTheme.successColor
        : AppTheme.warningColor,
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0);
    Widget _buildStatCard(
    String icon,
    String label,
    String value,
    Color color,
    padding: const EdgeInsets.all(AppTheme.paddingMD),
    decoration: BoxDecoration(
    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    child: Column(
    children: [
    Text(icon, style: const TextStyle(fontSize: 24)),
    const SizedBox(height: AppTheme.paddingXS),
    Text(
    label,
    style: Theme.of(
    context,
    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
    value,
    style: Theme.of(context).textTheme.titleLarge?.copyWith(
    fontWeight: FontWeight.bold,
    color: color,
    ),
    ],
    Widget _buildAIAnalysisSection(BuildContext context, bool isDark) {
    if (_currentInsight == null) {
    return _buildEmptyState(
    context,
    isDark,
    'Nenhuma Análise Ainda',
    'Toque em "Analisar Agora" para obter insights de IA dos seus dados de sensores',
    Icons.analytics_outlined,
    );
    }
    if (_currentInsight!.isError) {
    return _buildErrorState(
    'Erro de Análise',
    _currentInsight!.errorMessage ?? 'Failed to analyze data',
    padding: const EdgeInsets.all(AppTheme.paddingLG),
    decoration: BoxDecoration(
    gradient: LinearGradient(
    colors: isDark
    ? [
    AppTheme.primaryColor.withValues(alpha: 0.1),
    AppTheme.secondaryColor.withValues(alpha: 0.05),
    ]
        : [
    AppTheme.primaryColor.withValues(alpha: 0.05),
    AppTheme.secondaryColor.withValues(alpha: 0.02),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
    border: Border.all(
    color: AppTheme.primaryColor.withValues(alpha: 0.2),
    width: 1,
    Row(
    children: [
    const Icon(Icons.insights, color: AppTheme.primaryColor),
    const SizedBox(width: AppTheme.paddingSM),
    Text(
    'Análise Atual',
    style: Theme.of(context).textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.bold,
    ),
    ),
    const Spacer(),
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: AppTheme.paddingSM,
    vertical: AppTheme.paddingXS,
    decoration: BoxDecoration(
    color: AppTheme.successColor.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
    child: Text(
    '${(_currentInsight!.confidence * 100).toInt()}% Confiança',
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: AppTheme.successColor,
    fontWeight: FontWeight.w600,
    ),
    ],
    const SizedBox(height: AppTheme.paddingMD),
    _buildInsightRow(
    'Atividade',
    _currentInsight!.activity,
    Icons.directions_walk,
    'Ambiente',
    _currentInsight!.environment,
    Icons.wb_sunny,
    'Saúde do Dispositivo',
    _currentInsight!.deviceHealth,
    Icons.phone_android,
    const Divider(height: AppTheme.paddingLG),
    'Padrões Detectados',
    ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    const SizedBox(height: AppTheme.paddingSM),
    _currentInsight!.patterns,
    style: Theme.of(context).textTheme.bodyMedium,
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    Widget _buildPredictionsSection(BuildContext context, bool isDark) {
    if (_currentPrediction == null) {
    return const SizedBox.shrink();
    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    const Icon(Icons.timeline, color: AppTheme.secondaryColor),
    'Previsões',
    _buildPredictionCard(
    'Próxima Atividade',
    _currentPrediction!.nextActivity,
    Icons.next_plan,
    'Previsão da Bateria',
    _currentPrediction!.batteryPrediction,
    Icons.battery_full,
    'Padrão de Movimento',
    _currentPrediction!.movementForecast,
    Icons.pattern,
    _currentPrediction!.environmentalChanges,
    Icons.cloud,
        .fadeIn(delay: 200.ms, duration: 600.ms)
        .slideX(begin: 0.1, end: 0);
    Widget _buildActivitySummarySection(BuildContext context, bool isDark) {
    if (_activitySummary == null) {
    const Icon(Icons.assessment, color: AppTheme.warningColor),
    'Resumo de Atividades',
    padding: const EdgeInsets.all(AppTheme.paddingSM),
    gradient: const LinearGradient(
    colors: [
    AppTheme.primaryColor,
    AppTheme.secondaryColor,
    ],
    shape: BoxShape.circle,
    '${_activitySummary!.score}',
    style: const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    // Activity breakdown
    if (_activitySummary!.activities.isNotEmpty)
    ...(_activitySummary!.activities.entries.map(
    (entry) => _buildActivityBar(context, entry.key, entry.value),
    )),
    Expanded(
    child: _buildSummaryDetail(
    'Movimento',
    _activitySummary!.movement,
    Icons.directions_run,
    'Ambiente',
    _activitySummary!.environment,
    Icons.location_on,
    _buildSummaryDetail(
    'Status de Saúde',
    _activitySummary!.health,
    Icons.favorite,
        .fadeIn(delay: 400.ms, duration: 600.ms)
        .slideY(begin: 0.1, end: 0);
    Widget _buildRecommendationsSection(BuildContext context, bool isDark) {
    final recommendations = <String>[];
    if (_currentInsight != null &&
    _currentInsight!.recommendations.isNotEmpty) {
    recommendations.addAll(_currentInsight!.recommendations);
    if (_currentPrediction != null &&
    _currentPrediction!.recommendations.isNotEmpty) {
    recommendations.addAll(_currentPrediction!.recommendations);
    if (_activitySummary != null &&
    _activitySummary!.recommendations.isNotEmpty) {
    recommendations.addAll(_activitySummary!.recommendations);
    if (recommendations.isEmpty) {
    AppTheme.successColor.withValues(alpha: 0.1),
    AppTheme.successColor.withValues(alpha: 0.05),
    AppTheme.successColor.withValues(alpha: 0.02),
    color: AppTheme.successColor.withValues(alpha: 0.2),
    const Icon(Icons.lightbulb, color: AppTheme.successColor),
    'Recomendações',
    ...recommendations.toSet().map(
    (recommendation) => Padding(
    padding: const EdgeInsets.only(bottom: AppTheme.paddingSM),
    child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.only(top: 6),
    decoration: const BoxDecoration(
    color: AppTheme.successColor,
    shape: BoxShape.circle,
    ),
    const SizedBox(width: AppTheme.paddingSM),
    Expanded(
    child: Text(
    recommendation,
    style: Theme.of(context).textTheme.bodyMedium,
        .fadeIn(delay: 600.ms, duration: 600.ms)
    Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingXS),
    child: Row(
    Icon(icon, size: 16, color: AppTheme.mutedText),
    const SizedBox(width: AppTheme.paddingSM),
    '$label:',
    style: TextStyle(
    color: AppTheme.mutedText,
    fontWeight: FontWeight.w500,
    Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
    Widget _buildPredictionCard(String label, String value, IconData icon) {
    margin: const EdgeInsets.only(bottom: AppTheme.paddingSM),
    padding: const EdgeInsets.all(AppTheme.paddingSM),
    color: AppTheme.secondaryColor.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
    Icon(icon, size: 18, color: AppTheme.secondaryColor),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(
    label,
    style: TextStyle(fontSize: 12, color: AppTheme.mutedText),
    value,
    style: const TextStyle(fontWeight: FontWeight.w600),
    ],
    Widget _buildActivityBar(
    String activity,
    int percentage,
    crossAxisAlignment: CrossAxisAlignment.start,
    Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    Text(activity),
    '$percentage%',
    style: const TextStyle(fontWeight: FontWeight.bold),
    ClipRRect(
    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
    child: LinearProgressIndicator(
    value: percentage / 100,
    minHeight: 6,
    backgroundColor: AppTheme.warningColor.withValues(alpha: 0.2),
    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
    Widget _buildSummaryDetail(String label, String value, IconData icon) {
    color: Theme.of(context).brightness == Brightness.dark
    ? AppTheme.darkBackground
        : AppTheme.lightBackground,
    const SizedBox(width: AppTheme.paddingXS),
    style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
    style: const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    Widget _buildEmptyState(
    String title,
    String message,
    IconData icon,
    padding: const EdgeInsets.all(AppTheme.paddingXL),
    borderRadius: BorderRadius.circular(AppTheme.radiusLG),
    border: Border.all(
    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
    width: 1,
    mainAxisAlignment: MainAxisAlignment.center,
    Icon(
    icon,
    size: 64,
    color: AppTheme.mutedText.withValues(alpha: 0.3),
    const SizedBox(height: AppTheme.paddingMD),
    title,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    const SizedBox(height: AppTheme.paddingSM),
    message,
    textAlign: TextAlign.center,
    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
    Widget _buildErrorState(
    padding: const EdgeInsets.all(AppTheme.paddingLG),
    color: AppTheme.errorColor.withValues(alpha: 0.1),
    color: AppTheme.errorColor.withValues(alpha: 0.3),
    const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 32),
    const SizedBox(width: AppTheme.paddingMD),
    title,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.bold,
    color: AppTheme.errorColor,
    const SizedBox(height: AppTheme.paddingXS),
    message,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
    color: AppTheme.errorColor.withValues(alpha: 0.8),
    Future<void> _performAnalysis() async {
    setState(() {
    _isAnalyzing = true;
    });
    try {
    final sensorHistory = ref.read(sensorHistoryProvider);
    final allData = <SensorData>[];
    // Collect all sensor data
    sensorHistory.forEach((type, dataList) {
    allData.addAll(dataList);
    });
    if (allData.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
    content: Text('Nenhum dado de sensor disponível para análise'),
    backgroundColor: AppTheme.warningColor,
    );
    setState(() {
    _isAnalyzing = false;
    });
    return;
    }
    final aiService = ref.read(nvidiaAiServiceProvider);
    // Perform all analyses in parallel
    final results = await Future.wait([
    aiService.analyzeSensorData(allData),
    aiService.predictSensorPatterns(allData),
    aiService.generateActivitySummary(allData),
    ]);
    setState(() {
    _currentInsight = results[0] as AIInsight;
    _currentPrediction = results[1] as Prediction;
    _activitySummary = results[2] as ActivitySummary;
    _isAnalyzing = false;
    if (mounted) {
    content: Text('Análise de IA concluída com sucesso!'),
    backgroundColor: AppTheme.successColor,
    } catch (e) {
    SnackBar(
    content: Text('Análise falhou: ${e.toString()}'),
    backgroundColor: AppTheme
    .
    errorColor
    ,
