import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/sensor_providers.dart';

class AIInsightsPanel extends ConsumerWidget {
  const AIInsightsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiInsightsState = ref.watch(aiInsightsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.psychology, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (aiInsightsState.isAnalyzing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryColor,
                  ),
                ).animate().fadeIn().scale(),
            ],
          ),

          const SizedBox(height: AppTheme.paddingLG),

          // Current Insight
          if (aiInsightsState.currentInsight != null) ...[
            _buildCurrentInsight(
              context,
              aiInsightsState.currentInsight!,
              isDark,
            ),
            const SizedBox(height: AppTheme.paddingLG),
          ],

          // Recent Insights
          if (aiInsightsState.recentInsights.isNotEmpty) ...[
            Text(
              'Recent Analysis',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppTheme.paddingMD),
            Expanded(
              child: ListView.builder(
                itemCount: aiInsightsState.recentInsights.length,
                itemBuilder: (context, index) {
                  final insight = aiInsightsState.recentInsights[index];
                  return _buildInsightCard(context, insight, isDark, index);
                },
              ),
            ),
          ] else ...[
            Expanded(child: _buildEmptyState(context, isDark)),
          ],

          // Error Display
          if (aiInsightsState.error != null) ...[
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingMD),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.errorColor),
                  const SizedBox(width: AppTheme.paddingSM),
                  Expanded(
                    child: Text(
                      aiInsightsState.error!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentInsight(
    BuildContext context,
    AIInsight insight,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        boxShadow: AppTheme.lightShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Latest Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSM,
                  vertical: AppTheme.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Text(
                  '${(insight.confidence * 100).toInt()}% confident',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          _buildInsightSection(
            'Activity',
            insight.activity,
            Icons.directions_run,
          ),
          const SizedBox(height: AppTheme.paddingSM),
          _buildInsightSection(
            'Environment',
            insight.environment,
            Icons.wb_sunny,
          ),
          const SizedBox(height: AppTheme.paddingSM),
          _buildInsightSection(
            'Device Health',
            insight.deviceHealth,
            Icons.health_and_safety,
          ),
          if (insight.recommendations.isNotEmpty) ...[
            const SizedBox(height: AppTheme.paddingMD),
            const Text(
              'Recommendations:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.paddingXS),
            ...insight.recommendations
                .take(3)
                .map(
                  (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.paddingXS),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: AppTheme.paddingSM),
                        Expanded(
                          child: Text(
                            rec,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildInsightSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: AppTheme.paddingSM),
        Text(
          '$title: ',
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    AIInsight insight,
    bool isDark,
    int index,
  ) {
    return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.paddingSM),
          padding: const EdgeInsets.all(AppTheme.paddingMD),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    insight.activity,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(insight.confidence * 100).toInt()}%',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.paddingXS),
              Text(
                insight.patterns,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 * index))
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .scale(duration: 2000.ms, begin: 0.9, end: 1.1),

          const SizedBox(height: AppTheme.paddingLG),

          Text(
            'AI Analysis Coming Soon',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: AppTheme.paddingSM),

          Text(
            'Start monitoring sensors to generate\nintelligent insights about your activity',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
          ),

          const SizedBox(height: AppTheme.paddingLG),

          ElevatedButton.icon(
            onPressed: () {
              // Trigger manual analysis
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Analyze Current Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0);
  }
}
