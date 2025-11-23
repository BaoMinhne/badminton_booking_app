import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/pages/social/chat/chat_page.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_section_header.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/contact_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'add_friend_page.dart';
import 'friend_manager.dart';

class ChatHomePage extends StatelessWidget {
  const ChatHomePage({super.key});

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
    final friendManager = context.watch<FriendManager>();
    final cs = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: ChatHeader(
          title: 'Danh sách trò chuyện',
          onAddFriend: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: friendManager,
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
                builder: (_) => ChangeNotifierProvider.value(
                  value: friendManager,
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
            _buildFriendList(context, cs, friendManager),
          ],
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

  Widget _buildFriendList(
    BuildContext context,
    ColorScheme cs,
    FriendManager friendManager,
  ) {
    return RefreshIndicator(
      onRefresh: friendManager.loadFriends,
      child: Builder(
        builder: (context) {
          if (friendManager.isLoadingFriends) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendManager.friendError != null) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(friendManager.friendError!),
              ],
            );
          }

          if (friendManager.friends.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                const ChatSectionHeader(
                  title: 'Tất cả bạn bè',
                  subtitle: 'Bấm vào Thêm bạn bè để bắt đầu kết nối',
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
                          'Chưa có bạn bè nào. Hãy gửi lời mời kết bạn ngay! ',
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
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            itemCount: friendManager.friends.length + 1,
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

              final contact = friendManager.friends[index - 1];
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
        },
      ),
    );
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
