import 'package:flutter/material.dart';
import '../../../../services/recruitment_service.dart';

class CourtInfoSection extends StatelessWidget {
  const CourtInfoSection({
    super.key,
    required this.selectedCourtId,
    required this.availableCourts,
    required this.onCourtChanged,
    this.message,
  });

  final String? selectedCourtId;
  final List<BookedCourtOption> availableCourts;
  final ValueChanged<String?> onCourtChanged;
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
            isExpanded:
                true, // Thêm để chiếm hết chiều rộng, tránh overflow do giới hạn width
            decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
            items: availableCourts
                .map<DropdownMenuItem<String>>(
                  (court) => DropdownMenuItem<String>(
                    value: court.id,
                    child: Tooltip(
                      message: court.displayName,
                      preferBelow:
                          false, // Ưu tiên hiển thị tooltip ở trên để tránh che UI dưới
                      child: Text(
                        court.displayName,
                        maxLines: 2, // Cho phép wrap thành 2 dòng nếu text dài
                        overflow: TextOverflow.ellipsis,
                        softWrap: true, // Kích hoạt wrap text
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: onCourtChanged,
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
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12), // Tăng padding để text có không gian wrap
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
