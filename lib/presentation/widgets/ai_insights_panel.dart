import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/sensor_data.dart';
import '../../data/services/nvidia_ai_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            
            const SizedBox(height: AppTheme.paddingLG),
            
            // AI Analysis Section
            _buildAIAnalysisSection(context, isDark),
            
            const SizedBox(height: AppTheme.paddingLG),
            
            // Predictions Section
            _buildPredictionsSection(context, isDark),
            
            const SizedBox(height: AppTheme.paddingLG),
            
            // Activity Summary
            _buildActivitySummarySection(context, isDark),
            
            const SizedBox(height: AppTheme.paddingLG),
            
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🤖 AI Insights',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingXS),
            Text(
              'Powered by NVIDIA AI',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
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
          label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, bool isDark, Map<String, List<SensorData>> sensorHistory) {
    final totalDataPoints = sensorHistory.values.fold(0, (sum, list) => sum + list.length);
    final activeSensors = sensorHistory.values.where((list) => list.isNotEmpty).length;
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            isDark,
            '📊',
            'Data Points',
            totalDataPoints.toString(),
            AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.paddingMD),
        Expanded(
          child: _buildStatCard(
            context,
            isDark,
            '📡',
            'Active Sensors',
            '$activeSensors/7',
            AppTheme.secondaryColor,
          ),
        ),
        const SizedBox(width: AppTheme.paddingMD),
        Expanded(
          child: _buildStatCard(
            context,
            isDark,
            '⚡',
            'AI Status',
            _currentInsight != null ? 'Ready' : 'Idle',
            _currentInsight != null ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: 500.ms)
      .slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(BuildContext context, bool isDark, String icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: AppTheme.paddingXS),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: AppTheme.paddingXS),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(BuildContext context, bool isDark) {
    if (_currentInsight == null) {
      return _buildEmptyState(
        context,
        isDark,
        'No Analysis Yet',
        'Tap "Analyze Now" to get AI insights from your sensor data',
        Icons.analytics_outlined,
      );
    }

    if (_currentInsight!.isError) {
      return _buildErrorState(
        context,
        isDark,
        'Analysis Error',
        _currentInsight!.errorMessage ?? 'Failed to analyze data',
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.05)]
            : [AppTheme.primaryColor.withOpacity(0.05), AppTheme.secondaryColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Current Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSM,
                  vertical: AppTheme.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  '${(_currentInsight!.confidence * 100).toInt()}% Confidence',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          _buildInsightRow('Activity', _currentInsight!.activity, Icons.directions_walk),
          _buildInsightRow('Environment', _currentInsight!.environment, Icons.wb_sunny),
          _buildInsightRow('Device Health', _currentInsight!.deviceHealth, Icons.phone_android),
          const Divider(height: AppTheme.paddingLG),
          Text(
            'Patterns Detected',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
          Text(
            _currentInsight!.patterns,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 600.ms)
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildPredictionsSection(BuildContext context, bool isDark) {
    if (_currentPrediction == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.secondaryColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Predictions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          _buildPredictionCard('Next Activity', _currentPrediction!.nextActivity, Icons.next_plan),
          _buildPredictionCard('Battery Forecast', _currentPrediction!.batteryPrediction, Icons.battery_full),
          _buildPredictionCard('Movement Pattern', _currentPrediction!.movementForecast, Icons.pattern),
          _buildPredictionCard('Environment', _currentPrediction!.environmentalChanges, Icons.cloud),
        ],
      ),
    ).animate()
      .fadeIn(delay: 200.ms, duration: 600.ms)
      .slideX(begin: 0.1, end: 0);
  }

  Widget _buildActivitySummarySection(BuildContext context, bool isDark) {
    if (_activitySummary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assessment, color: AppTheme.warningColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Activity Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSM),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_activitySummary!.score}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          // Activity breakdown
          if (_activitySummary!.activities.isNotEmpty)
            ...(_activitySummary!.activities.entries.map((entry) => 
              _buildActivityBar(context, entry.key, entry.value))),
          const SizedBox(height: AppTheme.paddingMD),
          Row(
            children: [
              Expanded(
                child: _buildSummaryDetail('Movement', _activitySummary!.movement, Icons.directions_run),
              ),
              const SizedBox(width: AppTheme.paddingSM),
              Expanded(
                child: _buildSummaryDetail('Environment', _activitySummary!.environment, Icons.location_on),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSM),
          _buildSummaryDetail('Health Status', _activitySummary!.health, Icons.favorite),
        ],
      ),
    ).animate()
      .fadeIn(delay: 400.ms, duration: 600.ms)
      .slideY(begin: 0.1, end: 0);
  }

  Widget _buildRecommendationsSection(BuildContext context, bool isDark) {
    final recommendations = <String>[];
    
    if (_currentInsight != null && _currentInsight!.recommendations.isNotEmpty) {
      recommendations.addAll(_currentInsight!.recommendations);
    }
    if (_currentPrediction != null && _currentPrediction!.recommendations.isNotEmpty) {
      recommendations.addAll(_currentPrediction!.recommendations);
    }
    if (_activitySummary != null && _activitySummary!.recommendations.isNotEmpty) {
      recommendations.addAll(_activitySummary!.recommendations);
    }

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
            ? [AppTheme.successColor.withOpacity(0.1), AppTheme.successColor.withOpacity(0.05)]
            : [AppTheme.successColor.withOpacity(0.05), AppTheme.successColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppTheme.successColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppTheme.successColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Recommendations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          ...recommendations.toSet().map((recommendation) => Padding(
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
                ),
                const SizedBox(width: AppTheme.paddingSM),
                Expanded(
                  child: Text(
                    recommendation,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate()
      .fadeIn(delay: 600.ms, duration: 600.ms)
      .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildInsightRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingXS),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedText),
          const SizedBox(width: AppTheme.paddingSM),
          Text(
            '$label:',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.paddingSM),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSM),
      padding: const EdgeInsets.all(AppTheme.paddingSM),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.secondaryColor),
          const SizedBox(width: AppTheme.paddingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar(BuildContext context, String activity, int percentage) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(activity),
              Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: AppTheme.paddingXS),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSM),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: AppTheme.warningColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSM),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? AppTheme.darkBackground 
          : AppTheme.lightBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedText),
          const SizedBox(width: AppTheme.paddingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, String title, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingXL),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.mutedText.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.paddingMD),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark, String title, String message) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorColor,
            size: 32,
          ),
          const SizedBox(width: AppTheme.paddingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingXS),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.errorColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            content: Text('No sensor data available for analysis'),
            backgroundColor: AppTheme.warningColor,
          ),
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
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI analysis completed successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analysis failed: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}