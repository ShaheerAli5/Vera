class MomentUnlockRule {
  const MomentUnlockRule({
    this.type = 'DATE',
    this.unlockAt,
    this.timezone,
    this.latitude,
    this.longitude,
    this.radiusM,
    this.placeName,
  });

  final String type;
  final String? unlockAt;
  final String? timezone;
  final double? latitude;
  final double? longitude;
  final int? radiusM;
  final String? placeName;

  static String normalizeIanaTimezone(String? tz) {
    if (tz == null || tz.trim().isEmpty) return 'UTC';
    final trimmed = tz.trim();
    if (trimmed.contains('/') || trimmed.toUpperCase() == 'UTC') {
      return trimmed;
    }
    final upper = trimmed.toUpperCase();
    switch (upper) {
      case 'PKT':
        return 'Asia/Karachi';
      case 'IST':
        return 'Asia/Kolkata';
      case 'BST':
      case 'GMT':
        return 'Europe/London';
      case 'CET':
      case 'CEST':
        return 'Europe/Paris';
      case 'EST':
      case 'EDT':
        return 'America/New_York';
      case 'CST':
      case 'CDT':
        return 'America/Chicago';
      case 'MST':
      case 'MDT':
        return 'America/Denver';
      case 'PST':
      case 'PDT':
        return 'America/Los_Angeles';
      case 'GST':
        return 'Asia/Dubai';
      case 'SGT':
        return 'Asia/Singapore';
      case 'JST':
        return 'Asia/Tokyo';
      case 'AEST':
      case 'AEDT':
        return 'Australia/Sydney';
    }

    final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
    switch (offsetMinutes) {
      case 300:
        return 'Asia/Karachi';
      case 330:
        return 'Asia/Kolkata';
      case 240:
        return 'Asia/Dubai';
      case 480:
        return 'Asia/Singapore';
      case 540:
        return 'Asia/Tokyo';
      case 600:
        return 'Australia/Sydney';
      case -300:
        return 'America/New_York';
      case -360:
        return 'America/Chicago';
      case -420:
        return 'America/Denver';
      case -480:
        return 'America/Los_Angeles';
      case 60:
        return 'Europe/Paris';
      default:
        return 'UTC';
    }
  }

  Map<String, dynamic> toJson() {
    final t = type.toUpperCase();
    if (t == 'LOCATION') {
      return {
        'type': 'LOCATION',
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (radiusM != null) 'radiusM': radiusM,
        if (placeName != null && placeName!.isNotEmpty) 'placeName': placeName,
      };
    }
    return {
      'type': 'DATE',
      if (unlockAt != null) 'unlockAt': unlockAt,
      'timezone': normalizeIanaTimezone(timezone),
    };
  }

  factory MomentUnlockRule.fromJson(Map<String, dynamic> json) {
    return MomentUnlockRule(
      type: json['type']?.toString().toUpperCase() ?? 'DATE',
      unlockAt: json['unlockAt']?.toString(),
      timezone: json['timezone']?.toString() ?? 'UTC',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      radiusM: (json['radiusM'] as num?)?.toInt(),
      placeName: json['placeName']?.toString(),
    );
  }
}

class CreateMomentParams {
  const CreateMomentParams({
    required this.title,
    required this.category,
    required this.teaser,
    this.message,
    this.visibility = 'PRIVATE',
    this.recipientUserIds = const [],
    this.inviteEmails = const [],
    required this.unlockRule,
    this.expiresAt,
  });

  final String title;
  final String category;
  final String teaser;
  final String? message;
  final String visibility;
  final List<String> recipientUserIds;
  final List<String> inviteEmails;
  final MomentUnlockRule unlockRule;
  final String? expiresAt;

  static String normalizeCategory(String cat) {
    final upper = cat.trim().toUpperCase();
    if (upper == 'BIRTHDAYS') return 'BIRTHDAY';
    if (['TRAVEL', 'NATURE', 'BIRTHDAY', 'LOVE', 'OTHER'].contains(upper)) {
      return upper;
    }
    return 'OTHER';
  }

  Map<String, dynamic> toJson() {
    final isPublic = visibility.toUpperCase() == 'PUBLIC';

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    final cleanRecipientUserIds = recipientUserIds
        .map((id) => id.trim())
        .where((id) => uuidRegex.hasMatch(id))
        .toList();

    final allEmails = <String>{
      ...inviteEmails.map((e) => e.trim()).where((e) => e.contains('@')),
      ...recipientUserIds.map((id) => id.trim()).where((id) => id.contains('@')),
    }.toList();

    return {
      'title': title,
      'category': normalizeCategory(category),
      'teaser': teaser,
      if (message != null && message!.isNotEmpty) 'message': message,
      'visibility': visibility.toUpperCase(),
      if (!isPublic && cleanRecipientUserIds.isNotEmpty)
        'recipientUserIds': cleanRecipientUserIds,
      if (!isPublic && allEmails.isNotEmpty)
        'inviteEmails': allEmails,
      'unlockRule': unlockRule.toJson(),
      if (expiresAt != null && expiresAt!.isNotEmpty)
        'expiresAt': expiresAt,
    };
  }

  CreateMomentParams copyWith({
    String? title,
    String? category,
    String? teaser,
    String? message,
    String? visibility,
    List<String>? recipientUserIds,
    List<String>? inviteEmails,
    MomentUnlockRule? unlockRule,
    String? expiresAt,
  }) {
    return CreateMomentParams(
      title: title ?? this.title,
      category: category ?? this.category,
      teaser: teaser ?? this.teaser,
      message: message ?? this.message,
      visibility: visibility ?? this.visibility,
      recipientUserIds: recipientUserIds ?? this.recipientUserIds,
      inviteEmails: inviteEmails ?? this.inviteEmails,
      unlockRule: unlockRule ?? this.unlockRule,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
