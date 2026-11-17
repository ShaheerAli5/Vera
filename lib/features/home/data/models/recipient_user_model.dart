class RecipientUserModel {
  const RecipientUserModel({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.avatarUrl,
  });

  final String id;
  final String displayName;
  final String? username;
  final String? email;
  final String? avatarUrl;

  factory RecipientUserModel.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatarUrl']?.toString() ?? json['avatar_url']?.toString();
    final fullAvatarUrl = (avatar != null && avatar.startsWith('/'))
        ? 'https://vera.aptechmedia.com$avatar'
        : avatar;

    return RecipientUserModel(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ??
          json['name']?.toString() ??
          json['username']?.toString() ??
          'User',
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      avatarUrl: fullAvatarUrl,
    );
  }
}
