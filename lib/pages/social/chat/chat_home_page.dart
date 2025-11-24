import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_request.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_page.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_section_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'add_friend_page.dart';
import 'friend_manager.dart';
import 'friend_request_manager.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  late final FriendRequestManager _friendRequestManager;

  @override
  void initState() {
    super.initState();
    _friendRequestManager = FriendRequestManager()..loadIncomingRequests();
  }

  @override
  void dispose() {
    _friendRequestManager.dispose();
    super.dispose();
  }

  static const List<ChatContact> _activeChats = [
    ChatContact(
      id: 'chat-1',
      name: 'Nhỏ quậy lắm chiều',
      avatarText: 'NC',
      lastMessage: 'Bạn: hehe hehe <3 tối qua đánh cầu nhe bạn',
      lastMessageTimeLabel: '1 phút',
      unreadCount: 2,
      isOnline: true,
    ),
    ChatContact(
      id: 'chat-2',
      name: 'Bến Đò Không Người Lái Đó',
      avatarText: 'BD',
      lastMessage: 'Bạn: tìm được con trai thất lạc nên khóc...',
      lastMessageTimeLabel: '15 phút',
    ),
    ChatContact(
      id: 'chat-3',
      name: 'Cf chủ nhật',
      avatarText: 'CF',
      lastMessage: '😊 😌',
      lastMessageTimeLabel: '30 phút',
      isOnline: true,
    ),
    ChatContact(
      id: 'chat-4',
      name: 'Trần Gia Thạnh',
      avatarText: 'TT',
      lastMessage: 'Đã gửi cho bạn một ảnh',
      lastMessageTimeLabel: '1 giờ',
    ),
    ChatContact(
      id: 'chat-5',
      name: 'Khu Tự Trị Dữ Đồ',
      avatarText: 'KD',
      lastMessage: 'Bé thỏ mới uống: Mà deokdame đáng cháy vcl',
      lastMessageTimeLabel: '2 giờ',
      unreadCount: 1,
    ),
    ChatContact(
      id: 'chat-6',
      name: 'Hua Tan Datt',
      avatarText: 'HD',
      lastMessage: 'Game bào điên',
      lastMessageTimeLabel: '5 giờ',
    ),
  ];

  static const List<ChatContact> _friends = [
    ChatContact(
      id: 'friend-1',
      name: 'Nhỏ quậy lắm chiều',
      avatarText: 'NC',
      statusMessage: 'Bạn: chờ nứng l đi mà nứng !',
      isOnline: true,
    ),
    ChatContact(
      id: 'friend-2',
      name: 'Bến Đò Không Người Lái Đó',
      avatarText: 'BD',
      statusMessage: 'Bạn: tìm được con trai thất lạc nên khóc...',
    ),
    ChatContact(
      id: 'friend-3',
      name: 'Cf chủ nhật',
      avatarText: 'CF',
      statusMessage: 'Bạn bè để cà phê thôi nha 😌',
      isOnline: true,
    ),
    ChatContact(
      id: 'friend-4',
      name: 'Trần Gia Thạnh',
      avatarText: 'TT',
      statusMessage: 'Luôn sẵn sàng cho một set đôi',
    ),
    ChatContact(
      id: 'friend-5',
      name: 'Khu Tự Trị Dữ Đồ',
      avatarText: 'KD',
      statusMessage: 'Tối nay đánh tăng 2 nhen',
    ),
    ChatContact(
      id: 'friend-6',
      name: 'Hua Tan Datt',
      avatarText: 'HD',
      statusMessage: 'Game báo done',
    ),
  ];

  TabBar _buildTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TabBar(
      tabs: const [
        Tab(text: 'Đoạn chat'),
        Tab(text: 'Bạn bè'),
        Tab(text: 'Lời mời'),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ChangeNotifierProvider.value(
      value: _friendRequestManager,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          appBar: ChatHeader(
            title: 'Danh sách trò chuyện',
            onAddFriend: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => FriendManager(),
                    child: const AddFriendPage(),
                  ),
                ),
              );
            }, // hoặc null nếu chưa dùng
            bottom: _buildTabs(context), // TabBar hiển thị ngay dưới title
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => FriendManager(),
                    child: const AddFriendPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Thêm bạn bè'),
          ),
          body: TabBarView(
            children: [
              _buildActiveChatList(context),
              _buildFriendList(context, cs),
              _buildRequestList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveChatList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _activeChats.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: ChatSectionHeader(
              title: 'Đang trò chuyện',
              subtitle: 'Danh sách những người bạn đang nhắn tin gần đây',
            ),
          );
        }

        final contact = _activeChats[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ContactListTile.chat(
            contact: contact,
            onTap: () => _openChat(context, contact),
          ),
        );
      },
    );
  }

  Widget _buildFriendList(BuildContext context, ColorScheme cs) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: _friends.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ChatSectionHeader(
                  title: 'Tất cả bạn bè',
                  subtitle: 'Bấm vào biểu tượng chat để mở cuộc trò chuyện',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: cs.primaryContainer.withOpacity(0.3),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tìm kiếm bạn bè nhanh chóng',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final contact = _friends[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ContactListTile.friend(
            contact: contact,
            onTap: () => _openChat(context, contact),
            onChatPressed: () => _openChat(context, contact),
          ),
        );
      },
    );
  }

  Widget _buildRequestList(BuildContext context) {
    final theme = Theme.of(context);
    final manager = context.watch<FriendRequestManager>();

    if (manager.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (manager.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(manager.error!, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: manager.loadIncomingRequests,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (manager.incoming.isEmpty) {
      return RefreshIndicator(
        onRefresh: manager.loadIncomingRequests,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.people_outline, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Chưa có lời mời kết bạn',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Khi có người gửi lời mời, bạn sẽ thấy tại đây.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: manager.loadIncomingRequests,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: manager.incoming.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ChatSectionHeader(
                title: 'Lời mời kết bạn',
                subtitle: 'Chấp nhận hoặc từ chối lời mời từ người khác',
              ),
            );
          }

          final request = manager.incoming[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FriendRequestTile(
              request: request,
              isProcessing: manager.isProcessing(request.id),
              onAccept: () => _acceptRequest(context, request),
              onReject: () => _rejectRequest(context, request),
            ),
          );
        },
      ),
    );
  }

  Future<void> _acceptRequest(
    BuildContext context,
    FriendRequestItem request,
  ) async {
    final manager = context.read<FriendRequestManager>();
    try {
      await manager.accept(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bạn và ${request.from.displayName} đã trở thành bạn bè.')),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$err')),
        );
      }
    }
  }

  Future<void> _rejectRequest(
    BuildContext context,
    FriendRequestItem request,
  ) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Từ chối lời mời?',
      message: 'Bạn có chắc muốn từ chối lời mời từ ${request.from.displayName}?',
    );

    if (!confirmed) return;

    final manager = context.read<FriendRequestManager>();
    try {
      await manager.reject(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã từ chối lời mời của ${request.from.displayName}.')),
        );
      }
    } catch (err) {
      if (mounted) {
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

  void _openChat(BuildContext context, ChatContact contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          contactName: contact.name,
          isContactOnline: contact.isOnline,
          avatarText: contact.avatarText,
        ),
      ),
    );
  }
}

class _FriendRequestTile extends StatelessWidget {
  const _FriendRequestTile({
    required this.request,
    required this.onAccept,
    required this.onReject,
    required this.isProcessing,
  });

  final FriendRequestItem request;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subtitleParts = <String>[];

    if (request.from.subtitle.isNotEmpty) {
      subtitleParts.add(request.from.subtitle);
    }

    subtitleParts.add('Gửi ${request.timeLabel}');

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primaryContainer,
            foregroundImage: request.from.details?.avatarUrl != null
                ? NetworkImage(request.from.details!.avatarUrl!)
                : null,
            child: Text(
              request.from.initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.from.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleParts.join(' • '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: isProcessing ? null : onAccept,
                        child: const Text('Xác nhận'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing ? null : onReject,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.outlineVariant),
                        ),
                        child: const Text('Xóa'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
