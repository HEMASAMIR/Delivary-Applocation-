// 1. تأكد إن اسم الملف هون مطابق لاسم ملف الموديل عندك
// إذا كان اسم ملف الطلبات هو order.dart غير السطر لـ import 'order.dart';
import 'order.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  bool isRead;

  // 2. غيرنا الاسم من OrderModel لـ Order عشان يطابق الكلاس اللي عندك
  final Order? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      // 3. نستخدم Order.fromJson اللي جهزناه سوا
      data: json['data'] != null ? Order.fromJson(json['data']) : null,
    );
  }
}
