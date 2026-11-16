import '../../../home/data/models/moment_model.dart';
import '../../data/models/admin_audit_log_model.dart';
import '../../data/models/admin_user_model.dart';

abstract class AdminRepository {
  Future<AdminUserListResponse> getUsers({
    int page = 1,
    int limit = 25,
    String? search,
    String? role,
    bool? isActive,
    bool includeDeleted = false,
  });

  Future<AdminUserModel> updateUserRole(
    String userId, {
    required String role,
    int version = 1,
  });

  Future<AdminUserModel> updateUserStatus(
    String userId, {
    required bool isActive,
    int version = 1,
  });

  Future<AdminAuditLogResponse> getAuditLogs({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<MomentsListResponse> getPendingMoments({
    int page = 1,
    int limit = 20,
    String? search,
  });

  Future<MomentModel> getMomentById(String momentId);

  Future<MomentModel> approveMoment(
    String momentId, {
    int version = 1,
  });

  Future<MomentModel> rejectMoment(
    String momentId, {
    required String reason,
    int version = 1,
  });

  Future<Map<String, int>> getModerationStats();
}
