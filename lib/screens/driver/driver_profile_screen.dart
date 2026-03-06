import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DriverProfileScreen extends StatelessWidget {
  final Map driverData; // البيانات اللي بتيجي من قاعدة البيانات

  const DriverProfileScreen({super.key, required this.driverData});

  @override
  Widget build(BuildContext context) {
    // نفترض إن البيانات جاية هيك
    double averageRating = driverData['avgRating'] ?? 0.0;
    int totalReviews = driverData['totalReviews'] ?? 0;
    List reviews = driverData['reviews'] ?? [];

    return Scaffold(
      appBar: AppBar(
          title: const Text("بروفايل السائق"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 1. صورة السائق واسمه
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 10),
            Text(driverData['name'] ?? "اسم السائق",
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            // 2. عرض المعدل
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(averageRating.toString(),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                RatingBarIndicator(
                  rating: averageRating,
                  itemBuilder: (context, index) =>
                      const Icon(Icons.star, color: Colors.amber),
                  itemCount: 5,
                  itemSize: 25.0,
                ),
              ],
            ),
            Text("بناءً على $totalReviews تقييم",
                style: const TextStyle(color: Colors.grey)),

            const Divider(height: 40),

            // 3. قائمة التعليقات
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text("آخر التعليقات",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold))),
            ),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  child: ListTile(
                    leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person_outline)),
                    title: RatingBarIndicator(
                      rating: reviews[index]['rating'].toDouble(),
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      itemSize: 15,
                    ),
                    subtitle: Text(reviews[index]['comment'] ?? "بدون تعليق"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
