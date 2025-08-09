import 'package:location/location.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final Location _location = Location();
  LocationData? _currentLocation;
  bool _serviceEnabled = false;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  LocationData? get currentLocation => _currentLocation;

  Future<bool> checkAndRequestPermission() async {
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        return false;
      }
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  // Stream for continuous location updates with logging (returns LatLng)
  Stream<LatLng> getLocationStream() async* {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        throw Exception('Location permission not granted');
      }

      await for (final locationData in _location.onLocationChanged) {
        _currentLocation = locationData;
        final latLng = LatLng(
          locationData.latitude ?? 0.0,
          locationData.longitude ?? 0.0,
        );
        debugPrint(
          'LocationService: Location updated - Lat: ${latLng.latitude.toStringAsFixed(6)}, '
          'Lng: ${latLng.longitude.toStringAsFixed(6)}, '
          'Accuracy: ${locationData.accuracy?.toStringAsFixed(1) ?? 'N/A'}m',
        );
        yield latLng;
      }
    } catch (e) {
      debugPrint('LocationService: Stream error - $e');
      rethrow;
    }
  }
}
