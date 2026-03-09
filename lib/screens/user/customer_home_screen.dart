import 'package:delivery_app/config/api_config.dart';
import 'package:delivery_app/screens/common/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../providers/socket_provider.dart';
import 'tracking_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final UserModel user;
  const CustomerHomeScreen({super.key, required this.user});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(31.963158, 35.930359);
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketProv = Provider.of<SocketProvider>(context, listen: false);
      socketProv.connect(widget.user.id);

      socketProv.listenOrderUpdates((data) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث حالة الطلب 🚚'),
              backgroundColor: Colors.black87,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (!mounted) return;

      setState(() {
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition,
            infoWindow: const InfoWindow(title: 'موقع التسليم'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
          ),
        );
      });

      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition, 15));
    } catch (e) {
      debugPrint("خطأ في تحديد الموقع: $e");
    }
  }

  // --- دالة إنشاء الطلب المحسنة ---
  void _createOrder() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    // إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 5),
      ),
    );

    try {
      final response = await http
          .post(
            Uri.parse("${ApiConfig.baseUrl}/orders/create"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
            body: jsonEncode({
              "userId": widget.user.id,
              "orderType": "GAS",
              "lat": _currentPosition.latitude,
              "lng": _currentPosition.longitude,
              "paymentMethod": "CASH"
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      Navigator.pop(context); // إغلاق الـ Loading

      final data = jsonDecode(response.body);
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 🔥 حل مشكلة الـ null: استخراج الـ ID بأكثر من طريقة حسب رد السيرفر
        String? orderId;

        if (data['id'] != null) {
          orderId = data['id'].toString();
        } else if (data['order'] != null && data['order']['id'] != null) {
          orderId = data['order']['id'].toString();
        }

        if (orderId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackingScreen(
                orderId: orderId!,
                userLocation: _currentPosition,
              ),
            ),
          );
        } else {
          throw Exception("لم يتم العثور على معرف الطلب في رد السيرفر");
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'فشل إنشاء الطلب ❌')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (Navigator.canPop(context)) Navigator.pop(context);

      debugPrint("Order Creation Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تعذر إنشاء الطلب.. تأكد من اتصالك بالسيرفر')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // نراقب حالة الاتصال من السوكيت بروفايدر
    final isConnected = context.watch<SocketProvider>().isConnected;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'أهلاً ${widget.user.fullName}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.black),
            onPressed: () async {
              final updatedData = await Navigator.push<Map<String, String>>(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );

              if (updatedData != null && mounted) {
                setState(() {
                  widget.user.fullName = updatedData['fullName'];
                  // لو تحب تحدث العنوان:
                  // widget.user.address = updatedData['address'];
                });
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Icon(
              Icons.circle,
              color: isConnected ? Colors.green : Colors.red,
              size: 10,
            ),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: _currentPosition, zoom: 15),
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        markers: markers,
        zoomControlsEnabled: false,
      ),
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        width: MediaQuery.of(context).size.width,
        child: FloatingActionButton.extended(
          onPressed: _createOrder,
          label: const Text('اطلب الآن',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18)),
          icon: const Icon(Icons.local_gas_station,
              color: Color.fromARGB(255, 0, 0, 0)),
          backgroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
