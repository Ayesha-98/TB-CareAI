import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  /// Get current city from device location
  static Future<String?> getCurrentCity() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ Location permission permanently denied');
        return null;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Convert to city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String city = placemark.locality ??
            placemark.subAdministrativeArea ??
            placemark.administrativeArea ??
            "Unknown";
        print('✅ Detected city: $city');
        return city;
      }
      return null;
    } catch (e) {
      print('❌ Failed to get location: $e');
      return null;
    }
  }

  /// Check if location services are enabled
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Open location settings
  static Future<void> openSettings() async {
    await Geolocator.openLocationSettings();
  }
}