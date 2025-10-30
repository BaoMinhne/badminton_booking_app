import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/recruitment_post_card.dart';
import 'package:badminton_booking_app/pages/social/chat_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment_form_page.dart';
import 'package:flutter/material.dart';

class SocialPage extends StatelessWidget {
  SocialPage({super.key});

  final DateTime _now = DateTime.now();

  final List<_RecruitmentPost> _recruitmentPosts = [
    _RecruitmentPost(
      hostName: 'Bảo Minh',
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      description: 'Cần 2 bạn trình trung bình khá đánh đôi giao lưu. Team rất vui tính.',
      requiredPlayers: 4,
      joinedPlayers: 2,
      skillLevel: 'Trung bình khá',
      courtName: 'Sân Quận 7 - Court A',
      playTime: DateTime.now().add(const Duration(hours: 2)),
    ),
    _RecruitmentPost(
      hostName: 'Ngọc Anh',
      createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
      description:
          'Tuyển gấp 1 nữ trình trung bình để đánh đôi cố định sáng chủ nhật hàng tuần.',
      requiredPlayers: 4,
      joinedPlayers: 3,
      skillLevel: 'Trung bình',
      courtName: 'Sân Phú Nhuận - Court C',
      playTime: DateTime.now().add(const Duration(days: 1, hours: 10)),
    ),
    _RecruitmentPost(
      hostName: 'Văn Hòa',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      description:
          'Nhóm mình chưa có sân, cần tuyển 3 bạn trình nâng cao lập team đi đánh giải.',
      requiredPlayers: 5,
      joinedPlayers: 1,
      skillLevel: 'Nâng cao',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Cộng đồng cầu lông'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            tooltip: 'Tin nhắn',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatPage()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecruitmentFormPage()),
          );
        },
        icon: const Icon(Icons.post_add_rounded),
        label: const Text('Đăng tuyển thành viên'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildWelcomeCard(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Bài tuyển thành viên',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final post = _recruitmentPosts[index];
                  return RecruitmentPostCard(
                    hostName: post.hostName,
                    createdTime: post.createdAt,
                    requiredPlayers: post.requiredPlayers,
                    joinedPlayers: post.joinedPlayers,
                    description: post.description,
                    skillLevel: post.skillLevel,
                    courtName: post.courtName,
                    playTime: post.playTime,
                    onJoin: () {},
                  );
                },
                childCount: _recruitmentPosts.length,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
                child: Text(
                  'Bảng tin cộng đồng',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate.fixed([
                MyPost(
                  message: 'https://picsum.photos/seed/recruitment1/1200/600',
                  userName: 'Bảo Minh',
                  time: _now,
                ),
                MyPost(
                  message:
                      'Đánh giao hữu cuối tuần này ở Quận 2, ai rảnh thì join nhé!',
                  userName: 'Ngọc Anh',
                  time: _now.subtract(const Duration(hours: 5)),
                ),
                MyPost(
                  message: 'https://picsum.photos/seed/recruitment2/1200/600',
                  userName: 'Văn Hòa',
                  time: _now.subtract(const Duration(hours: 9)),
                ),
              ]),
            ),
            SliverPadding(padding: const EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chào mừng bạn!',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tạo bài tuyển thành viên và kết nối người chơi xung quanh bạn ngay hôm nay.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onPrimary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RecruitmentFormPage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Tạo bài tuyển ngay'),
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.onPrimary,
                    foregroundColor: cs.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.onPrimary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.sports_tennis,
              size: 42,
              color: cs.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecruitmentPost {
  final String hostName;
  final DateTime createdAt;
  final int requiredPlayers;
  final int joinedPlayers;
  final String? skillLevel;
  final String? description;
  final String? courtName;
  final DateTime? playTime;

  const _RecruitmentPost({
    required this.hostName,
    required this.createdAt,
    required this.requiredPlayers,
    required this.joinedPlayers,
    this.skillLevel,
    this.description,
    this.courtName,
    this.playTime,
  });
}
