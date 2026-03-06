import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/socket_provider.dart';
import '../../models/app_notification.dart';
import 'order_details_screen.dart';

class DriverInboxScreen extends StatelessWidget {
  const DriverInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // مراقبة التغييرات في الإشعارات
    final socketProv = context.watch<SocketProvider>();
    final notifications = socketProv.notifications;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("صندوق الوارد",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => socketProv.markAllAsRead(),
            tooltip: "تحديد الكل كمقروء",
          )
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationCard(context, notif, socketProv);
              },
            ),
    );
  }

  Widget _buildNotificationCard(
      BuildContext context, AppNotification notif, SocketProvider socketProv) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color:
              notif.isRead ? Colors.transparent : Colors.blue.withOpacity(0.3),
        ),
      ),
      color: notif.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: notif.isRead ? Colors.grey[200] : Colors.blue,
          child: Icon(
            notif.isRead
                ? Icons.notifications_outlined
                : Icons.notifications_active,
            color: notif.isRead ? Colors.grey : Colors.white,
          ),
        ),
        title: Text(notif.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notif.body),
            const SizedBox(height: 5),
            Text(
              DateFormat('hh:mm a').format(notif.createdAt),
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          // 1. تحديد كمقروء
          socketProv.markAsRead(notif.id);

          // 2. الانتقال لشاشة التفاصيل مع تحويل الموديل لـ Map
          if (notif.data != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                // تم التعديل هنا ليتوافق النوع مع OrderDetailsScreen
                builder: (context) =>
                    OrderDetailsScreen(order: notif.data!.toJson()),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("لا توجد إشعارات حالياً",
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
