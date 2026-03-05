import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// شلنا الـ dotenv لأنه مش مستخدم هون
import '../config/api_config.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  String? token;
  Map<String, dynamic>? user;

  bool get isLoggedIn => token != null;

  String? get userId => user != null ? user!['id'].toString() : null;

  // --- دالة تسجيل الدخول ---
  Future<void> login(String phone, String password) async {
    // غيرنا final لـ const بناءً على طلب الفلاتر
    const url = ApiConfig.login;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
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

  // --- تحديث الملف الشخصي ---
  Future<bool> updateProfile(String name, String address) async {
    try {
      final response = await ApiService.postAuth(ApiConfig.updateProfile, {
        "name": name,
        "address": address,
      });

      if (response.statusCode == 200) {
        if (user != null) {
          user!['name'] = name;
          user!['address'] = address;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(user));

          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update Profile Error: $e");
      return false;
    }
  }

  // --- تسجيل الخروج ---
  Future<void> logout() async {
    token = null;
    user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');
    notifyListeners();
  }
}
