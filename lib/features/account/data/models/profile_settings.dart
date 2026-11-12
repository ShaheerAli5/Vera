class ProfileSettings {
  const ProfileSettings({
    this.language = 'en',
    this.timezone = 'UTC',
    this.pushInvitations = true,
    this.pushUnlocks = true,
    this.pushReplies = true,
    this.discoverableByEmail = true,
    this.analyticsEnabled = false,
    this.privacy = 'Everyone',
    this.allowLocationChecks = true,
    this.raw = const {},
  });

  final String language;
  final String timezone;
  final bool pushInvitations;
  final bool pushUnlocks;
  final bool pushReplies;
  final bool discoverableByEmail;
  final bool analyticsEnabled;
  final String privacy;
  final bool allowLocationChecks;
  final Map<String, dynamic> raw;

  bool get pushNotifications => pushInvitations || pushUnlocks || pushReplies;

  ProfileSettings copyWith({
    String? language,
    String? timezone,
    bool? pushInvitations,
    bool? pushUnlocks,
    bool? pushReplies,
    bool? discoverableByEmail,
    bool? analyticsEnabled,
    String? privacy,
    bool? allowLocationChecks,
    Map<String, dynamic>? raw,
  }) {
    return ProfileSettings(
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      pushInvitations: pushInvitations ?? this.pushInvitations,
      pushUnlocks: pushUnlocks ?? this.pushUnlocks,
      pushReplies: pushReplies ?? this.pushReplies,
      discoverableByEmail: discoverableByEmail ?? this.discoverableByEmail,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      privacy: privacy ?? this.privacy,
      allowLocationChecks: allowLocationChecks ?? this.allowLocationChecks,
      raw: raw ?? this.raw,
    );
  }

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    final data = json['settings'] is Map<String, dynamic>
        ? json['settings'] as Map<String, dynamic>
        : (json['data'] is Map<String, dynamic>
            ? (json['data']['settings'] is Map<String, dynamic>
                ? json['data']['settings'] as Map<String, dynamic>
                : json['data'] as Map<String, dynamic>)
            : json);

    final notifs = data['notifications'] is Map<String, dynamic>
        ? data['notifications'] as Map<String, dynamic>
        : (data['notification'] is Map<String, dynamic>
            ? data['notification'] as Map<String, dynamic>
            : const <String, dynamic>{});

    final priv = data['privacy'] is Map<String, dynamic>
        ? data['privacy'] as Map<String, dynamic>
        : const <String, dynamic>{};

    // Language
    final lang = data['language'] ??
        data['locale'] ??
        data['lang'] ??
        json['language'];
    final String language = (lang != null && lang.toString().trim().isNotEmpty)
        ? lang.toString().trim()
        : 'en';

    // Timezone (IANA identifier)
    final tz = data['timezone'] ??
        data['timeZone'] ??
        data['tz'] ??
        json['timezone'];
    final String timezone = (tz != null && tz.toString().trim().isNotEmpty)
        ? tz.toString().trim()
        : 'UTC';

    // Push notification preferences
    final pushInv = data['pushInvitations'] ??
        notifs['pushInvitations'] ??
        notifs['invitations'] ??
        data['invitations'];
    final bool pushInvitations = pushInv is bool ? pushInv : true;

    final pushUnl = data['pushUnlocks'] ??
        notifs['pushUnlocks'] ??
        notifs['unlocks'] ??
        data['unlocks'];
    final bool pushUnlocks = pushUnl is bool ? pushUnl : true;

    final pushRep = data['pushReplies'] ??
        notifs['pushReplies'] ??
        notifs['replies'] ??
        data['replies'];
    final bool pushReplies = pushRep is bool ? pushRep : true;

    // Discoverability & Analytics
    final disc = data['discoverableByEmail'] ??
        priv['discoverableByEmail'] ??
        data['discoverable'];
    final bool discoverableByEmail = disc is bool ? disc : true;

    final analytics = data['analyticsEnabled'] ??
        priv['analyticsEnabled'] ??
        data['analytics'];
    final bool analyticsEnabled = analytics is bool ? analytics : false;

    // Privacy option (Everyone, Contacts, Nobody)
    String privacyOpt = 'Everyone';
    final rawPrivacy = (priv['visibility'] ??
            priv['level'] ??
            priv['option'] ??
            priv['privacy'] ??
            data['privacy'] ??
            data['visibility'])
        ?.toString();
    if (rawPrivacy != null && rawPrivacy.trim().isNotEmpty) {
      final lower = rawPrivacy.toLowerCase().trim();
      if (lower.contains('contact')) {
        privacyOpt = 'Contacts';
      } else if (lower.contains('nobody') ||
          lower.contains('private') ||
          lower.contains('none')) {
        privacyOpt = 'Nobody';
      } else {
        privacyOpt = 'Everyone';
      }
    }

    // Location checks
    final location = priv['allowLocationChecks'] ??
        priv['locationChecks'] ??
        priv['location'] ??
        data['allowLocationChecks'] ??
        data['locationChecks'];
    final bool allowLocationChecks = location is bool ? location : true;

    return ProfileSettings(
      language: language,
      timezone: timezone,
      pushInvitations: pushInvitations,
      pushUnlocks: pushUnlocks,
      pushReplies: pushReplies,
      discoverableByEmail: discoverableByEmail,
      analyticsEnabled: analyticsEnabled,
      privacy: privacyOpt,
      allowLocationChecks: allowLocationChecks,
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language,
      'timezone': timezone,
      'pushInvitations': pushInvitations,
      'pushUnlocks': pushUnlocks,
      'pushReplies': pushReplies,
      'discoverableByEmail': discoverableByEmail,
      'analyticsEnabled': analyticsEnabled,
      'privacy': privacy,
      'allowLocationChecks': allowLocationChecks,
    };
  }
}
