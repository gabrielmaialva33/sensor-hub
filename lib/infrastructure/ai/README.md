# Human Insights AI Service

The Human Insights Service provides empathetic, caring AI analysis of user behavior and health patterns, acting like a personal health coach.

## Features

### 🤖 Real-time Behavior Analysis
- **Activity Classification**: Working, exercising, resting, commuting
- **Posture Analysis**: From accelerometer data patterns
- **Stress Detection**: Through movement pattern analysis
- **Environment Awareness**: Light exposure, indoor/outdoor detection

### 💙 Human-like Insights
- **Empathetic Communication**: Like a caring health professional
- **Contextual Warnings**: Gentle alerts for unusual patterns
- **Encouraging Feedback**: Positive reinforcement for healthy behavior
- **Personalized Recommendations**: Based on individual patterns

### 📊 Summary & Reporting
- **Daily Summaries**: Encouraging overview of activities and health
- **Weekly Reports**: Progress tracking with motivational quotes
- **Health Recommendations**: Evidence-based suggestions with search integration

## Usage

### Basic Setup

```dart
// Initialize the service
final humanInsights = HumanInsightsService();
humanInsights.initialize();

// Get real-time insight
final insight = await humanInsights.generateRealTimeInsight(sensorData);
print(insight.message); // "I noticed you've been sitting for a while. Your spine will thank you for a quick stretch! 🧘‍♀️"
```

### With Riverpod Providers

```dart
// In your widget
class HealthDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorData = ref.watch(sensorHistoryProvider);
    final insights = ref.watch(realTimeInsightsProvider(sensorData.values.expand((list) => list).toList()));
    
    return insights.when(
      data: (insight) => Text(insight.message),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('Coach temporariamente indisponível'),
    );
  }
}
```

## Available Providers

### Core Providers
- `humanInsightsServiceProvider`: Service instance
- `realTimeInsightsProvider`: Real-time behavior insights
- `unusualPatternProvider`: Detect anomalies
- `humanDailySummaryProvider`: Daily summary with encouragement
- `humanWeeklySummaryProvider`: Weekly progress report
- `healthRecommendationsProvider`: Personalized health suggestions

### Classification Providers
- `currentBehaviorProvider`: Activity classification (walking, sitting, driving, etc.)
- `environmentProvider`: Environment detection (indoor/outdoor, light levels)
- `wellnessScoreProvider`: Overall wellness score (0-10)

### UI Management
- `insightDisplayProvider`: Controls when and how insights are shown

## Example Insights

### Posture Alerts
> "I noticed you've been sitting for 45 minutes. Your spine will thank you for a quick stretch! 🧘‍♀️"

### Activity Encouragement
> "Great job staying active today! You've moved 20% more than yesterday. 🎉"

### Environmental Awareness
> "The low light levels suggest you might benefit from some natural sunlight. ☀️"

### Stress Detection
> "Your movement patterns indicate you might be feeling stressed. How about a breathing exercise? 🧘‍♂️"

## Daily Summary Example

```
Que dia interessante você teve!

**Atividades**: Você passou 120 minutos em movimento, sendo "caminhando" sua atividade principal (80 min). Que legal! 🎯

**Postura & Movimento**: Boa postura na maior parte do tempo - continue assim! 💪

**Ambiente**: Bom ambiente na maior parte do tempo. 👍

**Encorajamento**: Bom dia de cuidados com a saúde. Continue assim! 💚

**Sugestões para Amanhã**:
• Configure lembretes para alongar a cada hora
• Busque mais luz natural durante o dia
```

## Integration with Existing Services

The Human Insights Service seamlessly integrates with:
- **NVIDIA AI Service**: For advanced pattern analysis
- **Sensor Service**: For real-time data streams
- **All existing sensor types**: Accelerometer, GPS, light, battery, etc.

## Widget Usage

Use the `HumanInsightsWidget` for a complete UI experience:

```dart
// Add to your home screen or dashboard
HumanInsightsWidget()
```

This widget provides:
- Real-time wellness score
- Current activity and environment status
- AI-generated insights with action suggestions
- Daily summary dialog
- Refresh and summary buttons

## Architecture

```
HumanInsightsService
├── Real-time Analysis
│   ├── BehaviorPattern detection
│   ├── EnvironmentalFactors analysis
│   └── HealthIndicators calculation
├── Insight Generation
│   ├── Contextual message creation
│   ├── Priority assessment
│   └── Action suggestions
└── Summary Creation
    ├── Daily progress reports
    ├── Weekly trend analysis
    └── Goal setting
```

## Human-Centered Design Principles

1. **Empathy First**: All messages are crafted with care and understanding
2. **Encouraging Tone**: Focus on positive reinforcement rather than criticism
3. **Actionable Advice**: Every insight includes specific, doable suggestions
4. **Contextual Awareness**: Insights adapt to user's current situation
5. **Privacy Focused**: All analysis happens locally, respecting user privacy

This service transforms cold sensor data into warm, human insights that genuinely care about user wellbeing. 💚