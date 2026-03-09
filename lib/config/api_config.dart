class ApiConfig {
  // الرابط الأساسي للسيرفر بدون سلاش في الآخر
  static const String domain = "https://gas-delivery-app.onrender.com";
  static const String baseUrl = "$domain/api";

  // --- روابط تسجيل الدخول والحساب (Auth & User) ---
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";

  // المسار النهائي: https://gas-delivery-app.onrender.com/api/auth/update-profile
  // static const String updateProfile = "$baseUrl/auth/update-profile";
  static const String updateProfile = "$baseUrl/auth/update-profile-test";
  // روابط المستخدم
  static const String orderHistory = "$baseUrl/user/orders";
  static const String updateFcmToken = "$baseUrl/user/update-fcm-token";

  // --- روابط السائق (Driver) ---
  static const String wallet = "$baseUrl/driver/wallet";
  static const String updateStatus = "$baseUrl/driver/status";

  // --- روابط الطلبات (Orders) ---
  static const String rateOrder = "$baseUrl/orders/rate";
}
