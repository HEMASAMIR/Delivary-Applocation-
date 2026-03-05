import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static io.Socket? socket;

  static void connect() {
    socket = io.io('http://10.0.2.2:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket!.connect();
  }

  // --- التعديل اللي كان ناقصك ومسبب الخطأ في الـ Dashboard ---
  static void emitOrderAccept(String orderId, String providerId) {
    if (socket?.connected == true) {
      socket?.emit('order:accept', {
        'orderId': orderId,
        'providerId': providerId,
      });
    }
  }

  // --- إضافة مهمة: عشان السائق يبعث موقعه لايف للزبون ---
  static void emitLocation(double lat, double lng) {
    if (socket?.connected == true) {
      socket?.emit('update:location', {
        'lat': lat,
        'lng': lng,
      });
    }
  }

  static void listenOrderAccepted(Function(dynamic) onAccepted) {
    socket?.on('order_accepted', (data) {
      onAccepted(data);
    });
  }

  static void disconnect() {
    socket?.disconnect();
  }
}
