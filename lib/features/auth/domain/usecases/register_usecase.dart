import '../entities/user_entity.dart';
import '../entities/invite_code.dart';
import '../repositories/auth_repository.dart';

/// Use case for user registration operations
class RegisterUseCase {
  const RegisterUseCase(this._authRepository);

  final AuthRepository _authRepository;

  /// Register with email and password
  Future<RegisterResult> registerWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
    String? inviteCode,
    String? firstName,
    String? lastName,
    String? displayName,
  }) async {
    try {
      // Validate input
      final validation = _validateRegistrationInput(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      
      if (!validation.isValid) {
        return RegisterResult.failure(validation.errorMessage!);
      }

      // Validate invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        final inviteValidation = await _authRepository.validateInviteCode(inviteCode);
        if (!inviteValidation.isValid) {
          return RegisterResult.failure(inviteValidation.errorMessage!);
        }
      }

      // Check if user already exists
      final userExists = await _authRepository.userExistsWithEmail(email);
      if (userExists) {
        return RegisterResult.failure('An account already exists with this email');
      }

      // Create account
      final user = await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        inviteCode: inviteCode,
        metadata: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
          if (displayName != null) 'displayName': displayName,
          'registrationMethod': 'email',
          'registrationTimestamp': DateTime.now().toIso8601String(),
        },
      );

      // Use invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await _authRepository.useInviteCode(inviteCode);
      }

      return RegisterResult.success(user);
    } catch (error) {
      _authRepository.reportAuthError('registerWithEmail', error);
      return RegisterResult.failure(_getErrorMessage(error));
    }
  }

  /// Register with Google
  Future<RegisterResult> registerWithGoogle({
    String? inviteCode,
  }) async {
    try {
      // Validate invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        final inviteValidation = await _authRepository.validateInviteCode(inviteCode);
        if (!inviteValidation.isValid) {
          return RegisterResult.failure(inviteValidation.errorMessage!);
        }
      }

      final user = await _authRepository.signInWithGoogle();

      // Use invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await _authRepository.useInviteCode(inviteCode);
      }

      return RegisterResult.success(user);
    } catch (error) {
      _authRepository.reportAuthError('registerWithGoogle', error);
      return RegisterResult.failure(_getErrorMessage(error));
    }
  }

  /// Register with Apple
  Future<RegisterResult> registerWithApple({
    String? inviteCode,
  }) async {
    try {
      // Validate invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        final inviteValidation = await _authRepository.validateInviteCode(inviteCode);
        if (!inviteValidation.isValid) {
          return RegisterResult.failure(inviteValidation.errorMessage!);
        }
      }

      final user = await _authRepository.signInWithApple();

      // Use invite code if provided
      if (inviteCode != null && inviteCode.isNotEmpty) {
        await _authRepository.useInviteCode(inviteCode);
      }

      return RegisterResult.success(user);
    } catch (error) {
      _authRepository.reportAuthError('registerWithApple', error);
      return RegisterResult.failure(_getErrorMessage(error));
    }
  }

  /// Validate invite code
  Future<InviteValidationResult> validateInviteCode(String code) async {
    try {
      if (code.isEmpty) {
        return InviteValidationResult.invalid('Invite code is required');
      }

      if (code.length < 6) {
        return InviteValidationResult.invalid('Invalid invite code format');
      }

      return await _authRepository.validateInviteCode(code);
    } catch (error) {
      _authRepository.reportAuthError('validateInviteCode', error);
      return InviteValidationResult.invalid('Error validating invite code');
    }
  }

  /// Check password strength
  PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) {
      return PasswordStrength.tooShort;
    }
    
    if (password.length < 8) {
      return PasswordStrength.weak;
    }

    bool hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowerCase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int strengthScore = 0;
    if (hasUpperCase) strengthScore++;
    if (hasLowerCase) strengthScore++;
    if (hasDigits) strengthScore++;
    if (hasSpecialChars) strengthScore++;

    if (password.length >= 12 && strengthScore >= 3) {
      return PasswordStrength.strong;
    }
    
    if (password.length >= 8 && strengthScore >= 2) {
      return PasswordStrength.medium;
    }
    
    return PasswordStrength.weak;
  }

  /// Validate registration input
  ValidationResult _validateRegistrationInput({
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    if (email.isEmpty) {
      return ValidationResult.invalid('Email is required');
    }

    if (!_isValidEmail(email)) {
      return ValidationResult.invalid('Invalid email format');
    }

    if (password.isEmpty) {
      return ValidationResult.invalid('Password is required');
    }

    if (password.length < 6) {
      return ValidationResult.invalid('Password must be at least 6 characters');
    }

    if (password != confirmPassword) {
      return ValidationResult.invalid('Passwords do not match');
    }

    final passwordStrength = checkPasswordStrength(password);
    if (passwordStrength == PasswordStrength.tooShort) {
      return ValidationResult.invalid('Password is too short');
    }

    return ValidationResult.valid();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('email-already-in-use')) {
      return 'An account already exists with this email';
    }
    
    if (errorString.contains('invalid-email')) {
      return 'Invalid email format';
    }
    
    if (errorString.contains('weak-password')) {
      return 'Password is too weak. Please choose a stronger password';
    }
    
    if (errorString.contains('too-many-requests')) {
      return 'Too many requests. Please try again later';
    }
    
    if (errorString.contains('network')) {
      return 'Network error. Please check your connection';
    }
    
    if (errorString.contains('cancelled')) {
      return 'Registration was cancelled';
    }

    if (errorString.contains('invalid-credential')) {
      return 'Invalid registration credentials';
    }

    // Default error message
    return 'An error occurred during registration. Please try again';
  }
}

/// Result of registration operation
sealed class RegisterResult {
  const RegisterResult();

  /// Successful registration
  factory RegisterResult.success(UserEntity user) = RegisterSuccess;

  /// Failed registration
  factory RegisterResult.failure(String message) = RegisterFailure;
}

/// Successful registration result
class RegisterSuccess extends RegisterResult {
  const RegisterSuccess(this.user);

  final UserEntity user;
}

/// Failed registration result
class RegisterFailure extends RegisterResult {
  const RegisterFailure(this.message);

  final String message;
}

/// Validation result
class ValidationResult {
  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  factory ValidationResult.valid() {
    return const ValidationResult._(isValid: true);
  }

  factory ValidationResult.invalid(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
}

/// Password strength levels
enum PasswordStrength {
  tooShort,
  weak,
  medium,
  strong;

  String get description {
    switch (this) {
      case PasswordStrength.tooShort:
        return 'Too short';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  double get strengthValue {
    switch (this) {
      case PasswordStrength.tooShort:
        return 0.0;
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 1.0;
    }
  }
}