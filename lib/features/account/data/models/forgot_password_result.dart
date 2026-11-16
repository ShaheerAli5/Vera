class ForgotPasswordResult {
  const ForgotPasswordResult({required this.message});

  final String message;

  factory ForgotPasswordResult.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResult(
      message: json['message']?.toString() ??
          'If an eligible account exists, a reset code has been sent.',
    );
  }
}
