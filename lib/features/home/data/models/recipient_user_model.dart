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
    final avatar = json['avatarUrl']?.toString() ??
        json['avatar_url']?.toString() ??
        json['avatar']?.toString() ??
        json['profilePicture']?.toString();
    final fullAvatarUrl = (avatar != null && avatar.startsWith('/'))
        ? 'https://vera.aptechmedia.com$avatar'
        : avatar;

    final displayName = json['displayName']?.toString() ??
        json['name']?.toString() ??
        json['fullName']?.toString() ??
        json['username']?.toString() ??
        'User';

    final username = json['username']?.toString() ??
        json['handle']?.toString() ??
        json['user_name']?.toString();

    return RecipientUserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      displayName: displayName,
      username: username,
      email: json['email']?.toString(),
      avatarUrl: fullAvatarUrl,
    );
  }
}
