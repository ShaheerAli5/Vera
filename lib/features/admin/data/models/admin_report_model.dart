class AdminReportModel {
  const AdminReportModel({
    required this.id,
    required this.type,
    required this.reason,
    this.details,
    required this.status,
    this.resolution,
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
    this.momentId,
    this.momentTitle,
    this.momentStatus,
    this.targetUserId,
    this.targetUserName,
    this.creatorId,
    this.creatorName,
    this.reporterId,
    this.reporterName,
    this.resolvedById,
    this.resolvedByName,
  });

  final String id;
  final String type; // 'MOMENT' or 'USER'
  final String reason;
  final String? details;
  final String status; // 'PENDING' or 'RESOLVED'
  final String? resolution; // 'DISMISSED', 'MOMENT_REMOVED', 'USER_SUSPENDED'
  final String? resolutionNote;
  final String? createdAt;
  final String? resolvedAt;
  final String? momentId;
  final String? momentTitle;
  final String? momentStatus;
  final String? targetUserId;
  final String? targetUserName;
  final String? creatorId;
  final String? creatorName;
  final String? reporterId;
  final String? reporterName;
  final String? resolvedById;
  final String? resolvedByName;

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    return AdminReportModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'MOMENT',
      reason: json['reason']?.toString() ?? 'OTHER',
      details: json['details']?.toString(),
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      resolution: json['resolution']?.toString(),
      resolutionNote: json['resolutionNote']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      resolvedAt: json['resolvedAt']?.toString() ?? json['resolved_at']?.toString(),
      momentId: json['momentId']?.toString() ?? json['moment_id']?.toString(),
      momentTitle: json['momentTitle']?.toString() ?? json['moment_title']?.toString(),
      momentStatus: json['momentStatus']?.toString() ?? json['moment_status']?.toString(),
      targetUserId: json['targetUserId']?.toString() ??
          json['reportedUserId']?.toString() ??
          json['reported_user_id']?.toString(),
      targetUserName: json['targetUserName']?.toString() ??
          json['target_user_name']?.toString() ??
          json['creatorName']?.toString(),
      creatorId: json['creatorId']?.toString() ?? json['creator_id']?.toString(),
      creatorName: json['creatorName']?.toString() ?? json['creator_name']?.toString(),
      reporterId: json['reporterId']?.toString() ?? json['reporter_id']?.toString(),
      reporterName: json['reporterName']?.toString() ?? json['reporter_name']?.toString(),
      resolvedById: json['resolvedById']?.toString() ?? json['resolved_by_id']?.toString(),
      resolvedByName: json['resolvedByName']?.toString() ?? json['resolved_by_name']?.toString(),
    );
  }
}

class AdminReportsResponse {
  const AdminReportsResponse({
    required this.items,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
  });

  final List<AdminReportModel> items;
  final int total;
  final int page;
  final int limit;

  factory AdminReportsResponse.fromJson(dynamic json) {
    if (json is List) {
      return AdminReportsResponse(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(AdminReportModel.fromJson)
            .toList(),
        total: json.length,
      );
    }
    if (json is Map<String, dynamic>) {
      final list = json['items'] is List
          ? json['items'] as List
          : (json['data'] is List ? json['data'] as List : <dynamic>[]);
      final pagination = json['pagination'] is Map<String, dynamic>
          ? json['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};
      return AdminReportsResponse(
        items: list
            .whereType<Map<String, dynamic>>()
            .map(AdminReportModel.fromJson)
            .toList(),
        total: (pagination['total'] as num?)?.toInt() ?? list.length,
        page: (pagination['page'] as num?)?.toInt() ?? 1,
        limit: (pagination['limit'] as num?)?.toInt() ?? 20,
      );
    }
    return const AdminReportsResponse(items: []);
  }
}
