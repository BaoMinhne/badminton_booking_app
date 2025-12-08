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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceVariant.withOpacity(0.6),
            cs.surfaceVariant.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_tennis, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin sân đã đặt',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chọn sân bạn đã đặt và thời gian phù hợp.',
                    style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (availableCourts.isEmpty)
            _EmptyCourtMessage(message: message)
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant.withOpacity(0.8)),
              ),
              child: DropdownButtonFormField<String>(
                value: selectedCourtId,
                isExpanded: true,
                decoration: _inputDecoration(cs, 'Chọn sân đã đặt'),
                items: availableCourts
                    .map<DropdownMenuItem<String>>(
                      (court) => DropdownMenuItem<String>(
                        value: court.id,
                        child: Tooltip(
                          message: court.displayName,
                          preferBelow: false,
                          child: Text(
                            court.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: onCourtChanged,
              ),
            ),
        ],
      ),
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
