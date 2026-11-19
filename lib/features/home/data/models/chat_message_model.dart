class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    this.threadId,
    this.senderId,
    required this.content,
    this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String? threadId;
  final String? senderId;
  final String content;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory ChatMessageModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson['data'] is Map<String, dynamic>
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['message'] is Map<String, dynamic>
            ? rawJson['message'] as Map<String, dynamic>
            : rawJson);

    final rawCreated = json['createdAt'] ??
        json['created_at'] ??
        rawJson['createdAt'] ??
        rawJson['created_at'] ??
        json['timestamp'] ??
        rawJson['timestamp'];

    final content = json['content']?.toString() ??
        json['text']?.toString() ??
        (json['message'] is String ? json['message'].toString() : null) ??
        json['body']?.toString() ??
        json['msg']?.toString() ??
        json['value']?.toString() ??
        rawJson['content']?.toString() ??
        rawJson['text']?.toString() ??
        (rawJson['message'] is String ? rawJson['message'].toString() : null) ??
        rawJson['body']?.toString() ??
        rawJson['msg']?.toString() ??
        '';

    return ChatMessageModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          rawJson['id']?.toString() ??
          rawJson['_id']?.toString() ??
          '',
      threadId: json['threadId']?.toString() ??
          json['thread_id']?.toString() ??
          rawJson['threadId']?.toString() ??
          rawJson['thread_id']?.toString(),
      senderId: json['senderId']?.toString() ??
          json['sender_id']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          rawJson['senderId']?.toString() ??
          rawJson['sender_id']?.toString(),
      content: content,
      createdAt: rawCreated is String
          ? DateTime.tryParse(rawCreated)
          : (rawCreated is DateTime ? rawCreated : null),
      raw: rawJson,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (threadId != null) 'threadId': threadId,
      if (senderId != null) 'senderId': senderId,
      'content': content,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      ...raw,
    };
  }
}

class ThreadMessagesResponse {
  const ThreadMessagesResponse({
    required this.items,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<ChatMessageModel> items;
  final String? nextCursor;
  final bool hasMore;

  factory ThreadMessagesResponse.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageModel.fromJson)
          .toList();
      return ThreadMessagesResponse(items: items);
    }

    if (json is! Map<String, dynamic>) {
      return const ThreadMessagesResponse(items: []);
    }

    final rawList = json['items'] is List
        ? json['items'] as List
        : (json['messages'] is List
            ? json['messages'] as List
            : (json['data'] is List
                ? json['data'] as List
                : (json['data'] is Map && (json['data']['items'] is List || json['data']['messages'] is List)
                    ? (json['data']['items'] ?? json['data']['messages']) as List
                    : [])));

    final items = rawList
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();

    return ThreadMessagesResponse(
      items: items,
      nextCursor: json['nextCursor']?.toString() ?? json['next_cursor']?.toString(),
      hasMore: json['hasMore'] == true || json['has_more'] == true,
    );
  }
}
