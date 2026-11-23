class AdminAuditLogModel {
  const AdminAuditLogModel({
    required this.id,
    required this.actorAdminId,
    required this.targetUserId,
    required this.action,
    required this.previousValue,
    required this.newValue,
    this.actorAdmin,
    this.targetUser,
    this.createdAt,
  });

  final String id;
  final String actorAdminId;
  final String targetUserId;
  final String action;
  final String previousValue;
  final String newValue;
  final Map<String, dynamic>? actorAdmin;
  final Map<String, dynamic>? targetUser;
  final DateTime? createdAt;

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogModel(
      id: json['id']?.toString() ?? '',
      actorAdminId: json['actorAdminId']?.toString() ?? '',
      targetUserId: json['targetUserId']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      previousValue: json['previousValue']?.toString() ?? '',
      newValue: json['newValue']?.toString() ?? '',
      actorAdmin: json['actorAdmin'] as Map<String, dynamic>?,
      targetUser: json['targetUser'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  String get actorName {
    if (actorAdmin != null && actorAdmin!['displayName'] != null) {
      return actorAdmin!['displayName'].toString();
    }
    return 'Admin';
  }
}

class AdminAuditLogResponse {
  const AdminAuditLogResponse({required this.items});

  final List<AdminAuditLogModel> items;

  factory AdminAuditLogResponse.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final itemsData = json['items'] ?? json['data'] ?? [];
      if (itemsData is List) {
        return AdminAuditLogResponse(
          items: itemsData
              .map((e) => AdminAuditLogModel.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }
    }
    if (json is List) {
      return AdminAuditLogResponse(
        items: json
            .map((e) => AdminAuditLogModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }
    return const AdminAuditLogResponse(items: []);
  }
}
