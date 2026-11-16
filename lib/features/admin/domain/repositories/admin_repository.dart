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
}
