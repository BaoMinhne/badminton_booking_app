import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/booking.dart';
import '../models/user_booking_view.dart';

class UserBookingTile extends StatelessWidget {
  const UserBookingTile({
    super.key,
    required this.bookingView,
  });

  final UserBookingView bookingView;

  @override
  Widget build(BuildContext context) {
    final booking = bookingView.booking;
    final colorScheme = Theme.of(context).colorScheme;

    final courtName = bookingView.courtName ?? 'Sân chưa xác định';
    final courtLocation = bookingView.courtLocation ?? 'Đang cập nhật địa điểm';
    final courtUnitLabel = bookingView.courtUnitLabel != null &&
            bookingView.courtUnitLabel!.isNotEmpty
        ? bookingView.courtUnitLabel!
        : booking.courtUnitId;

    final dateText = _formatDate(booking.startTime.toLocal());
    final timeRangeText = _formatTimeRange(
      booking.startTime.toLocal(),
      booking.endTime.toLocal(),
    );

    final statusLabel = _mapStatusToLabel(booking.status);
    final statusColor = _mapStatusToColor(booking.status, colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildCourtThumbnail(context),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courtName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          courtLocation,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeRangeText,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.sports_tennis, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sân: $courtUnitLabel',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourtThumbnail(BuildContext context) {
    final placeholder = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.sports_tennis,
        color: Theme.of(context).colorScheme.primary,
      ),
    );

    final imageUrl = bookingView.courtCoverImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return DateFormat('EEEE, dd/MM/yyyy', 'vi_VN').format(date);
}

String _formatTimeRange(DateTime start, DateTime end) {
  final formatter = DateFormat('HH:mm', 'vi_VN');
  return '${formatter.format(start)} - ${formatter.format(end)}';
}

String _mapStatusToLabel(BookingStatus status) {
  switch (status) {
    case BookingStatus.held:
      return 'Đang giữ chỗ';
    case BookingStatus.awaitingPayment:
      return 'Chờ thanh toán';
    case BookingStatus.confirmed:
      return 'Đã xác nhận';
    case BookingStatus.cancelled:
      return 'Đã hủy';
    case BookingStatus.expired:
      return 'Hết hạn';
  }
}

Color _mapStatusToColor(BookingStatus status, ColorScheme colorScheme) {
  switch (status) {
    case BookingStatus.held:
      return colorScheme.tertiary;
    case BookingStatus.awaitingPayment:
      return colorScheme.secondary;
    case BookingStatus.confirmed:
      return const Color(0xFF2E7D32);
    case BookingStatus.cancelled:
      return const Color(0xFFC62828);
    case BookingStatus.expired:
      return Colors.grey.shade700;
  }
}
