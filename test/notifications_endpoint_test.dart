import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vera/core/config/app_config.dart';
import 'package:vera/core/network/api_client.dart';
import 'package:vera/core/network/api_exception.dart';
import 'package:vera/features/home/data/datasources/moments_remote_data_source.dart';

void main() {
  test(
    'notification request uses supported limit and no page parameter',
    () async {
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/notifications');
          expect(request.url.queryParameters, {'limit': '20'});
          return http.Response(
            '{"items":[{"id":"event","title":"Approved","type":"ADMIN_APPROVAL"}]}',
            200,
          );
        }),
      );
      addTearDown(client.close);
      final result = await MomentsRemoteDataSource(client).getNotifications();
      expect(result.items.single.id, 'event');
    },
  );

  test(
    'empty notification list does not trigger synthetic inbox fallback',
    () async {
      var requests = 0;
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        httpClient: MockClient((request) async {
          requests++;
          expect(request.url.path, '/api/v1/notifications');
          return http.Response(
            '{"items":[],"nextCursor":null,"hasMore":false}',
            200,
          );
        }),
      );
      addTearDown(client.close);
      expect(
        (await MomentsRemoteDataSource(client).getNotifications()).items,
        isEmpty,
      );
      expect(requests, 1);
    },
  );

  test(
    'notification endpoint failures reach the caller instead of becoming empty success',
    () async {
      final client = ApiClient(
        config: const AppConfig(apiBaseUrl: 'https://example.com'),
        httpClient: MockClient(
          (_) async => http.Response('{"message":"Service unavailable"}', 503),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        MomentsRemoteDataSource(client).getNotifications(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 503)),
      );
    },
  );
}
