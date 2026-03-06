import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

// --- التعديل هون: نرجع خطوتين لورا عشان نوصل لمجلد providers الرئيسي ---
import '../../providers/socket_provider.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  final LatLng userLocation;

  const TrackingScreen(
      {super.key, required this.orderId, required this.userLocation});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  String _currentStatus = "جاري البحث عن سائق...";

  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
    _setCustomMarkerIcon();
    _addCustomerMarker();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketProv = context.read<SocketProvider>();

      socketProv.listenToDriverLocation((data) {
        if (mounted && data['orderId'] == widget.orderId) {
          LatLng driverLatLng = LatLng(double.parse(data['lat'].toString()),
              double.parse(data['lng'].toString()));
          _updateTracking(driverLatLng);
        }
      });

      socketProv.listenOrderUpdates((data) {
        if (mounted && data['orderId'] == widget.orderId) {
          String status = data['status'];
          setState(() {
            _currentStatus = _translateStatus(status);
          });

          if (status == 'DELIVERED') {
            _handleOrderCompletion(data);
          } else {
            _showStatusSnackBar(_currentStatus);
          }
        }
      });
    });
  }

  void _setCustomMarkerIcon() async {
    try {
      _driverIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(40, 40)),
        'assets/images/gas_truck_icon.png',
      );
    } catch (e) {
      debugPrint("Icon not found, using default");
    }
  }

  void _addCustomerMarker() {
    setState(() {
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: widget.userLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: "موقعك (نقطة التسليم)"),
        ),
      );
    });
  }

  void _updateTracking(LatLng driverPos) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPos,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          rotation: 0,
          infoWindow: const InfoWindow(title: "السائق"),
        ),
      );

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [driverPos, widget.userLocation],
          color: Colors.blueAccent,
          width: 4,
          geodesic: true,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(driverPos));
  }

  void _handleOrderCompletion(dynamic data) {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RatingScreen(
              driverName: data['driverName'] ?? "سائق الغاز",
              orderId: widget.orderId,
            ),
          ),
        );
      }
    });
  }

  String _translateStatus(String status) {
    switch (status) {
      case 'ACCEPTED':
        return "السائق قبل الطلب وهو في الطريق إليك";
      case 'ARRIVED':
        return "السائق وصل! يرجى الخروج لاستلام الطلب";
      case 'DELIVERED':
        return "تم تسليم الطلب بنجاح ✅";
      default:
        return "جاري تحديث حالة الطلب...";
    }
  }

  void _showStatusSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "تتبع الطلب #${widget.orderId.substring(widget.orderId.length > 5 ? widget.orderId.length - 5 : 0)}"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: widget.userLocation, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 30,
            left: 15,
            right: 15,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining,
                          color: Colors.orange, size: 30),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("حالة الطلب",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                            Text(_currentStatus,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_currentStatus.contains("نجاح")) ...[
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () => _handleOrderCompletion({}),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 45)),
                      child: const Text("تقييم السائق الآن",
                          style: TextStyle(color: Colors.white)),
                    )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

// شاشة التقييم المؤقتة
class RatingScreen extends StatelessWidget {
  final String driverName;
  final String orderId;
  const RatingScreen(
      {super.key, required this.driverName, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("تقييم الخدمة")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "شكراً لتعاملك معنا!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text("تقييم السائق: $driverName"),
            const SizedBox(height: 10),
            Text("رقم الطلب: $orderId",
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
