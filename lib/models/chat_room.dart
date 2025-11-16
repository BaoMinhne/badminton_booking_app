import 'package:intl/intl.dart';
import 'package:meta/meta.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/chat_contact.dart';
import 'user_summary.dart';

@immutable
class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.userAId,
    required this.userBId,
    this.lastMessage,
    this.lastMessageAt,
    this.lastSender,
    this.userA,
    this.userB,
    this.unreadCount = 0,
  });

  final String id;
  final String userAId;
  final String userBId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final UserSummary? lastSender;
  final UserSummary? userA;
  final UserSummary? userB;
  final int unreadCount;

  ChatRoom copyWith({int? unreadCount}) {
    return ChatRoom(
      id: id,
      userAId: userAId,
      userBId: userBId,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      lastSender: lastSender,
      userA: userA,
      userB: userB,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatRoom.fromRecord(
    RecordModel record,
    PocketBase pocketBase,
  ) {
    final userARecord = record.expand['user_a'] as RecordModel?;
    final userBRecord = record.expand['user_b'] as RecordModel?;
    final lastSenderRecord = record.expand['last_sender'] as RecordModel?;

    return ChatRoom(
      id: record.id,
      userAId: record.getStringValue('user_a'),
      userBId: record.getStringValue('user_b'),
      lastMessage: record.getStringValue('last_message').isEmpty
          ? null
          : record.getStringValue('last_message'),
      lastMessageAt: _parseDate(record.getStringValue('last_message_at')),
      lastSender: lastSenderRecord == null
          ? null
          : UserSummary.fromRecord(lastSenderRecord, pocketBase),
      userA: userARecord == null
          ? null
          : UserSummary.fromRecord(userARecord, pocketBase),
      userB: userBRecord == null
          ? null
          : UserSummary.fromRecord(userBRecord, pocketBase),
    );
  }

  ChatContact? toChatContact(String? currentUserId) {
    if (currentUserId == null) return null;
    final friend = currentUserId == userAId ? userB : userA;
    if (friend == null) return null;
    final timeLabel = lastMessageAt == null
        ? null
        : DateFormat.Hm().format(lastMessageAt!.toLocal());
    return ChatContact(
      id: friend.id,
      roomId: id,
      name: friend.displayName,
      avatarText: friend.initials,
      avatarUrl: friend.avatarUrl,
      lastMessage: lastMessage,
      lastMessageTimeLabel: timeLabel,
      unreadCount: unreadCount,
    );
  }

  static DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
