import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// استبدل 'your_project_name' باسم مشروعك الحقيقي
import 'package:delivery_app/providers/socket_provider.dart';

class CustomerOrderTracking extends StatefulWidget {
  final String orderId;

  // إضافة Key واستخدام const للـ Constructor لتحسين الأداء
  const CustomerOrderTracking({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<CustomerOrderTracking> createState() => _CustomerOrderTrackingState();
}

class _CustomerOrderTrackingState extends State<CustomerOrderTracking> {
  // تعريف الـ Controller والتحقق من جهوزيته
  GoogleMapController? _mapController;

  // يفضل البدء بموقع افتراضي (مثل وسط عمان) لحين وصول إحداثيات السائق
  LatLng _driverPosition = const LatLng(31.963158, 35.930359);
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    // ربط السوكت للاستماع لتحديثات الموقع
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocketProvider>().listenOrderUpdates((data) {
        // التأكد أن التحديث يخص هذا الطلب وأن البيانات تحتوي على الإحداثيات
        if (data['orderId'] == widget.orderId &&
            data['lat'] != null &&
            data['lng'] != null) {
          if (mounted) {
            setState(() {
              _driverPosition = LatLng(double.parse(data['lat'].toString()),
                  double.parse(data['lng'].toString()));

              markers = {
                Marker(
                  markerId: const MarkerId('driver'),
                  position: _driverPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure),
                  infoWindow: const InfoWindow(title: "موقع السائق"),
                )
              };
            });

            // تحريك الكاميرا لتتبع السائق تلقائياً
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_driverPosition),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب مباشرة'),
        centerTitle: true,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _driverPosition,
          zoom: 15, // تقريب الكاميرا أكثر للتتبع
        ),
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: markers,
        myLocationButtonEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
