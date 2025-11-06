import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:badminton_booking_app/components/create_post_card.dart';
import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/recruitment_post_card.dart';
import 'package:badminton_booking_app/models/community_post.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/pages/auth/auth_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_home_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_page.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';

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
      final auth = context.read<AuthManager>();
      final currentUserId = auth.user?.id;
      context.read<SocialManager>().loadInitialData(currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final socialManager = context.watch<SocialManager>();
    final authManager = context.watch<AuthManager>();
    final currentUserId = authManager.user?.id;

    final recruitmentPosts = socialManager.recruitmentPosts;
    final communityPosts = socialManager.posts;

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.3),
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
          const SizedBox(width: 6),
        ],
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
            const SliverToBoxAdapter(
              child: CreatePostCard(),
            ),
            ..._buildRecruitmentSlivers(
              context,
              socialManager,
              recruitmentPosts,
              currentUserId,
            ),
            ..._buildCommunityPostSlivers(
              context,
              socialManager,
              communityPosts,
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRecruitmentTitle(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          'Bài tuyển thành viên',
          style:
              Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildRecruitmentList(
    BuildContext context,
    SocialManager manager,
    List<RecruitmentPost> recruitmentPosts,
    String? currentUserId,
  ) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final post = recruitmentPosts[index];
          final joinedCount = post.joinedMemberCount;
          final targetCount = post.targetMemberCount;
          final isAuthor = post.authorId == currentUserId;
          final isFull = targetCount != null && joinedCount >= targetCount;
          final description = post.locationNote != null && post.locationNote!.isNotEmpty
              ? '${post.content}\nĐịa điểm: ${post.locationNote}'
              : post.content;

          return RecruitmentPostCard(
            hostName: post.authorName,
            createdTime: post.createdAt.toLocal(),
            joinedPlayers: joinedCount,
            targetPlayers: targetCount,
            skillLevel: post.skillLevel,
            playStyle: post.playStyle,
            description: description,
            courtName: post.courtName,
            playTime: post.eventTime?.toLocal(),
            hostAvatarUrl: post.authorAvatarUrl,
            isJoined: post.hasCurrentUserJoined || isAuthor,
            isJoinable: !isAuthor && !isFull,
            isJoining: manager.isJoiningRecruitment(post.id),
            onJoin: (!isAuthor && !isFull && !post.hasCurrentUserJoined)
                ? () async {
                    final auth = context.read<AuthManager>();
                    final user = auth.user;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bạn cần đăng nhập để tham gia.')),
                      );
                      return;
                    }
                    try {
                      await manager.joinRecruitment(
                        recruitmentId: post.id,
                        userId: user.id,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tham gia thành công.')),
                      );
                    } catch (error) {
                      final message = error.toString();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  }
                : null,
          );
        },
        childCount: recruitmentPosts.length,
      ),
    );
  }

  List<Widget> _buildRecruitmentSlivers(
    BuildContext context,
    SocialManager manager,
    List<RecruitmentPost> recruitmentPosts,
    String? currentUserId,
  ) {
    final slivers = <Widget>[_buildRecruitmentTitle(context)];

    if (manager.isLoadingRecruitments && recruitmentPosts.isEmpty) {
      slivers.add(_buildLoadingSliver(context));
      return slivers;
    }

    if (manager.recruitmentErrorMessage != null && recruitmentPosts.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              manager.recruitmentErrorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
      return slivers;
    }

    if (recruitmentPosts.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Chưa có bài tuyển nào. Hãy là người đầu tiên tạo bài!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      _buildRecruitmentList(context, manager, recruitmentPosts, currentUserId),
    );

    if (manager.isLoadingRecruitments && recruitmentPosts.isNotEmpty) {
      slivers.add(_buildLoadingSliver(context));
    }

    return slivers;
  }

  List<Widget> _buildCommunityPostSlivers(
    BuildContext context,
    SocialManager manager,
    List<CommunityPost> communityPosts,
  ) {
    final slivers = <Widget>[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 4),
          child: Text(
            'Bảng tin cộng đồng',
            style:
                Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ];

    if (manager.isLoadingPosts && communityPosts.isEmpty) {
      slivers.add(_buildLoadingSliver(context));
      return slivers;
    }

    if (manager.postErrorMessage != null && communityPosts.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              manager.postErrorMessage!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
      return slivers;
    }

    if (communityPosts.isEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              'Chưa có bài đăng nào. Hãy chia sẻ điều gì đó!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
      return slivers;
    }

    slivers.add(
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final post = communityPosts[index];
            return MyPost(
              content: post.content,
              userName: post.authorName,
              time: post.createdAt.toLocal(),
              imageUrls: post.imageUrls,
              userAvatarUrl: post.authorAvatarUrl,
            );
          },
          childCount: communityPosts.length,
        ),
      ),
    );

    if (manager.isLoadingPosts && communityPosts.isNotEmpty) {
      slivers.add(_buildLoadingSliver(context));
    }

    return slivers;
  }

  Widget _buildLoadingSliver(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
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
