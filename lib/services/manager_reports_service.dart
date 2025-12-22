import 'dart:math';

import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';

import '../models/booking.dart';
import '../models/court_detail.dart';
import 'pocketbase_client.dart';

class ManagerReportSnapshot {
  final int todayRevenueMinor;
  final double todayRevenueChange;
  final int weekRevenueMinor;
  final double weekRevenueChange;
  final int monthRevenueMinor;
  final double monthRevenueChange;
  final double occupancyRate;
  final double occupancyChange;
  final List<ReportChartPoint> revenueTrend;
  final List<CourtOccupancy> occupancyByCourt;
  final List<ReportBookingRow> bookings;

  const ManagerReportSnapshot({
    required this.todayRevenueMinor,
    required this.todayRevenueChange,
    required this.weekRevenueMinor,
    required this.weekRevenueChange,
    required this.monthRevenueMinor,
    required this.monthRevenueChange,
    required this.occupancyRate,
    required this.occupancyChange,
    required this.revenueTrend,
    required this.occupancyByCourt,
    required this.bookings,
  });
}

class ReportChartPoint {
  final String label;
  final double value;

  const ReportChartPoint(this.label, this.value);
}

class CourtOccupancy {
  final String label;
  final double rate;

  const CourtOccupancy(this.label, this.rate);
}

class ReportBookingRow {
  final String customer;
  final String court;
  final String time;
  final String channel;

  const ReportBookingRow({
    required this.customer,
    required this.court,
    required this.time,
    required this.channel,
  });
}

enum ReportRange { today, week, month }

class ManagerReportsService {
  Future<ManagerReportSnapshot> fetchReport(ReportRange range) async {
    final pb = await getPocketbaseInstance();
    final record = pb.authStore.record;

    if (record == null) {
      throw ClientException(
        statusCode: 401,
        response: {'message': 'Bạn cần đăng nhập để xem báo cáo.'},
      );
    }

    final ownerId = record.id;
    final courtsResult = await pb.collection('courts').getList(
          perPage: 200,
          filter: "owner='${_escape(ownerId)}'",
        );

    if (courtsResult.items.isEmpty) {
      return const ManagerReportSnapshot(
        todayRevenueMinor: 0,
        todayRevenueChange: 0,
        weekRevenueMinor: 0,
        weekRevenueChange: 0,
        monthRevenueMinor: 0,
        monthRevenueChange: 0,
        occupancyRate: 0,
        occupancyChange: 0,
        revenueTrend: [],
        occupancyByCourt: [],
        bookings: [],
      );
    }

    final courtIds = courtsResult.items.map((record) => record.id).toList();
    final now = DateTime.now();
    final rangeStart = _resolveRangeStart(now, range);
    final rangeEnd = _resolveRangeEnd(rangeStart, range);

    final bookingsResult = await pb.collection('court_bookings').getList(
          perPage: 200,
          sort: '-start_time',
          filter:
              "${_buildOrFilter('court_id', courtIds)} && start_time < '${rangeEnd.toUtc().toIso8601String()}' && end_time > '${rangeStart.toUtc().toIso8601String()}'",
          expand: 'user_id,court_unit_id',
        );

    final bookings = bookingsResult.items.map(CourtBooking.fromRecord).toList();

    final previousStart = _resolveRangeStart(rangeStart.subtract(const Duration(seconds: 1)), range);
    final previousEnd = rangeStart;

    final paymentToday = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now),
      end: _startOfDayUtc(now).add(const Duration(days: 1)),
    );

    final paymentYesterday = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now.subtract(const Duration(days: 1))),
      end: _startOfDayUtc(now),
    );

    final paymentWeek = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now.subtract(const Duration(days: 6))),
      end: _startOfDayUtc(now).add(const Duration(days: 1)),
    );

    final paymentPrevWeek = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now.subtract(const Duration(days: 13))),
      end: _startOfDayUtc(now.subtract(const Duration(days: 6))),
    );

    final paymentMonth = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now.subtract(const Duration(days: 29))),
      end: _startOfDayUtc(now).add(const Duration(days: 1)),
    );

    final paymentPrevMonth = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: _startOfDayUtc(now.subtract(const Duration(days: 59))),
      end: _startOfDayUtc(now.subtract(const Duration(days: 29))),
    );

    final occupancyRate = await _computeOccupancy(
      pb: pb,
      courtIds: courtIds,
      bookings: bookings,
      start: rangeStart,
      end: rangeEnd,
    );

    final previousOccupancy = await _computeOccupancy(
      pb: pb,
      courtIds: courtIds,
      bookings: await _listBookingsInRange(
        pb: pb,
        courtIds: courtIds,
        start: previousStart,
        end: previousEnd,
      ),
      start: previousStart,
      end: previousEnd,
    );

    final trend = await _buildRevenueTrend(
      pb: pb,
      courtIds: courtIds,
      start: rangeStart,
      end: rangeEnd,
      range: range,
    );

    final occupancyByCourt = await _computeOccupancyByCourt(
      pb: pb,
      courtIds: courtIds,
      bookings: bookings,
      start: rangeStart,
      end: rangeEnd,
    );

    final bookingRows = _mapBookings(bookingsResult.items, rangeStart, rangeEnd);

    final todayChange = _computeChange(paymentToday, paymentYesterday);
    final weekChange = _computeChange(paymentWeek, paymentPrevWeek);
    final monthChange = _computeChange(paymentMonth, paymentPrevMonth);

    return ManagerReportSnapshot(
      todayRevenueMinor: paymentToday,
      todayRevenueChange: todayChange,
      weekRevenueMinor: paymentWeek,
      weekRevenueChange: weekChange,
      monthRevenueMinor: paymentMonth,
      monthRevenueChange: monthChange,
      occupancyRate: occupancyRate,
      occupancyChange: occupancyRate - previousOccupancy,
      revenueTrend: trend,
      occupancyByCourt: occupancyByCourt,
      bookings: bookingRows,
    );
  }

  Future<int> _sumPaymentsForRange({
    required PocketBase pb,
    required List<String> courtIds,
    required DateTime start,
    required DateTime end,
  }) async {
    final bookings = await _listBookingsInRange(
      pb: pb,
      courtIds: courtIds,
      start: start,
      end: end,
    );
    final bookingIds = bookings.map((booking) => booking.id).toList();
    return _sumPaymentsForBookings(pb: pb, bookingIds: bookingIds);
  }

  Future<int> _sumPaymentsForBookings({
    required PocketBase pb,
    required List<String> bookingIds,
  }) async {
    if (bookingIds.isEmpty) return 0;
    final filter = "status='succeeded' && (${_buildOrFilter('booking_id', bookingIds)})";

    try {
      final payments = await pb.collection('payment').getList(
            perPage: 200,
            filter: filter,
          );

      return payments.items.fold<int>(0, (sum, record) {
        final raw = record.data['amount_minor'];
        return sum + _parseMinorUnit(raw);
      });
    } on ClientException catch (err) {
      if (err.statusCode == 401 || err.statusCode == 403) {
        return 0;
      }
      rethrow;
    }
  }

  Future<List<CourtBooking>> _listBookingsInRange({
    required PocketBase pb,
    required List<String> courtIds,
    required DateTime start,
    required DateTime end,
  }) async {
    final filter =
        "${_buildOrFilter('court_id', courtIds)} && start_time < '${end.toUtc().toIso8601String()}' && end_time > '${start.toUtc().toIso8601String()}'";

    final result = await pb.collection('court_bookings').getList(
          perPage: 200,
          filter: filter,
        );

    return result.items.map(CourtBooking.fromRecord).toList();
  }

  Future<double> _computeOccupancy({
    required PocketBase pb,
    required List<String> courtIds,
    required List<CourtBooking> bookings,
    required DateTime start,
    required DateTime end,
  }) async {
    final openingHoursResult = await pb.collection('court_opening_hours').getList(
          perPage: 200,
          filter: _buildOrFilter('court_id', courtIds),
        );

    final capacityMinutes = courtIds.fold<double>(0.0, (sum, id) {
      final durationMinutes = _computeOpeningDuration(
        openingHoursResult.items,
        id,
      );
      final unitCount = bookings.where((b) => b.courtId == id).map((b) => b.courtUnitId).toSet().length;
      final days = end.difference(start).inDays;
      return sum + durationMinutes * max(days, 1) * max(unitCount, 1);
    });

    final bookedMinutes = bookings
        .where((b) => b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.awaitingPayment)
        .fold<double>(0, (sum, booking) {
      final overlapStart = booking.startTime.toLocal().isBefore(start)
          ? start
          : booking.startTime.toLocal();
      final overlapEnd = booking.endTime.toLocal().isAfter(end)
          ? end
          : booking.endTime.toLocal();
      return sum + overlapEnd.difference(overlapStart).inMinutes;
    });

    if (capacityMinutes == 0) return 0;
    return (bookedMinutes / capacityMinutes).clamp(0, 1).toDouble();
  }

  Future<List<CourtOccupancy>> _computeOccupancyByCourt({
    required PocketBase pb,
    required List<String> courtIds,
    required List<CourtBooking> bookings,
    required DateTime start,
    required DateTime end,
  }) async {
    final courtUnitsResult = await pb.collection('court_units').getList(
          perPage: 200,
          filter: _buildOrFilter('court_id', courtIds),
        );

    final openingHoursResult = await pb.collection('court_opening_hours').getList(
          perPage: 200,
          filter: _buildOrFilter('court_id', courtIds),
        );

    final unitLabels = <String, String>{};
    final unitCourt = <String, String>{};
    for (final record in courtUnitsResult.items) {
      final unit = CourtUnit.fromRecord(record);
      unitLabels[record.id] = unit.label.isEmpty ? 'Sân' : unit.label;
      unitCourt[record.id] = (record.data['court_id'] as String?) ?? '';
    }

    final capacityByCourt = <String, double>{};
    for (final courtId in courtIds) {
      final durationMinutes = _computeOpeningDuration(
        openingHoursResult.items,
        courtId,
      );
      final units = unitCourt.values.where((id) => id == courtId).length;
      capacityByCourt[courtId] = durationMinutes * max(units, 1);
    }

    final bookedByCourt = <String, double>{};
    for (final booking in bookings) {
      final overlapStart = booking.startTime.toLocal().isBefore(start)
          ? start
          : booking.startTime.toLocal();
      final overlapEnd = booking.endTime.toLocal().isAfter(end)
          ? end
          : booking.endTime.toLocal();
      final minutes = overlapEnd.difference(overlapStart).inMinutes.toDouble();
      bookedByCourt.update(booking.courtId, (value) => value + minutes,
          ifAbsent: () => minutes);
    }

    final results = <CourtOccupancy>[];
    for (final entry in capacityByCourt.entries) {
      final capacity = entry.value;
      final booked = bookedByCourt[entry.key] ?? 0;
      final rate = capacity == 0
          ? 0.0
          : (booked / capacity).clamp(0.0, 1.0).toDouble();
      final matchingUnit = unitCourt.entries.firstWhere(
        (unit) => unit.value == entry.key,
        orElse: () => const MapEntry('', ''),
      );
      final label = matchingUnit.key.isNotEmpty
          ? (unitLabels[matchingUnit.key] ?? 'Sân')
          : 'Sân';
      results.add(CourtOccupancy(label, rate));
    }

    return results;
  }

  Future<List<ReportChartPoint>> _buildRevenueTrend({
    required PocketBase pb,
    required List<String> courtIds,
    required DateTime start,
    required DateTime end,
    required ReportRange range,
  }) async {
    final payments = await _sumPaymentsForRange(
      pb: pb,
      courtIds: courtIds,
      start: start,
      end: end,
    );

    if (payments == 0) {
      return const [ReportChartPoint('0', 0)];
    }

    final formatter = DateFormat('dd/MM');
    final days = end.difference(start).inDays;
    final buckets = max(days, 1);
    final step = days == 0 ? 1 : 1;

    final points = <ReportChartPoint>[];
    var cursor = start;
    for (var i = 0; i < buckets; i++) {
      final bucketStart = cursor;
      final bucketEnd = cursor.add(Duration(days: step));
      final value = await _sumPaymentsForRange(
        pb: pb,
        courtIds: courtIds,
        start: bucketStart,
        end: bucketEnd.isAfter(end) ? end : bucketEnd,
      );
      points.add(ReportChartPoint(formatter.format(bucketStart), value / 1000000));
      cursor = bucketEnd;
      if (cursor.isAfter(end)) break;
    }

    return points;
  }

  List<ReportBookingRow> _mapBookings(
    List<RecordModel> records,
    DateTime start,
    DateTime end,
  ) {
    final formatter = DateFormat('HH:mm');

    return records
        .where((record) {
          final booking = CourtBooking.fromRecord(record);
          return booking.status == BookingStatus.confirmed &&
              booking.userId.isEmpty &&
              booking.startTime.isAfter(start.subtract(const Duration(minutes: 1))) &&
              booking.endTime.isBefore(end.add(const Duration(minutes: 1)));
        })
        .take(5)
        .map((record) {
          final booking = CourtBooking.fromRecord(record);
          final userRecord = _asRecordModel(record.expand?['user_id']);
          final courtUnit = _asRecordModel(record.expand?['court_unit_id']);
          final name = _extractUserName(userRecord) ?? 'Khách lẻ';
          final courtLabel = _extractCourtLabel(courtUnit) ?? 'Sân';
          final startTime = booking.startTime.toLocal();
          final endTime = booking.endTime.toLocal();
          return ReportBookingRow(
            customer: name,
            court: courtLabel,
            time: '${formatter.format(startTime)} - ${formatter.format(endTime)}',
            channel: 'Offline',
          );
        })
        .toList();
  }

  DateTime _startOfDayUtc(DateTime dt) => DateTime(dt.year, dt.month, dt.day).toUtc();

  DateTime _resolveRangeStart(DateTime now, ReportRange range) {
    final base = DateTime(now.year, now.month, now.day);
    switch (range) {
      case ReportRange.today:
        return base;
      case ReportRange.week:
        return base.subtract(const Duration(days: 6));
      case ReportRange.month:
        return base.subtract(const Duration(days: 29));
    }
  }

  DateTime _resolveRangeEnd(DateTime start, ReportRange range) {
    switch (range) {
      case ReportRange.today:
        return start.add(const Duration(days: 1));
      case ReportRange.week:
        return start.add(const Duration(days: 7));
      case ReportRange.month:
        return start.add(const Duration(days: 30));
    }
  }

  double _computeOpeningDuration(List<RecordModel> items, String courtId) {
    for (final record in items) {
      final id = (record.data['court_id'] as String?) ?? '';
      if (id != courtId) continue;
      final open = record.data['open_time'] as String?;
      final close = record.data['close_time'] as String?;
      final minutes = _parseDurationMinutes(open, close);
      if (minutes != null) return minutes;
    }
    return 0;
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
    return diff.inMinutes.toDouble().clamp(0, double.infinity).toDouble();
  }

  RecordModel? _asRecordModel(dynamic expandedValue) {
    if (expandedValue is RecordModel) return expandedValue;
    if (expandedValue is List && expandedValue.isNotEmpty) {
      final first = expandedValue.first;
      if (first is RecordModel) return first;
    }
    return null;
  }

  String? _extractUserName(RecordModel? expandedUser) {
    final data = expandedUser?.data;
    if (data == null) return null;

    final username = data['username'] as String?;
    final name = data['name'] as String?;
    if (username != null && username.trim().isNotEmpty) return username.trim();
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return null;
  }

  String? _extractCourtLabel(RecordModel? expandedCourtUnit) {
    if (expandedCourtUnit == null) return null;

    final unit = CourtUnit.fromRecord(expandedCourtUnit);
    if (unit.label.isNotEmpty) return unit.label;
    return null;
  }

  double _computeChange(int current, int previous) {
    if (previous <= 0) return current > 0 ? 1 : 0;
    return (current - previous) / previous;
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
