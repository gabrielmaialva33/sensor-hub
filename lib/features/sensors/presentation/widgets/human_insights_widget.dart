import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_hub/features/sensors/presentation/providers/sensor_providers.dart';
import 'package:sensor_hub/infrastructure/ai/human_insights_service.dart';

/// Widget that displays human-like AI insights with empathy and care
class HumanInsightsWidget extends ConsumerWidget {
  const HumanInsightsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorHistory = ref.watch(sensorHistoryProvider);
    final allSensorData = sensorHistory.values.expand((list) => list).toList();
    
    if (allSensorData.isEmpty) {
      return const _WaitingForDataCard();
    }

    // Get current behavior and wellness score
    final currentBehavior = ref.watch(currentBehaviorProvider(allSensorData));
    final environment = ref.watch(environmentProvider(allSensorData));
    final wellnessScore = ref.watch(wellnessScoreProvider(allSensorData));
    
    // Get real-time insights
    final insightsAsync = ref.watch(realTimeInsightsProvider(allSensorData));
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.purple.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with wellness score
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Colors.blue.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seu Coach Pessoal de Bem-estar',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pontuação de Bem-estar: $wellnessScore/10',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _WellnessScoreIndicator(score: wellnessScore),
            ],
          ),
          
          const SizedBox(height: 16),
          const Divider(color: Colors.blue),
          const SizedBox(height: 16),
          
          // Current status
          _StatusRow(
            label: 'Atividade atual',
            value: _getActivityDisplayName(currentBehavior),
            icon: _getActivityIcon(currentBehavior),
            color: _getActivityColor(currentBehavior),
          ),
          
          const SizedBox(height: 8),
          
          _StatusRow(
            label: 'Ambiente',
            value: _getEnvironmentDisplayName(environment),
            icon: _getEnvironmentIcon(environment),
            color: _getEnvironmentColor(environment),
          ),
          
          const SizedBox(height: 20),
          
          // AI Insights
          insightsAsync.when(
            data: (insight) => _InsightCard(insight: insight),
            loading: () => const _LoadingInsightCard(),
            error: (error, stack) => _ErrorInsightCard(error: error),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.refresh,
                label: 'Atualizar',
                onPressed: () => ref.invalidate(realTimeInsightsProvider),
              ),
              _ActionButton(
                icon: Icons.trending_up,
                label: 'Resumo Diário',
                onPressed: () => _showDailySummary(context, ref, allSensorData),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDailySummary(BuildContext context, WidgetRef ref, List<dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => DailySummaryDialog(sensorData: data),
    );
  }
}

/// Waiting for data card
class _WaitingForDataCard extends StatelessWidget {
  const _WaitingForDataCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensors,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando dados dos sensores...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Seu coach pessoal estará pronto em instantes! 🌱',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Wellness score indicator
class _WellnessScoreIndicator extends StatelessWidget {
  final int score;
  
  const _WellnessScoreIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 8 ? Colors.green : score >= 6 ? Colors.orange : score >= 4 ? Colors.amber : Colors.red;
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: Text(
          '$score',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
      ),
    );
  }
}

/// Status row widget
class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  
  const _StatusRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Insight card widget
class _InsightCard extends StatelessWidget {
  final HumanInsight insight;
  
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(insight.priority);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.shade200),
        boxShadow: [
          BoxShadow(
            color: priorityColor.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getInsightTypeIcon(insight.type),
                color: priorityColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          
          if (insight.actionSuggestion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.actionSuggestion,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w500,
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

  MaterialColor _getPriorityColor(InsightPriority priority) {
    switch (priority) {
      case InsightPriority.urgent:
        return Colors.red;
      case InsightPriority.high:
        return Colors.orange;
      case InsightPriority.medium:
        return Colors.amber;
      case InsightPriority.low:
        return Colors.green;
    }
  }

  IconData _getInsightTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.postureAlert:
        return Icons.accessibility;
      case InsightType.environmental:
        return Icons.wb_sunny;
      case InsightType.encouragement:
        return Icons.favorite;
      case InsightType.stressAlert:
        return Icons.psychology;
      case InsightType.wellness:
        return Icons.spa;
      case InsightType.support:
        return Icons.support;
      case InsightType.concern:
        return Icons.warning;
      case InsightType.celebration:
        return Icons.celebration;
    }
  }
}

/// Loading insight card
class _LoadingInsightCard extends StatelessWidget {
  const _LoadingInsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 2),
          const SizedBox(width: 16),
          Text(
            'Analisando seus padrões...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error insight card
class _ErrorInsightCard extends StatelessWidget {
  final Object error;
  
  const _ErrorInsightCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Estou com um pequeno problema técnico, mas continuarei cuidando de você! 🤗',
              style: TextStyle(color: Colors.red.shade800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

/// Daily summary dialog
class DailySummaryDialog extends ConsumerWidget {
  final List<dynamic> sensorData;
  
  const DailySummaryDialog({required this.sensorData, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(humanDailySummaryProvider(sensorData.cast()));
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  'Seu Resumo Diário',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            Expanded(
              child: summaryAsync.when(
                data: (summary) => _DailySummaryContent(summary: summary),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    'Erro ao gerar resumo: $error',
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Daily summary content
class _DailySummaryContent extends StatelessWidget {
  final DailySummary summary;
  
  const _DailySummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.greeting,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 16),
          
          _SummarySection(
            title: 'Atividades',
            content: summary.activitySummary,
            icon: Icons.directions_run,
          ),
          
          _SummarySection(
            title: 'Postura & Movimento',
            content: summary.postureInsights,
            icon: Icons.accessibility,
          ),
          
          _SummarySection(
            title: 'Ambiente',
            content: summary.environmentalFactors,
            icon: Icons.wb_sunny,
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'Encorajamento',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary.encouragement,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ],
            ),
          ),
          
          if (summary.improvements.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Sugestões para Amanhã:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            ...summary.improvements.map((improvement) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $improvement'),
            )),
          ],
        ],
      ),
    );
  }
}

/// Summary section widget
class _SummarySection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  
  const _SummarySection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }
}

// Helper functions for display names and colors
String _getActivityDisplayName(String activity) {
  switch (activity) {
    case 'correndo': return 'Correndo 🏃‍♂️';
    case 'caminhando': return 'Caminhando 🚶‍♂️';
    case 'movimento_leve': return 'Movimento Leve 🚶‍♀️';
    case 'parado': return 'Parado 🪑';
    case 'dirigindo': return 'Dirigindo 🚗';
    case 'analisando': return 'Analisando... 🔍';
    default: return 'Aguardando dados... ⏳';
  }
}

IconData _getActivityIcon(String activity) {
  switch (activity) {
    case 'correndo': return Icons.directions_run;
    case 'caminhando': return Icons.directions_walk;
    case 'movimento_leve': return Icons.accessibility;
    case 'parado': return Icons.event_seat;
    case 'dirigindo': return Icons.directions_car;
    default: return Icons.sensors;
  }
}

Color _getActivityColor(String activity) {
  switch (activity) {
    case 'correndo': return Colors.red;
    case 'caminhando': return Colors.green;
    case 'movimento_leve': return Colors.blue;
    case 'parado': return Colors.orange;
    case 'dirigindo': return Colors.purple;
    default: return Colors.grey;
  }
}

String _getEnvironmentDisplayName(String environment) {
  switch (environment) {
    case 'externo_sol': return 'Luz Solar ☀️';
    case 'externo_sombra': return 'Área Externa 🌤️';
    case 'interno_claro': return 'Ambiente Claro 💡';
    case 'interno_escuro': return 'Ambiente Interno 🏠';
    case 'escuro': return 'Escuro 🌙';
    default: return 'Ambiente Desconhecido 🤷‍♂️';
  }
}

IconData _getEnvironmentIcon(String environment) {
  switch (environment) {
    case 'externo_sol': return Icons.wb_sunny;
    case 'externo_sombra': return Icons.cloud;
    case 'interno_claro': return Icons.lightbulb;
    case 'interno_escuro': return Icons.home;
    case 'escuro': return Icons.nights_stay;
    default: return Icons.help_outline;
  }
}

Color _getEnvironmentColor(String environment) {
  switch (environment) {
    case 'externo_sol': return Colors.orange;
    case 'externo_sombra': return Colors.blue;
    case 'interno_claro': return Colors.yellow;
    case 'interno_escuro': return Colors.brown;
    case 'escuro': return Colors.indigo;
    default: return Colors.grey;
  }
}