import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_hub/core/core.dart';

import 'app_router.dart';

/// App principal com arquitetura 2025
class SensorHubApp extends ConsumerWidget {
  const SensorHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SensorHub Ultra 2025',
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Router moderno
      routerConfig: AppRouter.router,

      // Builder para configurações globais
      builder: (context, child) {
        // Limitar text scaling
        final mediaQuery = MediaQuery.of(context);
        final constrainedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.8,
          maxScaleFactor: 1.2,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: constrainedTextScaler),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

/// Extension para TextScaler (mantida do código anterior)
extension TextScalerExtension on TextScaler {
  TextScaler clamp({
    required double minScaleFactor,
    required double maxScaleFactor,
  }) {
    return TextScaler.linear(scale(1.0).clamp(minScaleFactor, maxScaleFactor));
  }
}
