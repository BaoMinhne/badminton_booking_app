import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:pocketbase/pocketbase.dart';

@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isMe,
    this.isRead = false,
    this.readAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final bool isRead;
  final DateTime? readAt;

  String get timeLabel => DateFormat.Hm().format(createdAt.toLocal());

  factory ChatMessage.fromRecord(
    RecordModel record,
    String currentUserId,
  ) {
    final createdAt = DateTime.tryParse(record.getStringValue('created')) ??
        DateTime.now();
    final readAt = DateTime.tryParse(record.getStringValue('read_at'));

    return ChatMessage(
      id: record.id,
      roomId: record.getStringValue('chat'),
      senderId: record.getStringValue('sender'),
      content: record.getStringValue('content'),
      createdAt: createdAt,
      isMe: record.getStringValue('sender') == currentUserId,
      isRead: record.getBoolValue('is_read'),
      readAt: readAt,
    );
  }
}
