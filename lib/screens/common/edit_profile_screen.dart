import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 1. هون التعديل: الوصول للـ Map بكون عن طريق المفاتيح [] مش عن طريق النقطة
    final userData = context.read<AuthProvider>().user;
    _nameController =
        TextEditingController(text: userData?['name']?.toString() ?? "");
    _addressController =
        TextEditingController(text: userData?['address']?.toString() ?? "");
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await context.read<AuthProvider>().updateProfile(
            name: _nameController.text,
            address: _addressController.text,
          );
      setState(() => _isLoading = false);
      Navigator.pop(context, {
        'fullName': _nameController.text,
        'address': _addressController.text,
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("تعديل الملف الشخصي"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            AssetImage('assets/images/user_placeholder.png')),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "الاسم الكامل", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "الرجاء إدخال الاسم" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                    labelText: "العنوان الدائم", border: OutlineInputBorder()),
                validator: (value) =>
                    value!.isEmpty ? "الرجاء إدخال العنوان" : null,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
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
                    : const Text("حفظ التغييرات",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
