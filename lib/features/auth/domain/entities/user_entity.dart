import 'package:equatable/equatable.dart';

/// User entity representing authenticated user information
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.gender,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.subscription = SubscriptionTier.free,
    this.accountStatus = AccountStatus.active,
    this.createdAt,
    this.lastSignInAt,
    this.onboardingCompleted = false,
    this.metadata = const {},
  });

  /// Unique user identifier
  final String id;

  /// User's email address
  final String email;

  /// Display name shown in the app
  final String? displayName;

  /// User's first name
  final String? firstName;

  /// User's last name  
  final String? lastName;

  /// Profile avatar URL
  final String? avatarUrl;

  /// Phone number
  final String? phoneNumber;

  /// Date of birth
  final DateTime? dateOfBirth;

  /// User's gender
  final Gender? gender;

  /// Whether email is verified
  final bool isEmailVerified;

  /// Whether phone is verified
  final bool isPhoneVerified;

  /// Subscription tier
  final SubscriptionTier subscription;

  /// Account status
  final AccountStatus accountStatus;

  /// Account creation timestamp
  final DateTime? createdAt;

  /// Last sign in timestamp
  final DateTime? lastSignInAt;

  /// Whether onboarding is completed
  final bool onboardingCompleted;

  /// Additional user metadata
  final Map<String, dynamic> metadata;

  /// Get full name from first and last name
  String? get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName;
  }

  /// Get display name with fallback to full name or email
  String get displayNameOrFallback {
    return displayName ?? fullName ?? email.split('@').first;
  }

  /// Check if profile is complete
  bool get isProfileComplete {
    return displayName != null &&
           firstName != null &&
           lastName != null &&
           dateOfBirth != null &&
           gender != null;
  }

  /// Check if user is premium
  bool get isPremium => subscription != SubscriptionTier.free;

  /// Check if account is active
  bool get isActive => accountStatus == AccountStatus.active;

  /// Check if user needs onboarding
  bool get needsOnboarding => !onboardingCompleted;

  /// Create copy with updated fields
  UserEntity copyWith({
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
    return UserEntity(
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

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        firstName,
        lastName,
        avatarUrl,
        phoneNumber,
        dateOfBirth,
        gender,
        isEmailVerified,
        isPhoneVerified,
        subscription,
        accountStatus,
        createdAt,
        lastSignInAt,
        onboardingCompleted,
        metadata,
      ];
}

/// Gender enumeration
enum Gender {
  male,
  female,
  nonBinary,
  preferNotToSay;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.nonBinary:
        return 'Non-binary';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  static Gender fromString(String value) {
    switch (value.toLowerCase()) {
      case 'male':
        return Gender.male;
      case 'female':
        return Gender.female;
      case 'non-binary':
      case 'nonbinary':
        return Gender.nonBinary;
      case 'prefer-not-to-say':
      case 'prefernottosay':
        return Gender.preferNotToSay;
      default:
        throw ArgumentError('Invalid gender value: $value');
    }
  }
}

/// Subscription tier enumeration
enum SubscriptionTier {
  free,
  premium,
  pro;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.pro:
        return 'Pro';
    }
  }

  static SubscriptionTier fromString(String value) {
    switch (value.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'premium':
        return SubscriptionTier.premium;
      case 'pro':
        return SubscriptionTier.pro;
      default:
        throw ArgumentError('Invalid subscription tier: $value');
    }
  }
}

/// Account status enumeration
enum AccountStatus {
  active,
  suspended,
  pending;

  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.suspended:
        return 'Suspended';
      case AccountStatus.pending:
        return 'Pending';
    }
  }

  static AccountStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'active':
        return AccountStatus.active;
      case 'suspended':
        return AccountStatus.suspended;
      case 'pending':
        return AccountStatus.pending;
      default:
        throw ArgumentError('Invalid account status: $value');
    }
  }
}