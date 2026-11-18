class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.type,
    this.data = const {},
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final String? type;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final DateTime? createdAt;

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    bool? isRead,
    String? type,
    Map<String, dynamic>? data,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

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
      isRead: json['readAt'] != null ||
          json['read_at'] != null ||
          json['isRead'] == true ||
          json['is_read'] == true ||
          json['read'] == true,
      type: json['type']?.toString(),
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
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
