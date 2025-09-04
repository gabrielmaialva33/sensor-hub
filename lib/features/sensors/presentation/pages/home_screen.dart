import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../../core/core.dart';
import '../../../../infrastructure/infrastructure.dart';
import '../widgets/ai_insights_panel.dart';
import '../widgets/sensor_card.dart';
import '../widgets/sensor_timeline.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isMonitoring = false;
  String _selectedSensorCategory = '🏃 Movimento';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSensors();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSensors() async {
      try {
        final sensorService = SensorService();
        await sensorService.startMonitoring();
        if (mounted) {
          setState(() => _isMonitoring = true);
        }
      } catch (e) {
        Logger.error('Error initializing sensors', e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }

  void _toggleMonitoring() async {
        final sensorService = SensorService();
        if (_isMonitoring) {
          await sensorService.stopMonitoring();
          setState(() => _isMonitoring = false);
        } else {
          await sensorService.startMonitoring();
          setState(() => _isMonitoring = true);
        }
      }

  @override
  Widget build(BuildContext context) {
            final isDark = Theme
                .of(context)
                .brightness == Brightness.dark;
            return Scaffold(
              backgroundColor: isDark
                  ? AppTheme.darkBackground
                  : AppTheme.lightBackground,
              body: SafeArea(
                child: Row(
                  children: [
                    // Sidebar - Pieces style
                    _buildSidebar(isDark),
                    // Main Content Area
                    Expanded(
                      child: Column(
                        children: [
                          // Top Bar
                          _buildTopBar(isDark),
                          // Tab Content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildDashboardTab(),
                                _buildSensorsTab(),
                                _buildInsightsTab(),
                                _buildTimelineTab(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
  }

  // Sidebar inspired by Pieces
  Widget _buildSidebar(bool isDark) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
                              // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMD),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sensors,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppTheme.paddingSM),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Monitoring Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.paddingSM),
              decoration: BoxDecoration(
                color: _isMonitoring
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: _isMonitoring
                      ? AppTheme.secondaryColor
                      : AppTheme.errorColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isMonitoring ? Icons.sensors : Icons.sensors_off,
                    color: _isMonitoring
                        ? AppTheme.secondaryColor
                        : AppTheme.errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: AppTheme.paddingSM),
                  Text(
                    _isMonitoring
                        ? 'Monitoramento Ativo'
                        : 'Monitoramento Parado',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: _isMonitoring
                          ? AppTheme.secondaryColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      .animate()
                      .fadeIn()
                      .scale(delay: 200.ms),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingLG),
          // Sensor Categories
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
            child: Text(
              'Categorias de Sensores',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
          // Category List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingSM),
              itemCount: AppConstants.sensorCategories.keys.length,
              itemBuilder: (context, index) {
                final category = AppConstants.sensorCategories.keys.elementAt(index);
                final sensors = AppConstants.sensorCategories[category]!;
                final isSelected = _selectedSensorCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingXS),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => _selectedSensorCategory = category),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.paddingSM),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              category,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: isSelected ? AppTheme.primaryColor : null,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.paddingXS,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor.withValues(alpha: 0.2)
                                    : AppTheme.mutedText.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSM),
                              ),
                              child: Text(
                                '${sensors.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.mutedText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 100 * index))
                        .slideX(begin: -0.2, end: 0),
                  ),
                );
              },
            ),
          ),
          // Bottom Actions
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingMD),
            child: Column(
              children: [
                SizedBox(
                                                                                                  width: double
                                                                                                      .infinity,
                                                                                                  child: ElevatedButton
                                                                                                      .icon(
                                                                                                      onPressed: _toggleMonitoring,
                                                                                                      icon: Icon(
                                                                                                          _isMonitoring
                                                                                                              ? Icons
                                                                                                              .stop
                                                                                                              : Icons
                                                                                                              .play_arrow),
                                                                                                      label: Text(
                                                                                                        _isMonitoring
                                                                                                            ? 'Parar Monitoramento'
                                                                                                            : 'Iniciar Monitoramento',
                                                                                                        style: ElevatedButton
                                                                                                            .styleFrom(
                                                                                                            backgroundColor: _isMonitoring
                                                                                                                ? AppTheme
                                                                                                                .errorColor
                                                                                                                : AppTheme
                                                                                                                .primaryColor,
                                                                                                            padding: const EdgeInsets
                                                                                                                .symmetric(
                                                                                                                vertical: AppTheme
                                                                                                                    .paddingSM,
                                                                                                                const SizedBox(
                                                                                                                    height: AppTheme
                                                                                                                        .paddingSM),
                                                                                                                Row(
                                                                                                                    children
                                                                                                                        :
                                                                                                                    [
                                                                                                                    Expanded(
                                                                                                                    child: TextButton.icon(
                                                                                                                    onPressed
                                                                                                                    :
                                                                                                                    ()
                                                                                                                =>
                                                                                                                _showExportDialog
                                                                                                                (
                                                                                                                context),
                                                                                                            icon: const Icon(
                                                                                                                Icons
                                                                                                                    .download,
                                                                                                                size: 16),
                                                                                                            label: const Text(
                                                                                                                'Exportar'),
                                                                                                            onPressed: () =>
                                                                                                                _showSettingsDialog(
                                                                                                                    context),
                                                                                                            icon: const Icon(
                                                                                                                Icons
                                                                                                                    .settings,
                                                                                                                size: 16),
                                                                                                            label: const Text(
                                                                                                                'Configurações'),
                                                                                                            ],
                                                                                                            ],
                                                                                                            // Top Bar with tabs
                                                                                                            Widget
                                                                                                            _buildTopBar
                                                                                                            (
                                                                                                            bool
                                                                                                            isDark)
                                                                                                        {
                                                                                                        padding: const EdgeInsets.all(AppTheme.paddingMD),
                                                                                                        bottom: BorderSide(
                                                                                                        child: Row(
                                                                                                        // Search Bar - Pieces style
                                                                                                        height: 36,
                                                                                                        color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                                                                                                        color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                                                                                                        child: TextField(
                                                                                                        decoration: InputDecoration(
                                                                                                        hintText: 'Buscar dados de sensores, insights, padrões...',
                                                                                                        prefixIcon: const Icon(Icons.search, size: 18),
                                                                                                        border: InputBorder.none,
                                                                                                        contentPadding: const EdgeInsets.symmetric(
                                                                                                        horizontal: AppTheme.paddingSM,
                                                                                                        vertical: AppTheme.paddingXS
                                                                                                        ,
                                                                                                        const SizedBox(width: AppTheme.paddingMD),
                                                                                                        // Tab Bar
                                                                                                        TabBar(
                                                                                                        controller: _tabController,
                                                                                                        isScrollable: true,
                                                                                                        labelPadding: const EdgeInsets.symmetric(
                                                                                                        horizontal: AppTheme.paddingMD,
                                                                                                        indicator: BoxDecoration(
                                                                                                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                                                                                        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                                                                                                        border: Border.all(
                                                                                                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                                                                                        tabs: const [
                                                                                                        Tab(text: '📊 Dashboard'),
                                                                                                        Tab(text: '📱 Sensores
                                                                                                        '),
                                                                                                        Tab(text: '🤖 Insights de IA'
                                                                                                        ),
                                                                                                        Tab(text: '📈 Linha do Tempo')
                                                                                                        ,
                                                                                                        ],
                                                                                                        // Dashboard Tab
                                                                                                        Widget _buildDashboardTab()
                                                                                                      {
                                                                                                        return Padding(
                                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                        Text(
                                                                                                        'Visão Geral dos Sensores',
                                                                                                        style: Theme.of(
                                                                                                        context,
                                                                                                        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                                                                                        const SizedBox(height: AppTheme.paddingMD),
                                                                                                        child: MasonryGridView.count(
                                                                                                        crossAxisCount: 2,
                                                                                                        itemCount:
                                                                                                        AppConstants
                                                                                                            .sensorCategories[_selectedSensorCategory]
                                                                                                            ?.length ??
                                                                                                        0,
                                                                                                        final sensors =
                                                                                                        AppConstants.sensorCategories[_selectedSensorCategory]!;
                                                                                                        final sensorType = sensors[index];
                                                                                                        return SensorCard(
                                                                                                        sensorType: sensorType,
                                                                                                        isMonitoring: _isMonitoring
                                                                                                        ,
                                                                                                            .slideY(begin: 0.2, end:
                                                                                                        0);
                                                                                                        mainAxisSpacing: AppTheme.paddingMD,
                                                                                                        crossAxisSpacing
                                                                                                            : AppTheme.paddingMD,
                                                                                                        // Sensors Tab
                                                                                                        Widget _buildSensorsTab()
                                                                                                      {
                                                                                                        return const Center(child: Text('Visualizações Detalhadas dos Sensores
                                                                                                        '));
                                                                                                        // AI Insights Tab
                                                                                                        Widget _buildInsightsTab()
                                                                                                      {
                                                                                                        return const AIInsightsPanel();
                                                                                                        // Timeline Tab
                                                                                                        Widget _buildTimelineTab()
                                                                                                      {
                                                                                                        return const SensorTimeline();
                                                                                                        // Export Dialog
                                                                                                        void _showExportDialog(BuildContext
                                                                                                        context)
                                                                                                      {
                                                                                                        showDialog(
                                                                                                        context: context,
                                                                                                        builder: (context
                                                                                                        ) => AlertDialog(
                                                                                                        title: const Text('
                                                                                                        Exportar Dados dos Sensores'),
                                                                                                        content: const Text('
                                                                                                        Escolha o formato de exportação:'),
                                                                                                        actions: [
                                                                                                        TextButton(
                                                                                                        onPressed
                                                                                                            : () => Navigator.pop(context)
                                                                                                        ,
                                                                                                        child: const Text('Cancelar')
                                                                                                        ,
                                                                                                        child: const Text('JSON')
                                                                                                        ,
                                                                                                        child: const Text('CSV')
                                                                                                        ,
                                                                                                        // Settings Dialog
                                                                                                        void _showSettingsDialog(BuildContext context)
                                                                                                      {
                                                                                                        title: const Text('Configurações'),
                                                                                                        content: const Text(
                                                                                                        'Configurações de monitoramento de sensores em breve!',
                                                                                                        child
                                                                                                        :
                                                                                                        const
                                                                                                        Text
                                                                                                        (
                                                                                                        '
                                                                                                        Fechar
                                                                                                        '
                                                                                                        ),
