import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import 'auth_button.dart';

/// Social login buttons for Google and Apple authentication
class SocialLoginButtons extends ConsumerWidget {
  const SocialLoginButtons({
    super.key,
    this.onGoogleSignIn,
    this.onAppleSignIn,
    this.isRegistration = false,
  });

  final VoidCallback? onGoogleSignIn;
  final VoidCallback? onAppleSignIn;
  final bool isRegistration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isLoading = authState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Column(
      children: [
        // Google Sign In
        AuthButton(
          onPressed: isLoading
              ? null
              : () {
                  if (onGoogleSignIn != null) {
                    onGoogleSignIn!();
                  } else if (isRegistration) {
                    authNotifier.registerWithGoogle();
                  } else {
                    authNotifier.signInWithGoogle();
                  }
                },
          text: isRegistration 
              ? 'Continue with Google'
              : 'Sign in with Google',
          variant: AuthButtonVariant.secondary,
          isLoading: isLoading,
          icon: _GoogleIcon(isDark: isDark),
        ).animate().slideX(
          begin: -0.5,
          duration: 500.ms,
          delay: 100.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(
          duration: 500.ms,
          delay: 100.ms,
        ),

        const SizedBox(height: AppTheme.paddingMD),

        // Apple Sign In (iOS/macOS only)
        if (Platform.isIOS || Platform.isMacOS)
          AuthButton(
            onPressed: isLoading
                ? null
                : () {
                    if (onAppleSignIn != null) {
                      onAppleSignIn!();
                    } else if (isRegistration) {
                      authNotifier.registerWithApple();
                    } else {
                      authNotifier.signInWithApple();
                    }
                  },
            text: isRegistration 
                ? 'Continue with Apple'
                : 'Sign in with Apple',
            variant: AuthButtonVariant.glass,
            isLoading: isLoading,
            icon: _AppleIcon(isDark: isDark),
          ).animate().slideX(
            begin: 0.5,
            duration: 500.ms,
            delay: 200.ms,
            curve: Curves.easeOutCubic,
          ).fadeIn(
            duration: 500.ms,
            delay: 200.ms,
          ),

        if (Platform.isIOS || Platform.isMacOS)
          const SizedBox(height: AppTheme.paddingLG),

        // Divider
        _buildDivider(context, isDark).animate().fadeIn(
          duration: 400.ms,
          delay: 300.ms,
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.paddingLG),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLG),
            child: Text(
              'or',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/icons/google_logo.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.apple,
      size: 20,
      color: isDark ? Colors.white : Colors.black,
    );
  }
}