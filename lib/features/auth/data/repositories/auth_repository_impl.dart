import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/logger.dart';
import '../../../../infrastructure/supabase/supabase_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/invite_code.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../models/invite_code_model.dart';

/// Implementation of AuthRepository using Supabase
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required SupabaseService supabaseService,
    required GoogleSignIn googleSignIn,
    required LocalAuthentication localAuth,
  })  : _supabaseService = supabaseService,
        _googleSignIn = googleSignIn,
        _localAuth = localAuth;

  final SupabaseService _supabaseService;
  final GoogleSignIn _googleSignIn;
  final LocalAuthentication _localAuth;

  SupabaseClient get _client => _supabaseService.client;

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Get user profile data
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      return UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();
    } catch (error) {
      Logger.error('Failed to get current user', error);
      // Return basic user info if profile fetch fails
      final user = _client.auth.currentUser;
      if (user != null) {
        return UserModel.fromSupabaseUser(user).toEntity();
      }
      return null;
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _client.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;

      try {
        // Get user profile data
        final profileResponse = await _client
            .from('user_profiles')
            .select()
            .eq('user_id', user.id)
            .single();

        return UserModel.fromUserProfile(
          supabaseUser: user,
          profileData: profileResponse,
        ).toEntity();
      } catch (error) {
        Logger.error('Failed to get user profile in auth stream', error);
        // Return basic user info if profile fetch fails
        return UserModel.fromSupabaseUser(user).toEntity();
      }
    });
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign in failed - no user returned');
      }

      // Update last active timestamp
      await _updateUserActivity(user.id);

      // Get user profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final userEntity = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Email sign in successful for: $email');
      return userEntity;
    } catch (error) {
      Logger.error('Email sign in failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? inviteCode,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Sign up failed - no user returned');
      }

      // User profile is automatically created via database trigger
      // Wait a moment for the trigger to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the created user profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final userEntity = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Email sign up successful for: $email');
      return userEntity;
    } catch (error) {
      Logger.error('Email sign up failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Sign in with Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google tokens');
      }

      // Sign in with Supabase
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Google sign in failed - no user returned');
      }

      // Update last active timestamp
      await _updateUserActivity(user.id);

      // Get user profile (created via trigger if new user)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final userEntity = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Google sign in successful');
      return userEntity;
    } catch (error) {
      Logger.error('Google sign in failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInWithApple() async {
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        throw Exception('Apple sign in is only available on iOS and macOS');
      }

      // Sign in with Apple
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Failed to get Apple ID token');
      }

      // Sign in with Supabase
      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Apple sign in failed - no user returned');
      }

      // Update last active timestamp
      await _updateUserActivity(user.id);

      // Get user profile (created via trigger if new user)
      await Future.delayed(const Duration(milliseconds: 500));
      
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final userEntity = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Apple sign in successful');
      return userEntity;
    } catch (error) {
      Logger.error('Apple sign in failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> signInAnonymously() async {
    try {
      final response = await _client.auth.signInAnonymously();

      final user = response.user;
      if (user == null) {
        throw Exception('Anonymous sign in failed - no user returned');
      }

      // Update last active timestamp
      await _updateUserActivity(user.id);

      final userEntity = UserModel.fromSupabaseUser(user).toEntity();

      Logger.success('Anonymous sign in successful');
      return userEntity;
    } catch (error) {
      Logger.error('Anonymous sign in failed', error);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      Logger.success('Password reset email sent to: $email');
    } catch (error) {
      Logger.error('Failed to send password reset email', error);
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await _client.auth.resend(
        type: OtpType.signup,
        email: user.email,
      );
      
      Logger.success('Email verification sent');
    } catch (error) {
      Logger.error('Failed to send email verification', error);
      rethrow;
    }
  }

  @override
  Future<void> verifyEmail(String token) async {
    try {
      await _client.auth.verifyOTP(
        token: token,
        type: OtpType.signup,
      );
      Logger.success('Email verified successfully');
    } catch (error) {
      Logger.error('Email verification failed', error);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _clearUserCache();
      Logger.success('Sign out successful');
    } catch (error) {
      Logger.error('Sign out failed', error);
      rethrow;
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Delete user data via RPC function (if implemented)
      await _client.rpc('delete_user_account');

      Logger.success('Account deleted successfully');
    } catch (error) {
      Logger.error('Account deletion failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> updateProfile({
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
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Update user metadata
      final updateData = <String, dynamic>{};
      if (displayName != null) updateData['display_name'] = displayName;
      if (firstName != null) updateData['first_name'] = firstName;
      if (lastName != null) updateData['last_name'] = lastName;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (metadata != null) updateData.addAll(metadata);

      if (updateData.isNotEmpty) {
        await _client.auth.updateUser(UserAttributes(data: updateData));
      }

      // Update user profile in database
      final profileUpdateData = <String, dynamic>{};
      if (displayName != null) profileUpdateData['display_name'] = displayName;
      if (firstName != null) profileUpdateData['first_name'] = firstName;
      if (lastName != null) profileUpdateData['last_name'] = lastName;
      if (phoneNumber != null) profileUpdateData['phone_number'] = phoneNumber;
      if (dateOfBirth != null) {
        profileUpdateData['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
      }
      if (gender != null) {
        profileUpdateData['gender'] = gender.name
            .replaceAll('nonBinary', 'non-binary')
            .replaceAll('preferNotToSay', 'prefer-not-to-say');
      }
      if (avatarUrl != null) profileUpdateData['avatar_url'] = avatarUrl;
      if (metadata != null) profileUpdateData['metadata'] = metadata;

      if (profileUpdateData.isNotEmpty) {
        await _client
            .from('user_profiles')
            .update(profileUpdateData)
            .eq('user_id', user.id);
      }

      // Get updated profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final updatedUser = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Profile updated successfully');
      return updatedUser;
    } catch (error) {
      Logger.error('Profile update failed', error);
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    try {
      await _client.auth.updateUser(UserAttributes(email: newEmail));
      Logger.success('Email update initiated');
    } catch (error) {
      Logger.error('Email update failed', error);
      rethrow;
    }
  }

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      Logger.success('Password updated successfully');
    } catch (error) {
      Logger.error('Password update failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> refreshUser() async {
    try {
      final session = await _client.auth.refreshSession();
      final user = session?.user;
      
      if (user == null) {
        throw Exception('No user session');
      }

      // Get user profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final userEntity = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('User refreshed successfully');
      return userEntity;
    } catch (error) {
      Logger.error('User refresh failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> linkGoogleAccount() async {
    try {
      // This would require additional implementation
      throw UnimplementedError('Link Google account not implemented');
    } catch (error) {
      Logger.error('Link Google account failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> linkAppleAccount() async {
    try {
      // This would require additional implementation
      throw UnimplementedError('Link Apple account not implemented');
    } catch (error) {
      Logger.error('Link Apple account failed', error);
      rethrow;
    }
  }

  @override
  Future<void> unlinkAccount(String providerId) async {
    try {
      await _client.auth.unlinkIdentity(Identity(
        id: '',
        userId: '',
        identityId: '',
        provider: providerId,
        createdAt: '',
        lastSignInAt: '',
        updatedAt: '',
      ));
      Logger.success('Account unlinked: $providerId');
    } catch (error) {
      Logger.error('Unlink account failed', error);
      rethrow;
    }
  }

  @override
  Future<List<String>> getLinkedProviders() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      return user.appMetadata['providers'] as List<String>? ?? [];
    } catch (error) {
      Logger.error('Get linked providers failed', error);
      return [];
    }
  }

  @override
  Future<bool> userExistsWithEmail(String email) async {
    try {
      // This would require a custom RPC function
      final result = await _client.rpc('check_user_exists', params: {
        'email_param': email,
      });
      
      return result as bool? ?? false;
    } catch (error) {
      Logger.error('Check user exists failed', error);
      return false;
    }
  }

  @override
  Future<InviteValidationResult> validateInviteCode(String code) async {
    try {
      final result = await _client.rpc('validate_invite_code', params: {
        'invite_code': code,
      });

      return InviteValidationResultModel.fromSupabaseResult(result).toEntity();
    } catch (error) {
      Logger.error('Validate invite code failed', error);
      return InviteValidationResult.invalid('Error validating invite code');
    }
  }

  @override
  Future<void> useInviteCode(String code) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await _client.rpc('use_invite_code', params: {
        'invite_code': code,
        'user_id': user.id,
      });

      Logger.success('Invite code used successfully');
    } catch (error) {
      Logger.error('Use invite code failed', error);
      rethrow;
    }
  }

  @override
  Future<InviteCode> createInviteCode({
    String? email,
    DateTime? expiresAt,
    int maxUses = 1,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final result = await _client.rpc('create_invite_code', params: {
        'p_email': email,
        'p_expires_at': expiresAt?.toIso8601String(),
        'p_max_uses': maxUses,
        'p_metadata': metadata ?? {},
      });

      final data = result.first as Map<String, dynamic>;
      
      // Create and return the invite code
      final inviteCode = InviteCodeModel(
        id: data['invite_id'] as String,
        code: data['invite_code'] as String,
        email: email,
        createdBy: _client.auth.currentUser!.id,
        createdAt: DateTime.now(),
        expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
        maxUses: maxUses,
        currentUses: 0,
        metadata: metadata ?? {},
      );

      Logger.success('Invite code created: ${inviteCode.code}');
      return inviteCode.toEntity();
    } catch (error) {
      Logger.error('Create invite code failed', error);
      rethrow;
    }
  }

  @override
  Future<List<InviteCode>> getMyInviteCodes() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final response = await _client
          .from('invite_codes')
          .select()
          .eq('created_by', user.id)
          .order('created_at', ascending: false);

      final inviteCodes = response
          .map((data) => InviteCodeModel.fromSupabaseRow(data).toEntity())
          .toList();

      Logger.success('Retrieved ${inviteCodes.length} invite codes');
      return inviteCodes;
    } catch (error) {
      Logger.error('Get invite codes failed', error);
      return [];
    }
  }

  @override
  Future<void> enableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_auth_enabled', true);
      Logger.success('Biometric authentication enabled');
    } catch (error) {
      Logger.error('Enable biometric auth failed', error);
      rethrow;
    }
  }

  @override
  Future<void> disableBiometricAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_auth_enabled', false);
      Logger.success('Biometric authentication disabled');
    } catch (error) {
      Logger.error('Disable biometric auth failed', error);
      rethrow;
    }
  }

  @override
  Future<bool> isBiometricAuthAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (error) {
      Logger.error('Check biometric availability failed', error);
      return false;
    }
  }

  @override
  Future<bool> isBiometricAuthEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('biometric_auth_enabled') ?? false;
    } catch (error) {
      Logger.error('Check biometric enabled failed', error);
      return false;
    }
  }

  @override
  Future<UserEntity> signInWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access your SensorHub account',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!isAuthenticated) {
        throw Exception('Biometric authentication failed');
      }

      // Get current user (should already be signed in)
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user session found');
      }

      Logger.success('Biometric authentication successful');
      return currentUser;
    } catch (error) {
      Logger.error('Biometric sign in failed', error);
      rethrow;
    }
  }

  @override
  Future<UserEntity> completeOnboarding({
    required Map<String, dynamic> onboardingData,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      // Update user profile with onboarding data
      await _client
          .from('user_profiles')
          .update({
        ...onboardingData,
        'onboarding_completed': true,
        'onboarding_completed_at': DateTime.now().toIso8601String(),
      })
          .eq('user_id', user.id);

      // Create default health goals
      await _client.rpc('create_default_health_goals', params: {
        'p_user_id': user.id,
      });

      // Get updated profile
      final profileResponse = await _client
          .from('user_profiles')
          .select()
          .eq('user_id', user.id)
          .single();

      final updatedUser = UserModel.fromUserProfile(
        supabaseUser: user,
        profileData: profileResponse,
      ).toEntity();

      Logger.success('Onboarding completed successfully');
      return updatedUser;
    } catch (error) {
      Logger.error('Complete onboarding failed', error);
      rethrow;
    }
  }

  @override
  Future<void> updateNotificationPreferences({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? marketingEmails,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final updateData = <String, dynamic>{};
      if (pushNotifications != null) {
        updateData['push_notifications_enabled'] = pushNotifications;
      }
      if (marketingEmails != null) {
        updateData['marketing_emails_enabled'] = marketingEmails;
      }

      if (updateData.isNotEmpty) {
        await _client
            .from('user_profiles')
            .update(updateData)
            .eq('user_id', user.id);
      }

      Logger.success('Notification preferences updated');
    } catch (error) {
      Logger.error('Update notification preferences failed', error);
      rethrow;
    }
  }

  @override
  Future<void> updatePrivacySettings({
    bool? dataSharing,
    bool? analytics,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      final updateData = <String, dynamic>{};
      if (dataSharing != null) {
        updateData['data_sharing_enabled'] = dataSharing;
      }
      if (analytics != null) {
        updateData['analytics_enabled'] = analytics;
      }

      if (updateData.isNotEmpty) {
        await _client
            .from('user_profiles')
            .update(updateData)
            .eq('user_id', user.id);
      }

      Logger.success('Privacy settings updated');
    } catch (error) {
      Logger.error('Update privacy settings failed', error);
      rethrow;
    }
  }

  @override
  Future<SubscriptionTier> getSubscriptionTier() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return SubscriptionTier.free;
      }

      final response = await _client
          .from('user_profiles')
          .select('subscription_tier')
          .eq('user_id', user.id)
          .single();

      final tierString = response['subscription_tier'] as String? ?? 'free';
      return SubscriptionTier.fromString(tierString);
    } catch (error) {
      Logger.error('Get subscription tier failed', error);
      return SubscriptionTier.free;
    }
  }

  @override
  Future<void> updateSubscriptionTier(SubscriptionTier tier) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await _client
          .from('user_profiles')
          .update({
        'subscription_tier': tier.name,
        'subscription_expires_at': tier == SubscriptionTier.free
            ? null
            : DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      })
          .eq('user_id', user.id);

      Logger.success('Subscription tier updated to: ${tier.name}');
    } catch (error) {
      Logger.error('Update subscription tier failed', error);
      rethrow;
    }
  }

  @override
  void reportAuthError(String operation, dynamic error) {
    Logger.error('Auth operation failed: $operation', error);
    // Here you could send error reports to analytics service
  }

  @override
  Future<void> clearUserCache() async {
    await _clearUserCache();
  }

  // Helper methods

  Future<void> _updateUserActivity(String userId) async {
    try {
      await _client.rpc('update_user_activity', params: {
        'p_user_id': userId,
      });
    } catch (error) {
      Logger.warning('Failed to update user activity', error);
    }
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_data');
      Logger.success('User cache cleared');
    } catch (error) {
      Logger.error('Clear user cache failed', error);
    }
  }
}