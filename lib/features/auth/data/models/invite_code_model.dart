import '../../domain/entities/invite_code.dart';

/// Invite code model for data layer operations
class InviteCodeModel extends InviteCode {
  const InviteCodeModel({
    required super.id,
    required super.code,
    super.email,
    required super.createdBy,
    required super.createdAt,
    required super.expiresAt,
    super.usedAt,
    super.usedBy,
    required super.maxUses,
    required super.currentUses,
    super.metadata,
  });

  /// Create InviteCodeModel from JSON
  factory InviteCodeModel.fromJson(Map<String, dynamic> json) {
    return InviteCodeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      email: json['email'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      usedAt: json['used_at'] != null 
          ? DateTime.parse(json['used_at'] as String)
          : null,
      usedBy: json['used_by'] as String?,
      maxUses: json['max_uses'] as int,
      currentUses: json['current_uses'] as int,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Create InviteCodeModel from database row
  factory InviteCodeModel.fromSupabaseRow(Map<String, dynamic> row) {
    return InviteCodeModel(
      id: row['id'] as String,
      code: row['code'] as String,
      email: row['email'] as String?,
      createdBy: row['created_by'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String),
      usedAt: row['used_at'] != null 
          ? DateTime.parse(row['used_at'] as String)
          : null,
      usedBy: row['used_by'] as String?,
      maxUses: row['max_uses'] as int,
      currentUses: row['current_uses'] as int,
      metadata: (row['metadata'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'email': email,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'used_by': usedBy,
      'max_uses': maxUses,
      'current_uses': currentUses,
      'metadata': metadata,
    };
  }

  /// Convert to database insert data
  Map<String, dynamic> toInsertData() {
    return {
      'code': code,
      'email': email,
      'created_by': createdBy,
      'expires_at': expiresAt.toIso8601String(),
      'max_uses': maxUses,
      'metadata': metadata,
    };
  }

  /// Create copy with updated fields (override from parent)
  @override
  InviteCodeModel copyWith({
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
    return InviteCodeModel(
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

  /// Convert to entity
  InviteCode toEntity() {
    return InviteCode(
      id: id,
      code: code,
      email: email,
      createdBy: createdBy,
      createdAt: createdAt,
      expiresAt: expiresAt,
      usedAt: usedAt,
      usedBy: usedBy,
      maxUses: maxUses,
      currentUses: currentUses,
      metadata: metadata,
    );
  }
}

/// Model for invite validation result from database function
class InviteValidationResultModel extends InviteValidationResult {
  const InviteValidationResultModel({
    required super.isValid,
    super.inviteId,
    super.errorMessage,
  });

  /// Create from database function result
  factory InviteValidationResultModel.fromSupabaseResult(List<dynamic> result) {
    if (result.isEmpty) {
      return const InviteValidationResultModel(
        isValid: false,
        errorMessage: 'Invalid response from server',
      );
    }

    final data = result.first as Map<String, dynamic>;
    
    return InviteValidationResultModel(
      isValid: data['is_valid'] as bool,
      inviteId: data['invite_id'] as String?,
      errorMessage: data['error_message'] as String?,
    );
  }

  /// Convert to entity
  @override
  InviteValidationResult toEntity() {
    return InviteValidationResult(
      isValid: isValid,
      inviteId: inviteId,
      errorMessage: errorMessage,
    );
  }
}