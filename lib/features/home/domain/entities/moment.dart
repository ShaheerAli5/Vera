enum MomentUnlockType {
  location,
  time,
}

class Moment {
  const Moment({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.timeAgo,
    required this.backgroundImageUrl,
    required this.unlockCondition,
    this.unlockType = MomentUnlockType.location,
    this.isReadyToOpen = false,
    this.sentBadgeTitle,
    this.sentBadgeSubtitle,
    this.isPublicSentMoment = false,
    this.message,
    this.title,
    this.teaser,
    this.version = 1,
    this.status,
    this.invitationStatus,
    this.unlockedAt,
    this.openedAt,
  });

  final String id;
  final String userName;
  final String userAvatarUrl;
  final String timeAgo;
  final String backgroundImageUrl;
  final String unlockCondition;
  final MomentUnlockType unlockType;
  final bool isReadyToOpen;
  final String? sentBadgeTitle;
  final String? sentBadgeSubtitle;
  final bool isPublicSentMoment;
  final String? message;
  final String? title;
  final String? teaser;
  final int version;
  final String? status;
  final String? invitationStatus;
  final DateTime? unlockedAt;
  final DateTime? openedAt;

  Moment copyWith({
    String? id,
    String? userName,
    String? userAvatarUrl,
    String? timeAgo,
    String? backgroundImageUrl,
    String? unlockCondition,
    MomentUnlockType? unlockType,
    bool? isReadyToOpen,
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
  }) {
    return Moment(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      timeAgo: timeAgo ?? this.timeAgo,
      backgroundImageUrl: backgroundImageUrl ?? this.backgroundImageUrl,
      unlockCondition: unlockCondition ?? this.unlockCondition,
      unlockType: unlockType ?? this.unlockType,
      isReadyToOpen: isReadyToOpen ?? this.isReadyToOpen,
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
    );
  }
}
