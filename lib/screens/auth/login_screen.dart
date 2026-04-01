import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// استيراد الخدمة والموديل
import '../../services/supabase_auth_service.dart';
import '../../models/user_model.dart';

// استيراد الشاشات
import '../user/customer_home_screen.dart';
import '../provider/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- دالة تسجيل الدخول ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. تسجيل الدخول من خلال السيرفس
      final response = await SupabaseAuthService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. جلب بيانات البروفايل (عشان الـ Role)
        final profileData =
            await SupabaseAuthService.getUserProfile(response.user!.id);

        if (profileData == null) {
          throw "لم يتم العثور على بيانات المستخدم في الجدول";
        }

        // 3. تحويل البيانات لموديل عشان نحدد الوجهة
        final currentUser = UserModel.fromJson(profileData);

        if (!mounted) return;

        // 4. التوجيه المباشر حسب الـ Role
        if (currentUser.role == 'DRIVER' || currentUser.role == 'PROVIDER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => DashboardScreen(provider: currentUser)),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => CustomerHomeScreen(user: currentUser)),
          );
        }

        Fluttertoast.showToast(
            msg: "أهلاً بك! ✅", backgroundColor: Colors.green);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      Fluttertoast.showToast(
        msg: "خطأ: البريد أو كلمة السر غير صحيحة",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.local_gas_station,
                    size: 80, color: Colors.blue),
                const SizedBox(height: 40),

                // حقل البريد
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => (val == null || !val.contains('@'))
                      ? 'بريد غير صحيح'
                      : null,
                ),
                const SizedBox(height: 20),

                // حقل الباسورد
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'كلمة السر',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => (val == null || val.length < 6)
                      ? 'كلمة السر قصيرة'
                      : null,
                ),
                const SizedBox(height: 30),

                // زر الدخول
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleLogin,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child:
                            const Text('دخول', style: TextStyle(fontSize: 18)),
                      ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text('ليس لديك حساب؟ سجل الآن'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
