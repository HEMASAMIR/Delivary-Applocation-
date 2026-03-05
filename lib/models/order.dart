class Order {
  final int id;
  final int userId;
  final int? providerId;
  final String orderType;
  final String status;
  final double lat;
  final double lng;

  Order({
    required this.id,
    required this.userId,
    this.providerId,
    required this.orderType,
    required this.status,
    required this.lat,
    required this.lng,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      // استخدام ?? 0 بيحمي التطبيق من الانهيار إذا القيمة إجت null
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      providerId: json['provider_id'], // هاد أصلاً nullable فما في مشكلة
      orderType: json['order_type'] ?? 'GAS', // قيمة افتراضية
      status: json['status'] ?? 'PENDING',

      // تحويل القيم لـ double بطريقة آمنة (لأن السيرفر أحياناً ببعتها int)
      lat: (json['lat'] as num? ?? 0.0).toDouble(),
      lng: (json['lng'] as num? ?? 0.0).toDouble(),
    );
  }

  // دالة تحويل الكائن لـ Map (مفيدة لما بدك ترسل طلب للسيرفر)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'provider_id': providerId,
      'order_type': orderType,
      'status': status,
      'lat': lat,
      'lng': lng,
    };
  }
}
