import 'package:pocketbase/pocketbase.dart';

import '../models/booking.dart';
import 'pocketbase_client.dart';

class BookingServiceException implements Exception {
  BookingServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookingService {
  static const collection = 'court_bookings';

  Future<List<CourtBooking>> listBookings({
    required String courtId,
    required DateTime date,
  }) async {
    final pb = await getPocketbaseInstance();

    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final escapedCourt = _escapeFilterValue(courtId);
    final filter = "court_id='$escapedCourt' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";

    try {
      final result = await pb.collection(collection).getList(
            filter: filter,
            perPage: 200,
          );
      return result.items
          .map(CourtBooking.fromRecord)
          .where((booking) => booking.courtId == courtId)
          .toList(growable: false);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
          'Không thể tải lịch đặt sân. Vui lòng thử lại sau.');
    }
  }

  Future<CourtBooking> lockSlot({
    required String courtId,
    required String courtUnitId,
    required String userId,
    required DateTime startTime,
    required DateTime endTime,
    Duration holdDuration = const Duration(minutes: 15),
  }) async {
    final pb = await getPocketbaseInstance();

    final now = DateTime.now().toUtc();
    final lockedUntil = now.add(holdDuration);

    final body = {
      'court_id': courtId,
      'court_unit_id': courtUnitId,
      'user_id': userId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'locked',
      'locked_until': lockedUntil.toIso8601String(),
    };

    try {
      final record = await pb.collection(collection).create(body: body);
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException('Không thể giữ chỗ. Vui lòng thử lại.');
    }
  }

  Future<void> releaseBooking(String bookingId) async {
    final pb = await getPocketbaseInstance();
    try {
      await pb.collection(collection).delete(bookingId);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException('Không thể hủy giữ chỗ. Vui lòng thử lại.');
    }
  }

  Future<CourtBooking> submitForApproval(String bookingId) async {
    final pb = await getPocketbaseInstance();
    try {
      final record = await pb.collection(collection).update(bookingId, body: {
        'status': 'pending',
        'locked_until': null,
      });
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
          'Không thể gửi yêu cầu đặt sân. Vui lòng thử lại.');
    }
  }

  Future<CourtBooking> markAsConfirmed(String bookingId) async {
    final pb = await getPocketbaseInstance();
    try {
      final record = await pb.collection(collection).update(bookingId, body: {
        'status': 'confirmed',
        'locked_until': null,
      });
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
          'Không thể xác nhận đặt sân. Vui lòng thử lại.');
    }
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
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
    return error.message ?? 'Đã xảy ra lỗi. Vui lòng thử lại.';
  }
}
