class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? imageUrl;
  final DateTime? createdAt;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdAtStr = json['createdAt']?.toString() ??
        json['created_at']?.toString() ??
        json['timestamp']?.toString();

    return NotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ??
          json['message']?.toString() ??
          json['content']?.toString() ??
          '',
      isRead: json['isRead'] == true ||
          json['is_read'] == true ||
          json['read'] == true,
      imageUrl: json['imageUrl']?.toString() ??
          json['image']?.toString() ??
          json['avatarUrl']?.toString(),
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
    );
  }
}

class NotificationsListResponse {
  const NotificationsListResponse({
    required this.items,
  });

  final List<NotificationModel> items;

  factory NotificationsListResponse.fromJson(dynamic json) {
    if (json is List) {
      return NotificationsListResponse(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList(),
      );
    }
    if (json is! Map<String, dynamic>) {
      return const NotificationsListResponse(items: []);
    }

    final rawList = json['data'] is List
        ? json['data'] as List
        : (json['items'] is List
            ? json['items'] as List
            : (json['notifications'] is List
                ? json['notifications'] as List
                : []));

    return NotificationsListResponse(
      items: rawList
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList(),
    );
  }
}
