class ResetPasswordResult {
  const ResetPasswordResult({
    required this.message,
    this.accessToken,
    this.refreshToken,
  });

  final String message;
  final String? accessToken;
  final String? refreshToken;

  factory ResetPasswordResult.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResult(
      message: json['message']?.toString() ??
          'Your password has been reset successfully.',
      accessToken:
          json['accessToken']?.toString() ?? json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }
}
