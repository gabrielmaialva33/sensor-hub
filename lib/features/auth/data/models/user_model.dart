import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_entity.dart';

/// User model for data layer operations with Supabase
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.displayName,
    super.firstName,
    super.lastName,
    super.avatarUrl,
    super.phoneNumber,
    super.dateOfBirth,
    super.gender,
    super.isEmailVerified,
    super.isPhoneVerified,
    super.subscription,
    super.accountStatus,
    super.createdAt,
    super.lastSignInAt,
    super.onboardingCompleted,
    super.metadata,
  });

  /// Create UserModel from Supabase User
  factory UserModel.fromSupabaseUser(User user) {
    final metadata = user.userMetadata ?? {};
    final appMetadata = user.appMetadata;

    return UserModel(
      id: user.id,
      email: user.email ?? '',
      displayName: metadata['display_name'] as String? ??
          metadata['name'] as String? ??
          metadata['full_name'] as String?,
      firstName: metadata['first_name'] as String?,
      lastName: metadata['last_name'] as String?,
      avatarUrl: metadata['avatar_url'] as String? ?? metadata['picture'] as String?,
      phoneNumber: user.phone,
      isEmailVerified: user.emailConfirmedAt != null,
      isPhoneVerified: user.phoneConfirmedAt != null,
      createdAt: user.createdAt != null 
          ? DateTime.parse(user.createdAt!)
          : null,
      lastSignInAt: user.lastSignInAt != null 
          ? DateTime.parse(user.lastSignInAt!)
          : null,
      metadata: Map<String, dynamic>.from(metadata),
    );
  }

  /// Create UserModel from user profile data
  factory UserModel.fromUserProfile({
    required User supabaseUser,
    required Map<String, dynamic> profileData,
  }) {
    return UserModel(
      id: supabaseUser.id,
      email: supabaseUser.email ?? '',
      displayName: profileData['display_name'] as String?,
      firstName: profileData['first_name'] as String?,
      lastName: profileData['last_name'] as String?,
      avatarUrl: profileData['avatar_url'] as String?,
      phoneNumber: profileData['phone_number'] as String?,
      dateOfBirth: profileData['date_of_birth'] != null
          ? DateTime.parse(profileData['date_of_birth'] as String)
          : null,
      gender: profileData['gender'] != null
          ? Gender.fromString(profileData['gender'] as String)
          : null,
      isEmailVerified: supabaseUser.emailConfirmedAt != null,
      isPhoneVerified: supabaseUser.phoneConfirmedAt != null,
      subscription: profileData['subscription_tier'] != null
          ? SubscriptionTier.fromString(profileData['subscription_tier'] as String)
          : SubscriptionTier.free,
      accountStatus: profileData['account_status'] != null
          ? AccountStatus.fromString(profileData['account_status'] as String)
          : AccountStatus.active,
      createdAt: supabaseUser.createdAt != null
          ? DateTime.parse(supabaseUser.createdAt!)
          : null,
      lastSignInAt: supabaseUser.lastSignInAt != null
          ? DateTime.parse(supabaseUser.lastSignInAt!)
          : null,
      onboardingCompleted: profileData['onboarding_completed'] as bool? ?? false,
      metadata: (profileData['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      gender: json['gender'] != null
          ? Gender.fromString(json['gender'] as String)
          : null,
      isEmailVerified: json['is_email_verified'] as bool? ?? false,
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      subscription: json['subscription'] != null
          ? SubscriptionTier.fromString(json['subscription'] as String)
          : SubscriptionTier.free,
      accountStatus: json['account_status'] != null
          ? AccountStatus.fromString(json['account_status'] as String)
          : AccountStatus.active,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lastSignInAt: json['last_sign_in_at'] != null
          ? DateTime.parse(json['last_sign_in_at'] as String)
          : null,
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender?.name,
      'is_email_verified': isEmailVerified,
      'is_phone_verified': isPhoneVerified,
      'subscription': subscription.name,
      'account_status': accountStatus.name,
      'created_at': createdAt?.toIso8601String(),
      'last_sign_in_at': lastSignInAt?.toIso8601String(),
      'onboarding_completed': onboardingCompleted,
      'metadata': metadata,
    };
  }

  /// Convert to user profile data for database
  Map<String, dynamic> toUserProfileData() {
    return {
      'user_id': id,
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'phone_number': phoneNumber,
      'date_of_birth': dateOfBirth?.toIso8601String()?.split('T').first,
      'gender': gender?.name.replaceAll('nonBinary', 'non-binary').replaceAll('preferNotToSay', 'prefer-not-to-say'),
      'subscription_tier': subscription.name,
      'account_status': accountStatus.name,
      'onboarding_completed': onboardingCompleted,
      'metadata': metadata,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert to user metadata for Supabase auth
  Map<String, dynamic> toAuthMetadata() {
    return {
      'display_name': displayName,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'full_name': fullName,
      ...metadata,
    };
  }

  /// Create copy with updated fields (override from parent)
  @override
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    Gender? gender,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    SubscriptionTier? subscription,
    AccountStatus? accountStatus,
    DateTime? createdAt,
    DateTime? lastSignInAt,
    bool? onboardingCompleted,
    Map<String, dynamic>? metadata,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      subscription: subscription ?? this.subscription,
      accountStatus: accountStatus ?? this.accountStatus,
      createdAt: createdAt ?? this.createdAt,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      isEmailVerified: isEmailVerified,
      isPhoneVerified: isPhoneVerified,
      subscription: subscription,
      accountStatus: accountStatus,
      createdAt: createdAt,
      lastSignInAt: lastSignInAt,
      onboardingCompleted: onboardingCompleted,
      metadata: metadata,
    );
  }
}