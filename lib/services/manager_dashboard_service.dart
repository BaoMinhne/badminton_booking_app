import 'dart:math';

import 'package:pocketbase/pocketbase.dart';

import '../models/booking.dart';
import '../models/court_detail.dart';
import 'booking_service.dart';
import 'pocketbase_client.dart';

class ManagerDashboardData {
  final ManagerDailyStats today;
  final ManagerDailyStats? previous;

  const ManagerDashboardData({required this.today, required this.previous});

  bool get hasCourts => today.courtIds.isNotEmpty;
}

class ManagerDailyStats {
  final List<String> courtIds;
  final List<String> bookingIds;
  final int revenueMinor;
  final double occupancyRate;
  final int confirmedBookingCount;
  final int awaitingPaymentCount;
  final int blockedSlotCount;
  final List<ManagerScheduleItem> schedule;

  const ManagerDailyStats({
    required this.courtIds,
    required this.bookingIds,
    required this.revenueMinor,
    required this.occupancyRate,
    required this.confirmedBookingCount,
    required this.awaitingPaymentCount,
    required this.blockedSlotCount,
    this.schedule = const [],
  });
}

class ManagerScheduleItem {
  final String courtLabel;
  final DateTime startTime;
  final DateTime endTime;
  final String customerName;
  final BookingStatus status;
  final String? note;

  const ManagerScheduleItem({
    required this.courtLabel,
    required this.startTime,
    required this.endTime,
    required this.customerName,
    required this.status,
    this.note,
  });

  Duration get duration => endTime.difference(startTime);
}

class ManagerDashboardService {
  Future<ManagerDashboardData> fetchDashboardData(DateTime date) async {
    final pb = await getPocketbaseInstance();
    final authRecord = pb.authStore.record;

    if (authRecord == null) {
      throw ClientException(
        statusCode: 401,
        response: {'message': 'You need to log in to view data.'},
      );
    }

    final ownerId = authRecord.id;
    final courtsResult = await pb.collection('courts').getList(
          perPage: 200,
          filter: "owner='${_escape(ownerId)}'",
        );

    if (courtsResult.items.isEmpty) {
      const emptyStats = ManagerDailyStats(
        courtIds: [],
        bookingIds: [],
        revenueMinor: 0,
        occupancyRate: 0,
        confirmedBookingCount: 0,
        awaitingPaymentCount: 0,
        blockedSlotCount: 0,
        schedule: [],
      );
      return const ManagerDashboardData(today: emptyStats, previous: emptyStats);
    }

    final courtIds = courtsResult.items.map((record) => record.id).toList();

    final todayStats = await _loadStatsForDate(
      pb: pb,
      courtIds: courtIds,
      date: date,
    );

    final yesterdayStats = await _loadStatsForDate(
      pb: pb,
      courtIds: courtIds,
      date: date.subtract(const Duration(days: 1)),
    );

    return ManagerDashboardData(today: todayStats, previous: yesterdayStats);
  }

  Future<ManagerDailyStats> _loadStatsForDate({
    required PocketBase pb,
    required List<String> courtIds,
    required DateTime date,
  }) async {
    final dayStartLocal = DateTime(date.year, date.month, date.day);
    final dayStart = dayStartLocal.toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final courtFilter = _buildOrFilter('court_id', courtIds);

    final courtsFuture = pb.collection('court_units').getList(
          perPage: 200,
          filter: courtFilter,
        );

    final hoursFuture = pb.collection('court_opening_hours').getList(
          perPage: 200,
          filter: courtFilter,
        );

    final bookingsFuture = pb.collection(BookingService.collection).getList(
          perPage: 200,
          filter:
              "$courtFilter && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'",
          sort: 'start_time',
          expand: 'user_id,court_unit_id',
        );

    final results = await Future.wait([courtsFuture, hoursFuture, bookingsFuture]);

    final courtUnitsResult = results[0] as ResultList<RecordModel>;
    final openingHoursResult = results[1] as ResultList<RecordModel>;
    final bookingResult = results[2] as ResultList<RecordModel>;

    final unitLabels = <String, String>{};
    final unitCourtMap = <String, String>{};
    for (final unitRecord in courtUnitsResult.items) {
      final unit = CourtUnit.fromRecord(unitRecord);
      final courtId = (unitRecord.data['court_id'] as String?) ?? '';
      unitCourtMap[unitRecord.id] = courtId;
      unitLabels[unitRecord.id] = unit.label.isEmpty ? 'Court' : unit.label;
    }

    final openingDuration = _computeOpeningDurations(openingHoursResult.items);

    final bookings = bookingResult.items.map(CourtBooking.fromRecord).toList();
    final bookingIds = bookings.map((booking) => booking.id).toList();

    final scheduleItems = bookingResult.items.map((record) {
      final booking = CourtBooking.fromRecord(record);
      final unitLabel = unitLabels[booking.courtUnitId] ?? 'Court';
      final userRecord = record.expand?['user_id'];
      final customerName = _extractUserName(userRecord) ?? 'Walk-in';
      return ManagerScheduleItem(
        courtLabel: unitLabel,
        startTime: booking.startTime.toLocal(),
        endTime: booking.endTime.toLocal(),
        customerName: customerName,
        status: booking.status,
        note: booking.note,
      );
    }).toList();

    final bookedMinutes = bookings
        .where((b) => b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.awaitingPayment)
        .fold<double>(
          0.0,
          (sum, booking) =>
              sum + booking.endTime.difference(booking.startTime).inMinutes,
        );

    final capacityMinutes = courtIds.fold<double>(0.0, (sum, id) {
      final durationMinutes = openingDuration[id] ?? 0.0;
      final unitCount = unitCourtMap.values.where((cid) => cid == id).length;
      return sum + durationMinutes * max(1, unitCount);
    });

    final occupancyRate = capacityMinutes == 0
        ? 0.0
        : (bookedMinutes / capacityMinutes).clamp(0, 1).toDouble();

    final blockedSlots = bookings.where((b) => b.status == BookingStatus.held).length;
    final awaitingPayments =
        bookings.where((b) => b.status == BookingStatus.awaitingPayment).length;
    final confirmedCount = bookings.where((b) => b.status == BookingStatus.confirmed).length;

    final revenueMinor = await _sumRevenue(
      pb: pb,
      bookingIds: bookings.map((b) => b.id).toList(),
      dayStart: dayStart,
      dayEnd: dayEnd,
    );

    return ManagerDailyStats(
      courtIds: courtIds,
      bookingIds: bookingIds,
      revenueMinor: revenueMinor,
      occupancyRate: occupancyRate,
      confirmedBookingCount: confirmedCount,
      awaitingPaymentCount: awaitingPayments,
      blockedSlotCount: blockedSlots,
      schedule: scheduleItems,
    );
  }

  Map<String, double> _computeOpeningDurations(List<RecordModel> items) {
    final map = <String, double>{};
    for (final record in items) {
      final courtId = (record.data['court_id'] as String?) ?? '';
      final open = record.data['open_time'] as String?;
      final close = record.data['close_time'] as String?;
      final minutes = _parseDurationMinutes(open, close);
      if (minutes != null) {
        map[courtId] = minutes;
      }
    }
    return map;
  }

  Future<int> _sumRevenue({
    required PocketBase pb,
    required List<String> bookingIds,
    required DateTime dayStart,
    required DateTime dayEnd,
  }) async {
    if (bookingIds.isEmpty) return 0;
    final bookingFilter = _buildOrFilter('booking_id', bookingIds);
    final filter =
        "status='succeeded' && ($bookingFilter)";

    ResultList<RecordModel> payments;
    try {
      payments = await pb.collection('payment').getList(
            perPage: 200,
            filter: filter,
          );
    } on ClientException catch (err) {
      if (err.statusCode == 401 || err.statusCode == 403) {
        // Some accounts do not have access to the payment collection. Return 0
        // to avoid blocking the entire dashboard.
        return 0;
      }
      rethrow;
    }

    return payments.items.fold<int>(0, (sum, record) {
      final rawAmount = record.data['amount_minor'];
      final parsed = _parseMinorUnit(rawAmount);
      return sum + parsed;
    });
  }

  String? _extractUserName(dynamic expandedUser) {
    if (expandedUser is RecordModel) {
      final data = expandedUser.data;
      return (data['username'] as String?) ?? data['name'] as String?;
    }
    return null;
  }

  double? _parseDurationMinutes(String? openTime, String? closeTime) {
    if (openTime == null || closeTime == null) return null;
    final openParts = openTime.split(':');
    final closeParts = closeTime.split(':');
    if (openParts.length != 2 || closeParts.length != 2) return null;

    final openHour = int.tryParse(openParts[0]);
    final openMinute = int.tryParse(openParts[1]);
    final closeHour = int.tryParse(closeParts[0]);
    final closeMinute = int.tryParse(closeParts[1]);

    if ([openHour, openMinute, closeHour, closeMinute].any((v) => v == null)) {
      return null;
    }

    final open = Duration(hours: openHour!, minutes: openMinute!);
    final close = Duration(hours: closeHour!, minutes: closeMinute!);
    final diff = close - open;
    return diff.inMinutes
        .toDouble()
        .clamp(0, double.infinity)
        .toDouble();
  }

  String _buildOrFilter(String field, List<String> values) {
    final escaped = values.map(_escape).map((v) => "${field}='${v}'");
    return escaped.join(' || ');
  }

  String _escape(String value) => value.replaceAll("'", "\\'");

  int _parseMinorUnit(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }
}

class ManagerDashboardRealtimeService {
  UnsubscribeFunc? _bookingUnsubscribe;
  UnsubscribeFunc? _paymentUnsubscribe;

  Future<void> subscribe({
    required DateTime date,
    required List<String> courtIds,
    required List<String> bookingIds,
    required void Function() onChange,
  }) async {
    final pb = await getPocketbaseInstance();

    await unsubscribe();

    if (courtIds.isEmpty) {
      return;
    }

    final dayStartLocal = DateTime(date.year, date.month, date.day);
    final dayStart = dayStartLocal.toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));
    final courtFilter = _buildOrFilter('court_id', courtIds);
    final bookingFilter =
        "$courtFilter && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";

    _bookingUnsubscribe = await pb.collection(BookingService.collection).subscribe(
          '*',
          (_) => onChange(),
          filter: bookingFilter,
        );

    if (bookingIds.isEmpty) {
      return;
    }

    final paymentFilter =
        "status='succeeded' && (${_buildOrFilter('booking_id', bookingIds)})";

    try {
      _paymentUnsubscribe = await pb.collection('payment').subscribe(
            '*',
            (_) => onChange(),
            filter: paymentFilter,
          );
    } on ClientException catch (err) {
      if (err.statusCode == 401 || err.statusCode == 403) {
        return;
      }
      rethrow;
    }
  }

  Future<void> unsubscribe() async {
    final bookingUnsub = _bookingUnsubscribe;
    final paymentUnsub = _paymentUnsubscribe;
    _bookingUnsubscribe = null;
    _paymentUnsubscribe = null;

    if (bookingUnsub != null) {
      await bookingUnsub();
    }
    if (paymentUnsub != null) {
      await paymentUnsub();
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
