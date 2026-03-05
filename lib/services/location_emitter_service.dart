import 'dart:async'; // ضروري لإدارة الـ Stream
import 'dart:developer';
import 'package:location/location.dart';
import '../../providers/socket_provider.dart';

class LocationEmitterService {
  Location location = Location();
  bool _isTracking = false;
  StreamSubscription<LocationData>?
      _locationSubscription; // لإغلاق المستمع بشكل صحيح

  Future<void> startTracking(String orderId, SocketProvider socketProv) async {
    // 1. التأكد من تفعيل خدمة الموقع وإذن الوصول
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // 2. إعدادات جلب الموقع
    // تم تحسين الدقة لتوفير البطارية
    location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 5000, // إرسال كل 5 ثواني
      distanceFilter: 5, // إرسال إذا تحرك السائق 5 أمتار (أدق للغاز)
    );

    // إذا كان في تتبع قديم شغال، بنسكره قبل ما نبدأ جديد
    await stopTracking();

    _isTracking = true;

    // 3. الاستماع لتغير الموقع وإرساله
    _locationSubscription =
        location.onLocationChanged.listen((LocationData currentLocation) {
      if (_isTracking &&
          currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        socketProv.emitDriverLocation({
          "orderId": orderId,
          "lat": currentLocation.latitude,
          "lng": currentLocation.longitude,
          "bearing": currentLocation.heading,
          "speed": currentLocation.speed, // إضافة السرعة مفيدة للزبون
        });

        log("🚚 موقع السائق الجديد: ${currentLocation.latitude}, ${currentLocation.longitude}");
      }
    });
  }

  // تعديل مهم: إغلاق الـ Subscription بالكامل
  Future<void> stopTracking() async {
    _isTracking = false;
    if (_locationSubscription != null) {
      await _locationSubscription!.cancel();
      _locationSubscription = null;
      log("🛑 تم إيقاف تتبع الموقع");
    }
  }
}
