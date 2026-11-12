import '../../domain/entities/registered_user.dart';

class LoginResult {
  const LoginResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final RegisteredUser user;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) {
      throw const FormatException('Login response is missing user data.');
    }
    return LoginResult(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      tokenType: json['tokenType']?.toString() ?? 'Bearer',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      user: RegisteredUser(
        id: userJson['id']?.toString() ?? '',
        email: userJson['email']?.toString() ?? '',
        displayName: userJson['displayName']?.toString() ?? '',
      ),
    );
  }
}
