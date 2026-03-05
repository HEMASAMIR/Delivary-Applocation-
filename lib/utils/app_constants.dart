import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Uber Style Delivery';

  static const int maxActiveOrdersPerDriver = 4;
  static const double searchRadiusKm = 10.0;

  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String socketUrl = 'http://10.0.2.2:3000';

  // ألوان Uber
  static const Color primaryColor = Colors.black;
  static const Color accentColor = Color(0xFF1DB954);
}
