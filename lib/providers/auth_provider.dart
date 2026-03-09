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
  Future<bool> updateProfile({
    required String name,
    required String address,
    String? password,
    File? image,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.updateProfile);

      var request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['address'] = address;
      request.fields['userId'] = user!['id'].toString();

      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', image.path),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("STATUS CODE: ${response.statusCode}");
      print("RESPONSE BODY: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        user = responseData['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(user));

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      print("Update Profile Error: $e");
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
        body: jsonEncode({
          "phone": phone,
          "password": password,
        }),
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
