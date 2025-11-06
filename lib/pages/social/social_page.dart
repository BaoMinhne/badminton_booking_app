import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/my_post.dart';
import '../../components/recruitment_post_card.dart';
import '../../providers/file_manager.dart';
import 'chat/chat_home_page.dart';
import 'create_post_page.dart';
import 'recruitment/recruitment_page.dart';
import 'social_manager.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final manager = context.read<SocialFeedManager>();
      manager.refreshAll();
    });
  }

  Future<void> _refreshFeed() {
    return context.read<SocialFeedManager>().refreshAll();
  }

  Future<void> _openCreatePost() async {
    final fileManager = context.read<FileManager>();
    fileManager.clear();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text(
          'Cộng đồng cầu lông',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group, size: 30),
            tooltip: 'Tin nhắn',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatHomePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.post_add, size: 30),
            tooltip: 'Tạo bài viết',
            onPressed: _openCreatePost,
          ),
          const SizedBox(width: 6),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePost,
        icon: const Icon(Icons.post_add),
        label: const Text('Đăng bài'),
      ),
      body: SafeArea(
        child: Consumer<SocialFeedManager>(
          builder: (context, manager, _) {
            final recruitmentPosts = manager.recruitmentPosts;
            final posts = manager.posts;
            final isLoading =
                (manager.isLoadingPosts && manager.posts.isEmpty) ||
                    (manager.isLoadingRecruitments &&
                        manager.recruitmentPosts.isEmpty);

            return RefreshIndicator(
              onRefresh: _refreshFeed,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                  if (isLoading && recruitmentPosts.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (recruitmentPosts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Text(
                          'Chưa có bài tuyển nào. Hãy là người đầu tiên đăng bài!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = recruitmentPosts[index];
                          return RecruitmentPostCard(
                            hostName: post.authorName,
                            createdTime: post.createdAt,
                            requiredPlayers: post.requiredMembers,
                            joinedPlayers: post.joinedMembers,
                            description: post.content,
                            skillLevel: post.skillLevel,
                            courtName: post.courtName,
                            playTime: post.eventTime,
                            playStyle: _mapPlayStyle(post.playStyle),
                            locationNote: post.locationNote,
                            onJoin: () {},
                          );
                        },
                        childCount: recruitmentPosts.length,
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
                  if (isLoading && posts.isEmpty)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (posts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Text(
                          'Chưa có bài đăng nào. Hãy chia sẻ khoảnh khắc của bạn!',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return MyPost(
                            userName: post.authorName,
                            time: post.createdAt,
                            content: post.content,
                            imageUrls: post.imageUrls,
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            );
          },
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimary, fontWeight: FontWeight.bold),
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _mapPlayStyle(String? value) {
    switch (value) {
      case 'singles':
        return 'Đánh đơn';
      case 'doubles':
        return 'Đánh đôi';
      case 'mixed':
        return 'Đánh đôi nam nữ';
    }
    return value;
  }
}
