import 'package:pocketbase/pocketbase.dart';

import '../utils/time_ago.dart';

class AppNotification {
  final String id;
  final String? senderId;
  final String? senderName;
  final String? title;
  final String? body;
  final String type;
  final String? targetType;
  final Map<String, dynamic>? payload;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    this.senderId,
    this.senderName,
    this.title,
    this.body,
    required this.type,
    this.targetType,
    this.payload,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromRecord(RecordModel record) {
    final created = DateTime.tryParse(record.getStringValue('created')) ??
        DateTime.now();

    final senderId = record.getStringValue('sender');
    String? senderName;
    final senderExpanded = record.expand['sender'] as List<dynamic>?;
    if (senderExpanded != null && senderExpanded.isNotEmpty) {
      final senderRecord = senderExpanded.first;
      if (senderRecord is RecordModel) {
        senderName = _resolveDisplayName(senderRecord);
      }
    }

    return AppNotification(
      id: record.id,
      senderId: senderId.isNotEmpty ? senderId : null,
      senderName: senderName,
      title: record.getStringValue('title').isNotEmpty
          ? record.getStringValue('title')
          : null,
      body: record.getStringValue('body').isNotEmpty
          ? record.getStringValue('body')
          : null,
      type: record.getStringValue('type'),
      targetType: record.getStringValue('target_type').isNotEmpty
          ? record.getStringValue('target_type')
          : null,
      payload: record.getDataValue('payload') as Map<String, dynamic>?,
      isRead: record.getBoolValue('is_read'),
      createdAt: created.toLocal(),
      readAt: _parseDateTime(record.getStringValue('read_at'))?.toLocal(),
    );
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      senderId: senderId,
      senderName: senderName,
      title: title,
      body: body,
      type: type,
      targetType: targetType,
      payload: payload,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  String get timeLabel => formatRelativeTime(createdAt);

  String get displayTitle => title ?? _typeLabels[type] ?? 'Thông báo';

  String get displayBody =>
      body ?? (senderName != null ? '$senderName đã gửi một thông báo' : '');
}

DateTime? _parseDateTime(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
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

const Map<String, String> _typeLabels = {
  'booking_success': 'Đặt sân thành công',
  'booking_cancelled': 'Lịch đặt đã bị hủy',
  'post_commented': 'Bài viết có bình luận mới',
  'post_liked': 'Bài viết được thích',
  'recruitment_applied': 'Có ứng viên mới',
  'recruitment_status_changed': 'Trạng thái tuyển dụng thay đổi',
  'friend_request_received': 'Bạn có lời mời kết bạn',
  'friend_request_accepted': 'Lời mời kết bạn được chấp nhận',
  'friend_request_rejected': 'Lời mời kết bạn bị từ chối',
};
