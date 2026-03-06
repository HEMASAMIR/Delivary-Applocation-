import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user;

  bool get isLoggedIn => token != null;

  // دالة لجلب الـ ID الخاص بالمستخدم الحالي
  String? get currentUserId => user != null ? user!['id'].toString() : null;

  // --- محاولة تسجيل الدخول التلقائي ---
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return false;

    token = prefs.getString('token');
    if (prefs.containsKey('user_data')) {
      final String? userDataString = prefs.getString('user_data');
      if (userDataString != null) {
        user = jsonDecode(userDataString);
      }
    }
    notifyListeners();
    return true;
  }

  // --- تحديث الملف الشخصي (الإصدار المعتمد) ---
  Future<bool> updateProfile({
    required String name,
    required String address,
    String? password,
    File? image,
  }) async {
    try {
      // ⚠️ تأكد أن ApiConfig.updateProfile يشير إلى /api/auth/update-profile
      final uri = Uri.parse(ApiConfig.updateProfile);
      final request = http.MultipartRequest('POST', uri);

      // إضافة الهيدرز
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      // 🔥 التعديل الجوهري: إرسال الـ userId للسيرفر
      if (currentUserId != null) {
        request.fields['userId'] = currentUserId!;
      }

      // إضافة البيانات النصية
      request.fields['name'] = name;
      request.fields['address'] = address;

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      // إضافة الصورة
      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', // يطابق upload.single('image') في السيرفر
          image.path,
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Connecting to: ${uri.toString()}');
      debugPrint('Status Code: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['user'] != null) {
          // تحديث بيانات المستخدم في الـ Provider
          user = data['user'];

          // حفظ البيانات الجديدة في الهاتف
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(user));

          notifyListeners();
        }
        return true;
      } else {
        debugPrint("Update Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // --- تسجيل الدخول ---
  Future<void> login(String phone, String password) async {
    const url = ApiConfig.login;
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json"
        },
        body: jsonEncode({"phone": phone, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        token = data['token'];
        user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token!);
        await prefs.setString('user_data', jsonEncode(user));

        notifyListeners();
      } else {
        throw data['error'] ?? 'خطأ في تسجيل الدخول';
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
