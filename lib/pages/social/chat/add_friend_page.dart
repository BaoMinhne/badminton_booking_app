import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_relation.dart';
import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:badminton_booking_app/pages/user/user_public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddFriendPage extends StatelessWidget {
  const AddFriendPage({super.key});

  static const List<ChatContact> _suggestedFriends = [
    ChatContact(
      id: 'suggest-1',
      name: 'Linh Trần',
      avatarText: 'LT',
      statusMessage: 'Bạn chung: Bảo Minh, Ngọc Anh',
      isOnline: true,
    ),
    ChatContact(
      id: 'suggest-2',
      name: 'Phúc Nguyễn',
      avatarText: 'PN',
      statusMessage: 'Tham gia các nhóm giao lưu Quận 7',
    ),
    ChatContact(
      id: 'suggest-3',
      name: 'Thuỷ Tiên',
      avatarText: 'TT',
      statusMessage: 'Đánh đơn nữ trình trung bình khá',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final friendManager = context.watch<FriendManager>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text('Thêm bạn bè'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(
              'Tìm kiếm bạn bè',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSearchField(cs, friendManager),
            const SizedBox(height: 16),
            if (friendManager.currentQuery.trim().isNotEmpty)
              _buildSearchResults(context, friendManager, theme),
            const SizedBox(height: 24),
            Text(
              'Gợi ý kết bạn',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ..._suggestedFriends.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ContactListTile.suggestion(
                  contact: contact,
                  onTap: () {},
                  onChatPressed: () {},
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildCommunityCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs, FriendManager friendManager) {
    return SizedBox(
      height: 60,
      child: TextField(
        onChanged: friendManager.searchDebounced,
        cursorColor: cs.primary,
        style: TextStyle(
          fontSize: 18,
          color: cs.onSurface,
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 24,
            color: Colors.grey.shade600,
          ),
          hintText: 'Tìm kiếm bạn bè',
          hintStyle: TextStyle(
            fontSize: 18,
            color: Colors.grey.shade600,
          ),
          filled: true,
          fillColor: cs.secondary.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: cs.outline,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: BorderSide(
              color: cs.primary,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    FriendManager friendManager,
    ThemeData theme,
  ) {
    if (friendManager.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (friendManager.error != null) {
      return Text(friendManager.error!, style: theme.textTheme.bodyMedium);
    }

    if (friendManager.searchResults.isEmpty) {
      return Text(
        'Không tìm thấy người dùng phù hợp.',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kết quả tìm kiếm',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...friendManager.searchResults.map(
          (result) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContactListTile.suggestion(
              contact: ChatContact(
                id: result.user.id,
                name: result.displayName,
                avatarText: result.initials,
                statusMessage: result.subtitle.isEmpty ? null : result.subtitle,
              ),
              trailing: _buildTrailingActions(
                context,
                friendManager,
                result,
              ),
              onTap: () => _openProfile(context, result),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleFriendAction(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    final relation = friendManager.relationFor(result.user.id);
    final isPending = relation.type == FriendRelationType.outgoingRequest;

    if (isPending) {
      final confirmed = await _showConfirmDialog(
        context,
        title: 'Huỷ lời mời kết bạn?',
        message:
            'Bạn có chắc muốn huỷ lời mời kết bạn đã gửi cho ${result.displayName}?',
      );
      if (!confirmed) return;
    }

    try {
      if (isPending) {
        await friendManager.cancelPendingRequest(result.user.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã huỷ lời mời kết bạn.')),
          );
        }
      } else if (relation.type == FriendRelationType.none) {
        await friendManager.sendFriendRequest(result);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã gửi lời mời kết bạn.')),
          );
        }
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _openProfile(BuildContext context, FriendSearchResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserPublicProfilePage(result: result),
      ),
    );
  }

  Widget _buildTrailingActions(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) {
    final relation = friendManager.relationFor(result.user.id);
    final isProcessing = friendManager.isActionInProgress(result.user.id);
    final cs = Theme.of(context).colorScheme;

    final actions = <Widget>[
      FilledButton.tonalIcon(
        onPressed: () => _openProfile(context, result),
        icon: const Icon(Icons.person_search_rounded),
        label: const Text('Xem hồ sơ'),
      ),
    ];

    switch (relation.type) {
      case FriendRelationType.friends:
        actions.add(
          FilledButton.tonal(
            onPressed: null,
            child: const Text('Bạn bè'),
          ),
        );
        break;
      case FriendRelationType.incomingRequest:
        actions.addAll([
          FilledButton(
            onPressed: isProcessing
                ? null
                : () => _handleAcceptRequest(context, friendManager, result),
            child: const Text('Đồng ý'),
          ),
          FilledButton.tonal(
            onPressed: isProcessing
                ? null
                : () => _handleRejectRequest(context, friendManager, result),
            style: FilledButton.styleFrom(
              backgroundColor: cs.errorContainer,
              foregroundColor: cs.onErrorContainer,
            ),
            child: const Text('Xóa'),
          ),
        ]);
        break;
      case FriendRelationType.outgoingRequest:
      case FriendRelationType.none:
        final label = _primaryActionLabel(friendManager, result) ?? 'Kết bạn';
        actions.add(
          isProcessing
              ? const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                )
              : FilledButton(
                  style: relation.type == FriendRelationType.outgoingRequest
                      ? FilledButton.styleFrom(
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                        )
                      : null,
                  onPressed: () =>
                      _handleFriendAction(context, friendManager, result),
                  child: Text(label),
                ),
        );
        break;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
  }

  String? _primaryActionLabel(
    FriendManager friendManager,
    FriendSearchResult result,
  ) {
    final relation = friendManager.relationFor(result.user.id);

    switch (relation.type) {
      case FriendRelationType.none:
        return 'Kết bạn';
      case FriendRelationType.outgoingRequest:
        return 'Huỷ lời mời';
      case FriendRelationType.incomingRequest:
      case FriendRelationType.friends:
        return null;
    }
  }

  Future<void> _handleAcceptRequest(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    try {
      await friendManager.acceptIncomingRequest(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bạn và ${result.displayName} đã là bạn bè.'),
          ),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Future<void> _handleRejectRequest(
    BuildContext context,
    FriendManager friendManager,
    FriendSearchResult result,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Xóa lời mời kết bạn?',
      message:
          'Bạn có chắc muốn xóa lời mời kết bạn từ ${result.displayName}?',
    );

    if (!confirmed) return;

    try {
      await friendManager.rejectIncomingRequest(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa lời mời kết bạn.')),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Widget _buildCommunityCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kết nối nhiều hơn',
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tham gia các nhóm cầu lông địa phương để tìm thêm nhiều người bạn cùng sở thích.',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onPrimary),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: cs.onPrimary.withOpacity(0.15),
              foregroundColor: cs.onPrimary,
            ),
            onPressed: () {},
            child: const Text('Khám phá nhóm mới'),
          ),
        ],
      ),
    );
  }
}
