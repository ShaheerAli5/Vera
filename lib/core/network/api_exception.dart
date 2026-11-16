class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.code,
    this.details,
  });

  final int statusCode;
  final String message;
  final String? code;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
