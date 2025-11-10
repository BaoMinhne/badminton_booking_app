import 'package:badminton_booking_app/components/create_post.dart';
import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/recruitment_post_card.dart';
import 'package:badminton_booking_app/models/community_post.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_home_page.dart';
import 'package:badminton_booking_app/pages/social/create_post_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_page.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialManager>().loadInitial();
    });
  }

  Future<void> _openCreatePost(BuildContext context) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );
    if (result == true && mounted) {
      await context.read<SocialManager>().refreshPosts();
    }
  }

  Future<void> _refreshAll(SocialManager manager) async {
    await Future.wait([
      manager.refreshPosts(),
      manager.refreshRecruitments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final manager = context.watch<SocialManager>();

    final userManager = context.watch<UserManager>();
    final avatarUrl = userManager.avatarUrl;

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.3),
      appBar: AppBar(
        title: const Text(
          'Cộng đồng cầu lông',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Đăng bài',
            onPressed: () => _openCreatePost(context),
          ),
          IconButton(
            icon: const Icon(Icons.group, size: 30),
            tooltip: 'Tin nhắn',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ChatHomePage()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshAll(manager),
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
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: CreatePostBar(
                    // ấn vào ô nhập -> mở trang tạo post
                    onCreatePost: () => _openCreatePost(context),

                    // 3 action dưới—nếu chưa có picker thì cứ gọi trang tạo post luôn
                    onPickPhoto: () => _openCreatePost(context),
                    onInviteFriends: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RecruitmentFormPage(),
                        ),
                      );
                    },

                    // Avatar (nếu có)
                    avatarImageProvider:
                        (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null, // hoặc để null

                    // Tuỳ chỉnh giao diện
                    hintText: 'Bạn đang nghĩ gì thế?',
                    elevation: 5.0,
                    // compact: true, // nếu muốn chỉ hiện 1 hàng (ẩn 3 action)
                  ),
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
              _buildRecruitmentSection(manager),
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
              _buildCommunityPosts(manager),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecruitmentSection(SocialManager manager) {
    if (manager.isLoadingRecruitments && manager.recruitmentPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (manager.recruitmentError != null && manager.recruitmentPosts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _ErrorBox(message: manager.recruitmentError!),
        ),
      );
    }

    if (manager.recruitmentPosts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Text('Chưa có bài tuyển nào. Hãy là người đầu tiên đăng bài!'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final RecruitmentPost post = manager.recruitmentPosts[index];
          return RecruitmentPostCard(
            hostName: post.authorName,
            createdTime: post.createdAt,
            requiredPlayers: post.requiredPlayers,
            joinedPlayers: post.joinedPlayers,
            description: post.description,
            skillLevel: post.skillLevel,
            playStyle: post.playStyle,
            courtName: post.courtName,
            playTime: post.eventTime,
            locationNote: post.locationNote,
            onJoin: () async {
              try {
                await manager.joinRecruitment(post.id);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
            isJoined: post.isJoined,
            isOwner: post.isOwner,
            isJoinLoading: manager.isJoining(post.id),
          );
        },
        childCount: manager.recruitmentPosts.length,
      ),
    );
  }

  Widget _buildCommunityPosts(SocialManager manager) {
    if (manager.isLoadingPosts && manager.posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (manager.postError != null && manager.posts.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: _ErrorBox(message: manager.postError!),
        ),
      );
    }

    if (manager.posts.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Text('Bảng tin đang trống. Đăng bài đầu tiên ngay nào!'),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final CommunityPost post = manager.posts[index];
          return MyPost(
            content: post.content,
            userName: post.authorName,
            time: post.createdAt,
            imageUrls: post.imageUrls,
          );
        },
        childCount: manager.posts.length,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
