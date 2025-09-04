import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sensor_hub/core/core.dart';
import '../providers/sensor_providers.dart';
class QuickActionsPanel extends ConsumerWidget {
  const QuickActionsPanel({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMonitoring = ref.watch(isMonitoringProvider);
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
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
              const Icon(
                Icons.flash_on,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: AppTheme.paddingSM),
              Text(
                'Ações Rápidas',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: AppTheme.paddingMD),
          // Action Buttons Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.paddingSM,
            crossAxisSpacing: AppTheme.paddingSM,
            childAspectRatio: 2.5,
              _buildActionButton(
                context,
                icon: Icons.play_arrow,
                label: 'Iniciar Todos',
                color: AppTheme.successColor,
                onTap: isMonitoring ? null : () => _startAllSensors(ref),
              ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                icon: Icons.stop,
                label: 'Parar Todos',
                color: AppTheme.errorColor,
                onTap: !isMonitoring ? null : () => _stopAllSensors(ref),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                icon: Icons.refresh,
                label: 'Resetar Dados',
                onTap: () => _resetData(context, ref),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),
                icon: Icons.download,
                label: 'Exportar',
                color: AppTheme.primaryColor,
                onTap: () => _exportData(context, ref),
              ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                icon: Icons.analytics,
                label: 'Analisar',
                color: AppTheme.secondaryColor,
                onTap: () => _runAnalysis(context, ref),
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1, end: 0),
                icon: Icons.settings,
                label: 'Configurações',
                color: AppTheme.mutedText,
                onTap: () => _openSettings(context),
              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
          const Divider(),
          // Status Section
          _buildStatusSection(context, ref, isDark),
          // Features Toggle Section
          _buildFeatureToggles(context, ref, isDark),
        ],
    );
  }
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.paddingSM),
          decoration: BoxDecoration(
            color: isEnabled
                ? color.withValues(alpha: 0.1)
                : AppTheme.mutedText.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: isEnabled
                  ? color.withValues(alpha: 0.3)
                  : AppTheme.mutedText.withValues(alpha: 0.1),
              width: 1,
            ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
              Icon(
                icon,
                size: 16,
                color: isEnabled
                    ? color
                    : AppTheme.mutedText.withValues(alpha: 0.5),
              const SizedBox(width: AppTheme.paddingXS),
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isEnabled
                      ? color
                      : AppTheme.mutedText.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
  Widget _buildStatusSection(BuildContext context, WidgetRef ref, bool isDark) {
    final sensorStatus = ref.watch(sensorStatusProvider);
    final activeSensors = sensorStatus.values.where((active) => active).length;
    final sensorHistory = ref.watch(sensorHistoryProvider);
    final totalDataPoints = sensorHistory.values.fold(
      0,
      (sum, list) => sum + list.length,
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status do Sistema',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        const SizedBox(height: AppTheme.paddingSM),
        // Status Items
        _buildStatusItem(
          context,
          'Sensores Ativos',
          '$activeSensors / ${AppConstants.availableSensors.length}',
          activeSensors > 0 ? AppTheme.successColor : AppTheme.mutedText,
          'Pontos de Dados',
          totalDataPoints.toString(),
          AppTheme.primaryColor,
          'Uso de Memória',
          _calculateMemoryUsage(totalDataPoints),
          _getMemoryColor(totalDataPoints),
          'Status da IA',
          'Conectado',
          AppTheme.secondaryColor,
      ],
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.paddingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                value,
                  color: color,
  Widget _buildFeatureToggles(
    WidgetRef ref,
    bool isDark,
          'Features',
        // Feature Toggles
        _buildFeatureToggle(
          ref,
          'AI Analysis',
          'ai_analysis',
          Icons.psychology,
          'Background Monitoring',
          'background_monitoring',
          Icons.sync,
          'Share Insights',
          'share_insights',
          Icons.share,
  Widget _buildFeatureToggle(
    String featureKey,
    IconData icon,
    final isEnabled = AppConstants.features[featureKey] ?? false;
          Icon(
            icon,
            size: 16,
            color: isEnabled ? AppTheme.primaryColor : AppTheme.mutedText,
          const SizedBox(width: AppTheme.paddingSM),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              // TODO: Implement feature toggle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label ${value ? "enabled" : "disabled"}'),
                  backgroundColor: value
                      ? AppTheme.successColor
                      : AppTheme.warningColor,
              );
            },
            activeTrackColor: AppTheme.primaryColor,
  // Helper Methods
  String _calculateMemoryUsage(int dataPoints) {
    // Rough estimate: each data point ~100 bytes
    final bytes = dataPoints * 100;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  Color _getMemoryColor(int dataPoints) {
    final mb = (dataPoints * 100) / (1024 * 1024);
    if (mb < 10) return AppTheme.successColor;
    if (mb < 50) return AppTheme.warningColor;
    return AppTheme.errorColor;
  // Action Handlers
  void _startAllSensors(WidgetRef ref) async {
    final sensorService = ref.read(sensorServiceProvider);
    await sensorService.startMonitoring();
    ref.read(isMonitoringProvider.notifier).state = true;
  void _stopAllSensors(WidgetRef ref) async {
    await sensorService.stopMonitoring();
    ref.read(isMonitoringProvider.notifier).state = false;
  void _resetData(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will clear all sensor history and cannot be undone.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
            onPressed: () {
              ref.read(sensorHistoryProvider.notifier).clearAllHistory();
              Navigator.pop(context);
                const SnackBar(
                  content: Text('All data has been reset'),
                  backgroundColor: AppTheme.warningColor,
            child: const Text(
              'Reset',
              style: TextStyle(color: AppTheme.errorColor),
  void _exportData(BuildContext context, WidgetRef ref) {
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select export format:'),
            const SizedBox(height: AppTheme.paddingMD),
            ...AppConstants.supportedExportFormats.map(
              (format) => ListTile(
                leading: Icon(_getFormatIcon(format)),
                title: Text(format.toUpperCase()),
                onTap: () {
                  Navigator.pop(context);
                  _performExport(context, ref, format);
                },
          ],
  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'json':
        return Icons.code;
      case 'csv':
        return Icons.table_chart;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.file_present;
    }
  void _performExport(BuildContext context, WidgetRef ref, String format) {
    // TODO: Implement actual export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting data as ${format.toUpperCase()}...'),
        backgroundColor: AppTheme.successColor,
  void _runAnalysis(BuildContext context, WidgetRef ref) {
    final sensorHistory = ref.read(sensorHistoryProvider);
    final hasData = sensorHistory.values.any((list) => list.isNotEmpty);
    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sensor data available for analysis'),
          backgroundColor: AppTheme.warningColor,
      );
      return;
    // Navigate to AI Insights tab
    DefaultTabController.of(context).animateTo(2);
      const SnackBar(
        content: Text('Navigating to AI Insights...'),
        backgroundColor: AppTheme.primaryColor,
  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.darkSurface
          : AppTheme.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLG),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
              ],
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Sampling Rates'),
              subtitle: const Text('Configure sensor sampling frequencies'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Open sampling rates settings
              },
              leading: const Icon(Icons.storage),
              title: const Text('Storage'),
              subtitle: const Text('Manage data retention and limits'),
                // TODO: Open storage settings
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              subtitle: const Text('Configure alerts and notifications'),
                // TODO: Open notification settings
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: Text('Version ${AppConstants.appVersion}'),
                _showAboutDialog(context);
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          shape: BoxShape.circle,
        child: const Icon(Icons.sensors, color: Colors.white),
        Text(AppConstants.appDescription),
        const SizedBox(height: AppTheme.paddingMD),
        const Text('Powered by NVIDIA AI'),
}
