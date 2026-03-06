import 'package:delivery_app/models/app_notification.dart';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';

class SocketProvider with ChangeNotifier {
  io.Socket? socket;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // --- إدارة الإشعارات ---
  final List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isConnected => socket?.connected ?? false;

  // --- تشغيل صوت التنبيه ---
  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      log("Error playing sound: $e");
    }
  }

  // --- الاتصال بالسيرفر ---
  void connect(String userId) {
    if (socket?.connected == true) return;

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

    socket?.onConnectError((err) => log('Connection Error: $err'));
  }

  // --- 🛠️ دالة تنظيف البيانات (لحل مشكلة List<dynamic>) ---
  dynamic _cleanData(dynamic data) {
    if (data is List && data.isNotEmpty) {
      return data[0];
    }
    return data;
  }

  // --- 📍 دوال الموقع (التي تسببت في الخطأ الأخير) ---
  void emitLocation(double lat, double lng) {
    if (isConnected) {
      socket!.emit('update_location', {
        'lat': lat,
        'lng': lng,
        'timestamp': DateTime.now().toIso8601String(),
      });
      log('Location emitted: $lat, $lng');
    } else {
      log('Cannot emit location: Socket not connected');
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
      log('Message sent: $text');
    }
  }

  void listenToMessages(Function(dynamic) callback) {
    socket?.off('new_chat_message');
    socket?.on('new_chat_message', (data) {
      callback(_cleanData(data));
    });
  }

  // --- 🚚 دوال تحديث الطلبات والحالة ---
  void listenOrderUpdates(Function(dynamic) callback) {
    socket?.off('order_update');
    socket?.on('order_update', (data) {
      callback(_cleanData(data));
    });
  }

  void listenToStatusUpdate(Function(dynamic) callback) {
    socket?.off('status_updated');
    socket?.on('status_updated', (data) {
      callback(_cleanData(data));
    });
  }

  void emitStatusUpdate(String orderId, String status) {
    if (isConnected) {
      socket!.emit('update_status', {
        'order_id': orderId,
        'status': status,
      });
    }
  }

  // --- 🔔 الإشعارات داخل التطبيق ---
  void listenToInAppNotifications() {
    socket?.off('new_order_available');
    socket?.on('new_order_available', (data) {
      final cleanData = _cleanData(data);
      final newNotif = AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: "طلب جديد متاح! 🚚",
        body: "هناك طلب غاز جديد متاح الآن بالقرب منك",
        createdAt: DateTime.now(),
        data: cleanData,
      );
      _notifications.insert(0, newNotif);
      _playSound();
      notifyListeners();
    });
  }

  // --- إدارة حالة الإشعارات ---
  void markAllAsRead() {
    for (var n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    disconnect();
    super.dispose();
  }
}
