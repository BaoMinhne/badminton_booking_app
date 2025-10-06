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
    final filter = "court_id='${_escapeFilterValue(courtId)}' && "
        "end_time>'${startOfDay.toUtc().toIso8601String()}' && "
        "start_time<'${endOfDay.toUtc().toIso8601String()}'";

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

    final model = pb.authStore.record;
    if (!pb.authStore.isValid || model == null) {
      throw BookingServiceException('Bạn cần đăng nhập để đặt sân.');
    }

    final userId = model.id;

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
