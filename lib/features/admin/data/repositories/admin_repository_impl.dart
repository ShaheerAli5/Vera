import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';
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
}
