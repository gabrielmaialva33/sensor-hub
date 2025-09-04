import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

class SensorTimeline extends ConsumerStatefulWidget {
  const SensorTimeline({super.key});

  @override
  ConsumerState<SensorTimeline> createState() => _SensorTimelineState();
}

class _SensorTimelineState extends ConsumerState<SensorTimeline> {
  final List<TimelineEvent> _mockEvents = [
    TimelineEvent(
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      title: 'High Activity Detected',
      description: 'Accelerometer shows running pattern',
      type: 'activity',
      icon: Icons.directions_run,
    ),
    TimelineEvent(
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      title: 'Location Changed',
      description: 'Moved from indoor to outdoor environment',
      type: 'location',
      icon: Icons.location_on,
    ),
    TimelineEvent(
      time: DateTime.now().subtract(const Duration(minutes: 8)),
      title: 'Battery Optimization',
      description: 'Device entered power saving mode',
      type: 'system',
      icon: Icons.battery_saver,
    ),
    TimelineEvent(
      time: DateTime.now().subtract(const Duration(minutes: 12)),
      title: 'Light Level Change',
      description: 'Environment brightness increased significantly',
      type: 'environment',
      icon: Icons.wb_sunny,
    ),
    TimelineEvent(
      time: DateTime.now().subtract(const Duration(minutes: 18)),
      title: 'Movement Pattern',
      description: 'Walking detected for 10 minutes',
      type: 'activity',
      icon: Icons.directions_walk,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.timeline, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Activity Timeline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _clearTimeline,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.paddingLG),

          // Timeline
          Expanded(
            child: _mockEvents.isEmpty 
              ? _buildEmptyTimeline(context, isDark)
              : ListView.builder(
                  itemCount: _mockEvents.length,
                  itemBuilder: (context, index) {
                    return _buildTimelineItem(
                      context,
                      _mockEvents[index],
                      isDark,
                      index,
                      index == _mockEvents.length - 1,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    TimelineEvent event,
    bool isDark,
    int index,
    bool isLast,
  ) {
    final eventColor = _getEventColor(event.type);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: eventColor.withOpacity(0.1),
                border: Border.all(color: eventColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                event.icon,
                size: 16,
                color: eventColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDark 
                  ? AppTheme.darkBorder 
                  : AppTheme.lightBorder,
              ),
          ],
        ),

        const SizedBox(width: AppTheme.paddingMD),

        // Event content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.paddingMD),
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
                      event.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingXS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                        border: Border.all(
                          color: eventColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        event.type,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: eventColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.paddingXS),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingXS),
                Text(
                  _formatTime(event.time),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 * index))
      .slideX(begin: 0.3, end: 0);
  }

  Widget _buildEmptyTimeline(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.mutedText.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.mutedText.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.timeline,
              size: 40,
              color: AppTheme.mutedText,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLG),
          
          Text(
            'No Activity Yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedText,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSM),
          
          Text(
            'Start monitoring sensors to see your\nactivity timeline appear here',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    ).animate()
      .fadeIn(delay: 300.ms)
      .scale(begin: 0.8, end: 1.0);
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'activity':
        return AppTheme.getSensorColor('accelerometer');
      case 'location':
        return AppTheme.getSensorColor('location');
      case 'system':
        return AppTheme.getSensorColor('battery');
      case 'environment':
        return AppTheme.getSensorColor('light');
      default:
        return AppTheme.primaryColor;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _clearTimeline() {
    setState(() {
      _mockEvents.clear();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Timeline cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class TimelineEvent {
  final DateTime time;
  final String title;
  final String description;
  final String type;
  final IconData icon;

  TimelineEvent({
    required this.time,
    required this.title,
    required this.description,
    required this.type,
    required this.icon,
  });
}