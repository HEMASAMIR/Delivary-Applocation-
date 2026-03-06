// lib/config/api_config.dart

class ApiConfig {
  // الرابط الأساسي - ينتهي بـ /api
  static const String baseUrl = "https://gas-delivery-app.onrender.com/api";

  // --- روابط تسجيل الدخول والحساب (Auth & User) ---
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";

  // ✅ تم التصحيح: إزالة الـ /api الزائدة هنا
  static const String updateProfile = "$baseUrl/auth/update-profile";

  // رابط جلب سجل الطلبات للزبون
  static const String orderHistory = "$baseUrl/user/orders";

  // رابط تحديث توكن الإشعارات
  static const String updateFcmToken = "$baseUrl/user/update-fcm-token";

  // --- روابط السائق (Driver) ---
  static const String wallet = "$baseUrl/driver/wallet";
  static const String updateStatus = "$baseUrl/driver/status";

  // --- روابط الطلبات والتقييم (Orders) ---
  static const String rateOrder = "$baseUrl/orders/rate";
}
