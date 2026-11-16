class ResendInviteResult {
  const ResendInviteResult({
    required this.attempted,
    required this.sent,
    required this.failed,
    this.message,
    this.raw = const {},
  });

  final int attempted;
  final int sent;
  final int failed;
  final String? message;
  final Map<String, dynamic> raw;

  factory ResendInviteResult.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const ResendInviteResult(
        attempted: 0,
        sent: 0,
        failed: 0,
      );
    }

    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final attempted = (data['attempted'] as num?)?.toInt() ??
        (json['attempted'] as num?)?.toInt() ??
        0;
    final sent = (data['sent'] as num?)?.toInt() ??
        (json['sent'] as num?)?.toInt() ??
        0;
    final failed = (data['failed'] as num?)?.toInt() ??
        (json['failed'] as num?)?.toInt() ??
        0;
    final message = data['message']?.toString() ?? json['message']?.toString();

    return ResendInviteResult(
      attempted: attempted,
      sent: sent,
      failed: failed,
      message: message,
      raw: json,
    );
  }
}
