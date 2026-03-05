import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // القيمة الافتراضية لنوع المستخدم
  String _selectedRole = "CUSTOMER";
  bool _loading = false;

  void _register() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      Fluttertoast.showToast(msg: "يرجى تعبئة جميع الحقول");
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response =
          await http.post(Uri.parse('${dotenv.env['API_URL']}/auth/register'),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "phone": _phoneController.text.trim(),
                "password": _passwordController.text.trim(),
                "name": _nameController.text.trim(),
                "role": _selectedRole // نرسل الـ Role اللي اختاره المستخدم
              }));

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: "تم إنشاء الحساب بنجاح");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      } else {
        Fluttertoast.showToast(msg: data['error'] ?? 'خطأ بالتسجيل');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "مشكلة في الاتصال بالشبكة");
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
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/logo.jpeg',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person_add, // أيقونة بديلة في حال لم تظهر الصورة
                      size: 80,
                      color: Colors.blue),
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'الاسم كامل', prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                    labelText: 'كلمة السر', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 20),

              // --- إضافة اختيار نوع الحساب لربط السائق والزبون ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: "CUSTOMER",
                          child: Text("أنا زبون (أريد طلب غاز)")),
                      DropdownMenuItem(
                          value: "DRIVER",
                          child: Text("أنا سائق (أريد توصيل غاز)")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedRole = val!;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 30),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50)),
                      child: const Text('إنشاء الحساب')),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("لديك حساب بالفعل؟ سجل دخولك"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
