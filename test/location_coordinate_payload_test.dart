import 'package:flutter_test/flutter_test.dart';
import 'package:vera/features/home/data/models/create_moment_params.dart';
import 'package:vera/features/home/presentation/pages/location_picker_screen.dart';

void main() {
  test(
    'changing a place label preserves the selected latitude, longitude and radius',
    () {
      final payloads = <Map<String, dynamic>>[];
      for (final name in ['Original label', 'Updated building name']) {
        final selected = SelectedMomentLocation(
          name: name,
          latitude: 12.3456789,
          longitude: -98.7654321,
          radiusM: 150,
        );
        payloads.add(
          MomentUnlockRule(
            type: 'LOCATION',
            latitude: selected.latitude,
            longitude: selected.longitude,
            radiusM: selected.radiusM,
            placeName: selected.name,
          ).toJson(),
        );
      }
      for (final payload in payloads) {
        expect(payload['type'], 'LOCATION');
        expect(payload['latitude'], 12.345679);
        expect(payload['longitude'], -98.765432);
        expect(payload['radiusM'], 150);
        expect(payload['latitude'], isA<double>());
        expect(payload['longitude'], isA<double>());
      }
      expect(payloads.first['placeName'], 'Original label');
      expect(payloads.last['placeName'], 'Updated building name');
    },
  );
}
