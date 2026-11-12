import '../../domain/entities/registered_user.dart';

class RegistrationResult {
  const RegistrationResult({required this.message, required this.user});

  final String message;
  final RegisteredUser user;

  factory RegistrationResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Registration response is missing user data.');
    }
    return RegistrationResult(
      message: json['message']?.toString() ?? 'Registration successful.',
      user: RegisteredUser(
        id: userJson['id']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        displayName: userJson['displayName']?.toString() ?? '',
      ),
    );
  }
}
