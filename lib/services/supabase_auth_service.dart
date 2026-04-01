import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  // --- 1. إنشاء حساب جديد (مع تسجيل البيانات في الجدول) ---
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    required String address,
  }) async {
    // الخطوة الأولى: إنشاء المستخدم في Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    // الخطوة الثانية: لو الحساب اتعمل بنجاح، بنرمي البيانات في جدول الـ profiles
    if (response.user != null) {
      await _supabase.from('profiles').upsert({
        'id': response.user!.id, // بنربط البروفايل بالـ ID بتاع الـ Auth
        'full_name': name,
        'phone': phone,
        'role': role,
        'address': address,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  // --- 2. تسجيل الدخول ---
  static Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // --- 3. جلب بيانات البروفايل من جدول profiles ---
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return data;
    } catch (e) {
      return null;
    }
  }

  // --- 4. جلب المستخدم الحالي ---
  static User? get currentUser => _supabase.auth.currentUser;

  // --- 5. تسجيل الخروج ---
  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }


  // تحديث بيانات البروفايل
  static Future<void> updateProfile({
    required String userId,
    required String name,
    required String address,
    String? imageUrl,
  }) async {
    await _supabase.from('profiles').update({
      'full_name': name,
      'address': address,
      if (imageUrl != null) 'avatar_url': imageUrl, // لو رفعت صورة جديدة
    }).eq('id', userId);
  }

  // رفع الصورة لـ Storage
  static Future<String?> uploadAvatar(File imageFile, String userId) async {
    final fileName = 'avatar_$userId.png';
    await _supabase.storage.from('avatars').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true),
        );
    // جلب الرابط العام للصورة
    return _supabase.storage.from('avatars').getPublicUrl(fileName);
  }
}
