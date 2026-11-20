import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Caches and serializes user-triggered search/address lookups.
class LocationGeocodingDataSource {
  LocationGeocodingDataSource({
    http.Client? client,
    this.baseUrl = const String.fromEnvironment(
      'GEOCODING_BASE_URL',
      defaultValue: 'https://nominatim.openstreetmap.org',
    ),
    this.requestInterval = const Duration(seconds: 1),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;
  final Duration requestInterval;
  static Future<void> _queue = Future.value();
  static final _requestClock = Stopwatch()..start();
  static Duration? _lastRequest;
  final _cache = <String, Object?>{};
  bool _closed = false;

  Future<Object?> _get(String path, Map<String, String> query) async {
    final uri = Uri.parse('$baseUrl/$path').replace(queryParameters: query);
    final key = uri.toString();
    if (_cache.containsKey(key)) return _cache[key];
    final request = _queue.then((_) async {
      if (_closed) throw StateError('Place lookup closed');
      if (_cache.containsKey(key)) return _cache[key];
      final last = _lastRequest;
      if (last != null) {
        final remaining = requestInterval - (_requestClock.elapsed - last);
        if (remaining > Duration.zero) await Future<void>.delayed(remaining);
      }
      if (_closed) throw StateError('Place lookup closed');
      _lastRequest = _requestClock.elapsed;
      final response = await _client
          .get(
            uri,
            headers: const {
              'Accept': 'application/json',
              'User-Agent': 'VERA/1.0 (+https://vera.aptechmedia.com)',
            },
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw StateError('Place lookup unavailable');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map && decoded['error'] != null) {
        throw StateError('No address found');
      }
      if (_cache.length >= 100) _cache.remove(_cache.keys.first);
      _cache[key] = decoded;
      return decoded;
    });
    _queue = request.then<void>(
      (_) {},
      onError: (Object _, StackTrace stack) {},
    );
    return request;
  }

  Future<Object?> search(String query) => _get('search', {
    'q': query,
    'format': 'jsonv2',
    'addressdetails': '1',
    'limit': '5',
  });

  Future<String?> reverseName(double latitude, double longitude) async {
    final result = await _get('reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
      'zoom': '18',
      'accept-language': 'en',
    });
    if (result is! Map) return null;
    for (final value in [result['display_name'], result['name']]) {
      final name = value?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }
    return null;
  }

  void close() {
    _closed = true;
    if (_ownsClient) _client.close();
  }
}
