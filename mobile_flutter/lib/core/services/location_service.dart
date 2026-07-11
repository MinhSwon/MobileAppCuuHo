import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;

  Map<String, dynamic> toRequestPayload() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'gps_accuracy_meters': accuracyMeters,
    };
  }

  Map<String, dynamic> toMissionPayload() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'current_rescuer_latitude': latitude,
      'current_rescuer_longitude': longitude,
      'gps_accuracy_meters': accuracyMeters,
    };
  }
}

class LocationResult {
  const LocationResult._({this.location, this.message});

  const LocationResult.success(DeviceLocation location)
    : this._(location: location);

  const LocationResult.failure(String message) : this._(message: message);

  final DeviceLocation? location;
  final String? message;

  bool get hasLocation => location != null;
}

class LocationService {
  static Future<LocationResult> current() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult.failure('GPS đang tắt');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationResult.failure('Chưa cấp quyền GPS');
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult.failure('Quyền GPS đã bị từ chối vĩnh viễn');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult.success(
        DeviceLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMeters: position.accuracy,
        ),
      );
    } catch (_) {
      return const LocationResult.failure('Không lấy được vị trí hiện tại');
    }
  }
}
