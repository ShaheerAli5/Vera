class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.role,
    this.username,
    this.avatarUrl,
    this.bio,
    this.isEmailVerified = true,
    this.createdAt,
    this.linkedProviders = const [],
    this.raw = const {},
  });

  final String id;
  final String email;
  final String displayName;
  final String? role;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final List<String> linkedProviders;
  final Map<String, dynamic> raw;

  String get effectiveUsername {
    if (username != null && username!.trim().isNotEmpty) {
      final trimmed = username!.trim();
      return trimmed.startsWith('@') ? trimmed : '@$trimmed';
    }
    if (email.contains('@')) {
      final handle = email.split('@').first.trim();
      if (handle.isNotEmpty) return '@$handle';
    }
    return '@user';
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? role,
    String? username,
    String? avatarUrl,
    String? bio,
    bool? isEmailVerified,
    DateTime? createdAt,
    List<String>? linkedProviders,
    Map<String, dynamic>? raw,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      linkedProviders: linkedProviders ?? this.linkedProviders,
      raw: raw ?? this.raw,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final data = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : (json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : (json['data'] is Map<String, dynamic>
                ? (json['data']['user'] is Map<String, dynamic>
                    ? json['data']['user'] as Map<String, dynamic>
                    : json['data'] as Map<String, dynamic>)
                : json));

    final rawProviders = json['linkedProviders'] ??
        json['providers'] ??
        data['linkedProviders'] ??
        data['providers'];

    final providersList = <String>[];
    if (rawProviders is List) {
      for (final p in rawProviders) {
        if (p is String && p.trim().isNotEmpty) {
          providersList.add(p.trim());
        } else if (p is Map<String, dynamic>) {
          final name = p['provider'] ?? p['name'] ?? p['providerId'];
          if (name != null && name.toString().trim().isNotEmpty) {
            providersList.add(name.toString().trim());
          }
        }
      }
    }

    DateTime? parsedDate;
    final dateStr = (data['createdAt'] ?? json['createdAt'])?.toString();
    if (dateStr != null) {
      parsedDate = DateTime.tryParse(dateStr);
    }

    final displayName = (data['displayName'] ??
            data['name'] ??
            json['displayName'] ??
            json['name'])
        ?.toString() ??
        '';

    final email = (data['email'] ?? json['email'])?.toString() ?? '';
    final role = (data['role'] ?? json['role'] ?? (json['user'] is Map ? json['user']['role'] : null))?.toString();

    return UserProfile(
      id: (data['id'] ?? data['_id'] ?? json['id'] ?? '')?.toString() ?? '',
      email: email,
      displayName: displayName.isNotEmpty
          ? displayName
          : (email.isNotEmpty ? email.split('@').first : 'User'),
      role: role,
      username: (data['username'] ?? data['handle'] ?? json['username'])
          ?.toString(),
      avatarUrl: (data['avatarUrl'] ??
              data['photoUrl'] ??
              data['avatar'] ??
              data['profilePicture'] ??
              json['avatarUrl'])
          ?.toString(),
      bio: (data['bio'] ?? json['bio'])?.toString(),
      isEmailVerified: data['isEmailVerified'] == true ||
          json['isEmailVerified'] == true ||
          data['verified'] == true,
      createdAt: parsedDate,
      linkedProviders: providersList,
      raw: json,
    );
  }
}
