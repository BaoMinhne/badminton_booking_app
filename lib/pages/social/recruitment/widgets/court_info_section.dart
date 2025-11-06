import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/booked_court_option.dart';

class CourtInfoSection extends StatelessWidget {
  final BookedCourtOption? selectedBooking;
  final List<BookedCourtOption> availableBookings;
  final DateTime selectedDateTime;
  final ValueChanged<BookedCourtOption?> onBookingChanged;
  final VoidCallback onPickDateTime;

  const CourtInfoSection({
    super.key,
    required this.selectedBooking,
    required this.availableBookings,
    required this.selectedDateTime,
    required this.onBookingChanged,
    required this.onPickDateTime,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin sân đã đặt', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        DropdownButtonFormField<BookedCourtOption>(
          value: selectedBooking,
          decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
          items: availableBookings
              .map(
                (booking) => DropdownMenuItem<BookedCourtOption>(
                  value: booking,
                  child: Text(
                    booking.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged:
              availableBookings.isEmpty ? null : (value) => onBookingChanged(value),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onPickDateTime,
          child: InputDecorator(
            decoration: _inputDecoration(cs, 'Giờ đánh dự kiến'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(DateFormat('HH:mm - dd/MM/yyyy').format(selectedDateTime)),
                const Icon(Icons.calendar_month_outlined),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(ColorScheme cs, String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
