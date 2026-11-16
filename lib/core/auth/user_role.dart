enum UserRole {
  owner, // Admin / Owner
  user;  // Normal User

  static UserRole? parse(String? roleStr) {
    if (roleStr == null) return null;
    final normalized = roleStr.trim().toLowerCase();
    if (normalized == 'owner' || normalized == 'admin') {
      return UserRole.owner;
    }
    if (normalized == 'user') {
      return UserRole.user;
    }
    return null;
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
