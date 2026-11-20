import 'package:flutter/painting.dart';

import '../../../../core/network/api_client.dart';

/// Authenticate Vera avatar endpoints without sharing tokens with external hosts.
NetworkImage creatorAvatarImage(ApiClient client, String avatarUrl) {
  final base = Uri.parse(client.config.apiBaseUrl);
  final uri = base.resolve(avatarUrl.trim());
  final token = client.authToken;
  return NetworkImage(
    uri.toString(),
    headers: uri.origin == base.origin && token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : null,
  );
}
