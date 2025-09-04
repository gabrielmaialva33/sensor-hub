import 'package:flutter/foundation.dart';
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
  bool _isMobileMenuOpen = false;

  // Responsive breakpoints
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isTablet = screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;
    
    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      // Add drawer for mobile navigation
      drawer: isMobile ? _buildMobileDrawer(isDark) : null,
      body: SafeArea(
        child: _buildResponsiveLayout(isDark, isMobile, isTablet),
      ),
      // Add platform indicator for web
      floatingActionButton: kIsWeb && !isMobile
          ? _buildWebIndicator(isDark)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  /// Build responsive layout based on screen size
  Widget _buildResponsiveLayout(bool isDark, bool isMobile, bool isTablet) {
    if (isMobile) {
      // Mobile: Stack layout with drawer
      return Column(
        children: [
          _buildMobileTopBar(isDark),
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
      );
    } else {
      // Desktop/Tablet: Side-by-side layout (Pieces style)
      return Row(
        children: [
          // Sidebar
          _buildSidebar(isDark, isTablet),
          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(isDark, isTablet),
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
      );
    }
  }

  // Sidebar inspired by Pieces
  Widget _buildSidebar(bool isDark, bool isTablet) {
    final sidebarWidth = isTablet ? 240.0 : 280.0;
    return Container(
      width: sidebarWidth,
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
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _isMonitoring
                          ? AppTheme.secondaryColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate().fadeIn().scale(delay: 200.ms),
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
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
          // Category List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingSM,
              ),
              itemCount: AppConstants.sensorCategories.keys.length,
              itemBuilder: (context, index) {
                final category = AppConstants.sensorCategories.keys.elementAt(
                  index,
                );
                final sensors = AppConstants.sensorCategories[category]!;
                final isSelected = _selectedSensorCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.paddingXS),
                  child: Material(
                    color: Colors.transparent,
                    child:
                        InkWell(
                              onTap: () => setState(
                                () => _selectedSensorCategory = category,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMD,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  AppTheme.paddingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMD,
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.3),
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
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : null,
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
                                            ? AppTheme.primaryColor.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppTheme.mutedText.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSM,
                                        ),
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
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _toggleMonitoring,
                    icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                    label: Text(
                      _isMonitoring
                          ? 'Parar Monitoramento'
                          : 'Iniciar Monitoramento',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isMonitoring
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.paddingSM,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSM),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showExportDialog(context),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Exportar'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showSettingsDialog(context),
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Configurações'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Top Bar with tabs
  Widget _buildTopBar(bool isDark, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar - Pieces style
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                ),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar dados de sensores, insights, padrões...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingSM,
                    vertical: AppTheme.paddingXS,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.paddingMD),
          // Tab Bar
          Expanded(
            flex: 2,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMD,
              ),
              indicator: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              tabs: const [
                Tab(text: '📊 Dashboard'),
                Tab(text: '📱 Sensores'),
                Tab(text: '🤖 Insights de IA'),
                Tab(text: '📈 Linha do Tempo'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dashboard Tab
  Widget _buildDashboardTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visão Geral dos Sensores',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.paddingMD),
          Expanded(
            child: MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.paddingMD,
              crossAxisSpacing: AppTheme.paddingMD,
              itemCount:
                  AppConstants
                      .sensorCategories[_selectedSensorCategory]
                      ?.length ??
                  0,
              itemBuilder: (context, index) {
                final sensors =
                    AppConstants.sensorCategories[_selectedSensorCategory]!;
                final sensorType = sensors[index];
                return SensorCard(
                  sensorType: sensorType,
                  isMonitoring: _isMonitoring,
                ).animate().slideY(begin: 0.2, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Sensors Tab
  Widget _buildSensorsTab() {
    return const Center(child: Text('Visualizações Detalhadas dos Sensores'));
  }

  // AI Insights Tab
  Widget _buildInsightsTab() {
    return const AIInsightsPanel();
  }

  // Timeline Tab
  Widget _buildTimelineTab() {
    return const SensorTimeline();
  }

  // Export Dialog
  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exportar Dados dos Sensores'),
        content: const Text('Escolha o formato de exportação:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('JSON'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CSV'),
          ),
        ],
      ),
    );
  }

  // Settings Dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurações'),
        content: const Text(
          'Configurações de monitoramento de sensores em breve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  /// Web platform indicator
  Widget _buildWebIndicator(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingSM,
        vertical: AppTheme.paddingXS,
      ),
      decoration: BoxDecoration(
        color: kIsWeb 
            ? AppTheme.secondaryColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSM),
        border: Border.all(
          color: kIsWeb 
              ? AppTheme.secondaryColor
              : AppTheme.primaryColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            kIsWeb ? Icons.web : Icons.phone_android,
            size: 16,
            color: kIsWeb 
                ? AppTheme.secondaryColor
                : AppTheme.primaryColor,
          ),
          const SizedBox(width: AppTheme.paddingXS),
          Text(
            kIsWeb ? 'Web Demo' : 'Mobile',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: kIsWeb 
                  ? AppTheme.secondaryColor
                  : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile drawer for navigation
  Widget _buildMobileDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
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
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Web indicator for mobile drawer
            if (kIsWeb) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLG),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingSM),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.warningColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.paddingXS),
                      Expanded(
                        child: Text(
                          'Demo mode with simulated sensors',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.paddingMD),
            ],
            // Monitoring Status
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLG),
              child: Container(
                width: double.infinity,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isMonitoring
                            ? AppTheme.secondaryColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn().scale(delay: 200.ms),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingLG),
            // Category List - Mobile Optimized
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
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
                        onTap: () {
                          setState(() => _selectedSensorCategory = category);
                          Navigator.pop(context); // Close drawer
                        },
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
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isSelected ? AppTheme.primaryColor : null,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                                ),
                                child: Text(
                                  '${sensors.length}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Actions - Mobile Optimized
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleMonitoring,
                      icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                      label: Text(
                        _isMonitoring ? 'Parar' : 'Iniciar',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isMonitoring
                            ? AppTheme.errorColor
                            : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingSM),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingSM),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showExportDialog(context),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Exportar'),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showSettingsDialog(context),
                          icon: const Icon(Icons.settings, size: 16),
                          label: const Text('Config'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile-optimized top bar
  Widget _buildMobileTopBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSM),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                ),
              ),
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar sensores...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingSM,
                        vertical: AppTheme.paddingXS,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.paddingSM),
              IconButton(
                onPressed: () => _toggleMonitoring(),
                icon: Icon(
                  _isMonitoring ? Icons.sensors : Icons.sensors_off,
                  color: _isMonitoring 
                      ? AppTheme.successColor 
                      : AppTheme.mutedText,
                ),
                tooltip: _isMonitoring ? 'Parar' : 'Iniciar',
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingSM),
          // Mobile Tab Bar
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMD),
            indicator: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            tabs: const [
              Tab(text: '📊 Dashboard'),
              Tab(text: '📱 Sensores'),
              Tab(text: '🤖 IA'),
              Tab(text: '📈 Timeline'),
            ],
          ),
        ],
      ),
    );
  }
}
