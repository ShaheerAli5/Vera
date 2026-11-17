import '../../../../core/network/api_client.dart';

String adminMomentMediaUrl(ApiClient client, String? mediaUrl, String momentId) {
  final rawUrl = mediaUrl?.trim();
  if (rawUrl == null || rawUrl.isEmpty) {
    return client.config.endpoint('/admin/moments/$momentId/media').toString();
  }

  if (rawUrl.contains('/moments/$momentId/media') && !rawUrl.contains('/admin/moments/')) {
    return client.config.endpoint('/admin/moments/$momentId/media').toString();
  }

  final parsed = Uri.tryParse(rawUrl);
  if (parsed != null && parsed.hasScheme) return rawUrl;

  if (rawUrl.startsWith('/api/')) {
    final base = Uri.parse(client.config.apiBaseUrl);
    return base.replace(path: rawUrl).toString();
  }
  return client.config.endpoint(rawUrl).toString();
}

Map<String, String> adminMediaHeaders(ApiClient client) {
  final token = client.authToken;
  return {
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}
