class AdminAuditLogModel {
  const AdminAuditLogModel({
    required this.id,
    required this.actorName,
    required this.action,
    required this.targetName,
    this.createdAt,
  });

  final String id;
  final String actorName;
  final String action;
  final String targetName;
  final DateTime? createdAt;

  factory AdminAuditLogModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt']?.toString() ??
        json['created_at']?.toString() ??
        json['timestamp']?.toString();

    return AdminAuditLogModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      actorName: json['actorName']?.toString() ??
          json['actor']?.toString() ??
          json['user']?.toString() ??
          json['userName']?.toString() ??
          'Admin User',
      action: json['action']?.toString() ??
          json['event']?.toString() ??
          json['type']?.toString() ??
          json['description']?.toString() ??
          'Audit Event',
      targetName: json['targetName']?.toString() ??
          json['target']?.toString() ??
          json['details']?.toString() ??
          '',
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
    );
  }
}

class AdminAuditLogResponse {
  const AdminAuditLogResponse({
    required this.items,
  });

  final List<AdminAuditLogModel> items;

  factory AdminAuditLogResponse.fromJson(dynamic json) {
    if (json is List) {
      return AdminAuditLogResponse(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(AdminAuditLogModel.fromJson)
            .toList(),
      );
    }
    if (json is! Map<String, dynamic>) {
      return const AdminAuditLogResponse(items: []);
    }

    final rawList = json['data'] is List
        ? json['data'] as List
        : (json['items'] is List
            ? json['items'] as List
            : (json['logs'] is List ? json['logs'] as List : []));

    return AdminAuditLogResponse(
      items: rawList
          .whereType<Map<String, dynamic>>()
          .map(AdminAuditLogModel.fromJson)
          .toList(),
    );
  }
}
