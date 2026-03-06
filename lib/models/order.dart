class Order {
  final int id;
  final int userId;
  final int? providerId;
  final String orderType;
  final String status;
  final double lat;
  final double lng;
  final String? createdAt; // أضفتها لأنها مفيدة في الإشعارات

  Order({
    required this.id,
    required this.userId,
    this.providerId,
    required this.orderType,
    required this.status,
    required this.lat,
    required this.lng,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // دالة مساعدة داخلية لتحويل أي قيمة لـ int بأمان
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    // دالة مساعدة داخلية لتحويل أي قيمة لـ double بأمان
    double toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    return Order(
      // استخدام الدوال المساعدة بيمنع خطأ "type String is not subtype of int"
      id: toInt(json['id']),
      userId: toInt(json['user_id'] ?? json['userId']), // دعم التسميتين

      providerId:
          json['provider_id'] != null ? toInt(json['provider_id']) : null,

      orderType: json['order_type']?.toString() ?? 'GAS',
      status: json['status']?.toString() ?? 'PENDING',

      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),

      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'order_type': orderType,
      'status': status,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt,
    };
  }
}
