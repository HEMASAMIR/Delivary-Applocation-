import 'package:delivery_app/models/order.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import '../models/app_notification.dart';

class SocketProvider with ChangeNotifier {
  io.Socket? socket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isConnected => socket?.connected ?? false;

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      log("Error playing sound: $e");
    }
  }

  void connect(String userId) {
    if (socket?.connected == true) return;

    // الربط مع السيرفر
    socket = io.io('https://gas-delivery-app.onrender.com', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket?.connect();

    socket?.onConnect((_) {
      log('Socket connected ✅');
      socket?.emit('join', userId);
      listenToInAppNotifications();
      notifyListeners();
    });

    socket?.onDisconnect((_) {
      log('Socket disconnected ❌');
      notifyListeners();
    });

    socket?.onConnectError((data) => log('Connect Error: $data'));
  }

  // دالة تنظيف البيانات لمنع تكرار الـ List في بعض ردود السوكت
  dynamic _cleanData(dynamic data) {
    if (data is List && data.isNotEmpty) return data[0];
    return data;
  }

  // --- 📍 دوال الموقع والتتبع ---

  void emitLocation(double lat, double lng) {
    if (isConnected) {
      socket!.emit('update_location', {'lat': lat, 'lng': lng});
    }
  }

  // استقبال موقع السائق (نمرر Map للشاشة)
  void listenToDriverLocation(Function(Map<String, dynamic>) callback) {
    socket?.off('driver_location_update');
    socket?.on('driver_location_update', (data) {
      final cleaned = _cleanData(data);
      if (cleaned != null) {
        callback(Map<String, dynamic>.from(cleaned));
      }
    });
  }

  // --- 🚚 دوال الطلبات والحالة ---

  // استقبال تحديثات حالة الطلب
  void listenOrderUpdates(Function(Map<String, dynamic>) callback) {
    socket?.off('order_update');
    socket?.on('order_update', (data) {
      final cleaned = _cleanData(data);
      if (cleaned != null) {
        // نمرر البيانات كـ Map ليتعامل معها الـ Order.fromJson في الشاشة
        callback(Map<String, dynamic>.from(cleaned));
      }
    });
  }

  void emitStatusUpdate(String orderId, String status) {
    if (isConnected) {
      socket!.emit('update_status', {'order_id': orderId, 'status': status});
    }
  }

  // --- 💬 دوال الدردشة ---

  void sendMessage(String orderId, String senderId, String text) {
    if (isConnected) {
      socket!.emit('chat_message', {
        'orderId': orderId,
        'senderId': senderId,
        'text': text,
        'time': DateTime.now().toIso8601String(),
      });
    }
  }

  void listenToMessages(Function(Map<String, dynamic>) callback) {
    socket?.off('new_chat_message');
    socket?.on('new_chat_message', (data) {
      final cleaned = _cleanData(data);
      if (cleaned != null) {
        callback(Map<String, dynamic>.from(cleaned));
      }
    });
  }

  // --- 🔔 الإشعارات داخل التطبيق (محل الخطأ السابق) ---

  void listenToInAppNotifications() {
    socket?.off('new_order_available');
    socket?.on('new_order_available', (data) {
      log("🔔 New order signal received");
      final cleanData = _cleanData(data);

      // تأكد من استيراد كلاس الـ Order في أعلى الملف
      // نقوم بتحويل الـ Map القادم من السيرفر إلى كائن Order
      Order? orderData;
      if (cleanData != null) {
        orderData = Order.fromJson(Map<String, dynamic>.from(cleanData));
      }

      final newNotif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "طلب جديد متاح! 🚚",
        body: "هناك طلب غاز جديد متاح الآن بالقرب منك",
        createdAt: DateTime.now(),
        data: orderData, // ✅ الآن النوع مطابق (Order?)
      );

      _notifications.insert(0, newNotif);
      _playSound();
      notifyListeners();
    });
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
