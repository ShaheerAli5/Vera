class AdminLoginResult {
  const AdminLoginResult({
    required this.accessToken,
  });

  final String accessToken;

  factory AdminLoginResult.fromJson(Map<String, dynamic> json) {
    return AdminLoginResult(
      accessToken: json['adminAccessToken']?.toString() ?? '',
    );
  }
}
