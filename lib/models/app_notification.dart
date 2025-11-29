import 'package:pocketbase/pocketbase.dart';

enum NotificationType {
  bookingSuccess('booking_success'),
  bookingCancelled('booking_cancelled'),
  postCommented('post_commented'),
  postLiked('post_liked'),
  recruitmentApplied('recruitment_applied'),
  recruitmentStatusChanged('recruitment_status_changed'),
  friendRequestReceived('friend_request_received'),
  friendRequestAccepted('friend_request_accepted'),
  friendRequestRejected('friend_request_rejected');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromValue(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.bookingSuccess,
    );
  }
}

enum NotificationTargetType {
  booking('booking'),
  post('post'),
  recruitmentPost('recruitment_post'),
  recruitmentApplicant('recruitment_applicant'),
  friendRequest('friend_request'),
  userProfile('user_profile'),
  chat('chat');

  const NotificationTargetType(this.value);
  final String value;

  static NotificationTargetType? fromValue(String? value) {
    if (value == null) return null;
    for (final item in NotificationTargetType.values) {
      if (item.value == value) return item;
    }
    return null;
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.targetType,
    this.payload = const {},
    this.senderId,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String userId;
  final String? senderId;
  final NotificationType type;
  final String title;
  final String body;
  final NotificationTargetType? targetType;
  final Map<String, dynamic> payload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  factory AppNotification.fromRecord(RecordModel record) {
    final payloadData = record.data['payload'];
    Map<String, dynamic> parsedPayload = const {};
    if (payloadData is Map<String, dynamic>) {
      parsedPayload = payloadData;
    }

    DateTime? parsedReadAt;
    final rawReadAt = record.data['read_at'];
    if (rawReadAt is String && rawReadAt.isNotEmpty) {
      parsedReadAt = DateTime.tryParse(rawReadAt)?.toLocal();
    }

    DateTime? parsedCreatedAt;
    final rawCreatedAt = record.data['created'];
    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt)?.toLocal();
    }

    return AppNotification(
      id: record.id,
      userId: record.getStringValue('user'),
      senderId: record.getStringValue('sender').isEmpty
          ? null
          : record.getStringValue('sender'),
      type: NotificationType.fromValue(record.getStringValue('type')),
      targetType: NotificationTargetType.fromValue(
        record.getStringValue('target_type'),
      ),
      title: record.getStringValue('title'),
      body: record.getStringValue('body'),
      payload: parsedPayload,
      isRead: record.getBoolValue('is_read'),
      createdAt: parsedCreatedAt ?? DateTime.now(),
      readAt: parsedReadAt,
    );
  }
}
