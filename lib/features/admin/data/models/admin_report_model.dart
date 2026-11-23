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
    this.momentMediaUrl,
    this.targetUserId,
    this.targetUserName,
    this.targetUserEmail,
    this.targetUserAvatar,
    this.creatorId,
    this.creatorName,
    this.creatorEmail,
    this.creatorAvatar,
    this.reporterId,
    this.reporterName,
    this.reporterEmail,
    this.reporterAvatar,
    this.resolvedById,
    this.resolvedByName,
    this.severity,
    this.openReportsCount,
    this.warningsCount,
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
  final String? momentMediaUrl;
  final String? targetUserId;
  final String? targetUserName;
  final String? targetUserEmail;
  final String? targetUserAvatar;
  final String? creatorId;
  final String? creatorName;
  final String? creatorEmail;
  final String? creatorAvatar;
  final String? reporterId;
  final String? reporterName;
  final String? reporterEmail;
  final String? reporterAvatar;
  final String? resolvedById;
  final String? resolvedByName;
  final String? severity;
  final int? openReportsCount;
  final int? warningsCount;

  factory AdminReportModel.fromJson(Map<String, dynamic> json) {
    final map = (json['data'] is Map<String, dynamic>)
        ? (json['data'] as Map<String, dynamic>)
        : ((json['report'] is Map<String, dynamic>)
            ? (json['report'] as Map<String, dynamic>)
            : json);

    final reporterObj = (map['reporter'] is Map<String, dynamic>)
        ? (map['reporter'] as Map<String, dynamic>)
        : (json['reporter'] is Map<String, dynamic>
            ? (json['reporter'] as Map<String, dynamic>)
            : null);

    final momentObj = (map['moment'] is Map<String, dynamic>)
        ? (map['moment'] as Map<String, dynamic>)
        : (json['moment'] is Map<String, dynamic>
            ? (json['moment'] as Map<String, dynamic>)
            : null);

    final creatorObj = (map['creator'] is Map<String, dynamic>)
        ? (map['creator'] as Map<String, dynamic>)
        : (json['creator'] is Map<String, dynamic>
            ? (json['creator'] as Map<String, dynamic>)
            : (map['targetUser'] is Map<String, dynamic>
                ? (map['targetUser'] as Map<String, dynamic>)
                : (json['targetUser'] is Map<String, dynamic>
                    ? (json['targetUser'] as Map<String, dynamic>)
                    : null)));

    final resolutionObj = (map['resolution'] is Map<String, dynamic>)
        ? (map['resolution'] as Map<String, dynamic>)
        : (map['resolutionDetails'] is Map<String, dynamic>
            ? (map['resolutionDetails'] as Map<String, dynamic>)
            : (json['resolution'] is Map<String, dynamic>
                ? (json['resolution'] as Map<String, dynamic>)
                : null));

    final resolvedByObj = resolutionObj != null && resolutionObj['resolvedBy'] is Map<String, dynamic>
        ? resolutionObj['resolvedBy'] as Map<String, dynamic>
        : (map['resolvedBy'] is Map<String, dynamic>
            ? (map['resolvedBy'] as Map<String, dynamic>)
            : null);

    final rId = map['reporterId']?.toString() ??
        map['reporter_id']?.toString() ??
        reporterObj?['id']?.toString();

    final rAvatar = map['reporterAvatar']?.toString() ??
        map['reporter_avatar']?.toString() ??
        reporterObj?['avatarUrl']?.toString() ??
        reporterObj?['avatar_url']?.toString() ??
        reporterObj?['avatarPath']?.toString() ??
        reporterObj?['avatar_path']?.toString() ??
        reporterObj?['profilePicture']?.toString() ??
        reporterObj?['image']?.toString();

    final resolvedReporterAvatar = (rAvatar != null && rAvatar.trim().isNotEmpty)
        ? rAvatar.trim()
        : (rId != null && rId.isNotEmpty ? '/admin/users/$rId/avatar' : null);

    final tId = map['targetUserId']?.toString() ??
        map['target_user_id']?.toString() ??
        map['reportedUserId']?.toString() ??
        map['reported_user_id']?.toString() ??
        map['creatorId']?.toString() ??
        map['creator_id']?.toString() ??
        creatorObj?['id']?.toString();

    final tAvatar = map['targetUserAvatar']?.toString() ??
        map['target_user_avatar']?.toString() ??
        creatorObj?['avatarUrl']?.toString() ??
        creatorObj?['avatar_url']?.toString() ??
        creatorObj?['avatarPath']?.toString() ??
        creatorObj?['avatar_path']?.toString() ??
        creatorObj?['profilePicture']?.toString() ??
        creatorObj?['image']?.toString();

    final resolvedTargetAvatar = (tAvatar != null && tAvatar.trim().isNotEmpty)
        ? tAvatar.trim()
        : (tId != null && tId.isNotEmpty ? '/admin/users/$tId/avatar' : null);

    return AdminReportModel(
      id: map['id']?.toString() ?? map['_id']?.toString() ?? '',
      type: map['type']?.toString().toUpperCase() ?? 'MOMENT',
      reason: map['reason']?.toString() ?? 'OTHER',
      details: map['details']?.toString() ?? map['note']?.toString() ?? map['description']?.toString(),
      status: map['status']?.toString().toUpperCase() ?? 'PENDING',
      resolution: map['resolution'] is String
          ? map['resolution'].toString()
          : (resolutionObj?['type']?.toString() ?? resolutionObj?['resolution']?.toString()),
      resolutionNote: map['resolutionNote']?.toString() ??
          map['resolution_note']?.toString() ??
          resolutionObj?['note']?.toString() ??
          resolutionObj?['details']?.toString(),
      createdAt: map['createdAt']?.toString() ?? map['created_at']?.toString(),
      resolvedAt: map['resolvedAt']?.toString() ??
          map['resolved_at']?.toString() ??
          resolutionObj?['resolvedAt']?.toString() ??
          resolutionObj?['resolved_at']?.toString(),
      momentId: map['momentId']?.toString() ??
          map['moment_id']?.toString() ??
          momentObj?['id']?.toString(),
      momentTitle: map['momentTitle']?.toString() ??
          map['moment_title']?.toString() ??
          momentObj?['title']?.toString() ??
          momentObj?['caption']?.toString(),
      momentStatus: map['momentStatus']?.toString() ??
          map['moment_status']?.toString() ??
          momentObj?['status']?.toString(),
      momentMediaUrl: map['momentMediaUrl']?.toString() ??
          map['moment_media_url']?.toString() ??
          momentObj?['mediaUrl']?.toString() ??
          momentObj?['media_url']?.toString() ??
          momentObj?['imageUrl']?.toString() ??
          momentObj?['url']?.toString(),
      targetUserId: tId,
      targetUserName: map['targetUserName']?.toString() ??
          map['target_user_name']?.toString() ??
          creatorObj?['displayName']?.toString() ??
          creatorObj?['display_name']?.toString() ??
          creatorObj?['username']?.toString() ??
          creatorObj?['name']?.toString() ??
          map['creatorName']?.toString(),
      targetUserEmail: map['targetUserEmail']?.toString() ??
          map['target_user_email']?.toString() ??
          creatorObj?['email']?.toString(),
      targetUserAvatar: resolvedTargetAvatar,
      creatorId: map['creatorId']?.toString() ??
          map['creator_id']?.toString() ??
          creatorObj?['id']?.toString(),
      creatorName: map['creatorName']?.toString() ??
          map['creator_name']?.toString() ??
          creatorObj?['displayName']?.toString() ??
          creatorObj?['display_name']?.toString() ??
          creatorObj?['username']?.toString() ??
          creatorObj?['name']?.toString(),
      creatorEmail: map['creatorEmail']?.toString() ??
          map['creator_email']?.toString() ??
          creatorObj?['email']?.toString(),
      creatorAvatar: resolvedTargetAvatar,
      reporterId: rId,
      reporterName: map['reporterName']?.toString() ??
          map['reporter_name']?.toString() ??
          reporterObj?['displayName']?.toString() ??
          reporterObj?['display_name']?.toString() ??
          reporterObj?['username']?.toString() ??
          reporterObj?['name']?.toString(),
      reporterEmail: map['reporterEmail']?.toString() ??
          map['reporter_email']?.toString() ??
          reporterObj?['email']?.toString(),
      reporterAvatar: resolvedReporterAvatar,
      resolvedById: map['resolvedById']?.toString() ??
          map['resolved_by_id']?.toString() ??
          resolvedByObj?['id']?.toString(),
      resolvedByName: map['resolvedByName']?.toString() ??
          map['resolved_by_name']?.toString() ??
          resolvedByObj?['displayName']?.toString() ??
          resolvedByObj?['display_name']?.toString() ??
          resolvedByObj?['username']?.toString() ??
          resolvedByObj?['name']?.toString(),
      severity: map['severity']?.toString() ?? 'High',
      openReportsCount: (map['openReportsCount'] as num?)?.toInt() ??
          (map['open_reports_count'] as num?)?.toInt() ??
          (creatorObj?['openReportsCount'] as num?)?.toInt(),
      warningsCount: (map['warningsCount'] as num?)?.toInt() ??
          (map['warnings_count'] as num?)?.toInt() ??
          (creatorObj?['warningsCount'] as num?)?.toInt(),
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
      final totalVal = (json['total'] as num?)?.toInt() ??
          (pagination['total'] as num?)?.toInt() ??
          list.length;
      final pageVal = (json['page'] as num?)?.toInt() ??
          (pagination['page'] as num?)?.toInt() ??
          1;
      final limitVal = (json['limit'] as num?)?.toInt() ??
          (pagination['limit'] as num?)?.toInt() ??
          20;

      return AdminReportsResponse(
        items: list
            .whereType<Map<String, dynamic>>()
            .map(AdminReportModel.fromJson)
            .toList(),
        total: totalVal,
        page: pageVal,
        limit: limitVal,
      );
    }
    return const AdminReportsResponse(items: []);
  }
}
