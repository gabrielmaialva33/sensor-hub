import 'package:equatable/equatable.dart';
import 'user_entity.dart';

/// Authentication state representing the current auth status
sealed class AuthState extends Equatable {
  const AuthState();
}

/// Initial authentication state - checking if user is signed in
class AuthInitial extends AuthState {
  const AuthInitial();

  @override
  List<Object?> get props => [];
}

/// Loading authentication operation
class AuthLoading extends AuthState {
  const AuthLoading();

  @override
  List<Object?> get props => [];
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.user,
    this.isFirstTime = false,
  });

  /// Authenticated user
  final UserEntity user;

  /// Whether this is the user's first time signing in
  final bool isFirstTime;

  @override
  List<Object?> get props => [user, isFirstTime];
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();

  @override
  List<Object?> get props => [];
}

/// Authentication error occurred
class AuthError extends AuthState {
  const AuthError({
    required this.message,
    this.code,
    this.details,
  });

  /// Error message
  final String message;

  /// Error code (if available)
  final String? code;

  /// Additional error details
  final Map<String, dynamic>? details;

  @override
  List<Object?> get props => [message, code, details];
}

/// Specific authentication states for different scenarios

/// Email verification required
class AuthEmailVerificationRequired extends AuthState {
  const AuthEmailVerificationRequired({
    required this.email,
  });

  /// Email that needs verification
  final String email;

  @override
  List<Object?> get props => [email];
}

/// Password reset email sent
class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent({
    required this.email,
  });

  /// Email where reset link was sent
  final String email;

  @override
  List<Object?> get props => [email];
}

/// User profile needs setup (after successful auth but incomplete profile)
class AuthProfileSetupRequired extends AuthState {
  const AuthProfileSetupRequired({
    required this.user,
  });

  /// User with incomplete profile
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

/// Onboarding required for new user
class AuthOnboardingRequired extends AuthState {
  const AuthOnboardingRequired({
    required this.user,
  });

  /// New user who needs onboarding
  final UserEntity user;

  @override
  List<Object?> get props => [user];
}