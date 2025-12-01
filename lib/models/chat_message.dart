import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

class ChatMessage {
  final String id;
  final String authorId;
  final String author;
  final String content;
  final String? attachmentUrl;
  final DateTime createdAt;
  final bool isMe;

  const ChatMessage({
    required this.id,
    required this.authorId,
    required this.author,
    required this.content,
    this.attachmentUrl,
    required this.createdAt,
    required this.isMe,
  });

  factory ChatMessage.fromRecord(
    RecordModel record, {
    required PocketBase pb,
    required String currentUserId,
    String? authorName,
  }) {
    final senderId = record.getStringValue('sender');
    final created = _parseDateTime(record.data['created']) ?? DateTime.now();
    String? resolvedName = authorName;
    String? attachmentUrl;

    final expandedSender = record.expand['sender'] as List<dynamic>?;
    if (expandedSender != null && expandedSender.isNotEmpty) {
      final senderRecord = expandedSender.first;
      if (senderRecord is RecordModel) {
        resolvedName = _resolveDisplayName(senderRecord);
      }
    }

    final attachmentName = record.getStringValue('attachments');
    if (attachmentName.isNotEmpty) {
      attachmentUrl = pb.files.getUrl(record, attachmentName).toString();
    }

    return ChatMessage(
      id: record.id,
      authorId: senderId,
      author: resolvedName ?? 'Người dùng',
      content: record.getStringValue('content'),
      attachmentUrl: attachmentUrl,
      createdAt: created.toLocal(),
      isMe: senderId == currentUserId,
    );
  }

  bool get hasAttachment => attachmentUrl != null;
  bool get hasText => content.isNotEmpty;

  String get timeLabel => DateFormat('HH:mm').format(createdAt);
}

DateTime? _parseDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _resolveDisplayName(RecordModel userRecord) {
  final username = userRecord.getStringValue('username');
  if (username.isNotEmpty) return username;

  final email = userRecord.getStringValue('email');
  if (email.isNotEmpty) return email;

  final phone = userRecord.getStringValue('phone');
  if (phone.isNotEmpty) return phone;

  return 'Người dùng';
}
