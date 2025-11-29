import 'package:pocketbase/pocketbase.dart';

import 'booking_service.dart';
import 'pocketbase_client.dart';

class BookingRealtimeService {
  RealtimeSubscription? _subscription;

  Future<void> subscribeToBookings({
    required String courtId,
    required DateTime date,
    required void Function(RealtimeEvent event) onChange,
  }) async {
    final pb = await getPocketbaseInstance();
    await unsubscribe();

    final dayStart = DateTime(date.year, date.month, date.day).toUtc();
    final dayEnd = dayStart.add(const Duration(days: 1));

    final escapedCourt = _escapeFilterValue(courtId);
    final filter =
        "court_id='$escapedCourt' && start_time < '${dayEnd.toIso8601String()}' && end_time > '${dayStart.toIso8601String()}'";

    _subscription = await pb.collection(BookingService.collection).subscribe(
      filter,
      (event) => onChange(event),
    );
  }

  Future<void> unsubscribe() async {
    if (_subscription == null) return;
    final pb = await getPocketbaseInstance();
    await pb.collection(BookingService.collection).unsubscribe(_subscription!);
    _subscription = null;
  }

  Future<void> dispose() async {
    await unsubscribe();
  }

  String _escapeFilterValue(String value) {
    return value.replaceAll("'", "\\'");
  }
}
