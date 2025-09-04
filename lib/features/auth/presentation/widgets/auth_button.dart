import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';

/// Modern authentication button with glassmorphism effect
class AuthButton extends StatefulWidget {
  const AuthButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.isEnabled = true,
    this.variant = AuthButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 54,
  });

  final VoidCallback? onPressed;
  final String text;
  final bool isLoading;
  final bool isEnabled;
  final AuthButtonVariant variant;
  final Widget? icon;
  final double? width;
  final double height;

  @override
  State<AuthButton> createState() => _AuthButtonState();
}

class _AuthButtonState extends State<AuthButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: widget.isEnabled && !widget.isLoading
                ? widget.onPressed
                : null,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                gradient: _getGradient(isDark),
                borderRadius: BorderRadius.circular(AppTheme.radiusLG),
                boxShadow: widget.isEnabled && !widget.isLoading
                    ? _getShadow(isDark)
                    : null,
                border: _getBorder(isDark),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingLG,
                    vertical: AppTheme.paddingMD,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: AppTheme.paddingSM),
                      ],
                      if (widget.isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getTextColor(isDark),
                            ),
                          ),
                        )
                      else
                        Text(
                          widget.text,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: _getTextColor(isDark),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ).animate().slideY(
      begin: 0.5,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 400.ms);
  }

  Gradient _getGradient(bool isDark) {
    switch (widget.variant) {
      case AuthButtonVariant.primary:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isEnabled && !widget.isLoading
              ? [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFFA855F7),
                ]
              : [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
        );
      case AuthButtonVariant.secondary:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isEnabled && !widget.isLoading
              ? isDark
                  ? [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ]
                  : [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.02),
                    ]
              : [
                  Colors.grey.shade300,
                  Colors.grey.shade200,
                ],
        );
      case AuthButtonVariant.glass:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
            Colors.white.withValues(alpha: isDark ? 0.05 : 0.1),
          ],
        );
      case AuthButtonVariant.danger:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isEnabled && !widget.isLoading
              ? [
                  const Color(0xFFEF4444),
                  const Color(0xFFDC2626),
                ]
              : [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                ],
        );
    }
  }

  List<BoxShadow> _getShadow(bool isDark) {
    if (!widget.isEnabled || widget.isLoading) return [];

    switch (widget.variant) {
      case AuthButtonVariant.primary:
        return [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ];
      case AuthButtonVariant.secondary:
      case AuthButtonVariant.glass:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ];
      case AuthButtonVariant.danger:
        return [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ];
    }
  }

  Border? _getBorder(bool isDark) {
    switch (widget.variant) {
      case AuthButtonVariant.secondary:
        return Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        );
      case AuthButtonVariant.glass:
        return Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
          width: 1,
        );
      case AuthButtonVariant.primary:
      case AuthButtonVariant.danger:
        return null;
    }
  }

  Color _getTextColor(bool isDark) {
    switch (widget.variant) {
      case AuthButtonVariant.primary:
      case AuthButtonVariant.danger:
        return Colors.white;
      case AuthButtonVariant.secondary:
        return isDark ? Colors.white : Colors.black;
      case AuthButtonVariant.glass:
        return isDark ? Colors.white : Colors.black87;
    }
  }
}

/// Authentication button variants
enum AuthButtonVariant {
  primary,
  secondary,
  glass,
  danger,
}