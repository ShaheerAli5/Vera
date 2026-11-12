class UpdateMomentParams {
  const UpdateMomentParams({
    required this.version,
    this.title,
    this.teaser,
    this.category,
    this.message,
    this.visibility,
  });

  final int version;
  final String? title;
  final String? teaser;
  final String? category;
  final String? message;
  final String? visibility;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      if (title != null && title!.isNotEmpty) 'title': title,
      if (teaser != null && teaser!.isNotEmpty) 'teaser': teaser,
      if (category != null && category!.isNotEmpty) 'category': category!.toUpperCase(),
      if (message != null && message!.isNotEmpty) 'message': message,
      if (visibility != null && visibility!.isNotEmpty) 'visibility': visibility!.toUpperCase(),
    };
  }
}
