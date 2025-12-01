import 'package:badminton_booking_app/components/chat_bubble.dart';
import 'package:badminton_booking_app/models/chat_message.dart';
import 'package:flutter/material.dart';

class ChatMessageList extends StatelessWidget {
  final List<ChatMessage> messages;

  const ChatMessageList({
    super.key,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final prev = index > 0 ? messages[index - 1] : null;
        final isFirstFromAuthor = prev == null || prev.isMe != message.isMe;

        final isLastFromMe = message.isMe &&
            (index == messages.length - 1 || messages[index + 1].isMe == false);

        return ChatBubble(
          message: message,
          showAvatar: !message.isMe && isFirstFromAuthor,
          showSeen: isLastFromMe,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 8),
    );
  }
}
