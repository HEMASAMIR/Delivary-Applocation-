import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/socket_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/customer_home_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'services/notification_service.dart';
import 'models/user_model.dart';

// معالج الإشعارات في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // يجب عمل Initialize لـ Firebase داخل معالج الخلفية
  await Firebase.initializeApp();
  debugPrint("جاء إشعار في الخلفية: ${message.messageId}");
}

Future<void> main() async {
  // التأكد من تهيئة الـ Widgets
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة Firebase بشكل آمن
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e ⚠️");
  }

  // 2. تحميل ملف الـ .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Warning: .env file not found. Make sure it exists in assets. ⚠️");
  }

  // 3. تهيئة خدمة الإشعارات (مع معالجة خطأ تكرار الطلب)
  final notificationService = NotificationService();
  try {
    // نتحقق من حالة الإذن أولاً قبل البدء لتجنب الـ Exception
    NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await notificationService.init();
    } else {
      // إذا كان الإذن ممنوحاً بالفعل، نقوم بتشغيل المستمعات فقط دون طلب الإذن مرة أخرى
      debugPrint("Notification permission already set.");
    }
  } catch (e) {
    debugPrint("Notification Service Error: $e ⚠️");
  }

  // 4. فحص التوكن للدخول التلقائي
  final authProvider = AuthProvider();
  await authProvider.tryAutoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SocketProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (ctx, auth, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Uber Gas App',
          // استخدام الثيم الغامق
          themeMode: ThemeMode.dark,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          // تحديد الشاشة الرئيسية بناءً على حالة تسجيل الدخول
          home: auth.isLoggedIn
              ? _getHome(auth.user)
              : const LoginScreen(),
        );
      },
    );
  }

  // دالة توزيع الأدوار وتحويل البيانات لموديل
  Widget _getHome(dynamic userData) {
    if (userData == null) return const LoginScreen();

    try {
      // تحويل البيانات من Map إلى UserModel
      final user = UserModel.fromJson(userData);

      // توجيه المستخدم حسب دوره (Role)
      if (user.role == 'DRIVER' || user.role == 'PROVIDER') {
        return DashboardScreen(provider: user);
      } else {
        return CustomerHomeScreen(user: user);
      }
    } catch (e) {
      debugPrint("Error parsing user data: $e");
      return const LoginScreen();
    }
  }
}