import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
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
              _buildSearchResults(friendManager, theme),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        onChanged: friendManager.search,
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          hintText: 'Nhập tên, số điện thoại hoặc mã thành viên',
        ),
      ),
    );
  }

  Widget _buildSearchResults(
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
                statusMessage: result.subtitle.isEmpty
                    ? null
                    : result.subtitle,
              ),
              onTap: () {},
              onChatPressed: () {},
            ),
          ),
        ),
      ],
    );
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
