import 'dart:async';

import 'package:badminton_booking_app/components/create_post.dart';
import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/player_suggestion_card.dart';
import 'package:badminton_booking_app/components/post_comments_sheet.dart';
import 'package:badminton_booking_app/components/recruitment_post_card.dart';
import 'package:badminton_booking_app/models/community_post.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_home_page.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_list_manager.dart';
import 'package:badminton_booking_app/pages/social/create_post_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_applicants_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_page.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:flutter/material.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_list_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_request_manager.dart';
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
      length: 3,
      child: Scaffold(
        backgroundColor: cs.surfaceVariant.withOpacity(0.1),
        appBar: AppBar(
          title: const Text(
            'Cộng đồng cầu lông',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
              tooltip: 'Đăng bài',
              onPressed: () => _openCreatePost(context),
              style: IconButton.styleFrom(
                foregroundColor: cs.onPrimary,
                backgroundColor: cs.primary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.group_rounded, size: 28),
              tooltip: 'Tin nhắn',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiProvider(
                      providers: [
                        ChangeNotifierProvider(
                          create: (_) => FriendRequestManager()..initialize(),
                        ),
                        ChangeNotifierProvider(
                          create: (_) => FriendListManager()..initialize(),
                        ),
                        ChangeNotifierProvider(
                          create: (_) => ChatListManager()..initialize(),
                        ),
                      ],
                      child: const ChatHomePage(),
                    ),
                  ),
                );
              },
              style: IconButton.styleFrom(
                foregroundColor: cs.onPrimary,
                backgroundColor: cs.primary.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_alt_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Community'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_search_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Recruitment'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.handshake_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('Gợi ý bạn chơi'),
                  ],
                ),
              ),
            ],
            // Chữ tab đang chọn
            labelStyle: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            // Chữ tab chưa chọn
            unselectedLabelStyle: tt.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onPrimary.withOpacity(0.75),
            indicator: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              color: cs.primary.withOpacity(0.3),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.transparent,
            dividerColor: cs.onPrimary.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            overlayColor: WidgetStateProperty.all(cs.primary.withOpacity(0.1)),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
        ),
          body: SafeArea(
            child: TabBarView(
              children: [
                _buildPostsTab(context, manager, avatarUrl),
                _buildRecruitmentTab(context, manager),
                _buildPartnerSuggestionTab(context),
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
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

  Widget _buildPartnerSuggestionTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final suggestions = <_PartnerSuggestion>[
      const _PartnerSuggestion(
        name: 'Minh Anh',
        level: 'Intermediate',
        matchScore: 87,
        playTags: ['Đánh đơn', 'Phản công nhanh'],
        intensity: 'Medium',
        colorSeed: Colors.blue,
      ),
      const _PartnerSuggestion(
        name: 'Hải Đăng',
        level: 'Advanced',
        matchScore: 92,
        playTags: ['Đánh đôi', 'Phòng thủ chắc'],
        intensity: 'High',
        colorSeed: Colors.deepOrange,
      ),
      const _PartnerSuggestion(
        name: 'Khánh Chi',
        level: 'Beginner',
        matchScore: 73,
        playTags: ['Học hỏi', 'Giao lưu nhẹ nhàng'],
        intensity: 'Low',
        colorSeed: Colors.teal,
      ),
    ];

    final invites = <_CourtInvite>[
      const _CourtInvite(
        hostName: 'Anh Quân',
        courtName: 'Sân Nhật Hoa',
        playTime: '19:00 - Thứ 5',
        note: 'Cần thêm 2 người, mức Intermediate, đánh đôi.',
      ),
      const _CourtInvite(
        hostName: 'Lan Chi',
        courtName: 'Sân Thống Nhất',
        playTime: '08:00 - Chủ nhật',
        note: 'Giao lưu nhẹ nhàng, ưu tiên nữ.',
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async => Future<void>.delayed(const Duration(milliseconds: 800)),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.handshake_rounded,
                            color: cs.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gợi ý bạn chơi phù hợp',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Khám phá những partner hợp gu, match score được chuẩn hoá từ 0 - 100%.',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(Icons.tips_and_updates_rounded,
                              color: cs.onPrimaryContainer),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Gửi lời mời kết bạn hoặc mời vào sân trực tiếp từ danh sách gợi ý.',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final suggestion = suggestions[index];
                  return PlayerSuggestionCard(
                    name: suggestion.name,
                    level: suggestion.level,
                    matchScore: suggestion.matchScore,
                    playTags: suggestion.playTags,
                    intensityLabel: suggestion.intensity,
                    avatarColor: suggestion.colorSeed.withOpacity(0.16),
                    avatarInitial: suggestion.name.characters.first,
                    onProfileTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Xem hồ sơ ${suggestion.name}'),
                        ),
                      );
                    },
                    onInviteTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Đã gửi lời mời kết bạn cho ${suggestion.name}'),
                        ),
                      );
                    },
                  );
                },
                childCount: suggestions.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.mail_outline_rounded,
                      color: cs.onSurfaceVariant.withOpacity(0.8)),
                  const SizedBox(width: 10),
                  Text(
                    'Lời mời vào sân bạn nhận được',
                    style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _InviteCard(invite: invites[index]),
                childCount: invites.length,
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard(BuildContext context, String? avatarUrl) {
    final cs = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
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
        padding:
            const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tiêu đề + nút Viết bài (được làm gọn và tinh tế hơn)
            Row(
              children: [
                Text(
                  'Chia sẻ điều mới mẻ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1.2,
                      ),
                ),
                const Spacer(),
                // Nút "Viết bài" được làm kiểu chip hiện đại, có hiệu ứng ripple đẹp
                FilledButton.tonalIcon(
                  onPressed: () => _openCreatePost(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Viết bài'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16), // Tăng khoảng cách cho thoáng

            // CreatePostBar được tối ưu giao diện (dùng bản mình đã cải thiện trước đó)
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
              avatarImageProvider: (avatarUrl != null && avatarUrl!.isNotEmpty)
                  ? NetworkImage(avatarUrl!)
                  : null,
              hintText: 'Bạn đang nghĩ gì thế?',
              elevation: 4, // bật lại elevation nhẹ để nổi
              compact: false,
              // Tùy chọn: thêm chút màu chủ đạo nếu muốn nổi bật hơn
              // primaryColor: Colors.blue,
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
              if (!post.isActive) return;

              // Nếu đã có status (pending/accepted/rejected) thì không join lại
              if (post.currentUserStatus != null &&
                  post.currentUserStatus != 'cancelled') {
                return;
              }

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
            isActive: post.isActive,
            currentUserStatus: post.currentUserStatus,
            onManage: post.isOwner
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecruitmentApplicantsPage(post: post),
                      ),
                    );
                  }
                : null,
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

class _PartnerSuggestion {
  const _PartnerSuggestion({
    required this.name,
    required this.level,
    required this.matchScore,
    required this.playTags,
    required this.intensity,
    required this.colorSeed,
  });

  final String name;
  final String level;
  final int matchScore;
  final List<String> playTags;
  final String intensity;
  final Color colorSeed;
}

class _CourtInvite {
  const _CourtInvite({
    required this.hostName,
    required this.courtName,
    required this.playTime,
    required this.note,
  });

  final String hostName;
  final String courtName;
  final String playTime;
  final String note;
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.invite});

  final _CourtInvite invite;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sports_tennis_rounded,
                    color: cs.secondary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.courtName,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Chủ sân: ${invite.hostName} • ${invite.playTime}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lời mời',
                  style: tt.labelMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            invite.note,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Xem chi tiết lời mời tại ${invite.courtName}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_available_rounded, size: 18),
                  label: const Text('Xem lời mời'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã phản hồi lời mời của ${invite.hostName}'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.reply_rounded, size: 18),
                  label: const Text('Phản hồi sau'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
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
