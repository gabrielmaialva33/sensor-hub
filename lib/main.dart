import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/core.dart';
import 'infrastructure/infrastructure.dart';
import 'features/sensors/presentation/pages/home_screen.dart';
import 'features/sensors/presentation/pages/splash_screen.dart';

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

    Logger.success('SensorHub initialized successfully');
  } catch (e) {
    Logger.error('Failed to initialize SensorHub', e);
  }

  runApp(const ProviderScope(child: SensorHubApp()));
}

class SensorHubApp extends StatelessWidget {
  const SensorHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Initial route
      home: const SplashScreen(),

      // Route configuration
      routes: {
        '/home': (context) => const HomeScreen(),
        '/splash': (context) => const SplashScreen(),
      },

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
