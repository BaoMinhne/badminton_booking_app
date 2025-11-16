import 'dart:async';

import 'package:badminton_booking_app/components/create_post.dart';
import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/post_comments_sheet.dart';
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

  void _handleLikePressed(
    BuildContext context,
    SocialManager manager,
    CommunityPost post,
  ) {
    unawaited(
      manager.toggleLike(post.id).catchError((error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }),
    );
  }

  Future<void> _openCommentsSheet(
    BuildContext context,
    SocialManager manager,
    CommunityPost post,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostCommentsSheet(
        postId: post.id,
        manager: manager,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final manager = context.watch<SocialManager>();

    final userManager = context.watch<UserManager>();
    final avatarUrl = userManager.avatarUrl;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            tabs: [
              Tab(text: 'Community'),
              Tab(text: 'Recruitment'),
            ],
            // Chữ tab đang chọn
            labelStyle: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16, // ← tăng kích thước chữ
            ),
            // Chữ tab chưa chọn
            unselectedLabelStyle: tt.titleSmall?.copyWith(
              fontSize: 16, // ← giữ cùng size cho đồng đều
              fontWeight: FontWeight.w500,
            ),
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onPrimary.withOpacity(0.65),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: cs.onPrimary, width: 2.4),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildPostsTab(context, manager, avatarUrl),
              _buildRecruitmentTab(context, manager),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab(
    BuildContext context,
    SocialManager manager,
    String? avatarUrl,
  ) {
    return RefreshIndicator(
      onRefresh: manager.refreshPosts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _buildCreatePostCard(context, avatarUrl),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Bảng tin cộng đồng',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          _buildCommunityPosts(manager),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildRecruitmentTab(BuildContext context, SocialManager manager) {
    return RefreshIndicator(
      onRefresh: manager.refreshRecruitments,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(context),
                  const SizedBox(height: 24),
                  Text(
                    'Bài tuyển thành viên',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          _buildRecruitmentSection(manager),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard(BuildContext context, String? avatarUrl) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chia sẻ điều mới mẻ',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _openCreatePost(context),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Viết bài'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CreatePostBar(
              onCreatePost: () => _openCreatePost(context),
              onPickPhoto: () => _openCreatePost(context),
              onInviteFriends: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RecruitmentFormPage(),
                  ),
                );
              },
              avatarImageProvider: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              hintText: 'Bạn đang nghĩ gì thế?',
              elevation: 0,
            ),
          ],
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
            hostAvatarUrl: post.authorAvatarUrl,
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
            avatarUrl: post.authorAvatarUrl,
            isLiked: post.isLiked,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            onLikePressed: () => _handleLikePressed(context, manager, post),
            onCommentPressed: () => _openCommentsSheet(context, manager, post),
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
                  icon: Icon(Icons.flash_on_rounded, color: cs.primary),
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
