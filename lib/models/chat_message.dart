class ChatMessage {
  final String id;
  final String author;
  final String content;
  final String time;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.author,
    required this.content,
    required this.time,
    required this.isMe,
  });
}
