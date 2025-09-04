import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

/// Authentication state notifier managing auth state and operations
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({
    required AuthRepository authRepository,
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  })  : _authRepository = authRepository,
        _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        super(const AuthInitial()) {
    _initialize();
  }

  final AuthRepository _authRepository;
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;

  StreamSubscription<UserEntity?>? _authSubscription;

  /// Initialize authentication state
  void _initialize() async {
    try {
      // Check current user
      final currentUser = await _authRepository.getCurrentUser();
      
      if (currentUser != null) {
        _handleUserAuthenticated(currentUser);
      } else {
        state = const AuthUnauthenticated();
      }

      // Listen to auth state changes
      _authSubscription = _authRepository.authStateChanges.listen(
        (user) {
          if (user != null) {
            _handleUserAuthenticated(user);
          } else {
            state = const AuthUnauthenticated();
          }
        },
        onError: (error) {
          Logger.error('Auth state stream error', error);
          state = AuthError(message: 'Authentication error occurred');
        },
      );
    } catch (error) {
      Logger.error('Auth initialization failed', error);
      state = AuthError(message: 'Failed to initialize authentication');
    }
  }

  /// Handle user authenticated state
  void _handleUserAuthenticated(UserEntity user) {
    if (user.needsOnboarding) {
      state = AuthOnboardingRequired(user: user);
    } else if (!user.isProfileComplete) {
      state = AuthProfileSetupRequired(user: user);
    } else if (!user.isEmailVerified && user.email.isNotEmpty) {
      state = AuthEmailVerificationRequired(email: user.email);
    } else {
      state = AuthAuthenticated(user: user);
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _loginUseCase.signInWithEmail(
        email: email,
        password: password,
      );
      
      switch (result) {
        case LoginSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Email sign in successful');
          
        case LoginFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Email sign in error', error);
      state = AuthError(message: 'An unexpected error occurred');
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _loginUseCase.signInWithGoogle();
      
      switch (result) {
        case LoginSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Google sign in successful');
          
        case LoginFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Google sign in error', error);
      state = AuthError(message: 'Google sign in failed');
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _loginUseCase.signInWithApple();
      
      switch (result) {
        case LoginSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Apple sign in successful');
          
        case LoginFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Apple sign in error', error);
      state = AuthError(message: 'Apple sign in failed');
    }
  }

  /// Sign in with biometrics
  Future<void> signInWithBiometrics() async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _loginUseCase.signInWithBiometrics();
      
      switch (result) {
        case LoginSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Biometric sign in successful');
          
        case LoginFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Biometric sign in error', error);
      state = AuthError(message: 'Biometric authentication failed');
    }
  }

  /// Sign in anonymously (guest mode)
  Future<void> signInAnonymously() async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _loginUseCase.signInAnonymously();
      
      switch (result) {
        case LoginSuccess(user: final user):
          state = AuthAuthenticated(user: user);
          Logger.success('Anonymous sign in successful');
          
        case LoginFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Anonymous sign in error', error);
      state = AuthError(message: 'Anonymous sign in failed');
    }
  }

  /// Register with email and password
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String confirmPassword,
    String? inviteCode,
    String? firstName,
    String? lastName,
    String? displayName,
  }) async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _registerUseCase.registerWithEmail(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        inviteCode: inviteCode,
        firstName: firstName,
        lastName: lastName,
        displayName: displayName,
      );
      
      switch (result) {
        case RegisterSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Email registration successful');
          
        case RegisterFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Email registration error', error);
      state = AuthError(message: 'Registration failed');
    }
  }

  /// Register with Google
  Future<void> registerWithGoogle({String? inviteCode}) async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _registerUseCase.registerWithGoogle(
        inviteCode: inviteCode,
      );
      
      switch (result) {
        case RegisterSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Google registration successful');
          
        case RegisterFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Google registration error', error);
      state = AuthError(message: 'Google registration failed');
    }
  }

  /// Register with Apple
  Future<void> registerWithApple({String? inviteCode}) async {
    if (state is AuthLoading) return;
    
    state = const AuthLoading();
    
    try {
      final result = await _registerUseCase.registerWithApple(
        inviteCode: inviteCode,
      );
      
      switch (result) {
        case RegisterSuccess(user: final user):
          _handleUserAuthenticated(user);
          Logger.success('Apple registration successful');
          
        case RegisterFailure(message: final message):
          state = AuthError(message: message);
      }
    } catch (error) {
      Logger.error('Apple registration error', error);
      state = AuthError(message: 'Apple registration failed');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = AuthPasswordResetSent(email: email);
      Logger.success('Password reset email sent');
    } catch (error) {
      Logger.error('Send password reset error', error);
      state = AuthError(message: 'Failed to send password reset email');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await _authRepository.sendEmailVerification();
      Logger.success('Email verification sent');
      
      // Update state to show verification required
      if (state is AuthAuthenticated) {
        final user = (state as AuthAuthenticated).user;
        state = AuthEmailVerificationRequired(email: user.email);
      }
    } catch (error) {
      Logger.error('Send email verification error', error);
      state = AuthError(message: 'Failed to send email verification');
    }
  }

  /// Verify email with token
  Future<void> verifyEmail(String token) async {
    try {
      await _authRepository.verifyEmail(token);
      
      // Refresh user to get updated verification status
      final user = await _authRepository.refreshUser();
      _handleUserAuthenticated(user);
      
      Logger.success('Email verified successfully');
    } catch (error) {
      Logger.error('Email verification error', error);
      state = AuthError(message: 'Email verification failed');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    Gender? gender,
    String? avatarUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updatedUser = await _authRepository.updateProfile(
        displayName: displayName,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        avatarUrl: avatarUrl,
        metadata: metadata,
      );
      
      _handleUserAuthenticated(updatedUser);
      Logger.success('Profile updated successfully');
    } catch (error) {
      Logger.error('Profile update error', error);
      state = AuthError(message: 'Failed to update profile');
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding({
    required Map<String, dynamic> onboardingData,
  }) async {
    if (state is! AuthOnboardingRequired) return;
    
    try {
      final updatedUser = await _authRepository.completeOnboarding(
        onboardingData: onboardingData,
      );
      
      _handleUserAuthenticated(updatedUser);
      Logger.success('Onboarding completed');
    } catch (error) {
      Logger.error('Complete onboarding error', error);
      state = AuthError(message: 'Failed to complete onboarding');
    }
  }

  /// Validate invite code
  Future<bool> validateInviteCode(String code) async {
    try {
      final result = await _registerUseCase.validateInviteCode(code);
      return result.isValid;
    } catch (error) {
      Logger.error('Validate invite code error', error);
      return false;
    }
  }

  /// Enable biometric authentication
  Future<void> enableBiometricAuth() async {
    try {
      await _authRepository.enableBiometricAuth();
      Logger.success('Biometric authentication enabled');
    } catch (error) {
      Logger.error('Enable biometric auth error', error);
      state = AuthError(message: 'Failed to enable biometric authentication');
    }
  }

  /// Disable biometric authentication
  Future<void> disableBiometricAuth() async {
    try {
      await _authRepository.disableBiometricAuth();
      Logger.success('Biometric authentication disabled');
    } catch (error) {
      Logger.error('Disable biometric auth error', error);
      state = AuthError(message: 'Failed to disable biometric authentication');
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreferences({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? marketingEmails,
  }) async {
    try {
      await _authRepository.updateNotificationPreferences(
        pushNotifications: pushNotifications,
        emailNotifications: emailNotifications,
        marketingEmails: marketingEmails,
      );
      Logger.success('Notification preferences updated');
    } catch (error) {
      Logger.error('Update notification preferences error', error);
      state = AuthError(message: 'Failed to update notification preferences');
    }
  }

  /// Update privacy settings
  Future<void> updatePrivacySettings({
    bool? dataSharing,
    bool? analytics,
  }) async {
    try {
      await _authRepository.updatePrivacySettings(
        dataSharing: dataSharing,
        analytics: analytics,
      );
      Logger.success('Privacy settings updated');
    } catch (error) {
      Logger.error('Update privacy settings error', error);
      state = AuthError(message: 'Failed to update privacy settings');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      state = const AuthUnauthenticated();
      Logger.success('Sign out successful');
    } catch (error) {
      Logger.error('Sign out error', error);
      state = AuthError(message: 'Sign out failed');
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      await _authRepository.deleteAccount();
      state = const AuthUnauthenticated();
      Logger.success('Account deleted');
    } catch (error) {
      Logger.error('Delete account error', error);
      state = AuthError(message: 'Failed to delete account');
    }
  }

  /// Clear error state
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }

  /// Refresh current user
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.refreshUser();
      _handleUserAuthenticated(user);
      Logger.success('User refreshed');
    } catch (error) {
      Logger.error('Refresh user error', error);
      state = AuthError(message: 'Failed to refresh user data');
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}