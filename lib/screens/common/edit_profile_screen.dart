import 'dart:io';
import 'package:delivery_app/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  File? _selectedImage;

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل تريد بالفعل تسجيل الخروج؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () async {
              // 1. تنفيذ الخروج من السيرفر والبروفايدر
              await context.read<AuthProvider>().logout();

              if (mounted) {
                // 2. الانتقال المباشر لصفحة اللوجين ومسح كل اللي فات (الاستراكشر اللي إنت عاوزه)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen()), // اتأكد إن اسم الكلاس صح
                  (route) => false,
                );
              }
            },
            child: const Text("خروج", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

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
            image: _selectedImage,
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
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!) as ImageProvider
                              : const AssetImage(
                                  'assets/images/user_placeholder.png')),
                      const Positioned(
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

              const SizedBox(height: 15),

              // زرار تسجيل الخروج (إضافة جديدة بنفس الاستراكشر)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("تسجيل الخروج",
                      style: TextStyle(color: Colors.red, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
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

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:image_picker/image_picker.dart';
// import '../../providers/auth_provider.dart';

// class EditProfileScreen extends StatefulWidget {
//   const EditProfileScreen({super.key});

//   @override
//   State<EditProfileScreen> createState() => _EditProfileScreenState();
// }

// class _EditProfileScreenState extends State<EditProfileScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _addressController;
//   bool _isLoading = false;
//   File? _selectedImage;

//   @override
//   void initState() {
//     super.initState();
//     final userData = context.read<AuthProvider>().user;
//     _nameController =
//         TextEditingController(text: userData?['full_name']?.toString() ?? "");
//     _addressController =
//         TextEditingController(text: userData?['address']?.toString() ?? "");
//   }

//   Future<void> _pickImage() async {
//     try {
//       final pickedFile =
//           await ImagePicker().pickImage(source: ImageSource.gallery);
//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       debugPrint("Error picking image: $e");
//     }
//   }

//   Future<void> _updateProfile() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() => _isLoading = true);
//       try {
//         await context.read<AuthProvider>().updateProfile(
//               name: _nameController.text,
//               address: _addressController.text,
//               image: _selectedImage,
//             );

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text("تم تحديث البيانات بنجاح")),
//           );
//           Navigator.pop(context);
//         }
//       } catch (e) {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("فشل التحديث: $e")),
//           );
//         }
//       } finally {
//         if (mounted) setState(() => _isLoading = false);
//       }
//     }
//   }

//   Future<void> _handleLogout() async {
//     final authProvider = context.read<AuthProvider>();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text("تسجيل الخروج"),
//         content: const Text("هل تريد بالفعل تسجيل الخروج؟"),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("إلغاء")),
//           TextButton(
//             onPressed: () async {
//               await authProvider
//                   .logout(); // تم تعديلها لتطابق اسم الدالة في الـ Provider
//               if (mounted) {
//                 Navigator.of(context)
//                     .pushNamedAndRemoveUntil('/login', (route) => false);
//               }
//             },
//             child: const Text("خروج", style: TextStyle(color: Colors.red)),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userProfile = context.watch<AuthProvider>().user;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("تعديل الملف الشخصي"),
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               // --- صورة البروفايل ---
//               Center(
//                 child: GestureDetector(
//                   onTap: _pickImage,
//                   child: Stack(
//                     children: [
//                       CircleAvatar(
//                         radius: 60,
//                         backgroundColor: Colors.grey[300],
//                         backgroundImage: _selectedImage != null
//                             ? FileImage(_selectedImage!) as ImageProvider
//                             : (userProfile?['avatar_url'] != null
//                                     ? NetworkImage(userProfile!['avatar_url'])
//                                     : const AssetImage(
//                                         'assets/images/user_placeholder.png'))
//                                 as ImageProvider,
//                       ),
//                       const Positioned(
//                         bottom: 5,
//                         right: 5,
//                         child: CircleAvatar(
//                           radius: 18,
//                           backgroundColor: Colors.orange,
//                           child: Icon(Icons.camera_alt,
//                               size: 18, color: Colors.white),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 30),

//               // --- الحقول النصية ---
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: "الاسم الكامل",
//                   prefixIcon: Icon(Icons.person),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     value!.isEmpty ? "الرجاء إدخال الاسم" : null,
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _addressController,
//                 decoration: const InputDecoration(
//                   labelText: "العنوان الحالي",
//                   prefixIcon: Icon(Icons.map),
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) =>
//                     value!.isEmpty ? "الرجاء إدخال العنوان" : null,
//               ),
//               const SizedBox(height: 40),

//               // --- زرار حفظ التغييرات ---
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _updateProfile,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black,
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                               color: Colors.white, strokeWidth: 2),
//                         )
//                       : const Text("حفظ التغييرات",
//                           style: TextStyle(color: Colors.white, fontSize: 16)),
//                 ),
//               ),

//               const SizedBox(height: 15),

//               // --- زرار تسجيل الخروج (Button) ---
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton.icon(
//                   onPressed: _handleLogout,
//                   icon: const Icon(Icons.logout, color: Colors.red),
//                   label: const Text("تسجيل الخروج",
//                       style: TextStyle(color: Colors.red, fontSize: 16)),
//                   style: OutlinedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(vertical: 15),
//                     side: const BorderSide(color: Colors.red),
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10)),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
