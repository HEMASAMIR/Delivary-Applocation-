// lib/config/api_config.dart

class ApiConfig {
  // الرابط الأساسي الجديد - يشير الآن إلى سيرفرك على Render
  static const String baseUrl = "https://gas-delivery-app.onrender.com/api";

  // --- روابط تسجيل الدخول والحساب (Auth & User) ---
  static const String login = "$baseUrl/auth/login";
  static const String register = "$baseUrl/auth/register";

  // رابط تحديث بيانات الملف الشخصي (الاسم، العنوان، إلخ)
  static const String updateProfile = "$baseUrl/user/update-profile";

  // رابط جلب سجل الطلبات للزبون
  static const String orderHistory = "$baseUrl/user/orders";

  // رابط تحديث توكن الإشعارات
  static const String updateFcmToken = "$baseUrl/user/update-fcm-token";

  // --- روابط السائق (Driver) ---
  // رابط المحفظة لجلب الرصيد والعمليات المالية
  static const String wallet = "$baseUrl/driver/wallet";

  // رابط لتحديث حالة السائق (متصل / غير متصل)
  static const String updateStatus = "$baseUrl/driver/status";

  // --- روابط الطلبات والتقييم (Orders) ---
  // رابط إرسال تقييم من الزبون للسائق
  static const String rateOrder = "$baseUrl/orders/rate";
}
