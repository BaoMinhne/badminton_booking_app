import 'package:pocketbase/pocketbase.dart';

import '../models/booking.dart';
import 'pocketbase_client.dart';

class BookingServiceException implements Exception {
  BookingServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BookingRealtimeSubscription {
  BookingRealtimeSubscription(this._cancel);

  final Future<void> Function() _cancel;

  Future<void> cancel() async {
    try {
      await _cancel();
    } catch (_) {
      // Ignore cancellation errors to keep the UI stable.
    }
  }
}

class BookingService {
  static const collection = 'court_bookings';

  Future<List<CourtBooking>> listBookings({
    required String courtId,
    required DateTime date,
  }) async {
    final pb = await getPocketbaseInstance();
    final filter = _buildDailyCourtFilter(courtId: courtId, date: date);

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

  Future<BookingRealtimeSubscription> subscribeToBookings({
    required String courtId,
    required DateTime date,
    required void Function(List<CourtBooking> bookings) onData,
    void Function(Object error)? onError,
    bool emitInitial = true,
  }) async {
    final pb = await getPocketbaseInstance();
    final filter = _buildDailyCourtFilter(courtId: courtId, date: date);

    var isFetching = false;

    Future<void> loadLatest() async {
      if (isFetching) return;
      isFetching = true;
      try {
        final bookings = await listBookings(courtId: courtId, date: date);
        onData(bookings);
      } catch (error) {
        onError?.call(error);
      } finally {
        isFetching = false;
      }
    }

    if (emitInitial) {
      await loadLatest();
    }

    final subscription = await pb.collection(collection).subscribe(
      '*',
      (_) async {
        await loadLatest();
      },
      filter: filter,
    );

    return BookingRealtimeSubscription(() async {
      try {
        final dynamic sub = subscription;
        final collectionApi = pb.collection(collection);

        try {
          final dynamic maybeUnsubscribe = sub.unsubscribe;
          if (maybeUnsubscribe is Future<void> Function()) {
            await maybeUnsubscribe();
            return;
          }
        } catch (_) {
          // ignore and try other strategies
        }

        if (sub is Future<void> Function()) {
          await sub();
          return;
        }

        try {
          final dynamic maybeId = sub.id;
          if (maybeId is String && maybeId.isNotEmpty) {
            await collectionApi.unsubscribe(maybeId);
            return;
          }
        } catch (_) {
          // ignore and try other strategies
        }

        if (sub is String) {
          await collectionApi.unsubscribe(sub);
          return;
        }

        await collectionApi.unsubscribe('*');
      } catch (_) {
        try {
          await pb.collection(collection).unsubscribe('*');
        } catch (_) {}
      }
    });
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
      'status': 'held',
      'locked_until': lockedUntil.toIso8601String(),
    };

    try {
      await _ensureNoConflictingBookings(
        pb: pb,
        courtId: courtId,
        courtUnitId: courtUnitId,
        startTime: startTime,
        endTime: endTime,
      );
      final record = await pb.collection(collection).create(body: body);
      return CourtBooking.fromRecord(record);
    } on BookingServiceException {
      rethrow;
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException('Không thể giữ chỗ. Vui lòng thử lại.');
    }
  }

  /// Huỷ giữ chỗ (xoá bản ghi). Giữ nguyên hành vi cũ.
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

  /// CHANGED: chuyển trạng thái từ 'held' -> 'awaiting_payment'
  /// (trước đây là 'pending')
  Future<CourtBooking> submitForApproval(String bookingId) async {
    final pb = await getPocketbaseInstance();
    try {
      final record = await pb.collection(collection).update(bookingId, body: {
        'status': 'awaiting_payment', // CHANGED
        'locked_until': null, // bỏ khoá tạm khi sang chờ thanh toán
      });
      return CourtBooking.fromRecord(record);
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
          'Không thể chuyển sang chờ thanh toán. Vui lòng thử lại.');
    }
  }

  /// Xác nhận sau khi thanh toán thành công.
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

  Future<void> _ensureNoConflictingBookings({
    required PocketBase pb,
    required String courtId,
    required String courtUnitId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final startIso = startTime.toUtc().toIso8601String();
    final endIso = endTime.toUtc().toIso8601String();
    final escapedCourt = _escapeFilterValue(courtId);
    final escapedUnit = _escapeFilterValue(courtUnitId);

    final filter =
        "court_id='$escapedCourt' && court_unit_id='$escapedUnit' && start_time < '$endIso' && end_time > '$startIso' && status != 'cancelled' && status != 'expired'";

    try {
      final result = await pb.collection(collection).getList(
            page: 1,
            perPage: 200,
            filter: filter,
          );

      final now = DateTime.now().toUtc();
      for (final record in result.items) {
        final booking = CourtBooking.fromRecord(record);

        final isBlockingStatus = booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.awaitingPayment ||
            (booking.status == BookingStatus.held &&
                (booking.lockedUntil == null ||
                    booking.lockedUntil!.isAfter(now)));

        if (isBlockingStatus) {
          throw BookingServiceException(
            'Khung giờ này đã có lượt đặt khác. Vui lòng chọn thời gian khác.',
          );
        }
      }
    } on BookingServiceException {
      rethrow;
    } on ClientException catch (error) {
      throw BookingServiceException(_mapClientException(error));
    } catch (_) {
      throw BookingServiceException(
        'Không thể kiểm tra tình trạng sân. Vui lòng thử lại.',
      );
    }
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }

  String _buildDailyCourtFilter({
    required String courtId,
    required DateTime date,
  }) {
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));
    final escapedCourt = _escapeFilterValue(courtId);
    return "court_id='$escapedCourt' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";
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
}
