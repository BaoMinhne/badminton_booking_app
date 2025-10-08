import 'package:pocketbase/pocketbase.dart';

enum CourtBookingStatus { pending, confirmed, cancelled, locked }

CourtBookingStatus parseCourtBookingStatus(String? value) {
  switch (value) {
    case 'pending':
      return CourtBookingStatus.pending;
    case 'confirmed':
      return CourtBookingStatus.confirmed;
    case 'cancelled':
      return CourtBookingStatus.cancelled;
    case 'locked':
    default:
      return CourtBookingStatus.locked;
  }
}

String courtBookingStatusToString(CourtBookingStatus status) {
  switch (status) {
    case CourtBookingStatus.pending:
      return 'pending';
    case CourtBookingStatus.confirmed:
      return 'confirmed';
    case CourtBookingStatus.cancelled:
      return 'cancelled';
    case CourtBookingStatus.locked:
      return 'locked';
  }
}

class CourtBooking {
  const CourtBooking({
    required this.id,
    required this.courtId,
    required this.courtUnitId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.lockedUntil,
    this.note,
  });

  factory CourtBooking.fromRecord(RecordModel record) {
    final data = record.data;
    return CourtBooking(
      id: record.id,
      courtId: (data['court_id'] as String?)?.trim() ?? '',
      courtUnitId: (data['court_unit_id'] as String?)?.trim() ?? '',
      userId: (data['user_id'] as String?)?.trim() ?? '',
      startTime: _parseDate(data['start_time']),
      endTime: _parseDate(data['end_time']),
      status: parseCourtBookingStatus(data['status'] as String?),
      lockedUntil: _parseOptionalDate(data['locked_until']),
      note: (data['note'] as String?)?.trim(),
    );
  }

  final String id;
  final String courtId;
  final String courtUnitId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final CourtBookingStatus status;
  final DateTime? lockedUntil;
  final String? note;

  bool get isLockActive {
    if (status != CourtBookingStatus.locked) return false;
    final lock = lockedUntil;
    if (lock == null) return false;
    return lock.isAfter(DateTime.now());
  }

  bool get blocksSelection {
    switch (status) {
      case CourtBookingStatus.pending:
      case CourtBookingStatus.confirmed:
        return true;
      case CourtBookingStatus.locked:
        return isLockActive;
      case CourtBookingStatus.cancelled:
        return false;
    }
  }

  CourtBooking copyWith({
    CourtBookingStatus? status,
    DateTime? lockedUntil,
    String? note,
  }) {
    return CourtBooking(
      id: id,
      courtId: courtId,
      courtUnitId: courtUnitId,
      userId: userId,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      note: note ?? this.note,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value.toLocal();
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return parsed.toLocal();
    }
  }
  throw StateError('Invalid date value: $value');
}

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toLocal();
  if (value is String && value.isNotEmpty) {
    final parsed = DateTime.tryParse(value);
    return parsed?.toLocal();
  }
  return null;
}
