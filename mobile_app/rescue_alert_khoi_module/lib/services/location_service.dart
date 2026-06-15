import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    // GPS: kiem tra dich vu vi tri da bat hay chua.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS đang tắt. Vui lòng bật vị trí trên thiết bị.');
    }

    // GPS: xin quyen vi tri khi nguoi dung chua cap quyen.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Ứng dụng chưa được cấp quyền vị trí.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền vị trí đã bị từ chối vĩnh viễn. Vui lòng mở cài đặt để cấp quyền.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    );
  }
}
