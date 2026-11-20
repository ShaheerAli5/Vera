enum UserRole {
  owner, // Admin / Owner
  user;  // Normal User

  static UserRole parse(String? roleStr) {
    if (roleStr == null || roleStr.trim().isEmpty) return UserRole.user;
    final normalized = roleStr.trim().toLowerCase();
    if (normalized == 'owner' || normalized == 'admin') {
      return UserRole.owner;
    }
    return UserRole.user;
  }

  bool get isOwner => this == UserRole.owner;
  bool get isUser => this == UserRole.user;

  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.user:
        return 'user';
    }
  }
}
