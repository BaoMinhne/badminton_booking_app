import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';

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
            _buildSearchField(context, cs),
            const SizedBox(height: 24),
            Consumer<FriendManager>(
              builder: (context, manager, _) {
                if (manager.hasQuery) {
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
                      _buildSearchResultList(context, manager),
                    ],
                  );
                }

                return _buildSuggestedFriendsSection(theme);
              },
            ),
            const SizedBox(height: 24),
            _buildCommunityCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ColorScheme cs) {
    final isSearching = context.watch<FriendManager>().isSearching;
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
        onChanged: (value) => context.read<FriendManager>().searchFriends(value),
        decoration: InputDecoration(
          icon: const Icon(Icons.search_rounded),
          border: InputBorder.none,
          hintText: 'Nhập tên, số điện thoại hoặc mã thành viên',
          suffixIcon: isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchResultList(BuildContext context, FriendManager manager) {
    if (manager.isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (manager.searchError != null) {
      return _buildInfoMessage(
        context,
        icon: Icons.error_outline,
        message: manager.searchError!,
      );
    }

    if (manager.searchResults.isEmpty) {
      return _buildInfoMessage(
        context,
        icon: Icons.search_off_outlined,
        message: 'Không tìm thấy người dùng nào phù hợp từ từ khóa hiện tại.',
      );
    }

    return Column(
      children: manager.searchResults
          .map(
            (candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactListTile.suggestion(
                contact: candidate.toChatContact(),
                onTap: () {},
                onChatPressed: () {},
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildSuggestedFriendsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildInfoMessage(
    BuildContext context, {
    required IconData icon,
    required String message,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
