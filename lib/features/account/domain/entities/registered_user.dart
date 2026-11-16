class RegisteredUser {
  const RegisteredUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.role,
  });

  final String id;
  final String email;
  final String displayName;
  final String? role;
}
