import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RatingScreen extends StatefulWidget {
  final String driverName;
  final String orderId;

  const RatingScreen({
    super.key,
    required this.driverName,
    required this.orderId,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  double _userRating = 3.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false; // لمتابعة حالة التحميل

  Future<void> _submitRating() async {
    setState(() => _isLoading = true);

    // الرابط هاد استبدله برابط السيرفر تبعك (API)
    const String apiUrl = "https://your-api-domain.com/api/rate-order";

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.orderId,
          "rating": _userRating,
          "comment": _commentController.text,
        }),
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        _showSnackBar("فشل إرسال التقييم، حاول لاحقاً", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar("تأكد من اتصالك بالإنترنت", Colors.orange);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("شكراً لك!", textAlign: TextAlign.center),
        content: const Text("تم إرسال تقييمك بنجاح، شكراً لاستخدامك تطبيقنا."),
        actions: [
          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("العودة للرئيسية",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          // للإحتياط إذا كانت الشاشة صغيرة
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 25.0, vertical: 60.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                const SizedBox(height: 20),
                const Text(
                  "وصلت جرة الغاز!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "كيف كانت تجربتك مع السائق ${widget.driverName}؟",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                RatingBar.builder(
                  initialRating: 3,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(
                    Icons.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rating) {
                    setState(() => _userRating = rating);
                  },
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: "اكتب رأيك بالسائق (اختياري)...",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _isLoading ? null : _submitRating,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("إرسال التقييم",
                            style:
                                TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
