import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_request.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendManager>().refreshRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final manager = context.watch<FriendManager>();

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
            _buildSearchField(cs),
            const SizedBox(height: 24),
            _buildIncomingRequests(context, manager),
            const SizedBox(height: 24),
            _buildOutgoingRequests(context, manager),
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

  Widget _buildSearchField(ColorScheme cs) {
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
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          hintText: 'Nhập tên, số điện thoại hoặc mã thành viên',
        ),
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

  Widget _buildIncomingRequests(BuildContext context, FriendManager manager) {
    final theme = Theme.of(context);
    final requests = manager.incomingRequests;
    if (manager.isLoadingRequests && requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (requests.isEmpty) {
      return Text(
        'Không có lời mời kết bạn nào.',
        style: theme.textTheme.bodyMedium,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lời mời kết bạn',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...requests.map((request) => _buildRequestTile(
              context,
              manager,
              request,
              isIncoming: true,
            )),
      ],
    );
  }

  Widget _buildOutgoingRequests(BuildContext context, FriendManager manager) {
    final theme = Theme.of(context);
    final requests = manager.outgoingRequests;
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đã gửi',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...requests.map((request) => _buildRequestTile(
              context,
              manager,
              request,
              isIncoming: false,
            )),
      ],
    );
  }

  Widget _buildRequestTile(
    BuildContext context,
    FriendManager manager,
    FriendRequest request,
    {required bool isIncoming},
  ) {
    final userSummary =
        isIncoming ? request.fromUser : request.toUser;
    final contact = manager.contactFromSummary(userSummary);
    if (contact == null) {
      return const SizedBox.shrink();
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ContactListTile.friend(
              contact: contact,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (isIncoming) ...[
                  Expanded(
                    child: FilledButton(
                      onPressed: () => manager.acceptRequest(request.id),
                      child: const Text('Đồng ý'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => manager.rejectRequest(request.id),
                      child: const Text('Từ chối'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => manager.cancelRequest(request.id),
                      child: const Text('Huỷ yêu cầu'),
                    ),
                  ),
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}
