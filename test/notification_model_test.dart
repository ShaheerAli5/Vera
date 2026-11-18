import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/home/data/models/notification_model.dart';

void main() {
  test('parses backend invitation notification metadata and read state', () {
    final notification = NotificationModel.fromJson({
      'id': 'notification-id',
      'type': 'MOMENT_INVITATION',
      'title': 'New Private Moment',
      'body': 'A moment is waiting for you',
      'data': {'momentId': 'moment-id'},
      'readAt': '2026-11-18T09:00:00.000Z',
      'createdAt': '2026-11-18T08:00:00.000Z',
    });

    expect(notification.type, 'MOMENT_INVITATION');
    expect(notification.data['momentId'], 'moment-id');
    expect(notification.isRead, isTrue);
  });
}
