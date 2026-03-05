import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart'; // مكتبة تشغيل الصوت
import '../models/app_notification.dart';

class SocketProvider with ChangeNotifier {
  io.Socket? socket;
  final AudioPlayer _audioPlayer = AudioPlayer(); // تعريف مشغل الصوت

  // --- قائمة الإشعارات والتحكم بها ---
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  // حساب عدد الإشعارات غير المقروءة (لإظهار Badge)
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // 1. Getter لحالة الاتصال
  bool get isConnected => socket?.connected ?? false;

  // دالة داخلية لتشغيل صوت التنبيه
  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      log("Error playing sound: $e");
    }
  }

  // 2. الاتصال بالسيرفر
  void connect(String tokenOrUserId) {
    if (socket?.connected == true) return;

    // تم تحديث الرابط هنا ليشير إلى سيرفر Render الخاص بك
    socket = io.io('https://gas-delivery-app.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket?.connect();

    socket?.onConnect((_) {
      log('Socket connected ✅');
      socket?.emit('join', tokenOrUserId);

      // بمجرد الاتصال، بنشغل مستمع الإشعارات داخل التطبيق
      listenToInAppNotifications();

      notifyListeners();
    });

    socket?.onDisconnect((_) {
      log('Socket disconnected ❌');
      notifyListeners();
    });

    socket?.onConnectError((err) => log('Connection Error: $err'));
  }

  // 3. إرسال الموقع اللحظي (للسائق)
  void emitLocation(double lat, double lng) {
    if (socket != null && socket!.connected) {
      socket!.emit('update_location', {
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
      });
      log('Driver location emitted: $lat, $lng');
    }
  }

  // 4. إرسال الموقع اللحظي كـ Map
  void emitDriverLocation(Map<String, dynamic> data) {
    if (socket != null && socket!.connected) {
      socket!.emit('update_location', data);
      log('Detailed driver location emitted');
    }
  }

  // 5. إرسال تحديث حالة الطلب
  void emitStatusUpdate(String orderId, String status) {
    if (socket?.connected == true) {
      socket?.emit('update_status', {
        'order_id': orderId,
        'status': status,
      });
      log('Status updated to: $status');
    }
  }

  // 6. إرسال رسالة دردشة
  void sendMessage(String orderId, String senderId, String text) {
    if (socket?.connected == true) {
      socket?.emit('chat_message', {
        'orderId': orderId,
        'senderId': senderId,
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
      log('Chat message sent: $text');
    }
  }

  // 7. الاستماع للرسائل الجديدة
  void listenToMessages(Function(dynamic) callback) {
    socket?.off('new_chat_message');
    socket?.on('new_chat_message', (data) {
      log('New message received: ${data['text']}');
      callback(data);
    });
  }

  // 8. الاستماع لتحديثات الطلبات العامة (للسائقين)
  void listenOrderUpdates(Function(dynamic) callback) {
    socket?.off('order_update');
    socket?.on('order_update', (data) {
      log('New Order Update received: $data');
      callback(data);
    });
  }

  // 9. الاستماع لموقع السائق اللحظي (للزبون)
  void listenToDriverLocation(Function(dynamic) callback) {
    socket?.off('driver_location_update');
    socket?.on('driver_location_update', (data) {
      callback(data);
    });
  }

  // --- إضافة دالة الاستماع لتحديث الحالة (مهمة جداً للزبون) ---
  void listenToStatusUpdate(Function(dynamic) callback) {
    socket?.off('status_updated');
    socket?.on('status_updated', (data) {
      log('Received status_updated for customer: $data');
      callback(data);
    });
  }

  // --- 10. صندوق الوارد والاستماع للإشعارات مع الصوت ---
  void listenToInAppNotifications() {
    socket?.off('new_order_available'); // تنظيف المستمع لعدم التكرار
    socket?.on('new_order_available', (data) {
      final newNotif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "طلب جديد متاح! 🚚",
        body: "في طلب غاز جديد قريب منك، الحق قبله!",
        createdAt: DateTime.now(),
        data: data,
      );

      _notifications.insert(0, newNotif); // إضافة في بداية القائمة

      // تشغيل الصوت عند وصول إشعار جديد
      _playSound();

      log('In-app notification added and sound played: ${newNotif.title}');
      notifyListeners();
    });
  }

  // تحديد كل الإشعارات كمقروءة
  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  // تحديد إشعار واحد كمقروء
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  // 11. قطع الاتصال
  void disconnect() {
    socket?.disconnect();
    socket = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // تنظيف مشغل الصوت من الذاكرة
    disconnect();
    super.dispose();
  }
}
