class LogoutResult {
  const LogoutResult({required this.message});

  final String message;

  factory LogoutResult.fromJson(Map<String, dynamic> json) {
    return LogoutResult(
      message: json['message']?.toString() ?? 'Logged out successfully.',
    );
  }
}
