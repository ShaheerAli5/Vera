import 'package:flutter/painting.dart';

import '../../../../core/network/api_client.dart';

/// Authenticate Vera avatar endpoints without sharing tokens with external hosts.
NetworkImage creatorAvatarImage(ApiClient client, String avatarUrl) {
  final trimmed = avatarUrl.trim();
  final apiBaseUrl = client.config.apiBaseUrl;
  final baseUri = Uri.parse(apiBaseUrl);
  final baseOrigin = baseUri.origin;

  Uri uri;
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    uri = Uri.parse(trimmed);
  } else if (trimmed.startsWith('/api/')) {
    uri = Uri.parse('$baseOrigin$trimmed');
  } else if (trimmed.startsWith('/')) {
    final cleanPath = baseUri.path.endsWith('/')
        ? baseUri.path.substring(0, baseUri.path.length - 1)
        : baseUri.path;
    uri = Uri.parse('$baseOrigin$cleanPath$trimmed');
  } else {
    uri = baseUri.resolve(trimmed);
  }

  final token = client.authToken;
  return NetworkImage(
    uri.toString(),
    headers: uri.origin == baseOrigin && token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null,
  );
}
