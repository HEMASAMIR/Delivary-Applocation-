import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../providers/socket_provider.dart';
import '../../providers/auth_provider.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  List<dynamic> activeOrders = [];

  @override
  void initState() {
    super.initState();

    // بيانات وهمية للفحص الأولي (اختياري)
    activeOrders = [
      {"id": "101", "distance": 2.5},
      {"id": "102", "distance": 5.0},
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final socketProv = Provider.of<SocketProvider>(context, listen: false);

      if (auth.token != null) {
        socketProv.connect(auth.token!);

        // الاستماع للطلبات الجديدة القادمة من الباك إيند
        socketProv.listenOrderUpdates((order) {
          if (mounted) {
            setState(() {
              if (!activeOrders
                  .any((o) => o['id'].toString() == order['id'].toString())) {
                activeOrders.add(order);
              }
            });
          }
        });

        // الاستماع لحالة الخطأ (إذا سبقك سائق آخر للطلب)
        socketProv.socket?.on('order_error', (data) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(data.toString()), backgroundColor: Colors.red),
            );
          }
        });

        // الاستماع لتأكيد النجاح من السيرفر
        socketProv.socket?.on('order_accepted_success', (data) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("تم حجز الطلب لك بنجاح!"),
                  backgroundColor: Colors.green),
            );
          }
        });
      }
    });
  }

  void _acceptOrder(dynamic orderId) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final socketProv = Provider.of<SocketProvider>(context, listen: false);

    // الربط مع الباك إيند: نرسل الـ orderId والـ driverId
    // ملاحظة: تأكد أن auth.userId يحتوي على ID السائق من قاعدة البيانات
    socketProv.socket?.emit('accept_order', {
      'orderId': orderId,
      'driverId': auth.user,
    });

    // تحديث الواجهة محلياً بحذف الكرت
    setState(() {
      activeOrders.removeWhere((o) => o['id'] == orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "الطلبات المتاحة",
          style: TextStyle(
              color: AppColors.secondary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        centerTitle: true,
        elevation: 0,
      ),
      body: activeOrders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined,
                      size: 64, color: AppColors.divider),
                  SizedBox(height: 16),
                  Text("لا توجد طلبات حالياً",
                      style: TextStyle(color: AppColors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: activeOrders.length,
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return Card(
                  color: AppColors.card,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side:
                        const BorderSide(color: AppColors.divider, width: 0.5),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.accent,
                      child: Icon(Icons.gas_meter, color: AppColors.secondary),
                    ),
                    title: Text(
                      "طلب غاز #${order['id']?.toString() ?? '---'}",
                      style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "المسافة: ${order['distance']?.toString() ?? '0'} كم",
                      style: const TextStyle(color: AppColors.grey),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () => _acceptOrder(order['id']),
                      child: const Text("قبول"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
