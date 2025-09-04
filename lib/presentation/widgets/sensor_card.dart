import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../providers/sensor_providers.dart';

class SensorCard extends ConsumerStatefulWidget {
  final String sensorType;
  final bool isMonitoring;

  const SensorCard({
    super.key,
    required this.sensorType,
    required this.isMonitoring,
  });

  @override
  ConsumerState<SensorCard> createState() => _SensorCardState();
}

class _SensorCardState extends ConsumerState<SensorCard> {
  late Stream<dynamic> _sensorStream;
  dynamic _lastValue;
  List<FlSpot> _chartData = [];

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  void _initializeStream() {
    switch (widget.sensorType) {
      case 'accelerometer':
        _sensorStream = ref.read(accelerometerStreamProvider.stream);
        break;
      case 'gyroscope':
        _sensorStream = ref.read(gyroscopeStreamProvider.stream);
        break;
      case 'magnetometer':
        _sensorStream = ref.read(magnetometerStreamProvider.stream);
        break;
      case 'location':
        _sensorStream = ref.read(locationStreamProvider.stream);
        break;
      case 'battery':
        _sensorStream = ref.read(batteryStreamProvider.stream);
        break;
      case 'light':
        _sensorStream = ref.read(lightStreamProvider.stream);
        break;
      case 'proximity':
        _sensorStream = ref.read(proximityStreamProvider.stream);
        break;
      default:
        _sensorStream = const Stream.empty();
    }

    _sensorStream.listen((data) {
      if (mounted) {
        setState(() {
          _lastValue = data;
          _updateChartData(data);
        });
      }
    });
  }

  void _updateChartData(dynamic data) {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    double value = 0.0;

    // Extract meaningful value for chart
    switch (widget.sensorType) {
      case 'accelerometer':
        value = data.magnitude ?? 0.0;
        break;
      case 'battery':
        value = data.batteryLevel?.toDouble() ?? 0.0;
        break;
      case 'light':
        value = data.luxValue ?? 0.0;
        break;
      case 'gyroscope':
        value = (data.x * data.x + data.y * data.y + data.z * data.z).abs();
        break;
      default:
        value = 0.0;
    }

    _chartData.add(FlSpot(now, value));
    if (_chartData.length > 20) {
      _chartData.removeAt(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sensorColor = AppTheme.getSensorColor(widget.sensorType);
    final sensorIcon = AppConstants.sensorIcons[widget.sensorType] ?? '📱';
    final sensorName = AppConstants.sensorDisplayNames[widget.sensorType] ?? widget.sensorType;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: widget.isMonitoring 
              ? sensorColor.withOpacity(0.3) 
              : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
            width: widget.isMonitoring ? 2 : 1,
          ),
          gradient: widget.isMonitoring
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sensorColor.withOpacity(0.05),
                  sensorColor.withOpacity(0.02),
                ],
              )
            : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: sensorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: sensorColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      sensorIcon,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.isMonitoring ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.isMonitoring 
                            ? sensorColor 
                            : AppTheme.mutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isMonitoring ? sensorColor : AppTheme.mutedText,
                    shape: BoxShape.circle,
                  ),
                ).animate(
                  onPlay: (controller) {
                    if (widget.isMonitoring) {
                      controller.repeat();
                    }
                  },
                ).fadeIn(duration: 600.ms).fadeOut(delay: 600.ms, duration: 600.ms),
              ],
            ),

            const SizedBox(height: AppTheme.paddingMD),

            // Current Value Display
            if (_lastValue != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.paddingSM),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Reading',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.mutedText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _buildValueDisplay(),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingSM),
            ],

            // Mini Chart
            if (_chartData.isNotEmpty && widget.isMonitoring) ...[
              SizedBox(
                height: 60,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartData,
                        isCurved: true,
                        color: sensorColor,
                        strokeWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: sensorColor.withOpacity(0.1),
                        ),
                      ),
                    ],
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    lineTouchData: const LineTouchData(enabled: false),
                  ),
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            ] else ...[
              Container(
                height: 60,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.isMonitoring ? 'Waiting for data...' : 'Start monitoring to see chart',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildValueDisplay() {
    if (_lastValue == null) {
      return Text(
        'No data',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppTheme.mutedText,
        ),
      );
    }

    switch (widget.sensorType) {
      case 'accelerometer':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lastValue.magnitude.toStringAsFixed(2)} m/s²',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'X: ${_lastValue.x.toStringAsFixed(2)} Y: ${_lastValue.y.toStringAsFixed(2)} Z: ${_lastValue.z.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        );

      case 'battery':
        return Row(
          children: [
            Text(
              '${_lastValue.batteryLevel}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppTheme.paddingXS),
            Icon(
              _lastValue.isCharging ? Icons.battery_charging_full : Icons.battery_std,
              size: 16,
              color: _getBatteryColor(_lastValue.batteryLevel),
            ),
            const SizedBox(width: AppTheme.paddingXS),
            Text(
              _lastValue.isCharging ? 'Charging' : 'Not charging',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        );

      case 'light':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lastValue.luxValue.toStringAsFixed(1)} lux',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _lastValue.lightCondition,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        );

      case 'proximity':
        return Text(
          _lastValue.isNear ? 'Near' : 'Far',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: _lastValue.isNear ? AppTheme.errorColor : AppTheme.secondaryColor,
          ),
        );

      case 'location':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_lastValue.latitude.toStringAsFixed(4)}, ${_lastValue.longitude.toStringAsFixed(4)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Accuracy: ${_lastValue.accuracy.toStringAsFixed(1)}m',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.mutedText,
              ),
            ),
          ],
        );

      default:
        return Text(
          'Data available',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        );
    }
  }

  Color _getBatteryColor(int level) {
    if (level < 20) return AppTheme.errorColor;
    if (level < 50) return AppTheme.accentColor;
    return AppTheme.secondaryColor;
  }
}