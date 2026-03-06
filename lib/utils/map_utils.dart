import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapUtils {
  MapUtils._();

  static Future<void> openMap(double latitude, double longitude) async {
    String googleUrl = '';

    if (Platform.isAndroid) {
      // للأندرويد: بنفتح تطبيق الخرائط مباشرة
      googleUrl = 'google.navigation:q=$latitude,$longitude';
    } else {
      // للآيفون (iOS)
      googleUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    }

    if (await canLaunchUrl(Uri.parse(googleUrl))) {
      await launchUrl(Uri.parse(googleUrl),
          mode: LaunchMode.externalApplication);
    } else {
      // إذا ما فتح، جرب تفتح الرابط العادي بالمتصفح كخيار بديل
      String webUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }
}
