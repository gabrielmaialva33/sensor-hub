import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:sensor_hub/core/core.dart';
import 'package:sensor_hub/infrastructure/infrastructure.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Inicializando SensorHub...';
  bool _hasError = false;
  void initState() {
    super.initState();
    _initializeApp();
  }
  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Supabase
      setState(() => _status = 'Conectando aos serviços na nuvem...');
      await Future.delayed(const Duration(milliseconds: 800));
      final supabaseService = SupabaseService();
      if (!supabaseService.isInitialized) {
        await supabaseService.initialize();
      }
      // Step 2: Test connections
      setState(() => _status = 'Testando serviços de IA...');
      await Future.delayed(const Duration(milliseconds: 600));
      final aiService = NvidiaAiService();
      aiService.initialize();
      // Optional: Test API connection (non-blocking)
      aiService.testConnection().then((isConnected) {
        if (!isConnected) {
          Logger.warning(
            'AI services temporarily unavailable, app will work in offline mode',
          );
        }
      });
      // Step 3: Setup complete
      setState(() => _status = 'Pronto para monitorar sensores!');
      // Navigate to home screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _status = 'Falha ao inicializar: ${e.toString()}';
        _hasError = true;
      // After showing error, still navigate to home (offline mode)
      await Future.delayed(const Duration(seconds: 3));
    }
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.darkBackground
          : AppTheme.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // App Logo/Icon
              Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.secondaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                      boxShadow: AppTheme.mediumShadow,
                    ),
                    child: const Icon(
                      Icons.sensors,
                      size: 60,
                      color: Colors.white,
                  )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.elasticOut)
                  .shimmer(delay: 400.ms, duration: 1200.ms),
              const SizedBox(height: AppTheme.paddingXL),
              // App Name
              Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: AppTheme.paddingSM),
              // App Description
                AppConstants.appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              const SizedBox(height: AppTheme.paddingXL * 2),
              // Status Text
                _status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _hasError
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              const SizedBox(height: AppTheme.paddingLG),
              // Loading Indicator
              if (!_hasError)
                const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppTheme.primaryColor,
                    )
                    .animate()
                    .fadeIn(delay: 800.ms)
                    .scale(delay: 800.ms, duration: 400.ms),
              // Error Icon
              if (_hasError)
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 32,
                  color: AppTheme.errorColor,
                ).animate().fadeIn(duration: 400.ms).shake(),
              // Version Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Version ${AppConstants.appVersion}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.mutedText),
                  ),
                  const SizedBox(width: AppTheme.paddingSM),
                  Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _hasError
                              ? AppTheme.errorColor
                              : AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .fadeIn(duration: 800.ms)
                      .fadeOut(delay: 800.ms, duration: 800.ms),
                ],
              ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
