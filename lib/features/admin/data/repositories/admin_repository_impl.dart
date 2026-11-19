import '../../../home/data/models/moment_model.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';
import '../models/admin_audit_log_model.dart';
import '../models/admin_report_model.dart';
import '../models/admin_user_model.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remoteDataSource);

  final AdminRemoteDataSource _remoteDataSource;

  @override
  Future<AdminUserListResponse> getUsers({
    int page = 1,
    int limit = 25,
    String? search,
    String? role,
    bool? isActive,
    bool includeDeleted = false,
  }) {
    return _remoteDataSource.getUsers(
      page: page,
      limit: limit,
      search: search,
      role: role,
      isActive: isActive,
      includeDeleted: includeDeleted,
    );
  }

  @override
  Future<AdminUserModel> updateUserRole(
    String userId, {
    required String role,
    int version = 1,
  }) {
    return _remoteDataSource.updateUserRole(
      userId,
      role: role,
      version: version,
    );
  }

  @override
  Future<AdminUserModel> updateUserStatus(
    String userId, {
    required bool isActive,
    int version = 1,
  }) {
    return _remoteDataSource.updateUserStatus(
      userId,
      isActive: isActive,
      version: version,
    );
  }

  @override
  Future<AdminAuditLogResponse> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return _remoteDataSource.getAuditLogs(
      page: page,
      limit: limit,
      search: search,
    );
  }

  @override
  Future<MomentsListResponse> getPendingMoments({
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return _remoteDataSource.getPendingMoments(
      page: page,
      limit: limit,
      search: search,
    );
  }

  @override
  Future<MomentModel> getMomentById(String momentId) {
    return _remoteDataSource.getMomentById(momentId);
  }

  @override
  Future<MomentModel> approveMoment(
    String momentId, {
    int version = 1,
  }) {
    return _remoteDataSource.approveMoment(
      momentId,
      version: version,
    );
  }

  @override
  Future<MomentModel> rejectMoment(
    String momentId, {
    required String reason,
    int version = 1,
  }) {
    return _remoteDataSource.rejectMoment(
      momentId,
      reason: reason,
      version: version,
    );
  }

  @override
  Future<Map<String, int>> getModerationStats() {
    return _remoteDataSource.getModerationStats();
  }

  @override
  Future<AdminReportsResponse> getReports({
    int page = 1,
    int limit = 20,
    String? status,
    String? type,
  }) {
    return _remoteDataSource.getReports(
      page: page,
      limit: limit,
      status: status,
      type: type,
    );
  }

  @override
  Future<AdminReportModel> resolveReport({
    required String reportId,
    required String resolution,
    String? note,
  }) {
    return _remoteDataSource.resolveReport(
      reportId: reportId,
      resolution: resolution,
      note: note,
    );
  }
}
