import 'package:meta/meta.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/chat_contact.dart';
import 'user_summary.dart';

@immutable
class Friendship {
  const Friendship({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.createdAt,
    required this.updatedAt,
    this.userA,
    this.userB,
  });

  final String id;
  final String userAId;
  final String userBId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSummary? userA;
  final UserSummary? userB;

  factory Friendship.fromRecord(
    RecordModel record,
    PocketBase pocketBase,
  ) {
    final createdAt = DateTime.tryParse(record.getStringValue('created')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = DateTime.tryParse(record.getStringValue('updated')) ??
        createdAt;

    final userAList = record.expand['user_a'] as List<RecordModel>?;
    final userBList = record.expand['user_b'] as List<RecordModel>?;

    final userARecord =
        (userAList != null && userAList.isNotEmpty) ? userAList.first : null;
    final userBRecord =
        (userBList != null && userBList.isNotEmpty) ? userBList.first : null;

    return Friendship(
      id: record.id,
      userAId: record.getStringValue('user_a'),
      userBId: record.getStringValue('user_b'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      userA: userARecord == null
          ? null
          : UserSummary.fromRecord(userARecord, pocketBase),
      userB: userBRecord == null
          ? null
          : UserSummary.fromRecord(userBRecord, pocketBase),
    );
  }

  UserSummary? friendOf(String currentUserId) {
    if (userAId == currentUserId) {
      return userB;
    }
    if (userBId == currentUserId) {
      return userA;
    }
    return null;
  }

  ChatContact? toChatContact(String? currentUserId) {
    if (currentUserId == null) return null;
    final friend = friendOf(currentUserId);
    if (friend == null) return null;
    return ChatContact(
      id: friend.id,
      name: friend.displayName,
      avatarText: friend.initials,
      avatarUrl: friend.avatarUrl,
      statusMessage: 'Kết bạn từ ${createdAt.year}',
    );
  }
}
