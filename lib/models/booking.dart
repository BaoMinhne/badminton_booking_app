import 'package:pocketbase/pocketbase.dart';

/// Booking status available in the PocketBase `court_bookings` collection.
enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  locked,
}

BookingStatus _parseBookingStatus(dynamic value) {
  final raw = (value as String?)?.trim().toLowerCase();
  switch (raw) {
    case 'confirmed':
      return BookingStatus.confirmed;
    case 'cancelled':
      return BookingStatus.cancelled;
    case 'locked':
      return BookingStatus.locked;
    case 'pending':
    default:
      return BookingStatus.pending;
  }
}

class CourtBooking {
  CourtBooking({
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
      startTime: DateTime.parse(data['start_time'] as String),
      endTime: DateTime.parse(data['end_time'] as String),
      status: _parseBookingStatus(data['status']),
      lockedUntil: _tryParseDateTime(data['locked_until']),
      note: data['note'] as String?,
    );
  }

  final String id;
  final String courtId;
  final String courtUnitId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final DateTime? lockedUntil;
  final String? note;

  bool get isActiveLock {
    if (status != BookingStatus.locked) return false;
    if (lockedUntil == null) return true;
    return lockedUntil!.isAfter(DateTime.now().toUtc());
  }

  CourtBooking copyWith({
    BookingStatus? status,
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

  List<SelectedSlot> splitToSlots(Duration slotDuration) {
    final slots = <SelectedSlot>[];
    var cursor = startTime;
    while (cursor.isBefore(endTime)) {
      final next = cursor.add(slotDuration);
      slots.add(
        SelectedSlot(
          courtUnitId: courtUnitId,
          startTime: cursor,
          endTime: next.isAfter(endTime) ? endTime : next,
        ),
      );
      cursor = next;
    }
    return slots;
  }
}

class SelectedSlot {
  const SelectedSlot({
    required this.courtUnitId,
    required this.startTime,
    required this.endTime,
  });

  final String courtUnitId;
  final DateTime startTime;
  final DateTime endTime;

  SelectedSlot copyWith({
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return SelectedSlot(
      courtUnitId: courtUnitId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  int get hashCode =>
      Object.hash(courtUnitId, startTime.millisecondsSinceEpoch);

  @override
  bool operator ==(Object other) {
    return other is SelectedSlot &&
        other.courtUnitId == courtUnitId &&
        other.startTime.millisecondsSinceEpoch ==
            startTime.millisecondsSinceEpoch;
  }

  @override
  String toString() {
    return 'SelectedSlot(unit: $courtUnitId, start: $startTime, end: $endTime)';
  }
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value)?.toUtc();
  }
  return null;
}
