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
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      avatarPath: json['avatarPath'] as String?,
      emailVerifiedAt: json['emailVerifiedAt'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool,
      version: json['version'] as int,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      deletedAt: json['deletedAt'] as String?,
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
