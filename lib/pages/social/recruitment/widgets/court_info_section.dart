import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CourtInfoSection extends StatelessWidget {
  final String selectedCourt;
  final List<String> availableCourts;
  final DateTime selectedDateTime;
  final ValueChanged<String> onCourtChanged;
  final VoidCallback onPickDateTime;

  const CourtInfoSection({
    super.key,
    required this.selectedCourt,
    required this.availableCourts,
    required this.selectedDateTime,
    required this.onCourtChanged,
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
        DropdownButtonFormField<String>(
          value: selectedCourt,
          decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
          items: availableCourts
              .map(
                  (court) => DropdownMenuItem(value: court, child: Text(court)))
              .toList(),
          onChanged: (v) => v != null ? onCourtChanged(v) : null,
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
