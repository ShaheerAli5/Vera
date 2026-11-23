class AdminUserModel {
  const AdminUserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarPath,
    this.emailVerifiedAt,
    required this.role,
    required this.isActive,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String? avatarPath;
  final String? emailVerifiedAt;
  final String role;
  final bool isActive;
  final int version;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    final map = (json['user'] is Map<String, dynamic>)
        ? (json['user'] as Map<String, dynamic>)
        : ((json['data'] is Map<String, dynamic>)
            ? (json['data'] as Map<String, dynamic>)
            : json);

    final avatar = map['avatarPath']?.toString() ??
        map['avatar_path']?.toString() ??
        map['avatarUrl']?.toString() ??
        map['avatar_url']?.toString() ??
        map['profilePicture']?.toString() ??
        map['profile_picture']?.toString() ??
        map['avatar']?.toString() ??
        map['image']?.toString() ??
        map['photo']?.toString();

    final userId = map['id']?.toString() ?? map['_id']?.toString() ?? '';
    final resolvedAvatar = (avatar != null && avatar.trim().isNotEmpty)
        ? avatar.trim()
        : (userId.isNotEmpty ? '/admin/users/$userId/avatar' : null);

    final statusStr = map['status']?.toString().toUpperCase();
    final bool active = map['isActive'] is bool
        ? map['isActive'] as bool
        : (map['is_active'] is bool
            ? map['is_active'] as bool
            : (statusStr != 'SUSPENDED' && statusStr != 'INACTIVE' && statusStr != 'BLOCKED'));

    return AdminUserModel(
      id: userId,
      email: map['email']?.toString() ?? '',
      displayName: map['displayName']?.toString() ??
          map['display_name']?.toString() ??
          map['name']?.toString() ??
          map['username']?.toString() ??
          'User',
      avatarPath: resolvedAvatar,
      emailVerifiedAt: map['emailVerifiedAt']?.toString() ?? map['email_verified_at']?.toString(),
      role: map['role']?.toString() ?? 'USER',
      isActive: active,
      version: (map['version'] as num?)?.toInt() ?? 1,
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString() ?? '',
      updatedAt: map['updatedAt']?.toString() ?? map['updated_at']?.toString() ?? '',
      deletedAt: map['deletedAt']?.toString() ?? map['deleted_at']?.toString(),
    );
  }
}

class AdminUserListResponse {
  const AdminUserListResponse({
    required this.items,
  });

  final List<AdminUserModel> items;

  factory AdminUserListResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] is List
        ? json['items'] as List
        : (json['users'] is List
            ? json['users'] as List
            : (json['data'] is List ? json['data'] as List : <dynamic>[]));
    return AdminUserListResponse(
      items: itemsList
          .whereType<Map<String, dynamic>>()
          .map(AdminUserModel.fromJson)
          .toList(),
    );
  }
}
