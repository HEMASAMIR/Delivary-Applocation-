import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// --- Imports ---
import '../../providers/socket_provider.dart';
import '../../providers/auth_provider.dart';
import 'order_details_screen.dart';
import 'driver_inbox_screen.dart'; // استيراد شاشة صندوق الوارد

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  late GoogleMapController _mapController;
  bool _isMapControllerInitialized = false;

  LatLng _currentPosition = const LatLng(31.963158, 35.930359);
  Set<Marker> markers = {};
  List orders = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final socketProvider = context.read<SocketProvider>();

      final token = authProvider.token;
      if (token != null) {
        socketProvider.connect(token);

        // الاستماع لتحديثات الطلبات العامة
        socketProvider.listenOrderUpdates((data) {
          if (mounted) {
            setState(() => orders.insert(0, data));
          }
        });
      }
      _fetchOrders();
    });
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    Position pos = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );

    if (!mounted) return;

    setState(() {
      _currentPosition = LatLng(pos.latitude, pos.longitude);
    });

    // إرسال الموقع للسيرفر عبر السوكت
    Provider.of<SocketProvider>(context, listen: false)
        .emitLocation(pos.latitude, pos.longitude);

    if (_isMapControllerInitialized) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    }
  }

  void _fetchOrders() async {
    final token = context.read<AuthProvider>().token;
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/orders/available'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => orders = data);
      }
    } catch (e) {
      debugPrint("Error fetching orders: $e");
    }
  }

  void _acceptOrder(Map orderData) async {
    final token = context.read<AuthProvider>().token;
    final orderId = orderData['id'].toString();

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/orders/accept'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"orderId": orderId}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الطلب بنجاح ✅')),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(order: orderData),
          ),
        );

        _fetchOrders();
      }
    } catch (e) {
      debugPrint("Error accepting order: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // مراقبة عدد الإشعارات غير المقروءة من الـ Provider
    final unreadCount = context.watch<SocketProvider>().unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("طلبات التوصيل",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DriverInboxScreen()),
                  );
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _isMapControllerInitialized = true;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: markers,
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 280, // زدنا الارتفاع شوي عشان الراحة
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: const [
                  BoxShadow(blurRadius: 15, color: Colors.black38)
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text("الطلبات المتاحة حالياً",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: orders.isEmpty
                        ? _buildLoadingOrders()
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingOrders() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.black),
          SizedBox(height: 10),
          Text("جاري البحث عن طلبات قريبة... 🔎",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map order) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: const CircleAvatar(
          backgroundColor: Colors.orange,
          child: Icon(Icons.local_gas_station, color: Colors.white),
        ),
        title: Text('طلب غاز #${order['id']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('الموقع: ${order['address'] ?? "عمان، الأردن"}'),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: () => _acceptOrder(order),
          child: const Text('قبول',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
