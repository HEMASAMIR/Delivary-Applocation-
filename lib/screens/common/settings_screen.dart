import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart'; // تأكد من مسار شاشة اللوجن عندك

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // دالة تسجيل الخروج
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token'); // مسح التوكن من الجهاز

    if (!context.mounted) return;

    // الرجوع لشاشة اللوجن وتصفير الـ Navigation Stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("الإعدادات",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // خيار تغيير اللغة (مثلاً)
          _buildSettingsItem(
            icon: Icons.language,
            title: "لغة التطبيق",
            subtitle: "العربية",
            onTap: () {},
          ),

          // خيار المساعدة والدعم
          _buildSettingsItem(
            icon: Icons.support_agent,
            title: "الدعم الفني",
            subtitle: "تواصل معنا إذا واجهتك مشكلة",
            onTap: () {},
          ),

          const Divider(height: 40),

          // زر تسجيل الخروج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("تسجيل الخروج",
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget مساعد لبناء خيارات الإعدادات
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        child: Icon(icon, color: Colors.black),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // تنبيه تأكيد الخروج
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("تسجيل الخروج"),
        content: const Text("هل أنت متأكد أنك تريد الخروج من التطبيق؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("إلغاء"),
          ),
          TextButton(
            onPressed: () => _logout(context),
            child: const Text("خروج", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
