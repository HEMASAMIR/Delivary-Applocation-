import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/user_model.dart';

class ApiService {
  // --- الدوال المساعدة للتعامل مع الـ Token ---

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // --- دالة GET عامة (تم إضافتها لحل مشكلة المحفظة) ---
  static Future<http.Response> get(String url) async {
    final token = await _getToken();
    return await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // إرسال التوكن مع الطلب
      },
    );
  }

  // دالة POST عامة تضيف التوكن تلقائياً (تستخدم للطلبات المحمية)
  static Future<http.Response> postAuth(
      String url, Map<String, dynamic> body) async {
    final token = await _getToken();
    return await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }

  // --- دالة إنشاء طلب جديد (الغاز) ---
  static Future<bool> createOrder(Map<String, dynamic> orderData) async {
    try {
      final response =
          await postAuth("${ApiConfig.baseUrl}/orders/create", orderData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ تم إنشاء الطلب بنجاح");
        return true;
      } else {
        debugPrint("❌ فشل إنشاء الطلب: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("⚠️ خطأ في إنشاء الطلب: $e");
      return false;
    }
  }

  // --- الدوال الأساسية (Login & Register) ---

  static Future<UserModel?> login(String phone, String password) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      debugPrint("Login Error: $e");
      return null;
    }
  }

  static Future<UserModel?> register(
    String phone,
    String password,
    String name,
    String role, [
    String? vehicleType,
  ]) async {
    try {
      final res = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'fullName': name,
          'role': role,
          'vehicleType': vehicleType
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', data['token']);
        }
        return UserModel.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      debugPrint("Register Error: $e");
      return null;
    }
  }
}
