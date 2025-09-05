import 'package:badminton_booking_app/components/my_post.dart';
import 'package:flutter/material.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cs = Theme.of(context).colorScheme;
    final DateTime time = DateTime.now();

    return Scaffold(
      body: Stack(
        children: [
          // List Bài Viết
          Container(
            margin: EdgeInsets.only(top: screenHeight / 18),
            padding: const EdgeInsets.only(top: 50, bottom: 40),
            child: ListView(
              children: [
                MyPost(
                  message: "https://picsum.photos/seed/promo1/1200/600",
                  userName: "BaoMinh",
                  time: time,
                ),
                MyPost(
                  message: "https://picsum.photos/seed/promo2/1200/600",
                  userName: "BaoMinh",
                  time: time,
                ),
                MyPost(
                  message: "https://picsum.photos/seed/promo3/1200/600",
                  userName: "BaoMinh",
                  time: time,
                ),
                MyPost(
                  message: "https://picsum.photos/seed/promo4/1200/600",
                  userName: "BaoMinh",
                  time: time,
                ),
                MyPost(
                  message: "https://picsum.photos/seed/promo5/1200/600",
                  userName: "BaoMinh",
                  time: time,
                ),
              ],
            ),
          ),

          // Title
          Container(
            height: screenHeight / 7,
            decoration: BoxDecoration(
              color: cs.primary,
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 35),
              child: Center(
                child: Text(
                  'W A L L',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
