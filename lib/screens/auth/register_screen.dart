import 'package:delivery_app/services/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // الـ Controllers للتحكم في الحقول
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedRole = "CUSTOMER"; // القيمة الافتراضية
  bool _isLoading = false;

  // --- دالة معالجة التسجيل ---
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. نداء خدمة الـ Auth
      final response = await SupabaseAuthService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _selectedRole,
        address: _addressController.text.trim().isEmpty
            ? "القاهرة، مصر"
            : _addressController.text.trim(),
      );

      // 2. التحقق من النجاح
      if (response.user != null) {
        Fluttertoast.showToast(
          msg: "تم إنشاء الحساب بنجاح! ✅",
          backgroundColor: Colors.green,
          textColor: Colors.white,
          gravity: ToastGravity.BOTTOM,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint("Register Error Details: $e");

      // --- قاموس ترجمة الأخطاء للعربية ---
      String errorMessage = "حدث خطأ غير متوقع، حاول مرة أخرى";
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('already registered') ||
          errorString.contains('user_already_exists')) {
        errorMessage = "هذا البريد الإلكتروني مسجل بالفعل";
      } else if (errorString.contains('invalid format') ||
          errorString.contains('email_address_invalid')) {
        errorMessage = "صيغة البريد الإلكتروني غير صحيحة";
      } else if (errorString.contains('network') ||
          errorString.contains('socketexception')) {
        errorMessage = "تأكد من اتصالك بالإنترنت";
      } else if (errorString.contains('weak-password') ||
          errorString.contains('at least 6 characters')) {
        errorMessage = "كلمة السر ضعيفة جداً (6 رموز فأكثر)";
      } else if (errorString.contains('rate limit')) {
        errorMessage = "محاولات كثيرة جداً، انتظر قليلاً";
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red.shade800,
        textColor: Colors.white,
        fontSize: 16.0,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد'), centerTitle: true),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_pin_outlined,
                    size: 80, color: Colors.blue),
                const SizedBox(height: 25),
                _buildInput(_nameController, 'الاسم الكامل', Icons.person),
                const SizedBox(height: 15),
                _buildInput(_emailController, 'البريد الإلكتروني', Icons.email,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 15),
                _buildInput(_phoneController, 'رقم الهاتف', Icons.phone,
                    type: TextInputType.phone),
                const SizedBox(height: 15),
                _buildInput(_passwordController, 'كلمة السر', Icons.lock,
                    isPass: true),
                const SizedBox(height: 15),
                _buildInput(_addressController, 'العنوان (اختياري)',
                    Icons.location_city),
                const SizedBox(height: 20),
                _buildRolePicker(),
                const SizedBox(height: 35),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('إنشاء الحساب',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("لديك حساب بالفعل؟ سجل دخولك"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildInput(
      TextEditingController controller, String label, IconData icon,
      {bool isPass = false, TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      obscureText: isPass,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) {
          if (label.contains('اختياري')) return null;
          return 'هذا الحقل مطلوب';
        }
        if (isPass && val.length < 6)
          return 'كلمة السر يجب أن تكون 6 رموز على الأقل';
        if (label.contains('البريد') && !val.contains('@'))
          return 'صيغة البريد غير صحيحة';
        return null;
      },
    );
  }

  Widget _buildRolePicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRole,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
                value: "CUSTOMER", child: Text("أنا زبون (طلب غاز)")),
            DropdownMenuItem(
                value: "DRIVER", child: Text("أنا سائق (توصيل غاز)")),
          ],
          onChanged: (val) => setState(() => _selectedRole = val!),
        ),
      ),
    );
  }
}
