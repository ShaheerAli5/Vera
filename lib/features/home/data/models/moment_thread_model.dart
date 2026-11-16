class MomentThreadModel {
  const MomentThreadModel({
    required this.id,
    required this.momentId,
    this.creatorUserId,
    this.recipientUserId,
    this.lastMessage,
    this.unreadCount = 0,
    this.createdAt,
    this.updatedAt,
    this.messages = const [],
    this.raw = const {},
  });

  final String id;
  final String momentId;
  final String? creatorUserId;
  final String? recipientUserId;
  final dynamic lastMessage;
  final int unreadCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<dynamic> messages;
  final Map<String, dynamic> raw;

  factory MomentThreadModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson['data'] is Map<String, dynamic>
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['thread'] is Map<String, dynamic>
            ? rawJson['thread'] as Map<String, dynamic>
            : rawJson);

    final rawCreated = json['createdAt'] ?? json['created_at'];
    final rawUpdated = json['updatedAt'] ?? json['updated_at'];

    final messagesList = json['messages'] is List
        ? json['messages'] as List
        : <dynamic>[];

    final lastMsg = json['lastMessage'] ?? json['last_message'];
    final unread = (json['unreadCount'] as num?)?.toInt() ??
        (json['unread_count'] as num?)?.toInt() ??
        0;

    return MomentThreadModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          rawJson['id']?.toString() ??
          '',
      momentId: json['momentId']?.toString() ??
          json['moment_id']?.toString() ??
          rawJson['momentId']?.toString() ??
          '',
      creatorUserId: json['creatorUserId']?.toString() ??
          json['creator_user_id']?.toString() ??
          json['creatorId']?.toString(),
      recipientUserId: json['recipientUserId']?.toString() ??
          json['recipient_user_id']?.toString() ??
          json['recipientId']?.toString(),
      lastMessage: lastMsg,
      unreadCount: unread,
      createdAt: rawCreated is String ? DateTime.tryParse(rawCreated) : null,
      updatedAt: rawUpdated is String ? DateTime.tryParse(rawUpdated) : null,
      messages: messagesList,
      raw: rawJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'momentId': momentId,
      if (creatorUserId != null) 'creatorUserId': creatorUserId,
      if (recipientUserId != null) 'recipientUserId': recipientUserId,
      if (lastMessage != null) 'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'messages': messages,
      ...raw,
    };
  }
}

class ChatThreadsResponse {
  const ChatThreadsResponse({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<MomentThreadModel> items;
  final String? nextCursor;
  final bool hasMore;

  factory ChatThreadsResponse.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const ChatThreadsResponse(items: []);
    }

    final rawItems = json['items'] is List
        ? json['items'] as List
        : (json['threads'] is List ? json['threads'] as List : <dynamic>[]);

    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(MomentThreadModel.fromJson)
        .toList();

    return ChatThreadsResponse(
      items: items,
      nextCursor: json['nextCursor']?.toString() ?? json['next_cursor']?.toString(),
      hasMore: json['hasMore'] == true || json['has_more'] == true,
    );
  }
}
