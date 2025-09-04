import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/core.dart';
import 'app/app_router.dart';
import 'infrastructure/infrastructure.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://npqfsynpttyxxzrltjke.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5wcWZzeW5wdHR5eHh6cmx0amtlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcwMDMxNjMsImV4cCI6MjA3MjU3OTE2M30.B_7e5AYj_n_U9YNTSQUpfC26HWEeTq-4QYWVO5IldKI',
    );

    // Initialize services
    SupabaseService().initialize();
    NvidiaAiService().initialize();

    // Log platform information
    if (kIsWeb) {
      Logger.info('SensorHub running on Web - Mock sensors will be used');
    } else {
      Logger.info('SensorHub running on ${defaultTargetPlatform.name} - Real sensors enabled');
    }

    Logger.success('SensorHub initialized successfully');
  } catch (e) {
    Logger.error('Failed to initialize SensorHub', e);
  }

  runApp(const ProviderScope(child: SensorHubApp()));
}

class SensorHubApp extends ConsumerWidget {
  const SensorHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Builder for additional configuration
      builder: (context, child) {
        return MediaQuery(
          // Ensure text scaling doesn't break the UI
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.2),
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

// Global access to Supabase client
final supabase = Supabase.instance.client;
