class CreateMomentResult {
  const CreateMomentResult({
    required this.id,
    this.version = 1,
    this.title,
    this.category,
    this.teaser,
    this.message,
    this.visibility,
    this.status,
    this.unlockAt,
    this.timezone,
    this.createdAt,
    this.raw = const {},
  });

  final String id;
  final int version;
  final String? title;
  final String? category;
  final String? teaser;
  final String? message;
  final String? visibility;
  final String? status;
  final String? unlockAt;
  final String? timezone;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory CreateMomentResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : (json['moment'] is Map<String, dynamic>
            ? json['moment'] as Map<String, dynamic>
            : json);

    final unlockRule = data['unlockRule'] is Map<String, dynamic>
        ? data['unlockRule'] as Map<String, dynamic>
        : (data['unlock_rule'] is Map<String, dynamic>
            ? data['unlock_rule'] as Map<String, dynamic>
            : null);

    final rawCreated = data['createdAt'] ?? data['created_at'];
    final createdAt = rawCreated is String ? DateTime.tryParse(rawCreated) : null;

    return CreateMomentResult(
      id: data['id']?.toString() ??
          data['_id']?.toString() ??
          json['id']?.toString() ??
          '',
      version: (data['version'] as num?)?.toInt() ??
          (data['__v'] as num?)?.toInt() ??
          (json['version'] as num?)?.toInt() ??
          1,
      title: data['title']?.toString(),
      category: data['category']?.toString(),
      teaser: data['teaser']?.toString(),
      message: data['message']?.toString(),
      visibility: data['visibility']?.toString(),
      status: data['status']?.toString(),
      unlockAt: unlockRule?['unlockAt']?.toString() ??
          data['unlockAt']?.toString(),
      timezone: unlockRule?['timezone']?.toString() ??
          data['timezone']?.toString(),
      createdAt: createdAt,
      raw: json,
    );
  }
}
