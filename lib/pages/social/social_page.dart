import 'dart:async';

import 'package:badminton_booking_app/components/create_post.dart';
import 'package:badminton_booking_app/components/my_post.dart';
import 'package:badminton_booking_app/components/player_suggestion_card.dart';
import 'package:badminton_booking_app/components/post_comments_sheet.dart';
import 'package:badminton_booking_app/components/recruitment_post_card.dart';
import 'package:badminton_booking_app/models/community_post.dart';
import 'package:badminton_booking_app/models/invitation.dart';
import 'package:badminton_booking_app/models/recruitment_post.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_home_page.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_list_manager.dart';
import 'package:badminton_booking_app/pages/social/create_post_page.dart';
import 'package:badminton_booking_app/pages/social/invitation/invitation_manager.dart';
import 'package:badminton_booking_app/pages/social/invitation/invitation_sheet.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_applicants_page.dart';
import 'package:badminton_booking_app/pages/social/recruitment/recruitment_page.dart';
import 'package:badminton_booking_app/pages/social/partner_suggestion_manager.dart';
import 'package:badminton_booking_app/pages/social/social_manager.dart';
import 'package:badminton_booking_app/pages/user/user_manager.dart';
import 'package:badminton_booking_app/pages/user/user_public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_list_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_request_manager.dart';
import 'package:provider/provider.dart';

import '../../models/friend_search_result.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  late final PartnerSuggestionManager _partnerManager;
  late final InvitationManager _invitationManager;
  final Set<String> _pendingRequests = <String>{};

  @override
  void initState() {
    super.initState();
    _partnerManager = PartnerSuggestionManager();
    _invitationManager = InvitationManager();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialManager>().loadInitial();
      _partnerManager.loadSuggestions();
      _invitationManager.refreshIncoming();
    });
  }

  @override
  void dispose() {
    _partnerManager.dispose();
    _invitationManager.dispose();
    super.dispose();
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
      length: 4,
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
            isScrollable: true,
            padding: const EdgeInsets.only(
                left: 8), // hơi cách mép trái 1 chút cho đẹp
            labelPadding: const EdgeInsets.only(
                right: 24), // chỉ chừa khoảng cách bên phải mỗi tab
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.people_alt_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Community'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.person_search_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Recruitment'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.handshake_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Partner'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.mail_outline_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Invited'),
                  ],
                ),
              ),
            ],
            // các phần còn lại giữ nguyên
            labelStyle: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
            unselectedLabelStyle: tt.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            labelColor: cs.onPrimary,
            unselectedLabelColor: cs.onPrimary.withOpacity(0.75),
            indicator: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              color: cs.primary.withOpacity(0.3),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicatorColor: Colors.transparent,
            dividerColor: cs.onPrimary.withOpacity(0.15),
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
              _buildPartnerSuggestionTab(context, _partnerManager),
              _buildCourtInvitesTab(context, _invitationManager),
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

  Widget _buildPartnerSuggestionTab(
    BuildContext context,
    PartnerSuggestionManager partnerManager,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: () => partnerManager.loadSuggestions(force: true),
      child: AnimatedBuilder(
        animation: partnerManager,
        builder: (context, _) {
          final suggestions = partnerManager.suggestions;
          final userManager = context.watch<UserManager>();
          partnerManager.setHomeCourtId(userManager.myDetails?.homeCourtId);

          return CustomScrollView(
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
                      _QuickFilterPanel(
                        manager: partnerManager,
                        onAdvancedTap: () =>
                            _openPartnerFilterSheet(context, partnerManager),
                      ),
                      const SizedBox(height: 12),
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
              if (partnerManager.isLoading && suggestions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (partnerManager.error != null && suggestions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _PartnerErrorState(
                    message: partnerManager.error ?? '',
                    onRetry: () => partnerManager.loadSuggestions(force: true),
                  ),
                )
              else if (suggestions.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Không có gợi ý phù hợp với bộ lọc hiện tại.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final suggestion = suggestions[index];
                        final details = suggestion.friend.details;
                        final displayName = suggestion.friend.displayName;
                        final level = details?.level ??
                            'Level ${details?.levelNumeric ?? 3}';
                        final intensityLabel =
                            _humanize(details?.intensity) ?? 'Chưa cập nhật';

                        return PlayerSuggestionCard(
                          name: displayName,
                          level: level,
                          matchScore: suggestion.matchScore.round(),
                          playTags: details?.playStyleTags ?? const <String>[],
                          intensityLabel: intensityLabel,
                          avatarInitial: suggestion.friend.initials,
                          onProfileTap: () =>
                              _openProfile(context, suggestion.friend),
                          onInviteTap: () => _openInviteSheet(
                            context: context,
                            friend: suggestion.friend,
                          ),
                        );
                      },
                      childCount: suggestions.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPartnerFilterSheet(
    BuildContext context,
    PartnerSuggestionManager manager,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AnimatedBuilder(
        animation: manager,
        builder: (context, __) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Lọc nâng cao',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Chỉ hiện người cùng sân nhà'),
                  subtitle: Text(
                    manager.homeCourtId == null
                        ? 'Bạn chưa chọn sân nhà trong hồ sơ.'
                        : 'Ưu tiên các partner có home court trùng với bạn.',
                  ),
                  value: manager.homeCourtId != null && manager.onlyHomeCourt,
                  onChanged: manager.homeCourtId == null
                      ? null
                      : manager.setHomeCourtOnly,
                ),
                const SizedBox(height: 4),
                Text(
                  'Match score tối thiểu: ${manager.minMatchScore.round()}%',
                  style:
                      tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Slider(
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${manager.minMatchScore.round()}%',
                  value: manager.minMatchScore.clamp(0, 100),
                  activeColor: cs.primary,
                  onChanged: manager.setMinMatchScore,
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ẩn người đã gửi lời mời hoặc đã là bạn'),
                  subtitle: const Text(
                    'Loại bỏ các profile bạn đã gửi/nhận lời mời hoặc đã trở thành bạn bè.',
                  ),
                  value: manager.hideExistingRelations,
                  onChanged: (value) {
                    if (value == null) return;
                    unawaited(manager.setHideExistingRelations(value));
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String? _humanize(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return raw
        .split('_')
        .map((word) =>
            word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Widget _buildCourtInvitesTab(
    BuildContext context,
    InvitationManager invitationManager,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: invitationManager.refreshIncoming,
      child: AnimatedBuilder(
        animation: invitationManager,
        builder: (context, _) {
          final invites = invitationManager.invitations;

          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.mail_outline_rounded,
                            color: cs.primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lời mời vào sân',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Theo dõi các lời mời chơi gần đây và phản hồi nhanh chóng.',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (invitationManager.isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (invitationManager.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _PartnerErrorState(
                    message: invitationManager.error!,
                    onRetry: invitationManager.refreshIncoming,
                  ),
                )
              else if (invites.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Chưa có lời mời nào.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) => _InviteCard(
                      invite: invites[index],
                      onAccept: invites[index].isOutgoing
                          ? null
                          : () => invitationManager.respond(
                                invites[index],
                                accept: true,
                              ),
                      onReject: invites[index].isOutgoing
                          ? null
                          : () => invitationManager.respond(
                                invites[index],
                                accept: false,
                              ),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: invites.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          );
        },
      ),
    );
  }

  void _openProfile(BuildContext context, FriendSearchResult friend) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserPublicProfilePage(result: friend),
      ),
    );
  }

  Future<void> _openInviteSheet({
    required BuildContext context,
    required FriendSearchResult friend,
  }) async {
    final userId = friend.user.id;
    if (_pendingRequests.contains(userId)) return;

    setState(() {
      _pendingRequests.add(userId);
    });

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => InvitationSheet(
          toUser: friend,
          manager: _invitationManager,
        ),
      );
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _pendingRequests.remove(userId);
        });
      }
    }
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onAccept,
    required this.onReject,
  });

  final Invitation invite;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isOutgoing = invite.isOutgoing;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withOpacity(0.12),
                      cs.primary.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: cs.primary.withOpacity(0.18)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.search_rounded, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.courtName ?? 'Slot đang chờ xác nhận',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(invite, isOutgoing),
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.25)),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    _typeLabel(invite.type),
                    style: tt.labelMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (invite.message?.isNotEmpty == true)
            Text(
              invite.message!,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          if (invite.startTime != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatTime(invite),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          if (!isOutgoing && invite.isPending)
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.event_available_rounded, size: 18),
                    label: const Text('Chấp nhận'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: cs.primary,
                      foregroundColor: cs.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.reply_rounded, size: 18),
                    label: const Text('Từ chối'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: cs.primary.withOpacity(0.35)),
                      foregroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            _StatusLabel(invite: invite, isOutgoing: isOutgoing),
        ],
      ),
    );
  }

  String _subtitle(Invitation invite, bool isOutgoing) {
    final host = isOutgoing
        ? 'Bạn đã mời ${invite.toUserName ?? 'người chơi'}'
        : invite.fromUserName ?? 'Người chơi';
    final slot = _formatTime(invite);
    return '$host • ${slot ?? 'Slot đang chờ cập nhật'}';
  }

  String _typeLabel(InvitationType type) {
    switch (type) {
      case InvitationType.booking:
        return 'Booking có sẵn';
      case InvitationType.proposed:
        return 'Lời mời dự kiến';
      case InvitationType.recruitment:
        return 'Theo bài tuyển';
    }
  }

  String _formatTime(Invitation invite) {
    if (invite.startTime == null) return 'Thời gian đang đề xuất';
    final start = invite.startTime!;
    final end = invite.endTime;
    final timeString = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) {
      return '$timeString - ${_formatDate(start)}';
    }
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$timeString - $endStr • ${_formatDate(start)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.invite, required this.isOutgoing});

  final Invitation invite;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Color fg;
    Color bg;
    IconData icon;
    String title;
    String subtitle;

    switch (invite.status) {
      case 'accepted':
        fg = Colors.green.shade700;
        bg = Colors.green.withOpacity(0.12);
        icon = Icons.check_circle_rounded;
        title = isOutgoing ? 'Đã được chấp nhận' : 'Bạn đã chấp nhận lời mời này';
        subtitle = 'Đã khoá lịch hẹn, hãy liên hệ để xác nhận chi tiết.';
        break;
      case 'rejected':
        fg = Colors.red.shade600;
        bg = Colors.red.withOpacity(0.1);
        icon = Icons.cancel_rounded;
        title = isOutgoing ? 'Đã bị từ chối' : 'Bạn đã từ chối lời mời này';
        subtitle = 'Bạn có thể gửi lời mời khác hoặc chọn slot khác.';
        break;
      case 'cancelled':
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceVariant.withOpacity(0.3);
        icon = Icons.block_rounded;
        title = isOutgoing ? 'Bạn đã huỷ lời mời này' : 'Lời mời đã bị huỷ';
        subtitle = 'Nếu cần, hãy gửi lại lời mời mới với thông tin cập nhật.';
        break;
      default:
        fg = cs.primary;
        bg = cs.primary.withOpacity(0.08);
        icon = Icons.hourglass_top_rounded;
        title = isOutgoing ? 'Đã gửi • Chờ phản hồi' : 'Đang chờ phản hồi của bạn';
        subtitle = isOutgoing
            ? 'Người nhận sẽ xem và phản hồi sớm.'
            : 'Chấp nhận để chốt lịch, hoặc từ chối nếu chưa phù hợp.';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: tt.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PartnerErrorState extends StatelessWidget {
  const _PartnerErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 36, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tt.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Thử lại'),
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

class _QuickFilterPanel extends StatelessWidget {
  const _QuickFilterPanel({
    required this.manager,
    required this.onAdvancedTap,
  });

  final PartnerSuggestionManager manager;
  final VoidCallback onAdvancedTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    const matchTypeOptions = [
      (label: 'Tất cả', value: null as String?),
      (label: 'Đánh đơn', value: 'singles'),
      (label: 'Đánh đôi', value: 'doubles'),
      (label: 'Đôi nam nữ', value: 'mixed'),
    ];

    const intensityOptions = [
      (label: 'Chơi vui', value: 'casual'),
      (label: 'Vừa phải', value: 'semi_competitive'),
      (label: 'Đánh giải', value: 'competitive'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bộ lọc nhanh',
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            OutlinedButton.icon(
              onPressed: onAdvancedTap,
              icon: const Icon(Icons.filter_alt_rounded),
              label: const Text('Lọc nâng cao'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Loại kèo',
          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in matchTypeOptions)
              FilterChip(
                selected: manager.selectedMatchType == option.value,
                label: Text(option.label),
                onSelected: (selected) =>
                    manager.setMatchType(selected ? option.value : null),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                selectedColor: cs.primaryContainer,
                checkmarkColor: cs.onPrimaryContainer,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Độ "máu"',
          style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in intensityOptions)
              FilterChip(
                selected: manager.selectedIntensity == option.value,
                label: Text(option.label),
                onSelected: (selected) =>
                    manager.setIntensity(selected ? option.value : null),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                selectedColor: cs.secondaryContainer,
                checkmarkColor: cs.onSecondaryContainer,
              ),
          ],
        ),
      ],
    );
  }
}
