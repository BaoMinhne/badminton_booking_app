import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  ChatPage({super.key});

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      author: 'Nguyễn Minh',
      content: 'Chào bạn, mình thấy bài tuyển thành viên của bạn.',
      time: '17:45',
      isMe: false,
    ),
    _ChatMessage(
      author: 'Bạn',
      content: 'Hi Minh, bạn đang đánh trình nào vậy?',
      time: '17:46',
      isMe: true,
    ),
    _ChatMessage(
      author: 'Nguyễn Minh',
      content: 'Mình đang ở mức trung bình khá, hay đánh đôi.',
      time: '17:46',
      isMe: false,
    ),
    _ChatMessage(
      author: 'Bạn',
      content: 'Okie, sân mình đặt ở Quận 7 lúc 20:00. Bạn đến trước 10 phút nhé!',
      time: '17:47',
      isMe: true,
    ),
    _ChatMessage(
      author: 'Nguyễn Minh',
      content: 'Quá ổn luôn, tối gặp nhé!',
      time: '17:47',
      isMe: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surfaceVariant.withOpacity(0.4),
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: cs.primary,
              child: const Text('NM'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Nguyễn Minh', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  'Đang hoạt động',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.call_rounded),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.videocam_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isFirstFromAuthor = index == 0 ||
                    _messages[index - 1].isMe != message.isMe;
                return _MessageBubble(
                  message: message,
                  showAvatar: isFirstFromAuthor,
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _messages.length,
            ),
          ),
          const _TypingArea(),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool showAvatar;

  const _MessageBubble({required this.message, required this.showAvatar});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final alignment = message.isMe ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = message.isMe ? cs.primary : cs.surface;
    final textColor = message.isMe ? cs.onPrimary : cs.onSurface;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisAlignment:
              message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.isMe) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: showAvatar ? 1 : 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary,
                  child: const Text('NM', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(24),
                    topRight: const Radius.circular(24),
                    bottomLeft:
                        Radius.circular(message.isMe ? 24 : showAvatar ? 6 : 24),
                    bottomRight:
                        Radius.circular(message.isMe ? (showAvatar ? 6 : 24) : 24),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: message.isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: textColor, height: 1.4),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: textColor.withOpacity(0.7),
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.isMe) ...[
              const SizedBox(width: 8),
              Icon(Icons.done_all,
                  size: 18, color: cs.primary.withOpacity(0.7)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingArea extends StatelessWidget {
  const _TypingArea();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_circle_outline),
            ),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  children: const [
                    Expanded(
                      child: Text(
                        'Nhập tin nhắn...',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.primary,
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String author;
  final String content;
  final String time;
  final bool isMe;

  const _ChatMessage({
    required this.author,
    required this.content,
    required this.time,
    required this.isMe,
  });
}
