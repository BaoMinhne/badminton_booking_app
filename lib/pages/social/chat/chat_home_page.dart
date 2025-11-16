import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/add_friend_page.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/friend_manager.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_page.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_section_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatHomePage extends StatefulWidget {
  const ChatHomePage({super.key});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FriendManager>().loadInitial();
      context.read<ChatManager>().refreshRooms();
    });
  }

  TabBar _buildTabs(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return TabBar(
      tabs: const [
        Tab(text: 'Đoạn chat'),
        Tab(text: 'Bạn bè'),
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
    final friendManager = context.watch<FriendManager>();
    final chatManager = context.watch<ChatManager>();
    final activeChats = chatManager.activeChats;
    final friends = friendManager.friendContacts;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: ChatHeader(
          title: 'Danh sách trò chuyện',
          onAddFriend: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddFriendPage()),
            );
          }, // hoặc null nếu chưa dùng
          bottom: _buildTabs(context), // TabBar hiển thị ngay dưới title
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddFriendPage()),
            );
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Thêm bạn bè'),
        ),
        body: TabBarView(
          children: [
            _buildActiveChatList(context, chatManager, activeChats),
            _buildFriendList(context, cs, friendManager, friends),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveChatList(
    BuildContext context,
    ChatManager manager,
    List<ChatContact> contacts,
  ) {
    return RefreshIndicator(
      onRefresh: manager.refreshRooms,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: contacts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ChatSectionHeader(
                    title: 'Đang trò chuyện',
                    subtitle: 'Danh sách những người bạn đang nhắn tin gần đây',
                  ),
                  if (manager.isLoadingRooms && contacts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (contacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Chưa có cuộc trò chuyện nào. Hãy nhắn tin với bạn bè để bắt đầu!',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            );
          }

          final contact = contacts[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContactListTile.chat(
              contact: contact,
              onTap: () => _openChat(context, contact),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFriendList(
    BuildContext context,
    ColorScheme cs,
    FriendManager manager,
    List<ChatContact> contacts,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await manager.refreshFriends();
      },
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        itemCount: contacts.length + 1,
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
                            manager.isLoadingFriends && contacts.isEmpty
                                ? 'Đang tải danh sách bạn bè...'
                                : 'Tìm kiếm bạn bè nhanh chóng',
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

          final contact = contacts[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ContactListTile.friend(
              contact: contact,
              onTap: () => _openChat(context, contact),
              onChatPressed: () => _openChat(context, contact),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openChat(BuildContext context, ChatContact contact) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final chatManager = context.read<ChatManager>();
      final roomId = contact.roomId ?? (await chatManager.ensureRoom(contact.id)).id;
      final updatedContact = contact.roomId == null
          ? contact.copyWith(roomId: roomId)
          : contact;
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            roomId: roomId,
            contact: updatedContact,
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }
}
