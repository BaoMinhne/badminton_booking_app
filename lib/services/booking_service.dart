import 'package:pocketbase/pocketbase.dart';

import '../models/court_booking.dart';
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
    required DateTime day,
    int perPage = 200,
  }) async {
    final pb = await getPocketbaseInstance();
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final filter = "court_id='${_escapeFilterValue(courtId)}' && "
        "end_time>'${startOfDay.toUtc().toIso8601String()}' && "
        "start_time<'${endOfDay.toUtc().toIso8601String()}' && "
        "(status!='locked' || locked_until = null || locked_until>'$nowIso')";

    try {
      final result = await pb.collection(collection).getList(
            filter: filter,
            perPage: perPage,
          );
      return result.items
          .map((record) => CourtBooking.fromRecord(record))
          .toList(growable: false);
    } on ClientException catch (error) {
      throw BookingServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tải lịch đặt sân. Vui lòng thử lại sau.',
        ),
      );
    } catch (_) {
      throw BookingServiceException(
        'Có lỗi xảy ra khi tải lịch đặt sân. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtBooking> createBooking({
    required String courtId,
    required String courtUnitId,
    required DateTime startTime,
    required DateTime endTime,
    String status = 'pending',
    String? note,
  }) async {
    final pb = await getPocketbaseInstance();
    final user = _requireAuth(pb, message: 'Bạn cần đăng nhập để đặt sân.');
    final userId = user.id;

    try {
      final record = await pb.collection(collection).create(body: {
        'court_id': courtId,
        'court_unit_id': courtUnitId,
        'user_id': userId,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'status': status,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });

      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể tạo đặt sân mới. Vui lòng thử lại sau.',
        ),
      );
    } catch (_) {
      throw BookingServiceException(
        'Đã xảy ra lỗi khi tạo đặt sân. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtBooking> lockSlot({
    String? bookingId,
    required String courtId,
    required String courtUnitId,
    required DateTime startTime,
    required DateTime endTime,
    Duration holdDuration = const Duration(minutes: 15),
  }) async {
    final pb = await getPocketbaseInstance();
    final user = _requireAuth(pb, message: 'Bạn cần đăng nhập để giữ chỗ.');

    final lockUntil = DateTime.now().toUtc().add(holdDuration);
    final body = {
      'court_id': courtId,
      'court_unit_id': courtUnitId,
      'user_id': user.id,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'status': 'locked',
      'locked_until': lockUntil.toIso8601String(),
    };

    try {
      final collectionApi = pb.collection(collection);
      final record = bookingId == null
          ? await collectionApi.create(body: body)
          : await collectionApi.update(bookingId, body: body);
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(
        _mapClientException(
          error,
          fallback:
              'Không thể giữ chỗ cho khung giờ đã chọn. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw BookingServiceException(
        'Đã xảy ra lỗi khi giữ chỗ. Vui lòng thử lại.',
      );
    }
  }

  Future<CourtBooking> confirmBooking({
    required String bookingId,
    String? note,
  }) async {
    final pb = await getPocketbaseInstance();
    _requireAuth(pb, message: 'Phiên đăng nhập đã hết hạn.');

    try {
      final record = await pb.collection(collection).update(bookingId, body: {
        'status': 'pending',
        'locked_until': null,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      });
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể gửi yêu cầu đặt sân. Vui lòng thử lại sau.',
        ),
      );
    } catch (_) {
      throw BookingServiceException(
        'Đã xảy ra lỗi khi gửi yêu cầu đặt sân. Vui lòng thử lại.',
      );
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    final pb = await getPocketbaseInstance();

    try {
      await pb.collection(collection).update(bookingId, body: {
        'status': 'cancelled',
        'locked_until': null,
      });
    } on ClientException catch (error) {
      throw BookingServiceException(
        _mapClientException(
          error,
          fallback: 'Không thể huỷ giữ chỗ. Vui lòng thử lại.',
        ),
      );
    } catch (_) {
      throw BookingServiceException(
        'Đã xảy ra lỗi khi huỷ giữ chỗ. Vui lòng thử lại.',
      );
    }
  }

  RecordModel _requireAuth(PocketBase pb, {String? message}) {
    final record = pb.authStore.record;
    if (!pb.authStore.isValid || record == null) {
      throw BookingServiceException(
        message ?? 'Bạn cần đăng nhập để thực hiện thao tác này.',
      );
    }
    return record;
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }

  String _mapClientException(
    ClientException error, {
    required String fallback,
  }) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return 'Phiên đăng nhập đã hết hạn hoặc bạn không có quyền thực hiện thao tác này.';
    }

    final response = error.response;
    if (response is Map<String, dynamic>) {
      final message = response['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final buffer = StringBuffer();
        data.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            final detail = value['message'];
            if (detail is String && detail.trim().isNotEmpty) {
              if (buffer.isNotEmpty) buffer.writeln();
              buffer.write(detail.trim());
            }
          }
        });

        if (buffer.isNotEmpty) {
          return buffer.toString();
        }
      }
    }

    final rawMessage = error.toString();
    final colonIndex = rawMessage.indexOf(':');
    if (colonIndex != -1 && colonIndex + 1 < rawMessage.length) {
      final candidate = rawMessage.substring(colonIndex + 1).trim();
      if (candidate.isNotEmpty) {
        return candidate;
      }
    }

    return fallback;
  }
}
