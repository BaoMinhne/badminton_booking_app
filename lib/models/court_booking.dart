import 'package:pocketbase/pocketbase.dart';

enum CourtBookingStatus {
  pending,
  confirmed,
  cancelled,
  locked,
  unknown,
}

extension CourtBookingStatusX on CourtBookingStatus {
  bool get blocksTime {
    switch (this) {
      case CourtBookingStatus.pending:
      case CourtBookingStatus.confirmed:
      case CourtBookingStatus.locked:
        return true;
      case CourtBookingStatus.cancelled:
      case CourtBookingStatus.unknown:
        return false;
    }
  }

  bool get isLocked => this == CourtBookingStatus.locked;
}

CourtBookingStatus parseCourtBookingStatus(String? raw) {
  final value = raw?.trim().toLowerCase();
  switch (value) {
    case 'pending':
      return CourtBookingStatus.pending;
    case 'confirmed':
      return CourtBookingStatus.confirmed;
    case 'cancelled':
      return CourtBookingStatus.cancelled;
    case 'locked':
      return CourtBookingStatus.locked;
    default:
      return CourtBookingStatus.unknown;
  }
}

class CourtBooking {
  final String id;
  final String courtId;
  final String courtUnitId;
  final String? userId;
  final DateTime startTime;
  final DateTime endTime;
  final CourtBookingStatus status;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CourtBooking({
    required this.id,
    required this.courtId,
    required this.courtUnitId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.userId,
    this.note,
    this.createdAt,
    this.updatedAt,
  });

  bool get blocksTime => status.blocksTime;
  bool get isLocked => status.isLocked;

  factory CourtBooking.fromRecord(RecordModel record) {
    final data = record.data;
    final start = _parseDateTime(data['start_time']);
    final end = _parseDateTime(data['end_time']);

    final safeStart = (start ?? DateTime.now()).toLocal();
    final safeEndRaw = (end ?? safeStart.add(const Duration(hours: 1))).toLocal();
    final safeEnd = safeEndRaw.isAfter(safeStart)
        ? safeEndRaw
        : safeStart.add(const Duration(minutes: 30));

    return CourtBooking(
      id: record.id,
      courtId: (data['court_id'] as String?)?.trim() ?? '',
      courtUnitId: (data['court_unit_id'] as String?)?.trim() ?? '',
      userId: (data['user_id'] as String?)?.trim(),
      startTime: safeStart,
      endTime: safeEnd,
      status: parseCourtBookingStatus(data['status'] as String?),
      note: _parseOptionalText(data['note']),
      createdAt: _parseDateTime(data['created']),
      updatedAt: _parseDateTime(data['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'court_id': courtId,
        'court_unit_id': courtUnitId,
        'user_id': userId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'status': status.name,
        'note': note,
        'created': createdAt?.toIso8601String(),
        'updated': updatedAt?.toIso8601String(),
      };
}

String? _parseOptionalText(dynamic value) {
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
