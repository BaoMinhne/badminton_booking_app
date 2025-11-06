import 'package:badminton_booking_app/components/chat_input.dart';
import 'package:badminton_booking_app/models/chat_message.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_app_bar.dart';
import 'package:badminton_booking_app/pages/social/chat/widgets/chat_message_list.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.contactName = 'Nguyễn Minh',
    this.avatarText = 'NM',
    this.isContactOnline = true,
  });

  final String contactName;
  final String avatarText;
  final bool isContactOnline;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // sau này bạn sẽ thay bằng data từ backend
  final List<ChatMessage> _messages = [
    const ChatMessage(
      id: '1',
      author: 'Nguyễn Minh',
      content: 'Chào bạn, mình thấy bài tuyển thành viên của bạn.',
      time: '17:45',
      isMe: false,
    ),
    const ChatMessage(
      id: '2',
      author: 'Bạn',
      content: 'Hi Minh, bạn đang đánh trình nào vậy?',
      time: '17:46',
      isMe: true,
    ),
    const ChatMessage(
      id: '3',
      author: 'Nguyễn Minh',
      content: 'Mình đang ở mức trung bình khá, hay đánh đôi.',
      time: '17:46',
      isMe: false,
    ),
    const ChatMessage(
      id: '4',
      author: 'Bạn',
      content:
          'Okie, sân mình đặt ở Quận 7 lúc 20:00. Bạn đến trước 10 phút nhé!',
      time: '17:47',
      isMe: true,
    ),
    const ChatMessage(
      id: '5',
      author: 'Nguyễn Minh',
      content: 'Quá ổn luôn, tối gặp nhé!',
      time: '17:47',
      isMe: false,
    ),
  ];

  void _handleSend(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          author: 'Bạn',
          content: text.trim(),
          time: TimeOfDay.now().format(context),
          isMe: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: ChatAppBar(
        name: widget.contactName,
        isOnline: widget.isContactOnline,
        avatarText: widget.avatarText,
        onCall: () {},
        onVideoCall: () {},
      ),
      body: Column(
        children: [
          Expanded(
            child: ChatMessageList(
              messages: _messages,
            ),
          ),
          ChatInput(
            onSend: _handleSend,
            backgroundColor: cs.background,
          ),
        ],
      ),
    );
  }
}
