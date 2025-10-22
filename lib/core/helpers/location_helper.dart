import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracyMeters; // có thể null nếu platform không trả
  final String? address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.address,
  });
}

class LocationHelper {
  /// Kiểm tra service + xin quyền. Trả true nếu OK.
  static Future<bool> _ensurePermission() async {
    // 1) Yêu cầu bật Location Service
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Không bật => gợi ý mở settings
      await Geolocator.openLocationSettings();
      return false;
    }

    // 2) Kiểm tra & xin quyền
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      // Người dùng từ chối
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      // Bị chặn vĩnh viễn
      await Geolocator.openAppSettings();
      return false;
    }

    // Các trường hợp còn lại đều OK
    return true;
  }

  /// Lấy vị trí hiện tại, reverse geocode ra địa chỉ.
  static Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 12),
    bool needAddress = true,
  }) async {
    final ok = await _ensurePermission();
    if (!ok) {
      throw Exception('Chưa có quyền vị trí hoặc Location Service chưa bật.');
    }

    // Lấy vị trí 1 lần
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: accuracy,
      timeLimit: timeout,
    );

    String? address;
    if (needAddress) {
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
          // localeIdentifier: 'vi_VN', // có thể bật để ưu tiên tiếng Việt
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          // Ghép địa chỉ gọn gàng
          address = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
            p.postalCode,
            p.country,
          ].where((e) => (e != null && e.trim().isNotEmpty)).join(', ');
        }
      } catch (_) {
        // Không reverse được cũng không sao
        address = null;
      }
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy, // mét
      address: address,
    );
  }
}
