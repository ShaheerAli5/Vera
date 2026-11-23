import '../../../../core/network/api_client.dart';
import '../../../home/data/models/moment_model.dart';
import '../../../home/data/models/notification_model.dart';
import '../models/admin_audit_log_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';

class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<AdminUserListResponse> getUsers({
    int page = 1,
    int limit = 25,
    String? search,
    String? role,
    bool? isActive,
    bool includeDeleted = false,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'includeDeleted': includeDeleted.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (role != null && role.isNotEmpty) {
      queryParams['role'] = role;
    }
    if (isActive != null) {
      queryParams['isActive'] = isActive.toString();
    }

    final response = await _apiClient.get(
      '/admin/users',
      queryParameters: queryParams,
    );

    return AdminUserListResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<AdminUserModel> updateUserRole(
    String userId, {
    required String role,
    int version = 1,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/admin/users/$userId/role',
        body: {'role': role, 'version': version},
      );
      if (response is Map<String, dynamic>) {
        return AdminUserModel.fromJson(response);
      }
    } catch (_) {}

    final response = await _apiClient.patch(
      '/admin/users/$userId',
      body: {'role': role, 'version': version},
    );
    if (response is Map<String, dynamic>) {
      return AdminUserModel.fromJson(response);
    }
    throw const FormatException('Failed to update user role.');
  }

  Future<AdminUserModel> updateUserStatus(
    String userId, {
    required bool isActive,
    int version = 1,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/admin/users/$userId/status',
        body: {'isActive': isActive, 'version': version},
      );
      if (response is Map<String, dynamic>) {
        return AdminUserModel.fromJson(response);
      }
    } catch (_) {}

    final response = await _apiClient.patch(
      '/admin/users/$userId',
      body: {'isActive': isActive, 'version': version},
    );
    if (response is Map<String, dynamic>) {
      return AdminUserModel.fromJson(response);
    }
    throw const FormatException('Failed to update user status.');
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _apiClient.delete('/admin/users/$userId');
    } catch (_) {}
  }

  Future<void> revokeUserSessions(String userId) async {
    try {
      await _apiClient.post('/admin/users/$userId/revoke-sessions');
    } catch (_) {
      try {
        await _apiClient.delete('/admin/users/$userId/sessions');
      } catch (_) {}
    }
  }

  Future<AdminAuditLogResponse> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    try {
      final response = await _apiClient.get(
        '/admin/audit-logs',
        queryParameters: queryParams,
      );
      return AdminAuditLogResponse.fromJson(response);
    } catch (_) {
      try {
        final response = await _apiClient.get(
          '/admin/logs',
          queryParameters: queryParams,
        );
        return AdminAuditLogResponse.fromJson(response);
      } catch (_) {
        return const AdminAuditLogResponse(items: []);
      }
    }
  }

  Future<MomentsListResponse> getPendingMoments({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      'status': 'PENDING_REVIEW',
    };
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    try {
      final response = await _apiClient.get(
        '/admin/moments',
        queryParameters: queryParams,
      );
      return MomentsListResponse.fromJson(response);
    } catch (_) {
      try {
        final response = await _apiClient.get(
          '/admin/moderation/queue',
          queryParameters: queryParams,
        );
        return MomentsListResponse.fromJson(response);
      } catch (_) {
        final response = await _apiClient.get(
          '/moments',
          queryParameters: queryParams,
        );
        return MomentsListResponse.fromJson(response);
      }
    }
  }

  Future<MomentModel> getMomentById(String momentId) async {
    try {
      final response = await _apiClient.get('/admin/moments/$momentId');
      if (response is Map<String, dynamic>) {
        return MomentModel.fromJson(response);
      }
    } catch (_) {}

    final response = await _apiClient.get('/moments/$momentId');
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Moment response must be a JSON object.');
    }
    return MomentModel.fromJson(response);
  }

  Future<MomentModel> approveMoment(
    String momentId, {
    int version = 1,
  }) async {
    final response = await _apiClient.post(
      '/admin/moments/$momentId/approve',
      body: {'version': version},
    );
    if (response is Map<String, dynamic>) {
      return MomentModel.fromJson(response);
    }
    return MomentModel(
      id: momentId,
      title: 'Approved Moment',
      status: 'PUBLISHED',
      version: version + 1,
    );
  }

  Future<MomentModel> rejectMoment(
    String momentId, {
    required String reason,
    int version = 1,
  }) async {
    final response = await _apiClient.post(
      '/admin/moments/$momentId/reject',
      body: {
        'version': version,
        'reason': reason,
      },
    );
    if (response is Map<String, dynamic>) {
      return MomentModel.fromJson(response);
    }
    return MomentModel(
      id: momentId,
      title: 'Rejected Moment',
      status: 'REJECTED',
      version: version + 1,
    );
  }

  Future<Map<String, int>> getModerationStats() async {
    try {
      final response = await _apiClient.get('/admin/stats');
      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        return {
          for (final key in ['totalUsers', 'activeUsers', 'suspendedUsers',
            'pendingMoments', 'approvedMoments', 'rejectedMoments'])
            if (data[key] is num) key: (data[key] as num).toInt(),
        };
      }
    } catch (_) {}
    return {};
  }

  Future<AdminReportsResponse> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }

    final response = await _apiClient.get(
      '/admin/reports',
      queryParameters: queryParams,
    );
    return AdminReportsResponse.fromJson(response);
  }

  Future<AdminReportModel> getReportById(String reportId) async {
    final response = await _apiClient.get('/admin/reports/$reportId');
    if (response is Map<String, dynamic>) {
      return AdminReportModel.fromJson(response);
    }
    throw const FormatException('Invalid report detail response');
  }

  Future<AdminReportModel> resolveReport({
    required String reportId,
    required String resolution,
    String? note,
  }) async {
    final body = {
      'resolution': resolution,
      if (note != null && note.isNotEmpty) 'note': note,
    };

    Object? lastError;

    try {
      final response = await _apiClient.patch(
        '/admin/reports/$reportId/resolve',
        body: body,
      );
      if (response is Map<String, dynamic>) {
        return AdminReportModel.fromJson(response);
      }
    } catch (e) {
      lastError = e;
    }

    try {
      final response = await _apiClient.patch(
        '/admin/reports/$reportId',
        body: {
          'status': 'RESOLVED',
          ...body,
        },
      );
      if (response is Map<String, dynamic>) {
        return AdminReportModel.fromJson(response);
      }
    } catch (_) {}

    try {
      final response = await _apiClient.post(
        '/admin/reports/$reportId/resolve',
        body: body,
      );
      if (response is Map<String, dynamic>) {
        return AdminReportModel.fromJson(response);
      }
    } catch (_) {}

    if (lastError != null) throw lastError;
    throw const FormatException('Invalid report resolution response');
  }

  Future<NotificationsListResponse> getAdminNotifications({
    int limit = 50,
  }) async {
    try {
      final response = await _apiClient.get(
        '/admin/notifications',
        queryParameters: {'limit': limit.toString()},
      );
      return NotificationsListResponse.fromJson(response);
    } catch (_) {
      try {
        final response = await _apiClient.get(
          '/notifications',
          queryParameters: {'limit': limit.toString()},
        );
        return NotificationsListResponse.fromJson(response);
      } catch (_) {
        return const NotificationsListResponse(items: []);
      }
    }
  }

  Future<void> markAdminNotificationAsRead(String notificationId) async {
    try {
      await _apiClient.patch('/admin/notifications/$notificationId/read');
    } catch (_) {
      try {
        await _apiClient.patch('/notifications/$notificationId/read');
      } catch (_) {}
    }
  }

  Future<void> markAllAdminNotificationsAsRead() async {
    try {
      await _apiClient.post('/admin/notifications/read-all');
    } catch (_) {
      try {
        await _apiClient.post('/notifications/read-all');
      } catch (_) {}
    }
  }
}
