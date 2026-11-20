import 'package:flutter_test/flutter_test.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/features/home/presentation/utils/creator_avatar_image.dart';

void main() {
  test('Vera relative and absolute avatar endpoints include the current token', () {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://vera.aptechmedia.com'),
      initialAuthToken: 'test-token',
    );
    addTearDown(client.close);
    for (final url in [
      '/api/v1/discover/users/creator/avatar',
      'https://vera.aptechmedia.com/api/v1/discover/users/creator/avatar',
    ]) {
      final image = creatorAvatarImage(client, url);
      expect(image.url, 'https://vera.aptechmedia.com/api/v1/discover/users/creator/avatar');
      expect(image.headers, {'Authorization': 'Bearer test-token'});
    }
  });

  test('external avatars never receive the session token; logged-out requests have none', () {
    final client = ApiClient(
      config: const AppConfig(apiBaseUrl: 'https://vera.aptechmedia.com'),
      initialAuthToken: 'test-token',
    );
    final loggedOut = ApiClient(config: client.config);
    addTearDown(client.close);
    addTearDown(loggedOut.close);
    for (final url in [
      'https://images.example.com/avatar.jpg',
      'http://vera.aptechmedia.com/avatar',
      'https://vera.aptechmedia.com:8443/avatar',
    ]) {
      expect(creatorAvatarImage(client, url).headers, isNull);
    }
    expect(creatorAvatarImage(loggedOut, '/api/v1/discover/users/creator/avatar').headers, isNull);
  });
}
