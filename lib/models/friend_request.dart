import 'package:meta/meta.dart';
import 'package:pocketbase/pocketbase.dart';

import 'user_summary.dart';

enum FriendRequestStatus { pending, accepted, rejected, cancelled }

@immutable
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fromUser,
    this.toUser,
  });

  final String id;
  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserSummary? fromUser;
  final UserSummary? toUser;

  bool get isPending => status == FriendRequestStatus.pending;

  bool isIncoming(String currentUserId) => currentUserId == toUserId;

  factory FriendRequest.fromRecord(
    RecordModel record,
    PocketBase pocketBase,
  ) {
    final fromUserId = record.getStringValue('from_user');
    final toUserId = record.getStringValue('to_user');
    final statusValue = record.getStringValue('status');
    final createdAt = DateTime.tryParse(record.getStringValue('created')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = DateTime.tryParse(record.getStringValue('updated')) ??
        createdAt;

    final fromUserRecord = record.expand['from_user'] as RecordModel?;
    final toUserRecord = record.expand['to_user'] as RecordModel?;

    return FriendRequest(
      id: record.id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      status: FriendRequestStatus.values.firstWhere(
        (element) => element.name == statusValue,
        orElse: () => FriendRequestStatus.pending,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      fromUser: fromUserRecord == null
          ? null
          : UserSummary.fromRecord(fromUserRecord, pocketBase),
      toUser: toUserRecord == null
          ? null
          : UserSummary.fromRecord(toUserRecord, pocketBase),
    );
  }
}
