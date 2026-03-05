import 'package:flutter/material.dart';
import 'dart:convert';
import '../../services/api_service.dart'; // تأكد من المسار الصحيح للخدمة
import '../../config/api_config.dart'; // تأكد من المسار الصحيح للإعدادات

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  // 1. تعريف متغيرات استقبال البيانات
  double _totalBalance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWalletData(); // منادي البيانات أول ما تفتح الشاشة
  }

  // 2. دالة جلب البيانات الحقيقية من الـ API
  Future<void> _fetchWalletData() async {
    try {
      if (!mounted) return;
      setState(() => _isLoading = true);

      // استدعاء الـ API باستخدام الخدمة اللي بتضيف التوكن تلقائياً
      // ملاحظة: استبدلت "/driver/wallet" بـ ApiConfig.wallet إذا كنت معرفها هناك
      final response = await ApiService.get(ApiConfig.wallet);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          // تأكد من أسماء الحقول حسب شو برجع السيرفر تبعك (مثلاً balance و transactions)
          _totalBalance = (data['balance'] ?? 0.0).toDouble();
          _transactions = data['transactions'] ?? [];
          _isLoading = false;
        });
      } else {
        throw Exception("خطأ من السيرفر: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("فشل الاتصال بالسيرفر، جرب مرة أخرى"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title:
            const Text("محفظتي", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.black)) // شاشة تحميل
          : RefreshIndicator(
              // ميزة سحب الشاشة لتحت عشان يعمل تحديث
              onRefresh: _fetchWalletData,
              child: Column(
                children: [
                  _buildBalanceHeader(),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text("آخر العمليات",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Expanded(
                    child: _transactions.isEmpty
                        ? const Center(child: Text("لا توجد عمليات حالياً"))
                        : ListView.builder(
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final tx = _transactions[index];
                              return _buildTransactionItem(tx);
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // --- الـ Widgets المساعدة ---

  Widget _buildBalanceHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const Text("إجمالي الرصيد المتوفر",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Text("${_totalBalance.toStringAsFixed(2)} د.أ",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 35,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> tx) {
    // افترضنا إن القيمة بتيجي بمتغير اسمه amount
    double amount = (tx['amount'] ?? 0.0).toDouble();
    bool isEarn = amount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(isEarn ? Icons.add_circle : Icons.remove_circle,
              color: isEarn ? Colors.green : Colors.red),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx['status'] ?? "عملية غير معروفة",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(tx['date'] ?? "",
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const Spacer(),
          Text("${amount.toStringAsFixed(2)} د.أ",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isEarn ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}
