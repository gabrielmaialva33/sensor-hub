import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';

/// Beautiful welcome screen with glassmorphism design
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _buildAnimatedGradient(isDark),
            ),
            child: Stack(
              children: [
                _buildAnimatedBackground(size, isDark),
                SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTheme.paddingLG),
                          child: Column(
                            children: [
                              SizedBox(height: size.height * 0.1),
                              _buildLogo(),
                              const SizedBox(height: AppTheme.paddingXL * 2),
                              _buildWelcomeContent(theme, isDark),
                              const SizedBox(height: AppTheme.paddingXL * 2),
                              _buildFeatures(theme, isDark),
                            ],
                          ),
                        ),
                      ),
                      _buildBottomActions(isDark),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Gradient _buildAnimatedGradient(bool isDark) {
    final animationValue = _backgroundAnimation.value;
    
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.3, 0.7, 1.0],
        colors: [
          Color.lerp(
            const Color(0xFF0F0F23),
            const Color(0xFF1A0B2E),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFF533A7B),
            const Color(0xFF6B46C1),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFF7C3AED),
            const Color(0xFF8B5CF6),
            animationValue,
          )!,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: const [0.0, 0.3, 0.7, 1.0],
        colors: [
          Color.lerp(
            const Color(0xFFF8FAFC),
            const Color(0xFFEDE9FE),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFFE0E7FF),
            const Color(0xFFDDD6FE),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFFC4B5FD),
            const Color(0xFFA78BFA),
            animationValue,
          )!,
          Color.lerp(
            const Color(0xFF8B5CF6),
            const Color(0xFF7C3AED),
            animationValue,
          )!,
        ],
      );
    }
  }

  Widget _buildAnimatedBackground(Size size, bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _BackgroundPainter(
          animation: _backgroundAnimation,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFA855F7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: const Icon(
        Icons.sensors,
        size: 60,
        color: Colors.white,
      ),
    ).animate().scale(
      duration: 800.ms,
      delay: 200.ms,
      curve: Curves.elasticOut,
    ).fadeIn(duration: 600.ms);
  }

  Widget _buildWelcomeContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Welcome to\nSensorHub',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            height: 1.2,
            fontSize: 36,
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 400.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(
          duration: 600.ms,
          delay: 400.ms,
        ),
        
        const SizedBox(height: AppTheme.paddingLG),
        
        Text(
          'Your AI-powered comprehensive sensor monitoring companion. Track, analyze, and optimize your health with advanced sensor technology.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.black.withValues(alpha: 0.7),
            height: 1.6,
            fontSize: 16,
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 500.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(
          duration: 600.ms,
          delay: 500.ms,
        ),
      ],
    );
  }

  Widget _buildFeatures(ThemeData theme, bool isDark) {
    final features = [
      {
        'icon': Icons.analytics_outlined,
        'title': 'Real-time Analytics',
        'description': 'Monitor your sensors with live data visualization',
      },
      {
        'icon': Icons.psychology_outlined,
        'title': 'AI Insights',
        'description': 'Get personalized health recommendations',
      },
      {
        'icon': Icons.security_outlined,
        'title': 'Privacy First',
        'description': 'Your data is encrypted and stays secure',
      },
    ];

    return Column(
      children: features.asMap().entries.map((entry) {
        final index = entry.key;
        final feature = entry.value;
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.paddingLG),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: 80,
            borderRadius: AppTheme.radiusLG,
            blur: 10,
            alignment: Alignment.center,
            border: 1.5,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                Colors.white.withValues(alpha: isDark ? 0.1 : 0.1),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLG),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6366F1).withValues(alpha: 0.2),
                          const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: const Color(0xFF6366F1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingMD),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          feature['description'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ).animate().slideX(
          begin: index.isEven ? -0.5 : 0.5,
          duration: 600.ms,
          delay: (600 + index * 100).ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(
          duration: 600.ms,
          delay: (600 + index * 100).ms,
        );
      }).toList(),
    );
  }

  Widget _buildBottomActions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLG),
      child: Column(
        children: [
          AuthButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            text: 'Get Started',
            variant: AuthButtonVariant.primary,
            width: double.infinity,
          ).animate().slideY(
            begin: 0.5,
            duration: 600.ms,
            delay: 1000.ms,
            curve: Curves.easeOutCubic,
          ).fadeIn(
            duration: 600.ms,
            delay: 1000.ms,
          ),
          
          const SizedBox(height: AppTheme.paddingMD),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black.withValues(alpha: 0.7),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  'Sign in',
                  style: TextStyle(
                    color: const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ).animate().slideY(
            begin: 0.3,
            duration: 600.ms,
            delay: 1100.ms,
            curve: Curves.easeOutCubic,
          ).fadeIn(
            duration: 600.ms,
            delay: 1100.ms,
          ),
          
          const SizedBox(height: AppTheme.paddingMD),
          
          GestureDetector(
            onTap: () {
              final authNotifier = ref.read(authNotifierProvider.notifier);
              authNotifier.signInAnonymously();
            },
            child: Text(
              'Continue as Guest',
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ).animate().fadeIn(
            duration: 600.ms,
            delay: 1200.ms,
          ),
        ],
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({
    required this.animation,
    required this.isDark,
  });

  final Animation<double> animation;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    final animationValue = animation.value;

    // Draw animated circles
    _drawAnimatedCircle(
      canvas,
      size,
      Offset(
        size.width * 0.2 + (size.width * 0.1 * animationValue),
        size.height * 0.3,
      ),
      80 + (20 * animationValue),
      isDark 
          ? const Color(0xFF6366F1).withValues(alpha: 0.1)
          : const Color(0xFF6366F1).withValues(alpha: 0.05),
      paint,
    );

    _drawAnimatedCircle(
      canvas,
      size,
      Offset(
        size.width * 0.8 - (size.width * 0.1 * animationValue),
        size.height * 0.7,
      ),
      100 + (30 * animationValue),
      isDark 
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.1)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.05),
      paint,
    );

    _drawAnimatedCircle(
      canvas,
      size,
      Offset(
        size.width * 0.1,
        size.height * 0.8 + (size.height * 0.05 * animationValue),
      ),
      60 + (15 * animationValue),
      isDark 
          ? const Color(0xFFA855F7).withValues(alpha: 0.08)
          : const Color(0xFFA855F7).withValues(alpha: 0.04),
      paint,
    );
  }

  void _drawAnimatedCircle(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
    Color color,
    Paint paint,
  ) {
    paint.color = color;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}