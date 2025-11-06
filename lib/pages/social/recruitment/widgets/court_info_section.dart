import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../services/recruitment_service.dart';

class CourtInfoSection extends StatelessWidget {
  const CourtInfoSection({
    super.key,
    required this.selectedCourtId,
    required this.availableCourts,
    required this.selectedDateTime,
    required this.onCourtChanged,
    required this.onPickDateTime,
    this.message,
  });

  final String? selectedCourtId;
  final List<BookedCourtOption> availableCourts;
  final DateTime selectedDateTime;
  final ValueChanged<String?> onCourtChanged;
  final VoidCallback onPickDateTime;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Thông tin sân đã đặt', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        if (availableCourts.isEmpty)
          _EmptyCourtMessage(message: message)
        else
          DropdownButtonFormField<String>(
            value: selectedCourtId,
            decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
            items: availableCourts
                .map(
                  (court) => DropdownMenuItem(
                    value: court.id,
                    child: Text(
                      court.displayName,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _EmptyCourtMessage extends StatelessWidget {
  const _EmptyCourtMessage({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final resolvedMessage = message ??
        'Bạn chưa có sân trong ngày đã chọn. Vui lòng kiểm tra lại lịch đặt sân.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              resolvedMessage,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
