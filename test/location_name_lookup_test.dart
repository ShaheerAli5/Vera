import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:vera/features/home/data/datasources/location_geocoding_data_source.dart';
import 'package:vera/features/home/presentation/pages/location_picker_screen.dart';

void main() {
  test(
    'reverse lookup sends lat/lon correctly and caches the address',
    () async {
      var requests = 0;
      final source = LocationGeocodingDataSource(
        requestInterval: Duration.zero,
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, '/reverse');
          expect(request.url.queryParameters['lat'], '12.3456789');
          expect(request.url.queryParameters['lon'], '-98.7654321');
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response('{"display_name":"Test Tower, Test Road"}', 200);
        }),
      );
      addTearDown(source.close);
      expect(
        await source.reverseName(12.3456789, -98.7654321),
        'Test Tower, Test Road',
      );
      expect(
        await source.reverseName(12.3456789, -98.7654321),
        'Test Tower, Test Road',
      );
      expect(requests, 1);
    },
  );

  test('a failed lookup does not block later search requests', () async {
    var fail = true;
    final source = LocationGeocodingDataSource(
      requestInterval: Duration.zero,
      client: MockClient((request) async {
        if (fail) return http.Response('{}', 503);
        return http.Response(
          '[{"display_name":"Test Road","lat":"12","lon":"-98"}]',
          200,
        );
      }),
    );
    addTearDown(source.close);
    await expectLater(source.reverseName(12, -98), throwsStateError);
    fail = false;
    expect(await source.search('Test Road'), isA<List>());
  });

  for (final editManually in [false, true]) {
    testWidgets(
      'pin name lookup preserves coordinates and ${editManually ? 'manual edits' : 'radius'}',
      (tester) async {
        tester.view.physicalSize = const Size(600, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final response = Completer<http.Response>();
        final source = LocationGeocodingDataSource(
          requestInterval: Duration.zero,
          client: MockClient((request) => response.future),
        );
        addTearDown(source.close);
        SelectedMomentLocation? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    saved = await Navigator.of(context)
                        .push<SelectedMomentLocation>(
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              geocoding: source,
                              initialLocation: const SelectedMomentLocation(
                                name: 'Saved place',
                                latitude: 12,
                                longitude: -98,
                                radiusM: 150,
                              ),
                            ),
                          ),
                        );
                  },
                  child: const Text('Choose'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choose'));
        await tester.pumpAndSettle();
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
        map.options.onTap!(
          const TapPosition(Offset.zero, Offset.zero),
          const LatLng(12.3456789, -98.7654321),
        );
        await tester.pump(const Duration(milliseconds: 400));
        if (editManually) {
          await tester.enterText(find.byType(TextField).last, 'My building');
          tester.testTextInput.hide();
        }
        // The address provider's nearest-object coordinates must never move the pin.
        await tester.runAsync(() async {
          response.complete(
            http.Response(
              jsonEncode({
                'display_name': 'Test Tower, Test Road',
                'lat': '13.0',
                'lon': '-99.0',
              }),
              200,
            ),
          );
          await Future<void>.delayed(Duration.zero);
        });
        await tester.pumpAndSettle();
        final name = tester
            .widget<TextField>(find.byType(TextField).last)
            .controller!
            .text;
        expect(name, editManually ? 'My building' : 'Test Tower, Test Road');
        await tester.tap(find.text('Use this location'));
        await tester.pumpAndSettle();
        expect(saved?.name, name);
        expect(saved?.latitude, 12.3456789);
        expect(saved?.longitude, -98.7654321);
        expect(saved?.radiusM, 150);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
