import 'package:pocketbase/pocketbase.dart';

import '../models/court_booking.dart';
import 'pocketbase_client.dart';

class CourtBookingServiceException implements Exception {
  CourtBookingServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CourtBookingService {
  static const collection = 'court_bookings';

  Future<List<CourtBooking>> listBookings({
    required String courtId,
    required DateTime date,
  }) async {
    final pb = await getPocketbaseInstance();
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final now = DateTime.now().toUtc();

    final filter = [
      "court_id='${_escapeFilterValue(courtId)}'",
      "start_time < '${_formatDate(dayEnd)}'",
      "end_time > '${_formatDate(dayStart)}'",
      "(status='pending' || status='confirmed' || (status='locked' && locked_until >= '${_formatDate(now)}'))",
    ].join(' && ');

    try {
      final result = await pb.collection(collection).getList(
            filter: filter,
            perPage: 200,
            sort: 'start_time',
          );

      return result.items
          .map(CourtBooking.fromRecord)
          .where((booking) =>
              booking.status != CourtBookingStatus.cancelled &&
              (booking.status != CourtBookingStatus.locked ||
                  booking.isLockActive))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw CourtBookingServiceException(_mapClientException(error));
    } catch (_) {
      throw CourtBookingServiceException(
        'Không thể tải lịch đặt sân. Vui lòng thử lại sau.',
      );
    }
  }

  Future<CourtBooking> lockSlot({
    required String courtId,
    required String courtUnitId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    String? note,
    Duration holdDuration = const Duration(minutes: 15),
  }) async {
    final pb = await getPocketbaseInstance();

    final overlapping = await _countOverlappingBookings(
      pb,
      courtUnitId: courtUnitId,
      startTime: startTime,
      endTime: endTime,
    );

    if (overlapping > 0) {
      throw CourtBookingServiceException(
        'Khung giờ này đã có người giữ chỗ hoặc đặt trước.',
      );
    }

    final data = <String, dynamic>{
      'court_id': courtId,
      'court_unit_id': courtUnitId,
      'user_id': userId,
      'start_time': _formatDate(startTime),
      'end_time': _formatDate(endTime),
      'status': 'locked',
      'locked_until': _formatDate(DateTime.now().add(holdDuration)),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    try {
      final record = await pb.collection(collection).create(body: data);
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw CourtBookingServiceException(_mapClientException(error));
    } catch (_) {
      throw CourtBookingServiceException(
        'Không thể giữ chỗ cho khung giờ này. Vui lòng thử lại sau.',
      );
    }
  }

  Future<CourtBooking> confirmBooking(
    String bookingId, {
    String? note,
  }) async {
    final pb = await getPocketbaseInstance();
    final data = <String, dynamic>{
      'status': 'pending',
      'locked_until': null,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    try {
      final record = await pb.collection(collection).update(
            bookingId,
            body: data,
          );
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw CourtBookingServiceException(_mapClientException(error));
    } catch (_) {
      throw CourtBookingServiceException(
        'Không thể gửi yêu cầu đặt sân. Vui lòng thử lại sau.',
      );
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final pb = await getPocketbaseInstance();
    try {
      await pb.collection(collection).update(
        bookingId,
        body: {
          'status': 'cancelled',
        },
      );
    } on ClientException catch (error) {
      throw CourtBookingServiceException(_mapClientException(error));
    } catch (_) {
      throw CourtBookingServiceException(
        'Không thể hủy giữ chỗ. Vui lòng thử lại sau.',
      );
    }
  }

  Future<int> _countOverlappingBookings(
    PocketBase pb, {
    required String courtUnitId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final now = DateTime.now().toUtc();
    final filter = [
      "court_unit_id='${_escapeFilterValue(courtUnitId)}'",
      "start_time < '${_formatDate(endTime)}'",
      "end_time > '${_formatDate(startTime)}'",
      "(status='pending' || status='confirmed' || (status='locked' && locked_until >= '${_formatDate(now)}'))",
    ].join(' && ');

    final result = await pb.collection(collection).getList(
          filter: filter,
          perPage: 1,
        );
    return result.items.length;
  }

  String _mapClientException(ClientException error) {
    final data = error.response;
    if (data != null) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    return 'Có lỗi xảy ra. Vui lòng thử lại sau.';
  }
}

String _formatDate(DateTime date) {
  return date.toUtc().toIso8601String();
}

String _escapeFilterValue(String value) {
  return value.replaceAll("'", "\\'");
}
