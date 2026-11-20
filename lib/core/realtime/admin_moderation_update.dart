/// Admin moderation is separate from recipient availability. These messages
/// must never grant access to private content.
class ModerationCounts {
  const ModerationCounts({
    required this.pendingReview,
    required this.approved,
    required this.rejected,
  });
  final int pendingReview;
  final int approved;
  final int rejected;

  static ModerationCounts? parse(dynamic payload) {
    if (payload is! Map) return null;
    int? count(String key) {
      final value = payload[key];
      return value is num &&
              value.isFinite &&
              value >= 0 &&
              value == value.roundToDouble()
          ? value.toInt()
          : null;
    }

    final pending = count('pendingReview');
    final approved = count('approved');
    final rejected = count('rejected');
    if (pending == null || approved == null || rejected == null) return null;
    return ModerationCounts(
      pendingReview: pending,
      approved: approved,
      rejected: rejected,
    );
  }
}

class AdminModerationUpdate {
  const AdminModerationUpdate({
    this.momentId,
    this.transition,
    this.status,
    this.version,
    this.counts,
    this.serverTime,
  });
  final String? momentId;
  final String? transition;
  final String? status;
  final int? version;
  final ModerationCounts? counts;
  final DateTime? serverTime;
  bool get removesFromQueue =>
      transition == 'APPROVED' ||
      transition == 'REJECTED' ||
      transition == 'DELETED';
  bool get isTransition => momentId != null && transition != null;

  static AdminModerationUpdate? parse(String event, dynamic payload) {
    if (payload is! Map) return null;
    final data = payload['data'] is Map ? payload['data'] as Map : payload;
    final id = data['momentId'];
    final rawTransition = data['transition'];
    const transitions = {
      'admin:moderation:submitted': 'SUBMITTED',
      'admin:moderation:approved': 'APPROVED',
      'admin:moderation:rejected': 'REJECTED',
      'admin:moderation:deleted': 'DELETED',
    };
    final transition = rawTransition is String
        ? rawTransition.toUpperCase()
        : transitions[event];
    final counts = ModerationCounts.parse(data['moderationCounts']);
    final version = data['version'];
    final validId = id is String && id.isNotEmpty ? id : null;
    final validTransition =
        const [
          'SUBMITTED',
          'APPROVED',
          'REJECTED',
          'DELETED',
        ].contains(transition)
        ? transition
        : null;
    if (event != 'admin:moderation:subscribed' &&
        (validId == null || validTransition == null)) {
      return null;
    }
    if (event == 'admin:moderation:subscribed' && counts == null) return null;
    return AdminModerationUpdate(
      momentId: validId,
      transition: validTransition,
      status: data['status'] is String
          ? (data['status'] as String).toUpperCase()
          : null,
      version:
          version is num &&
              version.isFinite &&
              version >= 0 &&
              version == version.roundToDouble()
          ? version.toInt()
          : null,
      counts: counts,
      serverTime: data['serverTime'] is String
          ? DateTime.tryParse(data['serverTime'] as String)
          : null,
    );
  }
}
