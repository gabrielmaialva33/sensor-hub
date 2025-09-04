import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/entities/auth_state.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../features/auth/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/sensors/presentation/pages/home_screen.dart';
import '../features/sensors/presentation/pages/splash_screen.dart';

/// Router moderno com go_router 14.0+ - 2025 Pattern
/// Suporta deep linking, navegação declarativa e guarded routes
class AppRouter {
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      errorBuilder: (context, state) => _ErrorPage(error: state.error),
      redirect: (context, state) {
        final authState = ref.read(authNotifierProvider);
        final isOnAuthRoute = [
          '/welcome',
          '/login',
          '/register',
          '/forgot-password',
        ].contains(state.matchedLocation);
        
        // Handle authentication redirects
        switch (authState) {
          case AuthInitial():
          case AuthLoading():
            // Stay on current route while loading
            return null;
          case AuthUnauthenticated():
            if (!isOnAuthRoute && state.matchedLocation != '/') {
              return '/welcome';
            }
            return null;
          case AuthAuthenticated(:final user):
            if (isOnAuthRoute) {
              return '/home';
            }
            return null;
          case AuthOnboardingRequired():
            if (state.matchedLocation != '/onboarding') {
              return '/onboarding';
            }
            return null;
          case AuthProfileSetupRequired():
            if (state.matchedLocation != '/profile-setup') {
              return '/profile-setup';
            }
            return null;
          case AuthEmailVerificationRequired():
            if (state.matchedLocation != '/email-verification') {
              return '/email-verification';
            }
            return null;
          case AuthError():
            if (!isOnAuthRoute) {
              return '/welcome';
            }
            return null;
          default:
            return null;
        }
      },
      routes: [
        // Splash route
        GoRoute(
          path: '/',
          name: 'splash',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SplashScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),

        // Authentication routes
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const WelcomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  )),
                  child: child,
                ),
              );
            },
          ),
        ),

        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),

        GoRoute(
          path: '/register',
          name: 'register',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const RegisterScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),

        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const ForgotPasswordScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          ),
        ),

        // TODO: Add onboarding, profile setup, and email verification routes

      // Home com sub-rotas
      ShellRoute(
        builder: (context, state, child) => child,
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionDuration: const Duration(milliseconds: 200),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;

                    var tween = Tween(
                      begin: begin,
                      end: end,
                    ).chain(CurveTween(curve: curve));

                    return SlideTransition(
                      position: animation.drive(tween),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
            ),
            routes: [
              // Sub-rota para detalhes do sensor
              GoRoute(
                path: 'sensor/:type',
                name: 'sensor-detail',
                builder: (context, state) {
                  final sensorType = state.pathParameters['type']!;
                  return _SensorDetailPage(sensorType: sensorType);
                },
              ),

              // Sub-rota para configurações
              GoRoute(
                path: 'settings',
                name: 'settings',
                builder: (context, state) => const _SettingsPage(),
              ),

              // Sub-rota para análise IA
              GoRoute(
                path: 'ai-analysis',
                name: 'ai-analysis',
                builder: (context, state) => const _AIAnalysisPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Página de erro 404
class _ErrorPage extends StatelessWidget {
  final Exception? error;

  const _ErrorPage({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Página não encontrada',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error?.toString() ?? 'Erro desconhecido',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Voltar ao início'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder para página de detalhes do sensor
class _SensorDetailPage extends StatelessWidget {
  final String sensorType;

  const _SensorDetailPage({required this.sensorType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sensor: $sensorType')),
      body: Center(child: Text('Detalhes do sensor $sensorType')),
    );
  }
}

/// Placeholder para página de configurações
class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const Center(child: Text('Configurações')),
    );
  }
}

/// Placeholder para página de análise IA
class _AIAnalysisPage extends StatelessWidget {
  const _AIAnalysisPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análise IA')),
      body: const Center(child: Text('Análise com IA')),
    );
  }
}
