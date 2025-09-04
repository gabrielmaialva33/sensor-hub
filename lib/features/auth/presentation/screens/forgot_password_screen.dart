import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_state.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';

/// Forgot password screen with modern glassmorphism design
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  late AnimationController _backgroundController;
  late AnimationController _successController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _successAnimation;
  
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));
    
    _successAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
    
    _backgroundController.repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _successController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      switch (next) {
        case AuthPasswordResetSent():
          setState(() => _emailSent = true);
          _successController.forward();
        case AuthError(:final message):
          _showErrorSnackBar(message);
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppTheme.paddingLG),
                    child: Column(
                      children: [
                        _buildHeader(theme, isDark),
                        const SizedBox(height: AppTheme.paddingXL * 2),
                        if (_emailSent)
                          _buildSuccessContent(theme, isDark)
                        else
                          _buildForgotPasswordForm(theme, isDark),
                        const SizedBox(height: AppTheme.paddingXL),
                        _buildBottomActions(theme, isDark),
                      ],
                    ),
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
        painter: _ForgotPasswordBackgroundPainter(
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
        
        // Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87,
                size: 20,
              ),
            ),
          ),
        ).animate().slideX(
          begin: -0.5,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms),
        
        const SizedBox(height: AppTheme.paddingLG),
        
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
            Icons.lock_reset,
            size: 40,
            color: Colors.white,
          ),
        ).animate().scale(
          duration: 600.ms,
          delay: 200.ms,
          curve: Curves.elasticOut,
        ),
        
        const SizedBox(height: AppTheme.paddingLG),
        
        Text(
          _emailSent ? 'Check Your Email' : 'Forgot Password?',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 300.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 300.ms),
        
        const SizedBox(height: AppTheme.paddingSM),
        
        Text(
          _emailSent
              ? 'We\'ve sent password reset instructions to your email'
              : 'No worries! Enter your email and we\'ll send you reset instructions',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ).animate().slideY(
          begin: 0.3,
          duration: 600.ms,
          delay: 400.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 400.ms),
      ],
    );
  }

  Widget _buildForgotPasswordForm(ThemeData theme, bool isDark) {
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
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your registered email',
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
              ),
              
              const SizedBox(height: AppTheme.paddingXL),
              
              Consumer(
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
                              authNotifier.sendPasswordResetEmail(
                                _emailController.text.trim(),
                              );
                            }
                          },
                    text: 'Send Reset Instructions',
                    variant: AuthButtonVariant.primary,
                    isLoading: isLoading,
                    width: double.infinity,
                  );
                },
              ),
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

  Widget _buildSuccessContent(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _successAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _successAnimation.value,
          child: GlassmorphicContainer(
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
              padding: const EdgeInsets.all(AppTheme.paddingXL),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.successColor,
                          AppTheme.successColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mark_email_read,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.paddingLG),
                  
                  Text(
                    'Email Sent!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.paddingMD),
                  
                  Text(
                    'Check your inbox and follow the instructions to reset your password.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.paddingLG),
                  
                  Text(
                    'Didn\'t receive the email? Check your spam folder or ',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () {
                      setState(() => _emailSent = false);
                      _successController.reset();
                    },
                    child: Text(
                      'try again',
                      style: TextStyle(
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions(ThemeData theme, bool isDark) {
    return Column(
      children: [
        if (!_emailSent) ...[
          Text(
            'Remember your password?',
            style: TextStyle(
              color: isDark 
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
        ],
        
        AuthButton(
          onPressed: () {
            if (_emailSent) {
              Navigator.pushReplacementNamed(context, '/login');
            } else {
              Navigator.pop(context);
            }
          },
          text: _emailSent ? 'Back to Sign In' : 'Back to Sign In',
          variant: AuthButtonVariant.secondary,
          width: double.infinity,
        ),
      ],
    ).animate().slideY(
      begin: 0.3,
      duration: 600.ms,
      delay: 700.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 600.ms, delay: 700.ms);
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
}

class _ForgotPasswordBackgroundPainter extends CustomPainter {
  const _ForgotPasswordBackgroundPainter({
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

    // Draw animated background elements
    _drawCircle(
      canvas,
      Offset(
        size.width * 0.8 + (50 * animationValue),
        size.height * 0.3,
      ),
      60 + (20 * animationValue),
      isDark 
          ? const Color(0xFF6366F1).withValues(alpha: 0.08)
          : const Color(0xFF6366F1).withValues(alpha: 0.04),
      paint,
    );

    _drawCircle(
      canvas,
      Offset(
        size.width * 0.2 - (30 * animationValue),
        size.height * 0.7,
      ),
      80 + (30 * animationValue),
      isDark 
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.06)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.03),
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