import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;

  File? _imageFile; // لتخزين الصورة المختارة محلياً
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    // جلب بيانات المستخدم الحالية من الـ Provider
    final userData = context.read<AuthProvider>().user;
    _nameController =
        TextEditingController(text: userData?['name']?.toString() ?? "");
    _addressController =
        TextEditingController(text: userData?['address']?.toString() ?? "");
    _passwordController = TextEditingController();
  }

  // دالة اختيار الصورة من المعرض
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // تقليل الجودة قليلاً لتسريع الرفع
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("حدث خطأ أثناء اختيار الصورة")),
      );
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // 🔥 التعديل المهم جداً: إرسال كل البيانات للـ Provider
      // تأكد إن دالة updateProfile في الـ AuthProvider بتستقبل الأربع حاجات دول
      final success = await context.read<AuthProvider>().updateProfile(
            name: _nameController.text.trim(),
            address: _addressController.text.trim(),
            password: _passwordController.text.isEmpty
                ? null
                : _passwordController.text,
            image: _imageFile, // الملف اللي اخترناه
          );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تحديث البيانات بنجاح ✅"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("فشل التحديث، حاول مرة أخرى ❌"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الملف الشخصي"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- قسم الصورة الشخصية ---
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.grey[300],
                      // لو في صورة مختارة اعرضها، لو مفيش اعرض الصورة الافتراضية
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : const AssetImage('assets/icon.png'),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.camera_alt,
                              size: 22, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- حقل الاسم الكامل ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "الاسم الكامل",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "الرجاء إدخال الاسم" : null,
              ),
              const SizedBox(height: 20),

              // --- حقل العنوان ---
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "العنوان",
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "الرجاء إدخال العنوان" : null,
              ),
              const SizedBox(height: 20),

              // --- حقل كلمة المرور ---
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "كلمة مرور جديدة (اختياري)",
                  hintText: "اتركها فارغة لإبقاء الحالية",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value!.isNotEmpty && value.length < 6) {
                    return "كلمة المرور ضعيفة (6 أحرف على الأقل)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // --- زر الحفظ ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "حفظ التغييرات",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
