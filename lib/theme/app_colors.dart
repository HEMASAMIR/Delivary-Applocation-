import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية - الهوية البصرية لأوبر
  static const Color primary = Color(0xFF000000); // الأسود الأساسي
  static const Color secondary = Color(0xFFFFFFFF); // الأبيض الناصع
  static const Color accent =
      Color(0xFF276EF1); // أزرق أوبر (للأزرار التفاعلية)

  // خلفيات التطبيق (Dark Mode)
  static const Color background =
      Color(0xFF000000); // أوبر بستخدموا أسود حقيقي 100% بالخلفية
  static const Color surface = Color(0xFF121212); // رمادي غامق جداً للحقول
  static const Color card = Color(0xFF1A1A1A); // درجة البطاقات

  // ألوان المساعدة والنصوص
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFFAFAFAF); // رمادي للنصوص الفرعية
  static const Color divider = Color(0xFF222222); // لون الخطوط الفاصلة

  // ألوان الحالة (برضه بستايل أوبر)
  static const Color success = Color(0xFF05A357); // أخضر للطلبات الناجحة
  static const Color error = Color(0xFFE11900); // أحمر للأخطاء
}
