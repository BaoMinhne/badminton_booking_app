import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;
  final bool showSeen;

  const ChatBubble({
    super.key,
    required this.message,
    this.showAvatar = false,
    this.showSeen = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMe = message.isMe;
    final initials = _initials(message.author);

    final bubbleColor = isMe ? cs.primary : Colors.grey.shade300;
    final textColor = isMe ? cs.onPrimary : cs.onSurface;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * .78,
        ),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: showAvatar ? 1 : 0,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primary,
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(22),
                    topRight: const Radius.circular(22),
                    bottomLeft:
                        Radius.circular(isMe ? 22 : (showAvatar ? 8 : 22)),
                    bottomRight:
                        Radius.circular(isMe ? (showAvatar ? 8 : 22) : 22),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.content,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: textColor.withOpacity(.7),
                                  fontSize: 11,
                                ),
                          ),
                          if (isMe && showSeen) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 16,
                              color: cs.onPrimary.withOpacity(.85),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isMe) const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final word = parts.first;
    if (word.isEmpty) return '??';
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }

  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last.isNotEmpty ? parts.last[0] : '';
  final result = (first + last).trim();
  return result.isEmpty ? '??' : result.toUpperCase();
}
