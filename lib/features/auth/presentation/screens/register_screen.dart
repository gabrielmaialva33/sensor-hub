import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/usecases/register_usecase.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_button.dart';
import '../widgets/invite_code_input.dart';
import '../widgets/social_login_buttons.dart';

/// Modern registration screen with invite code validation
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  
  late AnimationController _backgroundController;
  late AnimationController _shakeController;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _shakeAnimation;
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isInviteCodeValid = false;
  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
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
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final registerUseCase = ref.read(registerUseCaseProvider);
    final strength = registerUseCase.checkPasswordStrength(_passwordController.text);
    if (_passwordStrength != strength) {
      setState(() {
        _passwordStrength = strength;
      });
    }
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
                              const SocialLoginButtons(isRegistration: true),
                              const SizedBox(height: AppTheme.paddingLG),
                              _buildRegistrationForm(theme, isDark),
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
        painter: _RegisterBackgroundPainter(
          animation: _backgroundAnimation,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      children: [
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
            Icons.person_add,
            size: 40,
            color: Colors.white,
          ),
        ).animate().scale(
          duration: 600.ms,
          curve: Curves.elasticOut,
        ),
        
        const SizedBox(height: AppTheme.paddingLG),
        
        Text(
          'Create Account',
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
          'Join SensorHub to start tracking your health',
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

  Widget _buildRegistrationForm(ThemeData theme, bool isDark) {
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
              // Invite Code (Optional)
              InviteCodeInput(
                controller: _inviteCodeController,
                onValidationChanged: (isValid) {
                  setState(() {
                    _isInviteCodeValid = isValid;
                  });
                },
              ),
              
              const SizedBox(height: AppTheme.paddingLG),
              
              // Name Fields
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _firstNameController,
                      labelText: 'First Name',
                      hintText: 'Enter first name',
                      prefixIcon: Icons.person_outline,
                      theme: theme,
                      isDark: isDark,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppTheme.paddingMD),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _lastNameController,
                      labelText: 'Last Name',
                      hintText: 'Enter last name',
                      prefixIcon: Icons.person_outline,
                      theme: theme,
                      isDark: isDark,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppTheme.paddingLG),
              
              // Email Field
              _buildTextFormField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                theme: theme,
                isDark: isDark,
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
              
              const SizedBox(height: AppTheme.paddingLG),
              
              // Password Field
              _buildTextFormField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                theme: theme,
                isDark: isDark,
                obscureText: _obscurePassword,
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
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Password is required';
                  }
                  if (value!.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.paddingSM),
              
              // Password Strength Indicator
              _buildPasswordStrengthIndicator(theme, isDark),
              
              const SizedBox(height: AppTheme.paddingLG),
              
              // Confirm Password Field
              _buildTextFormField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Confirm your password',
                prefixIcon: Icons.lock_outline,
                theme: theme,
                isDark: isDark,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    color: isDark 
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: AppTheme.paddingLG),
              
              // Terms and Conditions
              _buildTermsRow(theme, isDark),
              
              const SizedBox(height: AppTheme.paddingXL),
              
              // Register Button
              _buildRegisterButton(),
            ],
          ),
        ),
      ),
    ).animate().slideY(
      begin: 0.3,
      duration: 700.ms,
      delay: 400.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 700.ms, delay: 400.ms);
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required ThemeData theme,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(
          prefixIcon,
          color: isDark 
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6),
        ),
        suffixIcon: suffixIcon,
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
      validator: validator,
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Password strength: ',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            Text(
              _passwordStrength.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getPasswordStrengthColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingSM),
        LinearProgressIndicator(
          value: _passwordStrength.strengthValue,
          backgroundColor: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(_getPasswordStrengthColor()),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.tooShort:
      case PasswordStrength.weak:
        return AppTheme.errorColor;
      case PasswordStrength.medium:
        return AppTheme.warningColor;
      case PasswordStrength.strong:
        return AppTheme.successColor;
    }
  }

  Widget _buildTermsRow(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Checkbox(
          value: _acceptTerms,
          onChanged: (value) {
            setState(() => _acceptTerms = value ?? false);
          },
          activeColor: const Color(0xFF6366F1),
          checkColor: Colors.white,
          side: BorderSide(
            color: isDark 
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.3),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _acceptTerms = !_acceptTerms);
            },
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark 
                      ? Colors.white.withValues(alpha: 0.8)
                      : Colors.black.withValues(alpha: 0.7),
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF6366F1),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: const Color(0xFF6366F1),
                      decoration: TextDecoration.underline,
                      decorationColor: const Color(0xFF6366F1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authNotifierProvider);
        final authNotifier = ref.read(authNotifierProvider.notifier);
        
        final isLoading = authState.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );

        return AuthButton(
          onPressed: isLoading || !_acceptTerms
              ? null
              : () {
                  if (_formKey.currentState?.validate() ?? false) {
                    authNotifier.registerWithEmail(
                      email: _emailController.text.trim(),
                      password: _passwordController.text,
                      confirmPassword: _confirmPasswordController.text,
                      inviteCode: _inviteCodeController.text.trim().isEmpty 
                          ? null 
                          : _inviteCodeController.text.trim(),
                      firstName: _firstNameController.text.trim(),
                      lastName: _lastNameController.text.trim(),
                      displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
                    );
                  }
                },
          text: 'Create Account',
          variant: AuthButtonVariant.primary,
          isLoading: isLoading,
          isEnabled: _acceptTerms,
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
              'Already have an account? ',
              style: TextStyle(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
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
          delay: 700.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 600.ms, delay: 700.ms),
        
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
          delay: 800.ms,
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
}

class _RegisterBackgroundPainter extends CustomPainter {
  const _RegisterBackgroundPainter({
    required this.animation,
    required this.isDark,
  });

  final Animation<double> animation;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    final animationValue = animation.value;

    // Draw multiple floating elements
    _drawCircle(
      canvas,
      Offset(
        size.width * 0.8 + (size.width * 0.1 * animationValue),
        size.height * 0.2,
      ),
      40 + (20 * animationValue),
      isDark 
          ? const Color(0xFF6366F1).withValues(alpha: 0.08)
          : const Color(0xFF6366F1).withValues(alpha: 0.04),
      paint,
    );

    _drawCircle(
      canvas,
      Offset(
        size.width * 0.1 - (size.width * 0.05 * animationValue),
        size.height * 0.5,
      ),
      60 + (30 * animationValue),
      isDark 
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.06)
          : const Color(0xFF8B5CF6).withValues(alpha: 0.03),
      paint,
    );

    _drawCircle(
      canvas,
      Offset(
        size.width * 0.9,
        size.height * 0.8 + (size.width * 0.05 * animationValue),
      ),
      35 + (15 * animationValue),
      isDark 
          ? const Color(0xFFA855F7).withValues(alpha: 0.05)
          : const Color(0xFFA855F7).withValues(alpha: 0.02),
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