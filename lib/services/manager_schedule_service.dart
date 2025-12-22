import 'package:pocketbase/pocketbase.dart';

import '../models/booking.dart';
import '../models/court_detail.dart';
import 'booking_service.dart';
import 'pocketbase_client.dart';

class ManagerScheduleData {
  const ManagerScheduleData({
    required this.courtIds,
    required this.courts,
    required this.items,
  });

  final List<String> courtIds;
  final List<ScheduleCourt> courts;
  final List<ScheduleItem> items;

  bool get hasCourts => courts.isNotEmpty;
}

class ScheduleCourt {
  const ScheduleCourt({required this.id, required this.label});

  final String id;
  final String label;
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.courtId,
    required this.courtLabel,
    required this.startTime,
    required this.endTime,
    required this.customerName,
    required this.status,
    this.customerPhone,
    this.note,
  });

  final String id;
  final String courtId;
  final String courtLabel;
  final DateTime startTime;
  final DateTime endTime;
  final String customerName;
  final String? customerPhone;
  final BookingStatus status;
  final String? note;

  ScheduleItem copyWith({
    String? id,
    String? courtId,
    String? courtLabel,
    DateTime? startTime,
    DateTime? endTime,
    String? customerName,
    String? customerPhone,
    BookingStatus? status,
    String? note,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      courtLabel: courtLabel ?? this.courtLabel,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}

class ManagerScheduleService {
  Future<ManagerScheduleData> fetchSchedule(DateTime date) async {
    final pocketBase = await getPocketbaseInstance();
    final authRecord = pocketBase.authStore.record;

    if (authRecord == null) {
      throw ClientException(
        statusCode: 401,
        response: {'message': 'Bạn cần đăng nhập để xem lịch.'},
      );
    }

    final ownerId = _escape(authRecord.id);
    final courtsResult = await pocketBase.collection('courts').getList(
          perPage: 200,
          filter: "owner='$ownerId'",
        );

    if (courtsResult.items.isEmpty) {
      return const ManagerScheduleData(courtIds: [], courts: [], items: []);
    }

    final courtIds = courtsResult.items.map((record) => record.id).toList();
    final courtFilter = _buildOrFilter('court_id', courtIds);

    final unitsFuture = pocketBase.collection('court_units').getList(
          perPage: 200,
          filter: courtFilter,
        );

    final dayStartLocal = DateTime(date.year, date.month, date.day);
    final dayStart = dayStartLocal.toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final bookingsFuture = pocketBase.collection(BookingService.collection).getList(
          perPage: 200,
          filter:
              "$courtFilter && status != 'expired' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'",
          sort: 'start_time',
          expand: 'user_id,court_unit_id',
        );

    final results = await Future.wait([unitsFuture, bookingsFuture]);

    final unitResult = results[0] as ResultList<RecordModel>;
    final bookingResult = results[1] as ResultList<RecordModel>;

    final courts = unitResult.items.map(_mapCourtOption).toList();

    final unitLabelMap = <String, String>{
      for (final unit in unitResult.items)
        unit.id: CourtUnit.fromRecord(unit).label.isEmpty
            ? 'Sân'
            : CourtUnit.fromRecord(unit).label,
    };

    final bookings = bookingResult.items.map((record) {
      final booking = CourtBooking.fromRecord(record);
      final courtLabel = unitLabelMap[booking.courtUnitId] ?? 'Sân';

      final expandedUser = _resolveExpandedRecord(record.expand?['user_id']);
      final customerName = _extractUserName(expandedUser) ?? 'Khách lẻ';
      final customerPhone = _extractUserPhone(expandedUser);

      return ScheduleItem(
        id: booking.id,
        courtId: booking.courtUnitId,
        courtLabel: courtLabel,
        startTime: booking.startTime.toLocal(),
        endTime: booking.endTime.toLocal(),
        customerName: customerName,
        customerPhone: customerPhone,
        status: booking.status,
        note: booking.note,
      );
    }).toList(growable: false);

    return ManagerScheduleData(
      courtIds: courtIds,
      courts: courts,
      items: bookings,
    );
  }

  ScheduleCourt _mapCourtOption(RecordModel record) {
    final unit = CourtUnit.fromRecord(record);
    final label = unit.label.isEmpty ? 'Sân' : unit.label;
    return ScheduleCourt(id: record.id, label: label);
  }

  Future<void> cancelBooking(String bookingId) async {
    final pocketBase = await getPocketbaseInstance();

    try {
      await pocketBase.collection(BookingService.collection).update(
        bookingId,
        body: {'status': 'cancelled'},
      );
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
        'Không thể huỷ booking. Vui lòng thử lại.',
      );
    }
  }

  String _escape(String value) => value.replaceAll("'", "\\'");

  String _buildOrFilter(String field, List<String> values) {
    final escaped = values.map(_escape).map((v) => "${field}='${v}'");
    return escaped.join(' || ');
  }

  String _mapClientException(ClientException error) {
    if (error.response != null) {
      final data = error.response!['data'];
      if (data is Map && data.isNotEmpty) {
        final first = data.values.first;
        if (first is Map && first['message'] is String) {
          return first['message'] as String;
        }
      }
      if (error.response!['message'] is String) {
        return error.response!['message'] as String;
      }
    }
    return 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }

  RecordModel? _resolveExpandedRecord(dynamic expanded) {
    if (expanded is RecordModel) return expanded;
    if (expanded is List) {
      for (final item in expanded) {
        if (item is RecordModel) return item;
      }
    }
    return null;
  }

  String? _extractUserName(RecordModel? expandedUser) {
    if (expandedUser == null) return null;
    final data = expandedUser.data;
    return (data['username'] as String?)?.trim().isNotEmpty == true
        ? (data['username'] as String?)?.trim()
        : (data['name'] as String?)?.trim();
  }

  String? _extractUserPhone(RecordModel? expandedUser) {
    if (expandedUser == null) return null;
    final rawPhone = (expandedUser.data['phone'] as String?)?.trim();
    if (rawPhone == null || rawPhone.isEmpty) return null;
    return rawPhone;
  }
}

class ManagerScheduleRealtimeService {
  UnsubscribeFunc? _unsubscribe;

  Future<void> subscribe({
    required DateTime date,
    required List<String> courtIds,
    required void Function() onChange,
  }) async {
    final pocketBase = await getPocketbaseInstance();

    await unsubscribe();

    if (courtIds.isEmpty) return;

    final dayStartLocal = DateTime(date.year, date.month, date.day);
    final dayStart = dayStartLocal.toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));
    final courtFilter = _buildOrFilter('court_id', courtIds);
    final filter =
        "$courtFilter && status != 'expired' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";

    _unsubscribe = await pocketBase.collection(BookingService.collection).subscribe(
          '*',
          (_) => onChange(),
          filter: filter,
        );
  }

  Future<void> unsubscribe() async {
    final unsub = _unsubscribe;
    _unsubscribe = null;
    if (unsub != null) {
      await unsub();
    }
  }

  Future<void> dispose() async {
    await unsubscribe();
  }

  String _buildOrFilter(String field, List<String> values) {
    final escaped = values.map(_escape).map((v) => "${field}='${v}'");
    return escaped.join(' || ');
  }

  String _escape(String value) => value.replaceAll("'", "\\'");
}
