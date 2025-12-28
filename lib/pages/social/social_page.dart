import 'dart:async';
import 'dart:math';

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

import '../../models/partner_recommendation.dart';
import '../../models/friend_search_result.dart';
import '../../models/user_details.dart';

class SocialPage extends StatefulWidget {
  final int initialTab;

  const SocialPage({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<SocialPage> createState() => SocialPageState();
}

class SocialPageState extends State<SocialPage> {
  late final PartnerSuggestionManager _partnerManager;
  late final InvitationManager _invitationManager;
  final Set<String> _pendingRequests = <String>{};
  TabController? _tabController;
  int _visibleSuggestionCount = 10;
  String _suggestionSignature = '';

  @override
  void initState() {
    super.initState();
    _partnerManager = PartnerSuggestionManager();
    _invitationManager = InvitationManager();
    _partnerManager.addListener(_onSuggestionsUpdated);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialManager>().loadInitial();
      _partnerManager.loadSuggestions();
      _invitationManager.refreshIncoming();
    });
  }

  @override
  void dispose() {
    _partnerManager.removeListener(_onSuggestionsUpdated);
    _partnerManager.dispose();
    _invitationManager.dispose();
    super.dispose();
  }

  void _onSuggestionsUpdated() {
    final suggestions = _partnerManager.suggestions;
    final signature = _buildSuggestionSignature(suggestions);

    if (signature == _suggestionSignature) return;

    _suggestionSignature = signature;
    final newVisibleCount = suggestions.isEmpty ? 0 : min(10, suggestions.length);
    if (newVisibleCount != _visibleSuggestionCount) {
      setState(() {
        _visibleSuggestionCount = newVisibleCount;
      });
    }
  }

  String _buildSuggestionSignature(List<PartnerRecommendation> suggestions) =>
      suggestions.map((s) => s.friend.user.id).join('|');

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

  void _showRecommendationReason(
    BuildContext context,
    PartnerRecommendation suggestion,
    UserDetails? myDetails,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final friendDetails = suggestion.friend.details;

    final myStyles = myDetails?.playStyleTags ?? const <String>[];
    final friendStyles = friendDetails?.playStyleTags ?? const <String>[];
    final sharedStyles =
        friendStyles.where((style) => myStyles.contains(style)).toList();

    final myMatchTypes = myDetails?.matchTypes ?? const <String>[];
    final friendMatchTypes = friendDetails?.matchTypes ?? const <String>[];
    final sharedMatchTypes =
        friendMatchTypes.where((type) => myMatchTypes.contains(type)).toList();

    final reasons = <_ReasonDetail>[];

    if (sharedStyles.isNotEmpty) {
      reasons.add(
        _ReasonDetail(
          icon: Icons.style_rounded,
          iconColor: cs.primary,
          text: 'Shared play style: ${sharedStyles.join(' / ')}',
        ),
      );
    } else if (friendStyles.isNotEmpty) {
      reasons.add(
        _ReasonDetail(
          icon: Icons.auto_awesome_rounded,
          iconColor: cs.primary,
          text: 'Complementary play style: ${friendStyles.take(2).join(' / ')}',
        ),
      );
    }

    final intensity = friendDetails?.intensity;
    if (intensity != null) {
      final intensityLabel = _humanize(intensity) ?? intensity;
      reasons.add(
        _ReasonDetail(
          icon: Icons.local_fire_department_rounded,
          iconColor: cs.tertiary,
          text: intensity == myDetails?.intensity
              ? 'Same play intensity $intensityLabel'
              : 'Compatible play intensity: $intensityLabel',
        ),
      );
    }

    if (sharedMatchTypes.isNotEmpty) {
      reasons.add(
        _ReasonDetail(
          icon: Icons.sports_tennis,
          iconColor: cs.secondary,
          text: 'Preferred match types: ${sharedMatchTypes.join(' / ')}',
        ),
      );
    }

    reasons.add(
      _ReasonDetail(
        icon: Icons.stars_rounded,
        iconColor: cs.primary,
        text: 'Predicted match score: ${suggestion.matchScore.round()}%',
      ),
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.surface,
                  cs.surfaceVariant.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [cs.primary, cs.primary.withOpacity(0.75)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Icon(
                        Icons.recommend_rounded,
                        color: cs.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why recommend ${suggestion.friend.displayName}?',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Personalized based on your play profile',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${suggestion.matchScore.round()}%',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            'Match',
                            style: tt.labelSmall?.copyWith(
                              color: cs.onPrimaryContainer.withOpacity(0.8),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...reasons.map(
                  (reason) => Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceVariant.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: reason.iconColor.withOpacity(0.12),
                          ),
                          child: Icon(
                            reason.icon,
                            color: reason.iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason.text,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void jumpToTab(int index) {
    final controller = _tabController;
    if (controller == null) return;
    if (index < 0 || index >= controller.length) return;
    controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final int initialTab = widget.initialTab.clamp(0, 3).toInt();

    final manager = context.watch<SocialManager>();

    final userManager = context.watch<UserManager>();
    final avatarUrl = userManager.avatarUrl;

    return DefaultTabController(
      length: 4,
      initialIndex: initialTab,
      child: Builder(
        builder: (context) {
          _tabController = DefaultTabController.of(context);

          return Scaffold(
            backgroundColor: cs.surfaceVariant.withOpacity(0.1),
            appBar: AppBar(
              title: const Text(
                'Badminton Community',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 26),
                  tooltip: 'Create post',
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
                  tooltip: 'Messages',
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
                padding: const EdgeInsets.only(left: 8),
                labelPadding: const EdgeInsets.only(right: 24),
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
                        Text('Invitations'),
                      ],
                    ),
                  ),
                ],
                // other parts remain unchanged
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
                overlayColor:
                    WidgetStateProperty.all(cs.primary.withOpacity(0.1)),
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
          );
        },
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
                'Community feed',
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
                    'Member recruitment posts',
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
          final visibleSuggestions =
              min(_visibleSuggestionCount, suggestions.length);

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
                                  'Recommended partners',
                                  style: tt.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Discover well-matched partners with normalized match scores from 0 - 100%.',
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
                                  'Send friend requests or court invites directly from the suggestions list.',
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
                    child: Text('No suggestions match the current filters.'),
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
                            _humanize(details?.intensity) ?? 'Not updated yet';

                        return PlayerSuggestionCard(
                          name: displayName,
                          level: level,
                          matchScore: suggestion.matchScore.round(),
                          playTags: details?.playStyleTags ?? const <String>[],
                          intensityLabel: intensityLabel,
                          avatarInitial: suggestion.friend.initials,
                          onTap: () => _showRecommendationReason(
                            context,
                            suggestion,
                            userManager.myDetails,
                          ),
                          onProfileTap: () =>
                              _openProfile(context, suggestion.friend),
                          onInviteTap: () => _openInviteSheet(
                            context: context,
                            friend: suggestion.friend,
                          ),
                          onDismiss: () => partnerManager
                              .dismissSuggestion(suggestion.friend.user.id),
                        );
                      },
                      childCount: visibleSuggestions,
                    ),
                  ),
                ),
              if (visibleSuggestions < suggestions.length)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _visibleSuggestionCount = min(
                              suggestions.length,
                              _visibleSuggestionCount + 3,
                            );
                          });
                        },
                        child: const Text('Load more'),
                      ),
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
                      'Advanced filters',
                      style:
                          tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                  title: const Text('Show only players sharing my home court'),
                  subtitle: Text(
                    manager.homeCourtId == null
                        ? 'You have not set a home court in your profile.'
                        : 'Prioritize partners whose home court matches yours.',
                  ),
                  value: manager.homeCourtId != null && manager.onlyHomeCourt,
                  onChanged: manager.homeCourtId == null
                      ? null
                      : manager.setHomeCourtOnly,
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum match score: ${manager.minMatchScore.round()}%',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                  title: const Text('Hide people already invited or friended'),
                  subtitle: const Text(
                    "Exclude profiles you've sent/received invites to or are already friends with.",
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
                              'Court invitations',
                              style: tt.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Keep up with recent invitations and respond quickly.',
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
                    child: Text('No invitations yet.'),
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
    unawaited(_partnerManager.logProfileClicked(friend.user.id));
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

    unawaited(_partnerManager.logInviteAction(friend.user.id));

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
            // Header: title + Write post button with streamlined styling
            Row(
              children: [
                Text(
                  'Share something new',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        height: 1.2,
                      ),
                ),
                const Spacer(),
                // "Write post" chip-style button with ripple effect
                FilledButton.tonalIcon(
                  onPressed: () => _openCreatePost(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Write post'),
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

            const SizedBox(height: 16), // Extra spacing for breathing room

            // Optimized CreatePostBar layout
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
              hintText: 'What\'s on your mind?',
              elevation: 4, // subtle elevation for emphasis
              compact: false,
              // Optional: add primaryColor to highlight further
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
          child: Text('No recruitment posts yet. Be the first to post!'),
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

              // If status already exists (pending/accepted/rejected), skip joining again
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
          child: Text('The feed is empty. Be the first to post!'),
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
                  'Welcome!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Create a recruitment post and connect with nearby players today.',
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
                  label: const Text('Create a recruitment now'),
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
                      invite.courtName ?? 'Slot pending confirmation',
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
                    label: const Text('Accept'),
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
                    label: const Text('Decline'),
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
        ? 'You invited ${invite.toUserName ?? 'player'}'
        : invite.fromUserName ?? 'Player';
    final slot = _formatTime(invite);
    return '$host • ${slot ?? 'Slot awaiting update'}';
  }

  String _typeLabel(InvitationType type) {
    switch (type) {
      case InvitationType.booking:
        return 'Existing booking';
      case InvitationType.proposed:
        return 'Proposed invitation';
      case InvitationType.recruitment:
        return 'From recruitment';
    }
  }

  String _formatTime(Invitation invite) {
    if (invite.startTime == null) return 'Time to be proposed';
    final start = invite.startTime!;
    final end = invite.endTime;
    final timeString =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    if (end == null) {
      return '$timeString - ${_formatDate(start)}';
    }
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
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
        title = isOutgoing
            ? 'Accepted'
            : 'You have accepted this invitation';
        subtitle = 'Schedule locked—reach out to confirm details.';
        break;
      case 'rejected':
        fg = Colors.red.shade600;
        bg = Colors.red.withOpacity(0.1);
        icon = Icons.cancel_rounded;
        title = isOutgoing ? 'Declined' : 'You declined this invitation';
        subtitle = 'You can send another invite or choose a different slot.';
        break;
      case 'cancelled':
        fg = cs.onSurfaceVariant;
        bg = cs.surfaceVariant.withOpacity(0.3);
        icon = Icons.block_rounded;
        title = isOutgoing
            ? 'You cancelled this invitation'
            : 'The invitation was cancelled';
        subtitle = 'If needed, send a new invite with updated details.';
        break;
      default:
        fg = cs.primary;
        bg = cs.primary.withOpacity(0.08);
        icon = Icons.hourglass_top_rounded;
        title = isOutgoing
            ? 'Sent • Awaiting response'
            : 'Waiting for your response';
        subtitle = isOutgoing
            ? 'The recipient will review and respond soon.'
            : 'Accept to confirm the schedule or decline if it does not fit.';
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
            child: const Text('Retry'),
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
      (label: 'All', value: null as String?),
      (label: 'Singles', value: 'singles'),
      (label: 'Doubles', value: 'doubles'),
      (label: 'Mixed doubles', value: 'mixed'),
    ];

    const intensityOptions = [
      (label: 'Casual', value: 'casual'),
      (label: 'Semi-competitive', value: 'semi_competitive'),
      (label: 'Competitive', value: 'competitive'),
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(Icons.tune_rounded, color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick filters',
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onAdvancedTap,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Advanced filters'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primary.withOpacity(0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Match type',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final option in matchTypeOptions)
                _FilterPill(
                  label: option.label,
                  icon: option.value == null
                      ? Icons.all_inclusive_rounded
                      : option.value == 'singles'
                          ? Icons.person_outline_rounded
                          : option.value == 'doubles'
                              ? Icons.groups_2_outlined
                              : Icons.favorite_outline_rounded,
                  selected: manager.selectedMatchType == option.value,
                  onTap: () => manager.setMatchType(
                    manager.selectedMatchType == option.value
                        ? null
                        : option.value,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Intensity',
            style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              for (final option in intensityOptions)
                _FilterPill(
                  label: option.label,
                  icon: option.value == 'casual'
                      ? Icons.sentiment_satisfied_alt_rounded
                      : option.value == 'semi_competitive'
                          ? Icons.bolt_rounded
                          : Icons.emoji_events_outlined,
                  selected: manager.selectedIntensity == option.value,
                  onTap: () => manager.setIntensity(
                    manager.selectedIntensity == option.value
                        ? null
                        : option.value,
                  ),
                  accentColor: cs.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final color = accentColor ?? cs.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? color.withOpacity(0.14)
                : cs.surfaceVariant.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : cs.outlineVariant,
              width: 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_rounded, size: 18, color: color),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
                Icon(icon, size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: tt.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? color : cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonDetail {
  const _ReasonDetail({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
}
