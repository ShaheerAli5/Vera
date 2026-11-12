class ResendOtpResult {
  const ResendOtpResult({required this.message});

  final String message;

  factory ResendOtpResult.fromJson(Map<String, dynamic> json) {
    return ResendOtpResult(
      message: json['message']?.toString() ??
          'A new verification code has been sent.',
    );
  }
}
