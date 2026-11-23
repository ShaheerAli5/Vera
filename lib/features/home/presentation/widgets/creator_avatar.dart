import 'package:flutter/material.dart';

import '../../../../main.dart' show ApiClientScope;
import '../utils/creator_avatar_image.dart';

/// Keeps the creator identifiable until their photo's first decoded frame.
class CreatorAvatar extends StatelessWidget {
  const CreatorAvatar({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 36,
  });

  final String name;
  final String? avatarUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final trimmedName = name.trim();
    final initial = trimmedName.isEmpty ? '?' : trimmedName.characters.first.toUpperCase();
    final placeholder = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF58C3F4), Color(0xFF8E37FF)],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.44,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );

    final url = avatarUrl?.trim() ?? '';
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: url.isEmpty
            ? placeholder
            : Image(
                image: creatorAvatarImage(ApiClientScope.of(context), url),
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) =>
                    frame != null || wasSynchronouslyLoaded ? child : placeholder,
                errorBuilder: (context, error, stackTrace) => placeholder,
              ),
      ),
    );
  }
}
