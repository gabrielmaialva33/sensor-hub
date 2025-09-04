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

  Widget build(BuildContext context) {
    final isDark = Theme
        .of(context)
        .brightness == Brightness.dark;
    final sensorName =
        AppConstants.sensorDisplayNames[widget.sensorType] ?? widget.sensorType;
    final sensorIcon = AppConstants.sensorIcons[widget.sensorType] ?? '📊';
    return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          border: Border.all(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Header
        Container(
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppTheme.primaryColor.withValues(alpha: 0.05),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusLG),
            topRight: Radius.circular(AppTheme.radiusLG),
          ),
        ),
        child: Row(
            children: [
            // Icon
            Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: Center(
                child: Text(
                  sensorIcon,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppTheme.paddingSM),
                // Title
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sensorName,
                            style: Theme
                                .of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          widget.isMonitoring ? 'Ativo' : 'Inativo',
                          style: Theme
                              .of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                            color: widget.isMonitoring
                                ? AppTheme.successColor
                                : AppTheme.mutedText,
                          ),
                        ],
                        // Status Indicator
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: widget.isMonitoring
                              ? AppTheme.successColor
                              : AppTheme.mutedText,
                          shape: BoxShape.circle,
                        )
                            .animate(
                            onPlay: (controller) => controller.repeat())
                            .scale(
                            duration: 1.seconds,
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                                .then()
                            begin: const Offset(1.2, 1.2),
                        end: const Offset(1, 1),
                        ],
                        // Content
                        Padding(
                        child: _buildSensorContent(),
                    // Chart
                    if (widget.isMonitoring && _chartData.isNotEmpty)
                Container(
                height: 100,
                padding: const EdgeInsets.only(
                  left: AppTheme.paddingMD,
                  right: AppTheme.paddingMD,
                  bottom: AppTheme.paddingMD,
                  child: _buildChart(isDark),
                );
            }

  Widget _buildSensorContent() {
    if (!widget.isMonitoring) {
      return Center(
          child: Column(
              children: [
              Icon(
              Icons.sensors_off,
              size: 48,
              color: AppTheme.mutedText.withValues(alpha: 0.5),
              const SizedBox(height: AppTheme.paddingSM),
              Text(
                'Sensor não ativo',
                style: Theme
                    .of(
                  context,
                )
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.mutedText),
                ],
              );
          }
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
      Widget _buildAccelerometerContent() {
          final accelerometerAsync = ref.watch(accelerometerStreamProvider);
          return accelerometerAsync.when(
          data: (data) {
      _updateChartData(data.magnitude);
      return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      _buildDataRow('X', data.x.toStringAsFixed(2), 'm/s²'),
      _buildDataRow('Y', data.y.toStringAsFixed(2), 'm/s²'),
      _buildDataRow('Z', data.z.toStringAsFixed(2), 'm/s²'),
      const Divider(height: AppTheme.paddingMD),
      _buildDataRow(
      'Magnitude',
      data.magnitude.toStringAsFixed(2),
      'm/s²',
      isHighlighted: true,
      );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Erro: $error'),
      Widget _buildGyroscopeContent() {
          final gyroscopeAsync = ref.watch(gyroscopeStreamProvider);
          return gyroscopeAsync.when(
          final magnitude = (data.x * data.x + data.y * data.y + data.z * data.z);
          _updateChartData(magnitude);
          _buildDataRow('X', data.x.toStringAsFixed(2), 'rad/s'),
          _buildDataRow('Y', data.y.toStringAsFixed(2), 'rad/s'),
          _buildDataRow('Z', data.z.toStringAsFixed(2), 'rad/s'),
      Widget _buildMagnetometerContent() {
          final magnetometerAsync = ref.watch(magnetometerStreamProvider);
          return magnetometerAsync.when(
          _updateChartData(data.fieldStrength);
          _buildDataRow('X', data.x.toStringAsFixed(2), 'μT'),
          _buildDataRow('Y', data.y.toStringAsFixed(2), 'μT'),
          _buildDataRow('Z', data.z.toStringAsFixed(2), 'μT'),
          'Força do Campo',
          data.fieldStrength.toStringAsFixed(2),
          'μT',
          Widget _buildLocationContent() {
          final locationAsync = ref.watch(locationStreamProvider);
          return locationAsync.when(
          _buildDataRow('Latitude', data.latitude.toStringAsFixed(6), '°'),
          _buildDataRow('Longitude', data.longitude.toStringAsFixed(6), '°'),
          _buildDataRow('Altitude', data.altitude.toStringAsFixed(1), 'm'),
          _buildDataRow('Accuracy', data.accuracy.toStringAsFixed(1), 'm'),
          if (data.speed != null)
      _buildDataRow('Speed', data.speed!.toStringAsFixed(1), 'm/s'),
      Widget _buildBatteryContent() {
          final batteryAsync = ref.watch(batteryStreamProvider);
          return batteryAsync.when(
          final color = data.batteryLevel < 20
          ? AppTheme.errorColor
              : data.batteryLevel < 50
          ? AppTheme.warningColor
              : AppTheme.successColor;
          // Battery Level Bar
          Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
          Text(
          '${data.batteryLevel}%',
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
          Icon(
          data.isCharging
          ? Icons.battery_charging_full
              : Icons.battery_full,
          color: color,
          size: 32,
          ],
          const SizedBox(height: AppTheme.paddingSM),
          ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
          child: LinearProgressIndicator(
          value: data.batteryLevel / 100,
          minHeight: 8,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          const SizedBox(height: AppTheme.paddingMD),
          _buildDataRow('Status', data.batteryState, ''),
      _buildDataRow('Carregamento', data.isCharging ? 'Sim' : 'Não', ''),
      Widget _buildLightContent() {
          final lightAsync = ref.watch(lightStreamProvider);
          return lightAsync.when(
          _updateChartData(data.luxValue);
          'Lux',
          data.luxValue.toStringAsFixed(1),
          'lx',
          _buildDataRow('Condição', data.lightCondition, ''),
          // Visual indicator
          height: 40,
          decoration: BoxDecoration(
          gradient: LinearGradient(
          colors: [
          Colors.black,
          Colors.grey.shade800,
          Colors.grey.shade600,
          Colors.grey.shade400,
          Colors.yellow.shade200,
          Colors.yellow,
          Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusSM),
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
      ],
      Widget _buildProximityContent() {
          final proximityAsync = ref.watch(proximityStreamProvider);
          return proximityAsync.when(
          Center(
          child: Icon(
          data.isNear ? Icons.pan_tool : Icons.do_not_touch,
          size: 64,
          color: data.isNear
          ? AppTheme.warningColor
              : AppTheme.successColor,
          'Status',
          data.isNear ? 'Objeto Próximo' : 'Livre',
          '',
          if (data.distance != null)
          _buildDataRow(
          'Distância',
          data.distance!.toStringAsFixed(1),
          'cm',
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
          Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isHighlighted ? null : AppTheme.mutedText,
          fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.normal,
          '$value $unit',
          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          color: isHighlighted ? AppTheme.primaryColor : null,
          Widget _buildChart(bool isDark) {
          return LineChart(
          LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
          LineChartBarData(
          spots: _chartData,
          isCurved: true,
          gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
          colors: [
          AppTheme.primaryColor.withValues(alpha: 0.3),
      AppTheme.secondaryColor.withValues(alpha: 0.1),
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      void _updateChartData(double value) {
          setState(() {
      _chartData.add(FlSpot(_dataCounter.toDouble(), value));
      _dataCounter++;
      // Keep only last 50 points
      if (_chartData.length > 50) {
      _chartData.removeAt(0);
      }
      });
