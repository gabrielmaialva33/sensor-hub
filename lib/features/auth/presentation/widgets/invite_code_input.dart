import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_providers.dart';

/// Invite code input widget with validation and glassmorphism styling
class InviteCodeInput extends ConsumerStatefulWidget {
  const InviteCodeInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.onValidationChanged,
    this.isRequired = false,
    this.autoFocus = false,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onValidationChanged;
  final bool isRequired;
  final bool autoFocus;

  @override
  ConsumerState<InviteCodeInput> createState() => _InviteCodeInputState();
}

class _InviteCodeInputState extends ConsumerState<InviteCodeInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;
  
  bool _isValidating = false;
  bool? _isValid;
  String? _errorMessage;
  bool _showHelp = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticIn,
    ));

    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    
    if (widget.onChanged != null) {
      widget.onChanged!(text);
    }

    // Reset validation state when text changes
    if (_isValid != null) {
      setState(() {
        _isValid = null;
        _errorMessage = null;
      });
      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(false);
      }
    }

    // Auto-validate when code length reaches 8
    if (text.length == 8) {
      _validateInviteCode();
    }
  }

  Future<void> _validateInviteCode() async {
    final code = widget.controller.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _isValid = null;
        _errorMessage = null;
      });
      return;
    }

    if (code.length < 6) {
      setState(() {
        _isValid = false;
        _errorMessage = 'Invite code must be at least 6 characters';
      });
      _triggerShake();
      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(false);
      }
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      final isValid = await authNotifier.validateInviteCode(code);
      
      setState(() {
        _isValid = isValid;
        _isValidating = false;
        _errorMessage = isValid ? null : 'Invalid or expired invite code';
      });

      if (!isValid) {
        _triggerShake();
      }

      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(isValid);
      }
    } catch (error) {
      setState(() {
        _isValid = false;
        _isValidating = false;
        _errorMessage = 'Failed to validate invite code';
      });
      _triggerShake();
      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(false);
      }
    }
  }

  void _triggerShake() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(theme, isDark),
              const SizedBox(height: AppTheme.paddingSM),
              _buildInputField(theme, isDark),
              if (_errorMessage != null) ...[
                const SizedBox(height: AppTheme.paddingSM),
                _buildErrorMessage(theme),
              ],
              if (_showHelp) ...[
                const SizedBox(height: AppTheme.paddingSM),
                _buildHelpText(theme, isDark),
              ],
            ],
          ),
        );
      },
    ).animate().slideY(
      begin: 0.3,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 400.ms);
  }

  Widget _buildLabel(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Text(
          'Invite Code',
          style: theme.textTheme.labelLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!widget.isRequired) ...[
          const SizedBox(width: AppTheme.paddingSM),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Optional',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.7),
                fontSize: 10,
              ),
            ),
          ),
        ],
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showHelp = !_showHelp),
          child: Icon(
            _showHelp ? Icons.help : Icons.help_outline,
            size: 18,
            color: isDark
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.black.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.05 : 0.8),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: _getBorderColor(isDark),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        autofocus: widget.autoFocus,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          UpperCaseTextFormatter(),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          LengthLimitingTextInputFormatter(12),
        ],
        decoration: InputDecoration(
          hintText: 'Enter invite code (e.g., ABC12345)',
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppTheme.paddingLG),
          suffixIcon: _buildSuffixIcon(isDark),
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isDark) {
    if (_isValidating) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54,
            ),
          ),
        ),
      );
    }

    if (_isValid == true) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        child: Icon(
          Icons.check_circle,
          color: AppTheme.successColor,
          size: 24,
        ),
      );
    }

    if (_isValid == false && widget.controller.text.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.paddingMD),
        child: Icon(
          Icons.error,
          color: AppTheme.errorColor,
          size: 24,
        ),
      );
    }

    return null;
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.error_outline,
          size: 16,
          color: AppTheme.errorColor,
        ),
        const SizedBox(width: AppTheme.paddingSM),
        Expanded(
          child: Text(
            _errorMessage!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.errorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ).animate().slideX(
      begin: -0.2,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 300.ms);
  }

  Widget _buildHelpText(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMD),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Invite Codes',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSM),
          Text(
            '• Invite codes are 6-12 characters long\n'
            '• They may contain letters and numbers\n'
            '• Some codes are single-use, others allow multiple uses\n'
            '• Contact your inviter if the code doesn\'t work',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.black.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    ).animate().slideY(
      begin: -0.2,
      duration: 300.ms,
      curve: Curves.easeOutCubic,
    ).fadeIn(duration: 300.ms);
  }

  Color _getBorderColor(bool isDark) {
    if (_isValid == true) {
      return AppTheme.successColor;
    }
    if (_isValid == false && widget.controller.text.isNotEmpty) {
      return AppTheme.errorColor;
    }
    return isDark
        ? Colors.white.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.1);
  }
}

/// Text input formatter to convert text to uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}