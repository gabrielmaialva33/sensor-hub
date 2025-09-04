import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_state.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/social_login_buttons.dart';

/// Modern login screen with glassmorphism design
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _backgroundController;
  late AnimationController _shakeController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
    
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _triggerShake() {
    _shakeController.forward().then((_) {
      _shakeController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      switch (next) {
        case AuthAuthenticated():
          Navigator.pushReplacementNamed(context, '/home');
        case AuthOnboardingRequired():
          Navigator.pushReplacementNamed(context, '/onboarding');
        case AuthProfileSetupRequired():
          Navigator.pushReplacementNamed(context, '/profile-setup');
        case AuthEmailVerificationRequired():
          Navigator.pushNamed(context, '/email-verification');
        case AuthError(:final message):
          _showErrorSnackBar(message);
          _triggerShake();
        case AuthPasswordResetSent(:final email):
          _showSuccessSnackBar('Password reset email sent to $email');
        default:
          break;
      }
    });

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: _buildGradient(isDark),
            ),
            child: Stack(
              children: [
                _buildBackgroundElements(size, isDark),
                SafeArea(
                  child: AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppTheme.paddingLG),
                          child: Column(
                            children: [
                              _buildHeader(theme, isDark),
                              const SizedBox(height: AppTheme.paddingXL),
                              _buildBiometricButton(isDark),
                              const SizedBox(height: AppTheme.paddingLG),
                              _buildLoginForm(theme, isDark),
                              const SizedBox(height: AppTheme.paddingLG),
                              const SocialLoginButtons(isRegistration: false),
                              const SizedBox(height: AppTheme.paddingXL),
                              _buildBottomLinks(theme, isDark),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Gradient _buildGradient(bool isDark) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            const Color(0xFF0F0F23),
            const Color(0xFF1A0B2E),
            _backgroundAnimation.value,
          )!,
          Color.lerp(
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
            _backgroundAnimation.value,
          )!,
          Color.lerp(
            const Color(0xFF533A7B),
            const Color(0xFF6B46C1),
            _backgroundAnimation.value,
          )!,
        ],
      );
    } else {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
            const Color(0xFFF8FAFC),
            const Color(0xFFEDE9FE),
            _backgroundAnimation.value,
          )!,
          Color.lerp(
            const Color(0xFFE0E7FF),
            const Color(0xFFDDD6FE),
            _backgroundAnimation.value,
          )!,
        ],
      );
    }
  }

  Widget _buildBackgroundElements(Size size, bool isDark) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _LoginBackgroundPainter(
          animation: _backgroundAnimation,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
        const SizedBox(height: AppTheme.paddingXL),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.sensors,
            size: 40,
            color: Colors.white,
          ),
        ).animate().scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        
        const SizedBox(height: AppTheme.paddingLG),
        
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 200.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 200.ms),
        
        const SizedBox(height: AppTheme.paddingSM),
        
        Text(
          'Sign in to continue your health journey',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 300.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildBiometricButton(bool isDark) {
    return Consumer(
      builder: (context, ref, child) {
        return FutureBuilder<bool>(
          future: ref.read(biometricAuthAvailableProvider.future),
          builder: (context, availableSnapshot) {
            if (!availableSnapshot.hasData || !availableSnapshot.data!) {
              return const SizedBox.shrink();
            }

            return FutureBuilder<bool>(
              future: ref.read(biometricAuthEnabledProvider.future),
              builder: (context, enabledSnapshot) {
                if (!enabledSnapshot.hasData || !enabledSnapshot.data!) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    final authNotifier = ref.read(authNotifierProvider.notifier);
                    authNotifier.signInWithBiometrics();
                  },
                  child: GlassmorphicContainer(
                    width: 80,
                    height: 80,
                    borderRadius: 40,
                    blur: 15,
                    alignment: Alignment.center,
                    border: 1.5,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
                        Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.3),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    child: Icon(
                      Icons.fingerprint,
                      size: 40,
                      color: const Color(0xFF6366F1),
                    ),
                  ),
                ).animate().scale(
                  duration: 600.ms,
                  delay: 400.ms,
                  curve: Curves.elasticOut,
                ).fadeIn(duration: 600.ms, delay: 400.ms);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoginForm(ThemeData theme, bool isDark) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: null,
      borderRadius: AppTheme.radiusXL,
      blur: 15,
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
          Colors.white.withValues(alpha: 0.3),
          Colors.white.withValues(alpha: 0.1),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLG),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildEmailField(theme, isDark),
              const SizedBox(height: AppTheme.paddingLG),
              _buildPasswordField(theme, isDark),
              const SizedBox(height: AppTheme.paddingMD),
              _buildRememberMeRow(theme, isDark),
              const SizedBox(height: AppTheme.paddingXL),
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 0.3,
      duration: 700.ms,
      delay: 500.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 700.ms, delay: 500.ms);
  }

  Widget _buildEmailField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'Enter your email address',
        prefixIcon: Icon(
          Icons.email_outlined,
          color: isDark 
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.7),
        ),
        hintStyle: TextStyle(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(ThemeData theme, bool isDark) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: Icon(
          Icons.lock_outline,
          color: isDark 
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: isDark 
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: isDark ? 0.05 : 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
          borderSide: const BorderSide(
            color: Color(0xFF6366F1),
            width: 2,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.black.withValues(alpha: 0.7),
        ),
        hintStyle: TextStyle(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.4)
              : Colors.black.withValues(alpha: 0.4),
        ),
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Password is required';
        }
        if (value!.length < 6) {
          return 'Password must be at least 6 characters';
        }
        return null;
      },
    );
  }

  Widget _buildRememberMeRow(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value ?? false);
              },
              activeColor: const Color(0xFF6366F1),
              checkColor: Colors.white,
              side: BorderSide(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.3),
              ),
            ),
            Text(
              'Remember me',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, '/forgot-password');
          },
          child: Text(
            'Forgot Password?',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6366F1),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF6366F1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authNotifierProvider);
        final authNotifier = ref.read(authNotifierProvider.notifier);
        
        final isLoading = authState.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );

        return AuthButton(
          onPressed: isLoading
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    authNotifier.signInWithEmail(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                    );
                  }
                },
          text: 'Sign In',
          variant: AuthButtonVariant.primary,
          isLoading: isLoading,
          width: double.infinity,
        );
      },
    );
  }

  Widget _buildBottomLinks(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Don\'t have an account? ',
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/register');
              },
              child: Text(
                'Sign up',
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
          delay: 800.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 800.ms),
        
        const SizedBox(height: AppTheme.paddingMD),
        
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, '/welcome');
          },
          child: Text(
            'Back to Welcome',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.black.withValues(alpha: 0.5),
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ).animate().fadeIn(
          duration: 600.ms,
          delay: 900.ms,
        ),
      ],
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        margin: const EdgeInsets.all(AppTheme.paddingLG),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        margin: const EdgeInsets.all(AppTheme.paddingLG),
      ),
    );
  }
}

class _LoginBackgroundPainter extends CustomPainter {
  const _LoginBackgroundPainter({
    required this.animation,
    required this.isDark,
  });

  final Animation<double> animation;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);

    final animationValue = animation.value;

    // Draw floating elements
    _drawCircle(
      canvas,
      Offset(
        size.width * 0.9,
        size.height * 0.1 + (50 * animationValue),
      ),
      30 + (10 * animationValue),
      isDark 
          ? const Color(0xFF6366F1).withValues(alpha: 0.1)
          : const Color(0xFF6366F1).withValues(alpha: 0.05),
      paint,
    );

    _drawCircle(
      canvas,
      Offset(
        size.width * 0.1,
        size.height * 0.8 - (30 * animationValue),
      ),
      40 + (15 * animationValue),
      isDark 
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.08)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.04),
      paint,
    );
  }

  void _drawCircle(
    Canvas canvas,
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