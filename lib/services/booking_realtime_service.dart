import 'package:pocketbase/pocketbase.dart';

import 'booking_service.dart';
import 'pocketbase_client.dart';

class BookingRealtimeService {
  /// Hàm hủy subscribe do PocketBase trả về
  UnsubscribeFunc? _unsubscribe;

  Future<void> subscribeToBookings({
    required String courtId,
    required DateTime date,
    required void Function(RecordSubscriptionEvent event) onChange,
  }) async {
    final pb = await getPocketbaseInstance();

    // Hủy đăng ký cũ (nếu có)
    await unsubscribe();

    // Tính khoảng thời gian trong ngày
    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Filter theo sân + khoảng thời gian trong ngày
    final escapedCourt = _escapeFilterValue(courtId);
    final filter =
        "court_id='$escapedCourt' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";

    // SDK mới: topic là '*', filter truyền qua named param
    _unsubscribe = await pb.collection(BookingService.collection).subscribe(
          '*', // lắng nghe tất cả record của collection này
          (event) => onChange(event),
          filter: filter,
        );
  }

  Future<void> unsubscribe() async {
    final unsub = _unsubscribe;
    _unsubscribe = null;
    if (unsub != null) {
      await unsub(); // gọi hàm hủy do PocketBase trả về
    }
  }

  Future<void> dispose() async {
    await unsubscribe();
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }
}
