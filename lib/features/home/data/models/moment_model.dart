import '../../../../core/utils/server_time_manager.dart';
import '../../domain/entities/moment.dart';

class MomentsListResponse {
  const MomentsListResponse({
    required this.moments,
    this.total = 0,
    this.page = 1,
    this.limit = 20,
    this.hasMore = false,
    this.serverTime,
  });

  final List<MomentModel> moments;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
  final DateTime? serverTime;

  factory MomentsListResponse.fromJson(dynamic json) {
    if (json is List) {
      final items = json
          .whereType<Map<String, dynamic>>()
          .map(MomentModel.fromJson)
          .toList();
      return MomentsListResponse(
        moments: items,
        total: items.length,
        page: 1,
        limit: items.length,
        hasMore: false,
      );
    }

    if (json is! Map<String, dynamic>) {
      return const MomentsListResponse(moments: []);
    }

    List<dynamic> itemsRaw = const [];
    if (json['data'] is List) {
      itemsRaw = json['data'] as List;
    } else if (json['moments'] is List) {
      itemsRaw = json['moments'] as List;
    } else if (json['items'] is List) {
      itemsRaw = json['items'] as List;
    } else if (json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      if (data['moments'] is List) {
        itemsRaw = data['moments'] as List;
      } else if (data['items'] is List) {
        itemsRaw = data['items'] as List;
      }
    }

    final moments = itemsRaw
        .whereType<Map<String, dynamic>>()
        .map(MomentModel.fromJson)
        .toList();

    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : (json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : null);

    final total = (meta?['total'] as num?)?.toInt() ??
        (json['total'] as num?)?.toInt() ??
        moments.length;
    final page = (meta?['page'] as num?)?.toInt() ??
        (json['page'] as num?)?.toInt() ??
        1;
    final limit = (meta?['limit'] as num?)?.toInt() ??
        (json['limit'] as num?)?.toInt() ??
        20;
    final hasMore = meta?['hasMore'] == true ||
        (page * limit < total);

    final serverTimeStr = json['serverTime']?.toString() ?? json['server_time']?.toString();
    final serverTime = serverTimeStr != null ? DateTime.tryParse(serverTimeStr) : null;
    if (serverTime != null) {
      ServerTimeManager.instance.updateServerTime(serverTime);
    }

    return MomentsListResponse(
      moments: moments,
      total: total,
      page: page,
      limit: limit,
      hasMore: hasMore,
      serverTime: serverTime,
    );
  }
}

class MomentModel {
  const MomentModel({
    required this.id,
    required this.title,
    this.version = 1,
    this.category,
    this.teaser,
    this.message,
    this.visibility,
    this.status,
    this.unlockRuleType,
    this.unlockAt,
    this.timezone,
    this.locationName,
    this.locationRadius,
    this.creatorId,
    this.creatorName,
    this.creatorAvatarUrl,
    this.mediaUrl,
    this.recipientUserIds = const [],
    this.inviteEmails = const [],
    this.createdAt,
    this.invitationStatus,
    this.unlockedAt,
    this.openedAt,
    this.isVideo = false,
    this.timeAgo,
    this.contentType,
    this.hasMedia = true,
    this.raw = const {},
  });

  final String id;
  final String title;
  final int version;
  final String? category;
  final String? teaser;
  final String? message;
  final String? visibility;
  final String? status;
  final String? unlockRuleType;
  final DateTime? unlockAt;
  final String? timezone;
  final String? locationName;
  final String? locationRadius;
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatarUrl;
  final String? mediaUrl;
  final List<String> recipientUserIds;
  final List<String> inviteEmails;
  final DateTime? createdAt;
  final String? invitationStatus;
  final DateTime? unlockedAt;
  final DateTime? openedAt;
  final bool isVideo;
  final String? timeAgo;
  final String? contentType;
  final bool hasMedia;
  final Map<String, dynamic> raw;

  factory MomentModel.fromJson(Map<String, dynamic> rawJson) {
    final json = rawJson['data'] is Map<String, dynamic>
        ? rawJson['data'] as Map<String, dynamic>
        : (rawJson['moment'] is Map<String, dynamic>
            ? rawJson['moment'] as Map<String, dynamic>
            : rawJson);

    final unlockRule = json['unlock'] is Map<String, dynamic>
        ? json['unlock'] as Map<String, dynamic>
        : (json['unlockRule'] is Map<String, dynamic>
            ? json['unlockRule'] as Map<String, dynamic>
            : (json['unlock_rule'] is Map<String, dynamic>
                ? json['unlock_rule'] as Map<String, dynamic>
                : null));

    final creator = json['creator'] is Map<String, dynamic>
        ? json['creator'] as Map<String, dynamic>
        : (json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : null);

    final unlockAtStr = unlockRule?['unlockAt']?.toString() ??
        unlockRule?['unlock_at']?.toString() ??
        json['unlockAt']?.toString() ??
        json['unlock_at']?.toString();

    final apiTimeAgo = json['timeAgo']?.toString() ??
        json['time_ago']?.toString() ??
        rawJson['timeAgo']?.toString() ??
        rawJson['time_ago']?.toString();

    final createdAtStr = json['createdAt']?.toString() ??
        json['created_at']?.toString() ??
        rawJson['createdAt']?.toString() ??
        rawJson['created_at']?.toString() ??
        json['timestamp']?.toString() ??
        rawJson['timestamp']?.toString() ??
        json['date']?.toString() ??
        rawJson['date']?.toString();

    final recipients = (json['recipientUserIds'] ?? json['recipient_user_ids']) is List
        ? ((json['recipientUserIds'] ?? json['recipient_user_ids']) as List)
            .map((e) => e.toString())
            .toList()
        : <String>[];

    final invites = (json['inviteEmails'] ?? json['invite_emails']) is List
        ? ((json['inviteEmails'] ?? json['invite_emails']) as List)
            .map((e) => e.toString())
            .toList()
        : <String>[];

    final media = json['media'] is Map<String, dynamic>
        ? json['media'] as Map<String, dynamic>
        : null;

    final mediaUrl = media?['url']?.toString() ??
        json['mediaUrl']?.toString() ??
        json['media_url']?.toString();

    final version = (json['version'] as num?)?.toInt() ??
        (rawJson['version'] as num?)?.toInt() ??
        (json['__v'] as num?)?.toInt() ??
        1;

    final unlockedAtStr = json['unlockedAt']?.toString() ??
        json['unlocked_at']?.toString();
    final openedAtStr = json['openedAt']?.toString() ??
        json['opened_at']?.toString();
    final invitationStatus = json['invitationStatus']?.toString() ??
        json['invitation_status']?.toString();

    final avatarPath = creator?['avatarUrl']?.toString() ??
        creator?['avatar_url']?.toString() ??
        json['creatorAvatarUrl']?.toString();
    final fullAvatarUrl = (avatarPath != null && avatarPath.startsWith('/'))
        ? 'https://vera.aptechmedia.com$avatarPath'
        : avatarPath;

    final contentType = json['contentType']?.toString() ??
        json['content_type']?.toString() ??
        'TEXT';

    final mimeType = media?['mimeType']?.toString() ??
        media?['type']?.toString() ??
        media?['contentType']?.toString() ??
        json['contentType']?.toString() ??
        json['mediaType']?.toString() ??
        json['type']?.toString();

    final hasMedia = (media != null && (media['uploaded'] == true || (mediaUrl != null && mediaUrl.isNotEmpty))) ||
        contentType.toUpperCase() == 'IMAGE' ||
        contentType.toUpperCase() == 'VIDEO';

    final isVideo = (json['isVideo'] == true ||
        rawJson['isVideo'] == true ||
        json['is_video'] == true ||
        (mimeType != null && mimeType.toLowerCase().contains('video')) ||
        (mediaUrl != null && (
            mediaUrl.toLowerCase().contains('.mp4') ||
            mediaUrl.toLowerCase().contains('.mov') ||
            mediaUrl.toLowerCase().contains('.webm') ||
            mediaUrl.toLowerCase().contains('.avi') ||
            mediaUrl.toLowerCase().contains('/video/'))));

    return MomentModel(
      id: json['id']?.toString() ??
          json['_id']?.toString() ??
          '',
      title: json['title']?.toString() ?? 'Untitled Moment',
      version: version,
      category: json['category']?.toString(),
      teaser: json['teaser']?.toString(),
      message: json['message']?.toString(),
      visibility: json['visibility']?.toString() ?? 'PUBLIC',
      status: json['status']?.toString() ?? 'PUBLISHED',
      unlockRuleType: unlockRule?['type']?.toString() ??
          json['unlockType']?.toString() ??
          'DATE',
      unlockAt: unlockAtStr != null ? DateTime.tryParse(unlockAtStr) : null,
      timezone: unlockRule?['timezone']?.toString() ??
          json['timezone']?.toString() ??
          'UTC',
      locationName: unlockRule?['locationName']?.toString() ??
          unlockRule?['location_name']?.toString() ??
          json['locationName']?.toString(),
      locationRadius: unlockRule?['radius']?.toString() ??
          unlockRule?['locationRadius']?.toString() ??
          json['radius']?.toString(),
      creatorId: creator?['id']?.toString() ??
          creator?['_id']?.toString() ??
          json['creatorId']?.toString(),
      creatorName: creator?['displayName']?.toString() ??
          creator?['name']?.toString() ??
          creator?['username']?.toString() ??
          json['creatorName']?.toString() ??
          'You',
      creatorAvatarUrl: fullAvatarUrl,
      mediaUrl: mediaUrl,
      recipientUserIds: recipients,
      inviteEmails: invites,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
      invitationStatus: invitationStatus,
      unlockedAt: unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : null,
      openedAt: openedAtStr != null ? DateTime.tryParse(openedAtStr) : null,
      isVideo: isVideo,
      contentType: contentType,
      hasMedia: hasMedia,
      timeAgo: apiTimeAgo,
      raw: json,
    );
  }

  Moment toEntity({String? currentUserName}) {
    final isDateUnlock = (unlockRuleType ?? 'DATE').toUpperCase() == 'DATE';
    final now = ServerTimeManager.instance.now;

    bool isReady;
    if (unlockedAt != null) {
      isReady = true;
    } else if (unlockAt != null) {
      isReady = !now.isBefore(unlockAt!);
    } else {
      isReady = true;
    }

    final isApprovedAndPublished = status == 'PUBLISHED';
    final isReadyToOpen = isReady && isApprovedAndPublished;

    String conditionText;
    if (isDateUnlock && unlockAt != null) {
      final local = unlockAt!.toLocal();
      final monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final m = monthNames[local.month - 1];
      final d = local.day;
      final y = local.year;
      final hour = local.hour > 12
          ? local.hour - 12
          : (local.hour == 0 ? 12 : local.hour);
      final min = local.minute.toString().padLeft(2, '0');
      final ampm = local.hour >= 12 ? 'PM' : 'AM';
      conditionText = 'Opens $m $d, $y, $hour:$min $ampm';
    } else if (locationName != null && locationName!.isNotEmpty) {
      conditionText = "Opens when you're at $locationName";
    } else {
      conditionText = teaser != null && teaser!.isNotEmpty
          ? teaser!
          : 'Opens when unlocked';
    }

    String timeAgoText = 'Just now';
    if (timeAgo != null && timeAgo!.trim().isNotEmpty) {
      timeAgoText = timeAgo!.trim();
    } else {
      final refTime = createdAt ?? unlockedAt;
      if (refTime != null) {
        final diff = now.difference(refTime);
        if (diff.inDays > 365) {
          timeAgoText = '${(diff.inDays / 365).floor()}y ago';
        } else if (diff.inDays > 30) {
          timeAgoText = '${(diff.inDays / 30).floor()}mo ago';
        } else if (diff.inDays > 0) {
          timeAgoText = '${diff.inDays}d ago';
        } else if (diff.inHours > 0) {
          timeAgoText = '${diff.inHours}h ago';
        } else if (diff.inMinutes > 0) {
          timeAgoText = '${diff.inMinutes}m ago';
        } else if (diff.inSeconds >= 10) {
          timeAgoText = '${diff.inSeconds}s ago';
        } else {
          timeAgoText = 'Just now';
        }
      }
    }

    final isPriv = (visibility ?? 'PRIVATE').toUpperCase() == 'PRIVATE';

    String? badgeTitle;
    if (isPriv) {
      if (recipientUserIds.isNotEmpty) {
        badgeTitle = 'To ${recipientUserIds.first}';
      } else if (inviteEmails.isNotEmpty) {
        badgeTitle = 'To ${inviteEmails.first}';
      } else {
        badgeTitle = 'To Private Recipient';
      }
    } else {
      badgeTitle = 'To Everyone (public)';
    }

    final bgImage = (mediaUrl != null && mediaUrl!.isNotEmpty)
        ? mediaUrl!
        : (id.isNotEmpty
            ? 'https://vera.aptechmedia.com/api/v1/moments/$id/media'
            : '');

    final avatar = (creatorAvatarUrl != null && creatorAvatarUrl!.isNotEmpty)
        ? creatorAvatarUrl!
        : '';

    return Moment(
      id: id,
      userName: creatorName ?? 'You',
      userAvatarUrl: avatar,
      timeAgo: timeAgoText,
      backgroundImageUrl: bgImage,
      unlockCondition: conditionText,
      unlockType: isDateUnlock ? MomentUnlockType.time : MomentUnlockType.location,
      isReadyToOpen: isReadyToOpen,
      sentBadgeTitle: badgeTitle,
      sentBadgeSubtitle: invitationStatus == 'PENDING'
          ? 'Pending invitation'
          : (invitationStatus == 'ACCEPTED'
              ? 'Invitation accepted'
              : (invitationStatus == 'DECLINED'
                  ? 'Invitation declined'
                  : (status == 'PENDING_REVIEW'
                      ? 'Pending review'
                      : (status == 'DRAFT'
                          ? 'Draft'
                          : (status == 'PUBLISHED'
                              ? 'Published'
                              : (status == 'REJECTED'
                                  ? 'Rejected'
                                  : (isPriv ? timeAgoText : 'Pending review'))))))),
      isPublicSentMoment: !isPriv,
      message: message,
      title: title,
      teaser: teaser,
      version: version,
      status: status,
      invitationStatus: invitationStatus,
      unlockedAt: unlockedAt,
      openedAt: openedAt,
      unlockAt: unlockAt,
      isVideo: isVideo,
      contentType: contentType,
      hasMedia: hasMedia,
    );
  }
}
