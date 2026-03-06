import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMap extends StatelessWidget {
  final double lat;
  final double lng;

  const CustomMap({super.key, required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      // التصليح هون: بنعطي القيمة مباشرة للبراميتر المطلوب
      initialCameraPosition: CameraPosition(
        target: LatLng(lat, lng), // الأفضل يبدأ من موقع الطلب نفسه
        zoom: 14,
      ),
      markers: {
        Marker(
          markerId: const MarkerId('order'),
          position: LatLng(lat, lng),
          infoWindow: const InfoWindow(title: 'موقع الطلب'),
        )
      },
      // إضافات اختيارية لتحسين الشكل (ستايل أوبر)
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}
