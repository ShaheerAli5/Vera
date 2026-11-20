enum MomentUnlockType { location, time }

class Moment {
  const Moment({
    required this.id,
    this.creatorId,
    required this.userName,
    required this.userAvatarUrl,
    required this.timeAgo,
    this.createdAt,
    this.publishedAt,
    required this.backgroundImageUrl,
    this.clueCoverImageUrl = '',
    required this.unlockCondition,
    this.unlockType = MomentUnlockType.location,
    this.isReadyToOpen = false,
    this.isApproved,
    this.sentBadgeTitle,
    String? sentBadgeSubtitle,
    this.isPublicSentMoment = false,
    this.message,
    this.title,
    this.teaser,
    this.version = 1,
    this.status,
    this.invitationStatus,
    this.unlockedAt,
    this.openedAt,
    this.unlockAt,
    this.unlockLatitude,
    this.unlockLongitude,
    this.unlockRadiusM,
    this.unlockPlaceName,
    this.isVideo = false,
    this.contentType,
    this.hasMedia = true,
  }) : _sentBadgeSubtitle = sentBadgeSubtitle;

  final String id;
  final String? creatorId;
  final String userName;
  final String userAvatarUrl;
  final String timeAgo;
  final DateTime? createdAt;
  final DateTime? publishedAt;
  final String backgroundImageUrl;
  /// Separate preview supplied by the backend, safe to display while locked.
  final String clueCoverImageUrl;
  final String unlockCondition;
  final MomentUnlockType unlockType;
  final bool isReadyToOpen;
  final bool? isApproved;
  bool get needsInvitationAcceptance =>
      invitationStatus == 'PENDING' || invitationStatus == 'DECLINED';
  bool get canAccessContent =>
      isReadyToOpen && !needsInvitationAcceptance && isApproved != false;
  final String? sentBadgeTitle;
  final String? _sentBadgeSubtitle;
  // Derived at display time so socket status updates cannot retain an old label.
  String? get sentBadgeSubtitle => badgeSubtitleFor(
    invitationStatus: invitationStatus,
    status: status,
    fallback: _sentBadgeSubtitle,
  );

  static String? badgeSubtitleFor({
    String? invitationStatus,
    String? status,
    String? fallback,
  }) {
    switch (invitationStatus?.toUpperCase()) {
      case 'PENDING':
        return 'Pending invitation';
      case 'ACCEPTED':
        return 'Invitation accepted';
      case 'DECLINED':
        return 'Invitation declined';
    }
    switch (status?.toUpperCase()) {
      case 'PENDING_REVIEW':
        return 'Pending review';
      case 'DRAFT':
        return 'Draft';
      case 'PUBLISHED':
        return 'Published';
      case 'REJECTED':
        return 'Rejected';
    }
    return fallback;
  }

  final bool isPublicSentMoment;
  final String? message;
  final String? title;
  final String? teaser;
  final int version;
  final String? status;
  final String? invitationStatus;
  final DateTime? unlockedAt;
  final DateTime? openedAt;
  final DateTime? unlockAt;
  final double? unlockLatitude;
  final double? unlockLongitude;
  final int? unlockRadiusM;
  final String? unlockPlaceName;
  final bool isVideo;
  final String? contentType;
  final bool hasMedia;

  Moment copyWith({
    String? id,
    String? creatorId,
    String? userName,
    String? userAvatarUrl,
    String? timeAgo,
    DateTime? createdAt,
    DateTime? publishedAt,
    String? backgroundImageUrl,
    String? clueCoverImageUrl,
    String? unlockCondition,
    MomentUnlockType? unlockType,
    bool? isReadyToOpen,
    bool? isApproved,
    String? sentBadgeTitle,
    String? sentBadgeSubtitle,
    bool? isPublicSentMoment,
    String? message,
    String? title,
    String? teaser,
    int? version,
    String? status,
    String? invitationStatus,
    DateTime? unlockedAt,
    DateTime? openedAt,
    DateTime? unlockAt,
    double? unlockLatitude,
    double? unlockLongitude,
    int? unlockRadiusM,
    String? unlockPlaceName,
    bool? isVideo,
    String? contentType,
    bool? hasMedia,
  }) {
    return Moment(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      timeAgo: timeAgo ?? this.timeAgo,
      createdAt: createdAt ?? this.createdAt,
      publishedAt: publishedAt ?? this.publishedAt,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      clueCoverImageUrl: clueCoverImageUrl ?? this.clueCoverImageUrl,
      unlockCondition: unlockCondition ?? this.unlockCondition,
      unlockType: unlockType ?? this.unlockType,
      isReadyToOpen: isReadyToOpen ?? this.isReadyToOpen,
      isApproved: isApproved ?? this.isApproved,
      sentBadgeTitle: sentBadgeTitle ?? this.sentBadgeTitle,
      sentBadgeSubtitle: sentBadgeSubtitle ?? this.sentBadgeSubtitle,
      isPublicSentMoment: isPublicSentMoment ?? this.isPublicSentMoment,
      message: message ?? this.message,
      title: title ?? this.title,
      teaser: teaser ?? this.teaser,
      version: version ?? this.version,
      status: status ?? this.status,
      invitationStatus: invitationStatus ?? this.invitationStatus,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      openedAt: openedAt ?? this.openedAt,
      unlockAt: unlockAt ?? this.unlockAt,
      unlockLatitude: unlockLatitude ?? this.unlockLatitude,
      unlockLongitude: unlockLongitude ?? this.unlockLongitude,
      unlockRadiusM: unlockRadiusM ?? this.unlockRadiusM,
      unlockPlaceName: unlockPlaceName ?? this.unlockPlaceName,
      isVideo: isVideo ?? this.isVideo,
      contentType: contentType ?? this.contentType,
      hasMedia: hasMedia ?? this.hasMedia,
    );
  }
}
