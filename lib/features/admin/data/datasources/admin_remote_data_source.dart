import '../../../../core/network/api_client.dart';
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
}
