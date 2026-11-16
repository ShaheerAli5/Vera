import 'dart:typed_data';

class MomentMediaStream {
  const MomentMediaStream({
    required this.bytes,
    this.contentType,
    this.contentLength,
  });

  final Uint8List bytes;
  final String? contentType;
  final int? contentLength;

  bool get isVideo => contentType?.toLowerCase().contains('video') == true;
  bool get isImage => contentType?.toLowerCase().contains('image') == true;
}
