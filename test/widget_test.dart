import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// التعديل الأساسي: غيرنا الاسم لـ delivery_app عشان يطابق مشروعك
import 'package:delivery_app/main.dart';

void main() {
  testWidgets('App basic load test', (WidgetTester tester) async {
    // بناء التطبيق وتحفيز إطار (Frame)
    // التعديل: استخدمنا MyApp (الأحرف الكبيرة) زي ما هي بالـ main.dart
    await tester.pumpWidget(const MyApp());

    // فحص للتأكد إن التطبيق اشتغل وفتح الـ MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
