import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../infrastructure/ai/life_narrative_service.dart';
import '../../../../infrastructure/ai/predictive_insights_engine.dart';

class LifeStoryWidget extends StatefulWidget {
  const LifeStoryWidget({Key? key}) : super(key: key);

  @override
  State<LifeStoryWidget> createState() => _LifeStoryWidgetState();
}

class _LifeStoryWidgetState extends State<LifeStoryWidget>
    with TickerProviderStateMixin {
  final LifeNarrativeService _narrativeService = LifeNarrativeService();
  final PredictiveInsightsEngine _predictiveEngine = PredictiveInsightsEngine();
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  StreamSubscription<String>? _narrativeSubscription;
  StreamSubscription<Prediction>? _predictionSubscription;
  StreamSubscription<LifeEvent>? _eventSubscription;

  List<String> _dailyNarratives = [];
  List<String> _weeklyInsights = [];
  List<String> _proactiveSuggestions = [];
  List<Prediction> _predictions = [];
  List<LifeEvent> _lifeMemories = [];
  
  bool _isLoading = true;
  int _currentNarrativeIndex = 0;
  Timer? _narrativeTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToStreams();
    _loadLifeInsights();
    _startNarrativeRotation();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _subscribeToStreams() {
    _narrativeSubscription = _narrativeService.narrativeStream.listen((narrative) {
      setState(() {
        if (!_dailyNarratives.contains(narrative)) {
          _dailyNarratives.add(narrative);
        }
      });
    });

    _predictionSubscription = _predictiveEngine.predictionStream.listen((prediction) {
      setState(() {
        _predictions.add(prediction);
        // Add to proactive suggestions if it's actionable
        if (prediction.actionable_suggestions.isNotEmpty && 
            !_proactiveSuggestions.contains(prediction.description)) {
          _proactiveSuggestions.add(prediction.description);
        }
      });
    });

    _eventSubscription = _narrativeService.lifeEventStream.listen((event) {
      setState(() {
        _lifeMemories.add(event);
      });
    });
  }

  Future<void> _loadLifeInsights() async {
    try {
      final dailyNarratives = await _narrativeService.generateDailyNarratives();
      final weeklyInsights = await _narrativeService.generateWeeklyInsights();
      final proactiveSuggestions = await _narrativeService.generateProactiveSuggestions();
      final lifeMemories = _narrativeService.getLifeMemories(limit: 5);

      setState(() {
        _dailyNarratives = dailyNarratives;
        _weeklyInsights = weeklyInsights;
        _proactiveSuggestions = proactiveSuggestions;
        _lifeMemories = lifeMemories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading life insights: $e');
    }
  }

  void _startNarrativeRotation() {
    _narrativeTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_dailyNarratives.isNotEmpty) {
        setState(() {
          _currentNarrativeIndex = (_currentNarrativeIndex + 1) % _dailyNarratives.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _narrativeSubscription?.cancel();
    _predictionSubscription?.cancel();
    _eventSubscription?.cancel();
    _narrativeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withOpacity(0.1),
                      theme.colorScheme.secondaryContainer.withOpacity(0.1),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    if (_isLoading)
                      _buildLoadingState()
                    else
                      Expanded(
                        child: _buildContent(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_stories,
              color: Colors.deepPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vida Sentida',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Text(
                  'Your felt life insights',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Reading your life patterns...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMainNarrative(),
          const SizedBox(height: 16),
          _buildInsightsTabs(),
        ],
      ),
    );
  }

  Widget _buildMainNarrative() {
    if (_dailyNarratives.isEmpty) {
      return _buildEmptyState();
    }

    final currentNarrative = _dailyNarratives[_currentNarrativeIndex];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite,
                color: Colors.pink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Today\'s Story',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const Spacer(),
              if (_dailyNarratives.length > 1)
                Row(
                  children: List.generate(
                    _dailyNarratives.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentNarrativeIndex
                            ? Colors.deepPurple
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              currentNarrative,
              key: ValueKey(currentNarrative),
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTabs() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const TabBar(
              indicator: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Insights'),
                Tab(text: 'Predictions'),
                Tab(text: 'Memories'),
                Tab(text: 'Suggestions'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 400,
            child: TabBarView(
              children: [
                _buildWeeklyInsights(),
                _buildPredictions(),
                _buildLifeMemories(),
                _buildProactiveSuggestions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyInsights() {
    if (_weeklyInsights.isEmpty) {
      return _buildEmptyTabState('Weekly insights will appear here as patterns emerge.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _weeklyInsights.length,
      itemBuilder: (context, index) {
        return _buildInsightCard(
          icon: Icons.trending_up,
          title: 'Weekly Pattern',
          content: _weeklyInsights[index],
          color: Colors.green,
        );
      },
    );
  }

  Widget _buildPredictions() {
    final activePredictions = _predictions
        .where((p) => p.validUntil.isAfter(DateTime.now()))
        .toList();

    if (activePredictions.isEmpty) {
      return _buildEmptyTabState('Predictions will appear based on your patterns.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: activePredictions.length,
      itemBuilder: (context, index) {
        final prediction = activePredictions[index];
        return _buildPredictionCard(prediction);
      },
    );
  }

  Widget _buildLifeMemories() {
    if (_lifeMemories.isEmpty) {
      return _buildEmptyTabState('Significant moments will be captured here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _lifeMemories.length,
      itemBuilder: (context, index) {
        final memory = _lifeMemories[index];
        return _buildMemoryCard(memory);
      },
    );
  }

  Widget _buildProactiveSuggestions() {
    if (_proactiveSuggestions.isEmpty) {
      return _buildEmptyTabState('Personalized suggestions will appear here.');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _proactiveSuggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionCard(_proactiveSuggestions[index], index);
      },
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.left(
          width: 4,
          color: color,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(Prediction prediction) {
    IconData icon;
    Color color;

    switch (prediction.type) {
      case 'energy_prediction':
        icon = Icons.battery_charging_full;
        color = Colors.orange;
        break;
      case 'stress_risk':
        icon = Icons.psychology;
        color = Colors.red;
        break;
      case 'timing_optimization':
        icon = Icons.schedule;
        color = Colors.blue;
        break;
      case 'health_trend':
        icon = Icons.favorite;
        color = Colors.pink;
        break;
      default:
        icon = Icons.lightbulb;
        color = Colors.amber;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          prediction.title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              prediction.description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.stars,
                  size: 12,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${(prediction.confidence * 100).round()}% confidence',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (prediction.actionable_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Suggestions:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...prediction.actionable_suggestions.map(
                    (suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.arrow_right,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoryCard(LifeEvent memory) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.memory,
                  size: 16,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memory.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _formatMemoryDate(memory.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSignificanceColor(memory.significance),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(memory.significance * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            memory.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String suggestion, int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showSuggestionDetail(suggestion);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.left(
              width: 4,
              color: color,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your Story is Beginning',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep using the app to generate your personalized life insights',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.hourglass_empty,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestionDetail(String suggestion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Life Suggestion'),
        content: Text(suggestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatMemoryDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).round();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference / 30).round();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  Color _getSignificanceColor(double significance) {
    if (significance >= 0.8) return Colors.red;
    if (significance >= 0.6) return Colors.orange;
    if (significance >= 0.4) return Colors.blue;
    return Colors.grey;
  }
}