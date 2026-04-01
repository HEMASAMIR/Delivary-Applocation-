import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/socket_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/user/customer_home_screen.dart';
import 'screens/provider/dashboard_screen.dart';
import 'models/user_model.dart';

Future<void> main() async {
  // 1. السطر ده لازم يكون أول واحد عشان يجهز الـ Native Bindings
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint("🚀 Starting Supabase Initialization...");

  try {
    // 2. تهيئة Supabase مع await ضرورية جداً
    await Supabase.initialize(
      url: 'https://ocbmcsnovsuirjblawsa.supabase.co',
      anonKey: 'sb_publishable_IEWmAz99wNrpI6WXNyZYGw_ehlfvRjT',
    );
    debugPrint("✅ Supabase Initialized Successfully!");
  } catch (e) {
    debugPrint("❌ Supabase Initialization Error: $e");
  }

  // 3. إنشاء الـ AuthProvider بعد ما نتأكد إن سوبا بيز جاهز
  final authProvider = AuthProvider();

  // 4. محاولة تسجيل الدخول التلقائي
  // ملاحظة: تأكد إن tryAutoLogin جوه الـ AuthProvider ما بتعملش crash
  try {
    await authProvider.tryAutoLogin();
  } catch (e) {
    debugPrint("⚠️ AutoLogin Error: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        // بنستخدم .value لأننا عملنا له create فوق خلاص
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
          themeMode: ThemeMode.dark,
          theme: AppTheme.darkTheme,
          darkTheme: AppTheme.darkTheme,
          // التوجيه بناءً على حالة تسجيل الدخول
          home: auth.isLoggedIn ? _getHome(auth.user) : const LoginScreen(),
        );
      },
    );
  }

  Widget _getHome(dynamic userData) {
    if (userData == null) return const LoginScreen();
    try {
      final user =
          userData is UserModel ? userData : UserModel.fromJson(userData);

      if (user.role == 'DRIVER' || user.role == 'PROVIDER') {
        return DashboardScreen(provider: user);
      } else {
        return CustomerHomeScreen(user: user);
      }
    } catch (e) {
      debugPrint("🏠 Home Navigation Error: $e");
      return const LoginScreen();
    }
  }
}
