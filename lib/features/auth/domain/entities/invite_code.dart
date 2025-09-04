import 'package:equatable/equatable.dart';

/// Invite code entity for registration system
class InviteCode extends Equatable {
  const InviteCode({
    required this.id,
    required this.code,
    this.email,
    required this.createdBy,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    this.usedBy,
    required this.maxUses,
    required this.currentUses,
    this.metadata = const {},
  });

  /// Unique identifier
  final String id;

  /// The actual invite code
  final String code;

  /// Email this invite is for (optional)
  final String? email;

  /// User ID who created this invite
  final String createdBy;

  /// When the invite was created
  final DateTime createdAt;

  /// When the invite expires
  final DateTime expiresAt;

  /// When the invite was first used
  final DateTime? usedAt;

  /// User ID who used this invite
  final String? usedBy;

  /// Maximum number of uses allowed
  final int maxUses;

  /// Current number of uses
  final int currentUses;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  /// Check if invite code is valid
  bool get isValid {
    return !isExpired && !isFullyUsed;
  }

  /// Check if invite code has expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Check if invite code has been fully used
  bool get isFullyUsed {
    return currentUses >= maxUses;
  }

  /// Check if invite code has been used at least once
  bool get hasBeenUsed {
    return currentUses > 0;
  }

  /// Get remaining uses
  int get remainingUses {
    return maxUses - currentUses;
  }

  /// Check if invite is for a specific email
  bool get isEmailSpecific {
    return email != null && email!.isNotEmpty;
  }

  /// Get invite type from metadata
  String get inviteType {
    return metadata['type'] as String? ?? 'general';
  }

  /// Get invite description from metadata
  String? get description {
    return metadata['description'] as String?;
  }

  /// Create copy with updated fields
  InviteCode copyWith({
    String? id,
    String? code,
    String? email,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? usedAt,
    String? usedBy,
    int? maxUses,
    int? currentUses,
    Map<String, dynamic>? metadata,
  }) {
    return InviteCode(
      id: id ?? this.id,
      code: code ?? this.code,
      email: email ?? this.email,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      usedAt: usedAt ?? this.usedAt,
      usedBy: usedBy ?? this.usedBy,
      maxUses: maxUses ?? this.maxUses,
      currentUses: currentUses ?? this.currentUses,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        email,
        createdBy,
        createdAt,
        expiresAt,
        usedAt,
        usedBy,
        maxUses,
        currentUses,
        metadata,
      ];
}

/// Result of invite code validation
class InviteValidationResult extends Equatable {
  const InviteValidationResult({
    required this.isValid,
    this.inviteId,
    this.errorMessage,
  });

  /// Whether the invite code is valid
  final bool isValid;

  /// ID of the valid invite (if valid)
  final String? inviteId;

  /// Error message (if invalid)
  final String? errorMessage;

  /// Factory constructor for valid result
  factory InviteValidationResult.valid(String inviteId) {
    return InviteValidationResult(
      isValid: true,
      inviteId: inviteId,
    );
  }

  /// Factory constructor for invalid result
  factory InviteValidationResult.invalid(String errorMessage) {
    return InviteValidationResult(
      isValid: false,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isValid, inviteId, errorMessage];
}