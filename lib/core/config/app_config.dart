class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    this.apiPrefix = '/api/v1',
  });

  final String apiBaseUrl;
  final String apiPrefix;

  Uri endpoint(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(apiBaseUrl);
    final normalizedPrefix = apiPrefix.startsWith('/')
        ? apiPrefix.substring(1)
        : apiPrefix;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final basePath = base.path.endsWith('/') ? base.path : '${base.path}/';
    return base
        .replace(path: '$basePath$normalizedPrefix/$normalizedPath')
        .replace(queryParameters: queryParameters);
  }
}
