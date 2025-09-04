import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../infrastructure/supabase/supabase_service.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_notifier.dart';

/// Provider for SupabaseService
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// Provider for GoogleSignIn
final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
});

/// Provider for LocalAuthentication (biometrics)
final localAuthProvider = Provider<LocalAuthentication>((ref) {
  return LocalAuthentication();
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    supabaseService: ref.read(supabaseServiceProvider),
    googleSignIn: ref.read(googleSignInProvider),
    localAuth: ref.read(localAuthProvider),
  );
});

/// Provider for LoginUseCase
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.read(authRepositoryProvider));
});

/// Provider for RegisterUseCase
final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.read(authRepositoryProvider));
});

/// Provider for current user
final currentUserProvider = StreamProvider((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for authentication state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    authRepository: ref.read(authRepositoryProvider),
    loginUseCase: ref.read(loginUseCaseProvider),
    registerUseCase: ref.read(registerUseCaseProvider),
  );
});

/// Provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState is AuthAuthenticated;
});

/// Provider for checking if user needs onboarding
final needsOnboardingProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.needsOnboarding;
  }
  return false;
});

/// Provider for checking if biometric auth is available
final biometricAuthAvailableProvider = FutureProvider<bool>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.isBiometricAuthAvailable();
});

/// Provider for checking if biometric auth is enabled
final biometricAuthEnabledProvider = FutureProvider<bool>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.isBiometricAuthEnabled();
});

/// Provider for user subscription tier
final subscriptionTierProvider = FutureProvider((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getSubscriptionTier();
});

/// Provider for checking if user is premium
final isPremiumUserProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.user.isPremium;
  }
  return false;
});

/// Provider for user's invite codes
final userInviteCodesProvider = FutureProvider((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getMyInviteCodes();
});

/// Provider for user's linked providers
final linkedProvidersProvider = FutureProvider<List<String>>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  return await authRepository.getLinkedProviders();
});