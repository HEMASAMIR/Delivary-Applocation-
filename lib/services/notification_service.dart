import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. طلب إذن الإشعارات
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. الحصول على الـ FCM Token وإرساله للسيرفر
    String? token = await messaging.getToken();
    if (token != null) {
      debugPrint("FCM Token: $token");
      _updateTokenOnServer(token);
    }

    // 3. إعدادات الإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 4. الاستماع للإشعارات والتطبيق شغال (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _showNotification(notification.title!, notification.body!);
      }
    });

    // 5. التعامل مع النقر على الإشعار وفتح التطبيق
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("تم فتح التطبيق من خلال الإشعار: ${message.data}");
    });
  }

  // دالة لإرسال التوكن للسيرفر وتخزينه
  Future<void> _updateTokenOnServer(String token) async {
    try {
      // تصليح التحذير: استخدمنا String Interpolation بدل علامة الـ +
      await ApiService.postAuth(
          "${ApiConfig.baseUrl}/user/update-fcm-token", {"fcm_token": token});
    } catch (e) {
      debugPrint("Error updating token: $e");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin
        .show(0, title, body, platformChannelSpecifics, payload: 'item x');
  }
}
