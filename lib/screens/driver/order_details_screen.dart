import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../providers/socket_provider.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Map order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String _currentStatus = "في الطريق للزبون";

  void _updateStatus(String displayStatus, String techStatus) {
    final socketProv = Provider.of<SocketProvider>(context, listen: false);
    setState(() => _currentStatus = displayStatus);
    socketProv.emitStatusUpdate(widget.order['id'].toString(), techStatus);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم تحديث الحالة إلى: $displayStatus'),
        backgroundColor: Colors.black87));
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن إجراء المكالمة الآن')),
      );
    }
  }

  void _openInGoogleMaps() async {
    final lat = widget.order['lat'];
    final lng = widget.order['lng'];
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final Uri webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      await launchUrl(webUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("تفاصيل الرحلة",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        // تم التعديل هنا لحل مشكلة withValues
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.order['lat'], widget.order['lng']),
                zoom: 15,
              ),
              myLocationEnabled: true,
              zoomControlsEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('customer'),
                  position: LatLng(widget.order['lat'], widget.order['lng']),
                  infoWindow: const InfoWindow(title: "موقع الزبون"),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed),
                ),
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black12, blurRadius: 10, spreadRadius: 2)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    widget.order['customerName'] ?? "زبون غاز",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    _currentStatus,
                    style: const TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.directions,
                            color: Colors.blue, size: 30),
                        onPressed: _openInGoogleMaps,
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone,
                            color: Colors.green, size: 30),
                        onPressed: () => _makePhoneCall(
                            widget.order['customerPhone'] ?? "07XXXXXXXX"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_currentStatus == "في الطريق للزبون")
                  _buildUberButton(
                    label: "تأكيد الوصول للزبون",
                    color: Colors.blue[700]!,
                    onPressed: () =>
                        _updateStatus("وصلت لموقع الزبون", "ARRIVED"),
                  ),
                if (_currentStatus == "وصلت لموقع الزبون")
                  _buildUberButton(
                    label: "إتمام الطلب وتفريغ الغاز",
                    color: Colors.green[700]!,
                    onPressed: () {
                      _updateStatus("تم التوصيل بنجاح", "DELIVERED");
                      final navigator = Navigator.of(context);
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          navigator.pop();
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUberButton(
      {required String label,
      required Color color,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
