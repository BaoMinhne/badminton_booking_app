import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/pages/social/recruitment_post_page.dart';
import 'package:badminton_booking_app/pages/social/user_chat_page.dart';
import 'package:flutter/material.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cs = Theme.of(context).colorScheme;
    final DateTime time = DateTime.now();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecruitmentPostPage(),
            ),
          );
        },
        icon: const Icon(Icons.post_add_outlined),
        label: const Text('Đăng tuyển'),
      ),
      body: Stack(
        children: [
          // List Bài Viết
          Container(
            margin: EdgeInsets.only(top: screenHeight / 18),
            padding: const EdgeInsets.only(top: 70, bottom: 40),
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
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'W A L L',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RecruitmentPostPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.group_add_outlined),
                      label: const Text('Tuyển thành viên'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UserChatPage(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      tooltip: 'Chat với người dùng',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
