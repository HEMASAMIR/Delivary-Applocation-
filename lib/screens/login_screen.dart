import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

// استيراد الموديلات والبروفايدرز - بنرجع خطوة لورا لمجلد lib
import '../providers/auth_provider.dart';
import '../models/user_model.dart';

// --- التعديل الجوهري هون ---
// بما إنك في lib/screens وتريد الوصول لـ lib/screens/user
// ما في داعي تطلع برا مجلد screens، ادخل فوراً على user
import 'user/customer_home_screen.dart';
import 'provider/dashboard_screen.dart';
import 'auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  void _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "يا غالي عبّي كل الحقول أول");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      await auth.login(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (auth.isLoggedIn && auth.user != null) {
        final currentUser = UserModel.fromJson(auth.user!);

        if (currentUser.role == 'DRIVER' || currentUser.role == 'PROVIDER') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => DashboardScreen(provider: currentUser)),
          );
        } else {
          // التوجيه لشاشة الزبون
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => CustomerHomeScreen(user: currentUser)),
          );
        }
      }
    } catch (err) {
      Fluttertoast.showToast(msg: "صار مشكلة: ${err.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            ClipRRect(
                borderRadius:
                    BorderRadius.circular(10), // لو عايز تعمل حواف ناعمة للصورة
                child: Image.asset(
                  'assets/logo.jpeg',
                  width: 80,
                  height: 80,
                  fit: BoxFit
                      .cover, // عشان الصورة تملا الـ 80 بكسل من غير ما تتمط
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.local_gas_station,
                      size: 80,
                      color: Colors
                          .blue), // لو الصورة محملتش يظهر الأيقونة القديمة كاحتياطي
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة السر',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 25),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('دخول'),
                    ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text('ما عندك حساب؟ سجل الآن'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
