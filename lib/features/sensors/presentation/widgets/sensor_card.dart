import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_hub/core/core.dart';

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
  final List<FlSpot> _chartData = [];
  int _dataCounter = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sensorName =
        AppConstants.sensorDisplayNames[widget.sensorType] ?? widget.sensorType;
    final sensorIcon = AppConstants.sensorIcons[widget.sensorType] ?? Icons.sensors;
    final sensorColor = AppTheme.getSensorColor(widget.sensorType);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Professional Header
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingLG),
            child: Row(
              children: [
                // Modern Icon Design
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: sensorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: sensorColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    sensorIcon,
                    color: sensorColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingMD),
                // Title and Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sensorName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: widget.isMonitoring
                                  ? AppTheme.successColor
                                  : AppTheme.mutedText,
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(
                            onPlay: (controller) =>
                                widget.isMonitoring ? controller.repeat() : null,
                          )
                          .scale(
                            duration: 2.seconds,
                            begin: const Offset(1, 1),
                            end: const Offset(1.3, 1.3),
                          )
                          .then()
                          .scale(
                            begin: const Offset(1.3, 1.3),
                            end: const Offset(1, 1),
                          ),
                          const SizedBox(width: AppTheme.paddingSM),
                          Text(
                            widget.isMonitoring ? 'Ativo' : 'Inativo',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.isMonitoring
                                  ? AppTheme.successColor
                                  : AppTheme.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Minimal Actions
                if (widget.isMonitoring)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingSM,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sensorColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LIVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: sensorColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Divider
          if (widget.isMonitoring)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLG),
              height: 1,
              color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder)
                  .withValues(alpha: 0.5),
            ),
          // Content
          if (widget.isMonitoring) ...[
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: _buildSensorContent(),
            ),
            // Mini Chart
            if (_chartData.isNotEmpty)
              Container(
                height: 80,
                margin: const EdgeInsets.fromLTRB(
                  AppTheme.paddingLG, 0, AppTheme.paddingLG, AppTheme.paddingLG),
                child: _buildMiniChart(sensorColor),
              ),
          ] else
            // Empty State
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: _buildEmptyState(),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.mutedText.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.sensors_off,
            size: 28,
            color: AppTheme.mutedText.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppTheme.paddingMD),
        Text(
          'Sensor Inativo',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.paddingSM),
        Text(
          'Inicie o monitoramento para ver dados em tempo real',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.mutedText.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSensorContent() {

    // Build content based on sensor type
    switch (widget.sensorType) {
      case 'accelerometer':
        return _buildAccelerometerContent();
      case 'gyroscope':
        return _buildGyroscopeContent();
      case 'magnetometer':
        return _buildMagnetometerContent();
      case 'location':
        return _buildLocationContent();
      case 'battery':
        return _buildBatteryContent();
      case 'light':
        return _buildLightContent();
      case 'proximity':
        return _buildProximityContent();
      default:
        return const Text('Sensor desconhecido');
    }
  }

  Widget _buildAccelerometerContent() {
    final accelerometerAsync = ref.watch(accelerometerStreamProvider);
    return accelerometerAsync.when(
      data: (data) {
        _updateChartData(data.magnitude);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('X', data.x.toStringAsFixed(2), 'm/s²'),
            _buildDataRow('Y', data.y.toStringAsFixed(2), 'm/s²'),
            _buildDataRow('Z', data.z.toStringAsFixed(2), 'm/s²'),
            const Divider(height: AppTheme.paddingMD),
            _buildDataRow(
              'Magnitude',
              data.magnitude.toStringAsFixed(2),
              'm/s²',
              isHighlighted: true,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildGyroscopeContent() {
    final gyroscopeAsync = ref.watch(gyroscopeStreamProvider);
    return gyroscopeAsync.when(
      data: (data) {
        final magnitude = (data.x * data.x + data.y * data.y + data.z * data.z);
        _updateChartData(magnitude);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('X', data.x.toStringAsFixed(2), 'rad/s'),
            _buildDataRow('Y', data.y.toStringAsFixed(2), 'rad/s'),
            _buildDataRow('Z', data.z.toStringAsFixed(2), 'rad/s'),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildMagnetometerContent() {
    final magnetometerAsync = ref.watch(magnetometerStreamProvider);
    return magnetometerAsync.when(
      data: (data) {
        _updateChartData(data.fieldStrength);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('X', data.x.toStringAsFixed(2), 'μT'),
            _buildDataRow('Y', data.y.toStringAsFixed(2), 'μT'),
            _buildDataRow('Z', data.z.toStringAsFixed(2), 'μT'),
            const Divider(height: AppTheme.paddingMD),
            _buildDataRow(
              'Força do Campo',
              data.fieldStrength.toStringAsFixed(2),
              'μT',
              isHighlighted: true,
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildLocationContent() {
    final locationAsync = ref.watch(locationStreamProvider);
    return locationAsync.when(
      data: (data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow('Latitude', data.latitude.toStringAsFixed(6), '°'),
            _buildDataRow('Longitude', data.longitude.toStringAsFixed(6), '°'),
            _buildDataRow('Altitude', data.altitude.toStringAsFixed(1), 'm'),
            _buildDataRow('Accuracy', data.accuracy.toStringAsFixed(1), 'm'),
            if (data.speed != null)
              _buildDataRow('Speed', data.speed!.toStringAsFixed(1), 'm/s'),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildBatteryContent() {
    final batteryAsync = ref.watch(batteryStreamProvider);
    return batteryAsync.when(
      data: (data) {
        final color = data.batteryLevel < 20
            ? AppTheme.errorColor
            : data.batteryLevel < 50
            ? AppTheme.warningColor
            : AppTheme.successColor;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Battery Level Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${data.batteryLevel}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  data.isCharging
                      ? Icons.battery_charging_full
                      : Icons.battery_full,
                  color: color,
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSM),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              child: LinearProgressIndicator(
                value: data.batteryLevel / 100,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: AppTheme.paddingMD),
            _buildDataRow('Status', data.batteryState, ''),
            _buildDataRow('Carregamento', data.isCharging ? 'Sim' : 'Não', ''),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildLightContent() {
    final lightAsync = ref.watch(lightStreamProvider);
    return lightAsync.when(
      data: (data) {
        _updateChartData(data.luxValue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDataRow(
              'Lux',
              data.luxValue.toStringAsFixed(1),
              'lx',
              isHighlighted: true,
            ),
            _buildDataRow('Condição', data.lightCondition, ''),
            const SizedBox(height: AppTheme.paddingSM),
            // Visual indicator
            Container(
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.black,
                    Colors.grey,
                    Colors.yellow,
                    Colors.white,
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusSM),
              ),
              child: Stack(
                children: [
                  Positioned(
                    left:
                        (data.luxValue.clamp(0, 10000) / 10000) *
                        (MediaQuery.of(context).size.width * 0.3),
                    child: Container(
                      width: 4,
                      height: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildProximityContent() {
    final proximityAsync = ref.watch(proximityStreamProvider);
    return proximityAsync.when(
      data: (data) {
        return Column(
          children: [
            Center(
              child: Icon(
                data.isNear ? Icons.pan_tool : Icons.do_not_touch,
                size: 64,
                color: data.isNear
                    ? AppTheme.warningColor
                    : AppTheme.successColor,
              ),
            ),
            const SizedBox(height: AppTheme.paddingMD),
            _buildDataRow(
              'Status',
              data.isNear ? 'Objeto Próximo' : 'Livre',
              '',
              isHighlighted: true,
            ),
            if (data.distance != null)
              _buildDataRow(
                'Distância',
                data.distance!.toStringAsFixed(1),
                'cm',
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
    );
  }

  Widget _buildDataRow(
    String label,
    String value,
    String unit, {
    bool isHighlighted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isHighlighted ? null : AppTheme.mutedText,
                fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppTheme.paddingSM),
          Flexible(
            child: Text(
              '$value $unit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: isHighlighted ? AppTheme.primaryColor : null,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChart(Color sensorColor) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _chartData,
            isCurved: true,
            color: sensorColor,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  sensorColor.withValues(alpha: 0.2),
                  sensorColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  void _updateChartData(double value) {
    setState(() {
      _chartData.add(FlSpot(_dataCounter.toDouble(), value));
      _dataCounter++;
      // Keep only last 50 points
      if (_chartData.length > 50) {
        _chartData.removeAt(0);
      }
    });
  }
}
