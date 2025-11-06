import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CourtOption {
  final String id;
  final String name;

  const CourtOption({
    required this.id,
    required this.name,
  });
}

class CourtInfoSection extends StatelessWidget {
  final String? selectedCourtId;
  final List<CourtOption> availableCourts;
  final DateTime selectedDateTime;
  final ValueChanged<String?> onCourtChanged;
  final VoidCallback onPickDateTime;

  const CourtInfoSection({
    super.key,
    required this.selectedCourtId,
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
          value: selectedCourtId,
          decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
          items: availableCourts
              .map(
                (court) => DropdownMenuItem(
                  value: court.id,
                  child: Text(court.name),
                ),
              )
              .toList(),
          onChanged: onCourtChanged,
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
