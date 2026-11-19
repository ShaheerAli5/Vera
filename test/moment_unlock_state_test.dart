import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/home/data/models/moment_model.dart';

void main() {
  group('Moment unlock contract', () {
    test('early-approved creator response remains locked', () {
      final response = MomentsListResponse.fromJson({
        'items': [
          {
            'id': 'moment-id',
            'title': 'Early approval',
            'status': 'PUBLISHED',
            'unlock': {
              'type': 'DATE',
              'unlockAt': '2099-11-18T06:05:00.000Z',
              'timezone': 'Asia/Karachi',
            },
            'availability': {
              'isApproved': true,
              'isUnlocked': false,
              'unlockedAt': null,
            },
          },
        ],
        'serverTime': '2099-11-18T06:01:59.000Z',
      });

      final moment = response.moments.single.toEntity();

      expect(moment.status, 'PUBLISHED');
      expect(moment.unlockAt, DateTime.parse('2099-11-18T06:05:00.000Z'));
      expect(moment.isReadyToOpen, isFalse);
    });

    test('raw unlockAtUtc from an older response is parsed and stays locked', () {
      final response = MomentsListResponse.fromJson({
        'items': [
          {
            'id': 'legacy-moment',
            'title': 'Legacy payload',
            'status': 'PUBLISHED',
            'unlockRule': {
              'type': 'DATE',
              'unlockAtUtc': '2099-11-18T06:05:00.000Z',
              'timezoneId': 'Asia/Karachi',
            },
          },
        ],
        'serverTime': '2099-11-18T06:01:59.000Z',
      });

      expect(response.moments.single.toEntity().isReadyToOpen, isFalse);
    });

    test('approved response without an unlock timestamp fails closed', () {
      final model = MomentModel.fromJson({
        'id': 'incomplete-moment',
        'title': 'Incomplete',
        'status': 'PUBLISHED',
      });

      expect(model.toEntity().isReadyToOpen, isFalse);
    });

    test('not-approved Moment remains locked after its scheduled time', () {
      final response = MomentsListResponse.fromJson({
        'items': [
          {
            'id': 'pending-moment',
            'title': 'Pending',
            'status': 'PENDING_REVIEW',
            'unlock': {
              'type': 'DATE',
              'unlockAt': '2099-11-18T06:05:00.000Z',
            },
          },
        ],
        'serverTime': '2099-11-18T06:10:00.000Z',
      });

      expect(response.moments.single.toEntity().isReadyToOpen, isFalse);
    });

    test('approved Moment becomes ready when server-synchronised time is due', () {
      final response = MomentsListResponse.fromJson({
        'items': [
          {
            'id': 'due-moment',
            'title': 'Due',
            'status': 'PUBLISHED',
            'unlock': {
              'type': 'DATE',
              'unlockAt': '2000-11-18T06:05:00.000Z',
            },
            'viewer': {'isUnlocked': true},
          },
        ],
        'serverTime': '2000-11-18T06:05:00.000Z',
      });

      expect(response.moments.single.toEntity().isReadyToOpen, isTrue);
    });

    test('location Moment requires server-confirmed unlock', () {
      final model = MomentModel.fromJson({
        'id': 'location-moment',
        'title': 'Location',
        'status': 'PUBLISHED',
        'unlock': {'type': 'LOCATION', 'placeName': 'Tokyo Tower'},
        'viewer': {'isUnlocked': false},
      });

      expect(model.toEntity().isReadyToOpen, isFalse);
    });

    test('location rule coordinates and radius are parsed for creator editing', () {
      final moment = MomentModel.fromJson({
        'id': 'location-moment',
        'title': 'Location',
        'status': 'DRAFT',
        'unlockRule': {
          'type': 'LOCATION',
          'latitude': 24.860735,
          'longitude': 67.001137,
          'radiusM': 150,
          'placeName': 'Test building',
        },
      }).toEntity();

      expect(moment.unlockLatitude, 24.860735);
      expect(moment.unlockLongitude, 67.001137);
      expect(moment.unlockRadiusM, 150);
      expect(moment.unlockPlaceName, 'Test building');
      expect(moment.isReadyToOpen, isFalse);
    });
  });
}
