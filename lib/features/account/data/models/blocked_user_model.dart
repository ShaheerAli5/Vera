class BlockedUserModel {
  const BlockedUserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;

  factory BlockedUserModel.fromJson(Map<String, dynamic> json) {
    return BlockedUserModel(
      id: json['id']?.toString() ?? json['userId']?.toString() ?? '',
      username: json['username']?.toString() ?? json['handle']?.toString() ?? 'user',
      displayName: json['displayName']?.toString() ?? json['name']?.toString() ?? 'Blocked User',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
    );
  }
}

class BlockedUserListResponse {
  const BlockedUserListResponse({
    required this.items,
  });

  final List<BlockedUserModel> items;

  factory BlockedUserListResponse.fromJson(dynamic json) {
    if (json is List) {
      return BlockedUserListResponse(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(BlockedUserModel.fromJson)
            .toList(),
      );
    }
    if (json is! Map<String, dynamic>) {
      return const BlockedUserListResponse(items: []);
    }

    final rawList = json['data'] is List
        ? json['data'] as List
        : (json['items'] is List
            ? json['items'] as List
            : (json['blocked'] is List ? json['blocked'] as List : []));

    return BlockedUserListResponse(
      items: rawList
          .whereType<Map<String, dynamic>>()
          .map(BlockedUserModel.fromJson)
          .toList(),
    );
  }
}
