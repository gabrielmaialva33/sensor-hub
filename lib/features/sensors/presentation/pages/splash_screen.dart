import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Platform-specific initialization
      if (kIsWeb) {
        // Web platform initialization
        setState(() => _status = 'Inicializando demo web...');
        await Future.delayed(const Duration(milliseconds: 800));
        
        setState(() => _status = 'Configurando sensores simulados...');
        await Future.delayed(const Duration(milliseconds: 600));
        
        setState(() => _status = 'Preparando visualizações...');
        await Future.delayed(const Duration(milliseconds: 600));
        
        setState(() => _status = 'Demo web pronto! Sensores simulados ativos');
      } else {
        // Mobile platform initialization
        setState(() => _status = 'Conectando aos serviços na nuvem...');
        await Future.delayed(const Duration(milliseconds: 800));
        final supabaseService = SupabaseService();
        if (!supabaseService.isInitialized) {
          await supabaseService.initialize();
        }
        
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
        
        setState(() => _status = 'Pronto para monitorar sensores!');
      }
      
      // Check authentication status
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          context.go('/home');
        } else {
          context.go('/auth/welcome');
        }
      }
    } catch (e) {
      setState(() {
        _status = kIsWeb
            ? 'Erro no demo web: ${e.toString()}'
            : 'Falha ao inicializar: ${e.toString()}';
        _hasError = true;
      });
      // After showing error, navigate to auth
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        context.go('/auth/welcome');
      }
    }
  }

  @override
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
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                  boxShadow: AppTheme.mediumShadow,
                ),
                child: const Icon(Icons.sensors, size: 60, color: Colors.white)
                    .animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .shimmer(delay: 400.ms, duration: 1200.ms),
              ),
              const SizedBox(height: AppTheme.paddingXL),
              // App Name
              Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              const SizedBox(height: AppTheme.paddingSM),
              // App Description
              Text(
                AppConstants.appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.mutedText),
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
              // Web demo indicator
              if (kIsWeb) ...[
                const SizedBox(height: AppTheme.paddingMD),
                Container(
                  padding: const EdgeInsets.all(AppTheme.paddingSM),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    border: Border.all(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.web,
                        color: AppTheme.secondaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: AppTheme.paddingXS),
                      Text(
                        'Web Demo - Sensores Simulados',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
              const SizedBox(height: AppTheme.paddingXL * 2),
              // Status Text
              Text(
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
                      ),
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
              const Spacer(),
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
  }
}
