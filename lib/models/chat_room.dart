import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:pocketbase/pocketbase.dart';

import '../utils/time_ago.dart';

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.avatarText,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSenderId,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final String avatarText;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderId;

  factory ChatRoom.fromRecord(
    RecordModel record, {
    required String currentUserId,
  }) {
    final userAId = record.getStringValue('user_a');
    final userBId = record.getStringValue('user_b');
    final otherUserId = userAId == currentUserId ? userBId : userAId;

    final expandedA = record.expand['user_a'] as List<dynamic>?;
    final expandedB = record.expand['user_b'] as List<dynamic>?;

    final otherUser =
        (expandedA != null && expandedA.isNotEmpty && userBId == currentUserId)
            ? expandedA.first
            : expandedB?.first;

    String otherUserName = 'Người dùng';
    String avatarText = '??';

    if (otherUser is RecordModel) {
      otherUserName = _resolveDisplayName(otherUser);
      avatarText = _initials(otherUserName);
    }

    final lastMessageAt = _parseDateTime(record.data['last_message_at']);

    return ChatRoom(
      id: record.id,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      avatarText: avatarText,
      lastMessage: record.getStringValue('last_message'),
      lastMessageAt: lastMessageAt?.toLocal(),
      lastSenderId: record.getStringValue('last_sender'),
    );
  }

  ChatContact toContact(String currentUserId) {
    final isMyMessage = lastSenderId == currentUserId;
    final prefix =
        isMyMessage && (lastMessage?.isNotEmpty ?? false) ? 'Bạn: ' : '';

    return ChatContact(
      id: id,
      chatId: id,
      userId: otherUserId,
      name: otherUserName,
      avatarText: avatarText,
      lastMessage: lastMessage != null ? '$prefix$lastMessage' : null,
      lastMessageTimeLabel:
          lastMessageAt != null ? formatRelativeTime(lastMessageAt!) : null,
    );
  }
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

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '??';
  if (parts.length == 1) {
    return parts.first
        .substring(0, parts.first.length >= 2 ? 2 : 1)
        .toUpperCase();
  }
  final first = parts.first.isNotEmpty ? parts.first[0] : '';
  final last = parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
