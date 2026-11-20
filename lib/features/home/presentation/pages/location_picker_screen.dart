import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../data/datasources/location_geocoding_data_source.dart';

class SelectedMomentLocation {
  const SelectedMomentLocation({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusM,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int radiusM;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation, this.geocoding});

  final SelectedMomentLocation? initialLocation;
  final LocationGeocodingDataSource? geocoding;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _tileUrl = String.fromEnvironment(
    'MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final Map<String, List<_PlaceResult>> _searchCache = {};

  LatLng? _selectedPoint;
  int _radiusM = 100;
  bool _searching = false;
  bool _locating = false;
  String? _error;
  List<_PlaceResult> _results = const [];
  late final LocationGeocodingDataSource _geocoding;
  Timer? _nameLookupTimer;
  int _nameLookupRevision = 0;
  bool _resolvingName = false;

  void _setPoint(LatLng point) {
    _nameLookupTimer?.cancel();
    final revision = ++_nameLookupRevision;
    setState(() {
      _selectedPoint = point;
      _nameController.clear();
      _results = const [];
      _error = null;
      _resolvingName = true;
    });
    _nameLookupTimer = Timer(const Duration(milliseconds: 350), () async {
      try {
        final name = await _geocoding.reverseName(point.latitude, point.longitude);
        if (!mounted || revision != _nameLookupRevision) return;
        setState(() {
          _resolvingName = false;
          if (name != null) _nameController.text = _limitedPlaceName(name);
          if (name == null) _error = 'No address found. Enter a name for this pin.';
        });
      } catch (_) {
        if (!mounted || revision != _nameLookupRevision) return;
        setState(() {
          _resolvingName = false;
          _error = 'Could not find the address. Enter a name for this pin.';
        });
      }
    });
  }

  void _onNameEdited(String _) {
    _nameLookupTimer?.cancel();
    _nameLookupRevision++;
    setState(() {
      _resolvingName = false;
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _geocoding = widget.geocoding ?? LocationGeocodingDataSource();
    final initial = widget.initialLocation;
    if (initial != null) {
      _selectedPoint = LatLng(initial.latitude, initial.longitude);
      _radiusM = initial.radiusM.clamp(50, 1000).toInt();
      _nameController.text = initial.name;
      if (initial.name.trim().isEmpty || initial.name == 'Pinned location') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _setPoint(LatLng(initial.latitude, initial.longitude));
        });
      }
    }
  }

  @override
  void dispose() {
    _nameLookupTimer?.cancel();
    if (widget.geocoding == null) _geocoding.close();
    _searchController.dispose();
    _nameController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() => _error = 'Enter at least 3 characters.');
      return;
    }
    final cacheKey = query.toLowerCase();
    final cached = _searchCache[cacheKey];
    if (cached != null) {
      setState(() {
        _results = cached;
        _error = null;
      });
      return;
    }

    if (_searching) return;
    setState(() {
      _searching = true;
      _error = null;
    });

    try {
      final decoded = await _geocoding.search(query);
      final results = decoded is List
          ? decoded
              .whereType<Map<String, dynamic>>()
              .map(_PlaceResult.fromJson)
              .where((place) => place != null)
              .cast<_PlaceResult>()
              .toList(growable: false)
          : <_PlaceResult>[];
      _searchCache[cacheKey] = results;
      if (!mounted) return;
      setState(() {
        _results = results;
        _error = results.isEmpty ? 'No matching places found.' : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not search places. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    final revision = _nameLookupRevision;
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Enable Location Services and try again.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to use your position.');
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final point = LatLng(position.latitude, position.longitude);
      if (!mounted || revision != _nameLookupRevision) return;
      _setPoint(point);
      _mapController.move(point, 17);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _selectPlace(_PlaceResult place) {
    final point = LatLng(place.latitude, place.longitude);
    _nameLookupTimer?.cancel();
    _nameLookupRevision++;
    setState(() {
      _resolvingName = false;
      _selectedPoint = point;
      _nameController.text = _limitedPlaceName(place.name);
      _results = const [];
      _error = null;
    });
    _mapController.move(point, 17);
  }

  void _save() {
    final point = _selectedPoint;
    final name = _nameController.text.trim();
    if (point == null || name.isEmpty) {
      setState(() => _error = 'Select a point and enter a location name.');
      return;
    }
    Navigator.of(context).pop(
      SelectedMomentLocation(
        name: name,
        latitude: point.latitude,
        longitude: point.longitude,
        radiusM: _radiusM,
      ),
    );
  }

  String _limitedPlaceName(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 120 ? trimmed : trimmed.substring(0, 120).trim();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedPoint;
    final initialCenter = selected ?? const LatLng(24.8607, 67.0011);
    return Scaffold(
      backgroundColor: const Color(0xFF090A17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090A17),
        foregroundColor: Colors.white,
        title: const Text('Choose unlock location'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      maxLength: 160,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search a building, address, or place',
                        hintStyle: const TextStyle(color: Color(0xFF8A8EB3)),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0xFF17182D),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF8A8EB3)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _searching ? null : _search,
                    icon: _searching
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
            ),
            if (_results.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final place = _results[index];
                    return ListTile(
                      dense: true,
                      tileColor: const Color(0xFF17182D),
                      leading: const Icon(Icons.location_on, color: VeraTheme.purpleBright),
                      title: Text(place.name, style: const TextStyle(color: Colors.white)),
                      onTap: () => _selectPlace(place),
                    );
                  },
                ),
              ),
            Expanded(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: selected == null ? 12 : 17,
                  minZoom: 3,
                  maxZoom: 19,
                  onTap: (_, point) => _setPoint(point),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrl,
                    userAgentPackageName: 'com.example.vera',
                    maxZoom: 19,
                  ),
                  if (selected != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: selected,
                          radius: _radiusM.toDouble(),
                          useRadiusInMeter: true,
                          color: const Color(0x449044FB),
                          borderColor: VeraTheme.purpleBright,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  if (selected != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: selected,
                          width: 48,
                          height: 48,
                          child: const Icon(
                            Icons.location_pin,
                            size: 46,
                            color: Color(0xFF9044FB),
                          ),
                        ),
                      ],
                    ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        'OpenStreetMap contributors',
                        onTap: () => unawaited(
                          launchUrl(
                            Uri.parse('https://www.openstreetmap.org/copyright'),
                            mode: LaunchMode.externalApplication,
                          ).then<void>((_) {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _locating ? null : _useCurrentLocation,
                    icon: _locating
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: const Text('Use my current location'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    onChanged: _onNameEdited,
                    maxLength: 120,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: _resolvingName ? 'Finding address…' : 'Enter a location name',
                      suffixIcon: _resolvingName ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      ) : null,
                      labelText: 'Location or building name',
                      labelStyle: TextStyle(color: Color(0xFF8A8EB3)),
                      filled: true,
                      fillColor: Color(0xFF17182D),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unlock radius: $_radiusM m',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: _radiusM.toDouble(),
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '$_radiusM m',
                    onChanged: (value) => setState(() => _radiusM = value.round()),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  FilledButton(
                    onPressed: selected == null ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9044FB),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Use this location'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceResult {
  const _PlaceResult({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  static _PlaceResult? fromJson(Map<String, dynamic> json) {
    final latitude = double.tryParse(json['lat']?.toString() ?? '');
    final longitude = double.tryParse(json['lon']?.toString() ?? '');
    final name = json['display_name']?.toString().trim();
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        name == null ||
        name.isEmpty) {
      return null;
    }
    return _PlaceResult(name: name, latitude: latitude, longitude: longitude);
  }
}
