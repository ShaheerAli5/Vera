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
    return AdminUserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? json['display_name']?.toString() ?? json['name']?.toString() ?? 'User',
      avatarPath: json['avatarPath']?.toString() ??
          json['avatar_path']?.toString() ??
          json['avatarUrl']?.toString() ??
          json['avatar_url']?.toString() ??
          json['profilePicture']?.toString(),
      emailVerifiedAt: json['emailVerifiedAt']?.toString(),
      role: json['role']?.toString() ?? 'USER',
      isActive: (json['isActive'] as bool?) ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      deletedAt: json['deletedAt']?.toString(),
    );
  }
}

class AdminUserListResponse {
  const AdminUserListResponse({
    required this.items,
  });

  final List<AdminUserModel> items;

  factory AdminUserListResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>?;
    return AdminUserListResponse(
      items: itemsList?.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
