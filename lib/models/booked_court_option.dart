import 'package:intl/intl.dart';

import 'user_booking_view.dart';

class BookedCourtOption {
  BookedCourtOption({
    required this.bookingId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    this.courtName,
    this.courtUnitLabel,
  });

  factory BookedCourtOption.fromUserBooking(UserBookingView view) {
    return BookedCourtOption(
      bookingId: view.booking.id,
      courtId: view.booking.courtId,
      startTime: view.booking.startTime.toLocal(),
      endTime: view.booking.endTime.toLocal(),
      courtName: view.courtName,
      courtUnitLabel: view.courtUnitLabel,
    );
  }

  final String bookingId;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final String? courtName;
  final String? courtUnitLabel;

  String get label {
    final courtDisplay = [courtName, courtUnitLabel]
        .where((value) => value != null && value!.trim().isNotEmpty)
        .map((value) => value!.trim())
        .join(' • ');
    final formatter = DateFormat('HH:mm');
    final timeRange = '${formatter.format(startTime)} - ${formatter.format(endTime)}';
    if (courtDisplay.isEmpty) {
      return timeRange;
    }
    return '$courtDisplay • $timeRange';
  }
}
