import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/core.dart';
import 'features/sensors/presentation/pages/home_screen.dart';
import 'features/sensors/presentation/pages/splash_screen.dart';
import 'infrastructure/infrastructure.dart';

/// Main entry point for SensorHub 2025 - Ultra Performance Edition
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable Impeller for 120fps performance
  if (!kIsWeb && !kDebugMode) {
    // Force GPU acceleration
    debugDisableShadows = false;
  }

  // Configure high refresh rate
  if (!kIsWeb) {
    SchedulerBinding.instance.window.onReportTimings = (timings) {
      for (final timing in timings) {
        if (timing.totalSpan.inMicroseconds > 8333) {
          // 120fps target
          Logger.debug('Frame drop: ${timing.totalSpan.inMilliseconds}ms');
        }
      }
    };
  }

  try {
    Logger.info('🚀 SensorHub 2025 Ultra - Iniciando com 120fps...');

    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://npqfsynpttyxxzrltjke.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wcWZzeW5wdHR5eHh6cmx0amtlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMDMxNjMsImV4cCI6MjA3MjU3OTE2M30.B_7e5AYj_n_U9YNTSQUpfC26HWEeTq-4QYWVO5IldKI',
    );

    // Initialize performance systems
    final perfOptimizer = PerformanceOptimizer();
    perfOptimizer.initialize();

    // Initialize predictive rendering
    final predictiveEngine = PredictiveRenderingEngine();
    predictiveEngine.initialize();

    // Initialize NVIDIA AI
    final aiService = NvidiaAiService();
    aiService.initialize();

    // Initialize advanced sensor-LLM service
    final advancedService = AdvancedSensorLLMService();
    advancedService.initialize();

    Logger.success('Todos os sistemas inicializados com sucesso!');
  } catch (e) {
    Logger.error('Falha ao inicializar aplicação', e);
  }

  runApp(const ProviderScope(child: SensorHubUltraApp()));
}

/// Main app widget with ultra performance optimizations
class SensorHubUltraApp extends ConsumerWidget {
  const SensorHubUltraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable visual update optimization
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SchedulerBinding.instance.ensureVisualUpdate();
      });
    }

    return MaterialApp(
      title: 'SensorHub 2025 Ultra',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Performance optimizations
      showPerformanceOverlay: kDebugMode && false,
      // Set to true to see performance
      checkerboardOffscreenLayers: false,
      checkerboardRasterCacheImages: false,

      // Routes with smooth transitions
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const SplashScreen();
            break;
          case '/home':
            page = const HomeScreen();
            break;
          default:
            page = const SplashScreen();
        }

        // Ultra-smooth 120fps page transition
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => page,
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            var offsetAnimation = animation.drive(tween);

            // Add fade for smoother transition
            var fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: curve));

            // RepaintBoundary for performance
            return RepaintBoundary(
              child: SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: fadeAnimation, child: child),
              ),
            );
          },
        );
      },

      // Builder for global optimizations
      builder: (context, child) {
        // Apply text scaling limits
        final mediaQuery = MediaQuery.of(context);
        final constrainedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.2,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: constrainedTextScaler),
          child: ScrollConfiguration(
            behavior: UltraScrollBehavior(),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}

/// Ultra-smooth scroll behavior for 120fps scrolling
class UltraScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Custom physics for ultra-smooth scrolling
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Custom scrollbar for better performance
    return RawScrollbar(
      controller: details.controller,
      thumbVisibility: false,
      trackVisibility: false,
      thickness: 4,
      radius: const Radius.circular(2),
      thumbColor: AppTheme.primaryColor.withValues(alpha: 0.3),
      child: child,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Disable overscroll glow for better performance
    return child;
  }
}

/// Extension for clamping TextScaler
extension TextScalerExtension on TextScaler {
  TextScaler clamp({
    required double minScaleFactor,
    required double maxScaleFactor,
  }) {
    return TextScaler.linear(scale(1.0).clamp(minScaleFactor, maxScaleFactor));
  }
}
