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
}
