import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../models/court_detail.dart';

int? parseTimeToMinutes(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return hour * 60 + minute;
}

double calculateSlotPrice(
  CourtDetailData detail,
  SelectedSlot slot,
  Duration slotDuration,
) {
  final pricing = detail.pricing;
  if (pricing.isEmpty) return 0;
  final start = slot.startTime.toLocal();
  final minutes = start.hour * 60 + start.minute;
  final durationMinutes =
      slot.endTime.difference(slot.startTime).inMinutes.toDouble();

  for (final item in pricing) {
    final from = parseTimeToMinutes(item.timeFrom);
    final to = parseTimeToMinutes(item.timeTo);
    if (from == null || to == null || item.pricePerHour == null) {
      continue;
    }
    if (minutes >= from && minutes < to) {
      return item.pricePerHour! * (durationMinutes / 60.0);
    }
  }

  final fallback = pricing.firstWhere(
    (item) => item.pricePerHour != null,
    orElse: () => pricing.first,
  );
  return (fallback.pricePerHour ?? 0) * (durationMinutes / 60.0);
}

String formatCurrency(num value) {
  final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  return formatter.format(value);
}
