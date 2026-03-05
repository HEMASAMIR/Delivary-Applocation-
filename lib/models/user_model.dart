class UserModel {
  final String id;
  final String phone;
  final String? fullName;
  final String role;
  final String? vehicleType;

  UserModel({
    required this.id,
    required this.phone,
    this.fullName,
    required this.role,
    this.vehicleType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // استخدام ?? '' كحماية في حال كان السيرفر ببعث بيانات ناقصة
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      fullName: json['full_name'],
      role: json['role'] ?? 'CUSTOMER',
      vehicleType: json['vehicle_type'],
    );
  }

  // التعديل هنا: الميثود لازم تكون داخل أقواس الكلاس
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'full_name': fullName,
      'role': role,
      'vehicle_type': vehicleType,
    };
  }
} // القوس النهائي للكلاس كان ناقص مكانه الصح
