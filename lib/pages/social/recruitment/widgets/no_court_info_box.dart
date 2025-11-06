import 'package:flutter/material.dart';

class NoCourtInfoBox extends StatelessWidget {
  final String message;

  const NoCourtInfoBox({
    super.key,
    this.message =
        'Bạn chưa đặt sân — hãy nhập số lượng thành viên bạn muốn tuyển và mô tả yêu cầu để mọi người cùng tham gia.',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: cs.primary,
            child: Icon(Icons.group_add, color: cs.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
