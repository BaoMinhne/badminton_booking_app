import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';

enum InvitationType { recruitment, booking, proposed }

class Invitation {
  Invitation({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.type,
    required this.status,
    this.viewerId,
    this.fromUserName,
    this.fromAvatarUrl,
    this.toUserName,
    this.toAvatarUrl,
    this.recruitmentId,
    this.bookingId,
    this.courtId,
    this.courtName,
    this.startTime,
    this.endTime,
    this.message,
  });

  factory Invitation.fromRecord(
    RecordModel record,
    PocketBase pb, {
    String? viewerId,
  }) {
    final data = record.data;

    final fromUserRecord = resolveExpandedRecord(record.expand?['from_user']);
    final fromUserData = fromUserRecord?.data;
    final fromUserId = (data['from_user'] as String?) ?? fromUserRecord?.id ?? '';
    final fromName = sanitizeDisplayName(
      (fromUserData?['username'] as String?) ??
          (fromUserData?['email'] as String?),
    );

    final toUserRecord = resolveExpandedRecord(record.expand?['to_user']);
    final toUserData = toUserRecord?.data;

    final recruitmentRecord = resolveExpandedRecord(record.expand?['recruitment']);
    final recruitmentData = recruitmentRecord?.data;
    final bookingRecord = resolveExpandedRecord(record.expand?['booking']);
    final bookingData = bookingRecord?.data;

    final courtFromRecruitment = resolveExpandedRecord(recruitmentRecord?.expand?['court']);
    final courtFromBooking = resolveExpandedRecord(bookingRecord?.expand?['court_id']);
    final courtRecord =
        resolveExpandedRecord(record.expand?['court']) ?? courtFromRecruitment ?? courtFromBooking;
    final courtData = courtRecord?.data;

    return Invitation(
      id: record.id,
      fromUserId: fromUserId,
      toUserId: (data['to_user'] as String?) ?? '',
      type: _mapType(data['type'] as String?),
      status: (data['status'] as String?) ?? 'pending',
      viewerId: viewerId,
      fromUserName: fromName,
      fromAvatarUrl: resolveFileUrl(pb, fromUserRecord, fromUserData?['avatar']),
      toUserName: sanitizeDisplayName(
        (toUserData?['username'] as String?) ??
            (toUserData?['email'] as String?),
      ),
      toAvatarUrl: resolveFileUrl(pb, toUserRecord, toUserData?['avatar']),
      recruitmentId: (data['recruitment'] as String?) ?? recruitmentRecord?.id,
      bookingId: (data['booking'] as String?) ?? bookingRecord?.id,
      courtId: (data['court'] as String?) ??
          courtRecord?.id ??
          (recruitmentData?['court'] as String?) ??
          (bookingData?['court_id'] as String?),
      courtName: sanitizeDisplayName(
        (courtData?['name'] as String?) ??
            (recruitmentData?['court_name'] as String?) ??
            (bookingData?['court_name'] as String?),
      ),
      startTime: _tryParseDate(data['start_time'] ?? bookingData?['start_time'] ??
          recruitmentData?['event_time']),
      endTime: _tryParseDate(data['end_time'] ?? bookingData?['end_time']),
      message: (data['message'] as String?)?.trim(),
    );
  }

  final String id;
  final String fromUserId;
  final String toUserId;
  final InvitationType type;
  final String status;
  final String? viewerId;
  final String? fromUserName;
  final String? fromAvatarUrl;
  final String? toUserName;
  final String? toAvatarUrl;
  final String? recruitmentId;
  final String? bookingId;
  final String? courtId;
  final String? courtName;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? message;

  bool get isOutgoing => viewerId != null && viewerId == fromUserId;
  bool get isPending => status == 'pending';

  Invitation copyWith({String? status}) {
    return Invitation(
      id: id,
      fromUserId: fromUserId,
      toUserId: toUserId,
      type: type,
      status: status ?? this.status,
      viewerId: viewerId,
      fromUserName: fromUserName,
      fromAvatarUrl: fromAvatarUrl,
      toUserName: toUserName,
      toAvatarUrl: toAvatarUrl,
      recruitmentId: recruitmentId,
      bookingId: bookingId,
      courtId: courtId,
      courtName: courtName,
      startTime: startTime,
      endTime: endTime,
      message: message,
    );
  }
}

InvitationType _mapType(String? raw) {
  switch (raw) {
    case 'booking':
      return InvitationType.booking;
    case 'proposed':
      return InvitationType.proposed;
    case 'recruitment':
    default:
      return InvitationType.recruitment;
  }
}

DateTime? _tryParseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
