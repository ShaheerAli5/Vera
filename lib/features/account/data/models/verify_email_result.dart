import '../../domain/entities/registered_user.dart';

class VerifyEmailResult {
  const VerifyEmailResult({
    required this.message,
    this.user,
    this.token,
    this.refreshToken,
    this.data,
  });

  final String message;
  final RegisteredUser? user;
  final String? token;
  final String? refreshToken;
  final Map<String, dynamic>? data;

  factory VerifyEmailResult.fromJson(Map<String, dynamic> json) {
    final dataObj = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : null;
    final userJson = json['user'] ?? dataObj?['user'];
    final user = userJson is Map<String, dynamic>
        ? RegisteredUser(
            id: userJson['id']?.toString() ?? '',
            email: userJson['email']?.toString() ?? '',
            displayName: userJson['displayName']?.toString() ?? '',
            role: userJson['role']?.toString(),
          )
        : null;

    final token =
        json['token']?.toString() ??
        json['accessToken']?.toString() ??
        json['access_token']?.toString() ??
        dataObj?['token']?.toString() ??
        dataObj?['accessToken']?.toString() ??
        dataObj?['access_token']?.toString();

    final refreshToken =
        json['refreshToken']?.toString() ??
        json['refresh_token']?.toString() ??
        dataObj?['refreshToken']?.toString() ??
        dataObj?['refresh_token']?.toString();

    final rawMessage = json['message'];
    final message = switch (rawMessage) {
      String msg => msg,
      List list => list.map((e) => e.toString()).join('\n'),
      _ => rawMessage?.toString() ?? 'Email verified successfully.',
    };

    return VerifyEmailResult(
      message: message,
      user: user,
      token: token,
      refreshToken: refreshToken,
      data: json,
    );
  }
}
