import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sensor_hub/core/core.dart';
import 'package:sensor_hub/features/sensors/data/models/sensor_data.dart';
import '../providers/sensor_providers.dart';
class SensorTimeline extends ConsumerStatefulWidget {
  const SensorTimeline({super.key});
  @override
  ConsumerState<SensorTimeline> createState() => _SensorTimelineState();
}
class _SensorTimelineState extends ConsumerState<SensorTimeline> {
  String _selectedSensor = 'accelerometer';
  String _selectedTimeRange = '1 Hora';
  bool _showLegend = true;
  final Map<String, Duration> _timeRanges = {
    '15 Minutos': const Duration(minutes: 15),
    '30 Minutos': const Duration(minutes: 30),
    '1 Hora': const Duration(hours: 1),
    '3 Horas': const Duration(hours: 3),
    '6 Horas': const Duration(hours: 6),
    'Todos os Dados': const Duration(days: 365),
  };
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sensorHistory = ref.watch(sensorHistoryProvider);
    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(
        children: [
          // Header with controls
          _buildHeader(context, isDark),
          // Main Chart Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: _buildMainChart(context, isDark, sensorHistory),
            ),
          ),
          // Bottom Timeline Events
          _buildTimelineEvents(context, isDark, sensorHistory),
        ],
      ),
    );
  }
  Widget _buildHeader(BuildContext context, bool isDark) {
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
          Text(
            '📈 Linha do Tempo dos Sensores',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          const SizedBox(height: AppTheme.paddingMD),
          Row(
            children: [
              // Sensor Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingSM,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.darkBorder
                          : AppTheme.lightBorder,
                    ),
                  child: DropdownButton<String>(
                    value: _selectedSensor,
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down),
                    onChanged: (value) {
                      setState(() {
                        _selectedSensor = value!;
                      });
                    },
                    items: AppConstants.availableSensors.map((sensor) {
                      final icon = AppConstants.sensorIcons[sensor] ?? '📊';
                      final name =
                          AppConstants.sensorDisplayNames[sensor] ?? sensor;
                      return DropdownMenuItem(
                        value: sensor,
                        child: Row(
                          children: [
                            Text(icon),
                            const SizedBox(width: AppTheme.paddingSM),
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ),
              ),
              const SizedBox(width: AppTheme.paddingMD),
              // Time Range Selector
                    value: _selectedTimeRange,
                        _selectedTimeRange = value!;
                    items: _timeRanges.keys.map((range) {
                      return DropdownMenuItem(value: range, child: Text(range));
              // Legend Toggle
              IconButton(
                onPressed: () {
                  setState(() {
                    _showLegend = !_showLegend;
                  });
                },
                icon: Icon(
                  _showLegend
                      ? Icons.legend_toggle
                      : Icons.legend_toggle_outlined,
                  color: _showLegend
                      ? AppTheme.primaryColor
                      : AppTheme.mutedText,
                tooltip: 'Alternar Legenda',
              // Export Button
                onPressed: () => _showExportDialog(context),
                icon: const Icon(Icons.download),
                tooltip: 'Exportar Dados',
            ],
  Widget _buildMainChart(
    BuildContext context,
    bool isDark,
    Map<String, List<SensorData>> sensorHistory,
  ) {
    final selectedData = sensorHistory[_selectedSensor] ?? [];
    if (selectedData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: AppTheme.mutedText.withValues(alpha: 0.3),
            const SizedBox(height: AppTheme.paddingMD),
            Text(
              'Nenhum dado disponível',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.mutedText),
            const SizedBox(height: AppTheme.paddingSM),
              'Inicie o monitoramento para ver a linha do tempo dos sensores',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedText.withValues(alpha: 0.7),
          ],
      );
    }
    // Filter data based on time range
    final now = DateTime.now();
    final timeRange = _timeRanges[_selectedTimeRange]!;
    final filteredData = selectedData.where((data) {
      if (_selectedTimeRange == 'Todos os Dados') return true;
      return data.timestamp.isAfter(now.subtract(timeRange));
    }).toList();
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusLG),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              width: 1,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingLG),
            child: Column(
              children: [
                // Chart Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.sensorDisplayNames[_selectedSensor] ??
                              _selectedSensor,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          '${filteredData.length} pontos de dados',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.mutedText),
                      ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingSM,
                        vertical: AppTheme.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                      child: Text(
                        DateFormat('MMM dd, HH:mm').format(now),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                  ],
                const SizedBox(height: AppTheme.paddingLG),
                // The Chart
                Expanded(child: _buildChart(filteredData, isDark)),
                // Legend
                if (_showLegend)
                  Container(
                    margin: const EdgeInsets.only(top: AppTheme.paddingMD),
                    child: _buildLegend(context),
              ],
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  Widget _buildChart(List<SensorData> data, bool isDark) {
    if (data.isEmpty) {
      return const Center(child: Text('Nenhum dado no intervalo selecionado'));
    // Prepare chart data based on sensor type
    List<FlSpot> spots = [];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (int i = 0; i < data.length; i++) {
      double value = _getValueFromSensorData(data[i]);
      spots.add(FlSpot(i.toDouble(), value));
      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    // Add padding to Y axis
    final yPadding = (maxY - minY) * 0.1;
    minY -= yPadding;
    maxY += yPadding;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: (maxY - minY) / 5,
          verticalInterval: data.length / 10,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark
                  ? AppTheme.darkBorder.withValues(alpha: 0.3)
                  : AppTheme.lightBorder.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
                  ? AppTheme.darkBorder.withValues(alpha: 0.2)
                  : AppTheme.lightBorder.withValues(alpha: 0.2),
        titlesData: FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 10),
                );
              },
          bottomTitles: AxisTitles(
              reservedSize: 30,
              interval: data.length / 5,
                if (value.toInt() >= data.length) return const SizedBox();
                final date = data[value.toInt()].timestamp;
                  DateFormat('HH:mm').format(date),
        borderData: FlBorderData(
          border: Border.all(
        minX: 0,
        maxX: (data.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 20,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: AppTheme.primaryColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.secondaryColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                final dataPoint = data[touchedSpot.x.toInt()];
                final time = DateFormat('HH:mm:ss').format(dataPoint.timestamp);
                return LineTooltipItem(
                  '$time\n${touchedSpot.y.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
              }).toList();
            },
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
  Widget _buildLegend(BuildContext context) {
    final legends = _getLegendItems();
    return Wrap(
      spacing: AppTheme.paddingMD,
      runSpacing: AppTheme.paddingSM,
      children: legends.map((legend) {
        return Row(
          mainAxisSize: MainAxisSize.min,
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: legend['color'] as Color,
                borderRadius: BorderRadius.circular(2),
            const SizedBox(width: AppTheme.paddingXS),
              legend['label'] as String,
              style: Theme.of(context).textTheme.bodySmall,
        );
      }).toList(),
  Widget _buildTimelineEvents(
    final events = _generateTimelineEvents(sensorHistory);
    if (events.isEmpty) {
      return const SizedBox.shrink();
      height: 120,
          top: BorderSide(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Container(
                width: 200,
                margin: const EdgeInsets.only(right: AppTheme.paddingMD),
                padding: const EdgeInsets.all(AppTheme.paddingSM),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: event['color'] as Color, width: 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                    Row(
                        Icon(
                          event['icon'] as IconData,
                          size: 16,
                          color: event['color'] as Color,
                        const SizedBox(width: AppTheme.paddingXS),
                          event['type'] as String,
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: event['color'] as Color,
                    const SizedBox(height: AppTheme.paddingXS),
                    Text(
                      event['title'] as String,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      event['description'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mutedText,
                      maxLines: 2,
                    const Spacer(),
                      event['time'] as String,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index))
              .slideX(begin: 0.2, end: 0);
        },
  double _getValueFromSensorData(SensorData data) {
    switch (data.sensorType) {
      case 'accelerometer':
        return (data as AccelerometerData).magnitude;
      case 'gyroscope':
        final gyro = data as GyroscopeData;
        return (gyro.x * gyro.x + gyro.y * gyro.y + gyro.z * gyro.z);
      case 'magnetometer':
        return (data as MagnetometerData).fieldStrength;
      case 'battery':
        return (data as BatteryData).batteryLevel.toDouble();
      case 'light':
        return (data as LightData).luxValue;
      case 'proximity':
        return (data as ProximityData).distance ?? 0;
      case 'location':
        return (data as LocationData).speed ?? 0;
      default:
        return 0;
  List<Map<String, dynamic>> _getLegendItems() {
    switch (_selectedSensor) {
        return [
          {'label': 'Magnitude (m/s²)', 'color': AppTheme.primaryColor},
        ];
          {'label': 'Rotation (rad/s)', 'color': AppTheme.primaryColor},
          {'label': 'Field Strength (μT)', 'color': AppTheme.primaryColor},
          {'label': 'Battery Level (%)', 'color': AppTheme.primaryColor},
          {'label': 'Luminosity (lux)', 'color': AppTheme.primaryColor},
          {'label': 'Distance (cm)', 'color': AppTheme.primaryColor},
          {'label': 'Speed (m/s)', 'color': AppTheme.primaryColor},
        return [];
  List<Map<String, dynamic>> _generateTimelineEvents(
    final events = <Map<String, dynamic>>[];
    // Check for significant events in sensor data
    sensorHistory.forEach((sensorType, dataList) {
      if (dataList.isNotEmpty) {
        // Activity detected
        if (sensorType == 'accelerometer' && dataList.length > 10) {
          final recentData = dataList.last as AccelerometerData;
          if (recentData.magnitude > 15) {
            events.add({
              'type': 'Activity',
              'icon': Icons.directions_run,
              'color': AppTheme.warningColor,
              'title': 'High Activity',
              'description': 'Intense movement detected',
              'time': DateFormat('HH:mm').format(recentData.timestamp),
            });
          }
        }
        // Battery events
        if (sensorType == 'battery' && dataList.isNotEmpty) {
          final batteryData = dataList.last as BatteryData;
          if (batteryData.batteryLevel < 20) {
              'type': 'Alert',
              'icon': Icons.battery_alert,
              'color': AppTheme.errorColor,
              'title': 'Low Battery',
              'description': '${batteryData.batteryLevel}% remaining',
              'time': DateFormat('HH:mm').format(batteryData.timestamp),
        // Location events
        if (sensorType == 'location' && dataList.length > 1) {
          final locationData = dataList.last as LocationData;
          if (locationData.speed != null && locationData.speed! > 10) {
              'type': 'Movement',
              'icon': Icons.speed,
              'color': AppTheme.secondaryColor,
              'title': 'Fast Movement',
              'description': '${locationData.speed!.toStringAsFixed(1)} m/s',
              'time': DateFormat('HH:mm').format(locationData.timestamp),
      }
    });
    // Sort by time (most recent first)
    events.sort((a, b) => b['time'].compareTo(a['time']));
    return events.take(10).toList();
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Timeline Data'),
        content: Column(
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              onTap: () {
                Navigator.pop(context);
                _exportData('json');
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
                _exportData('csv');
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
                _exportData('pdf');
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
  void _exportData(String format) {
    // TODO: Implement actual export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data as $format...'),
        backgroundColor: AppTheme.successColor,
