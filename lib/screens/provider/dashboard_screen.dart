import 'package:delivery_app/screens/common/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/socket_service.dart';

class DashboardScreen extends StatefulWidget {
  final UserModel provider;
  const DashboardScreen({super.key, required this.provider});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List activeOrders = [];

  @override
  void initState() {
    super.initState();
    SocketService.connect();
    SocketService.socket?.on('new:order', (order) {
      if (mounted) {
        setState(() {
          activeOrders.add(order);
        });
      }
    });
  }

  void acceptOrder(dynamic orderId) {
    SocketService.emitOrderAccept(orderId.toString(), widget.provider.id);
    setState(() {
      activeOrders.removeWhere((o) => o['id'] == orderId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم قبول الطلب ✅ جاري التجهيز...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    SocketService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم للسائق'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: activeOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 50, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('لا توجد طلبات جديدة حالياً',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 3,
                  child: ListTile(
                    leading:
                        const Icon(Icons.shopping_bag, color: Colors.orange),
                    title: Text(
                      'طلب نوع ${order['orderType'] ?? 'غاز'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('الموقع: ${order['lat']}, ${order['lng']}'),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white),
                      onPressed: () => acceptOrder(order['id']),
                      child: const Text('قبول'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
