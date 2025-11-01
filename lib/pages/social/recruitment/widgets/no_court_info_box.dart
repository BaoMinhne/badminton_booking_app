import 'package:flutter/material.dart';

class NoCourtInfoBox extends StatelessWidget {
  const NoCourtInfoBox({super.key});

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
              'Bạn chưa đặt sân — hãy nhập số lượng thành viên bạn muốn tuyển và mô tả yêu cầu để mọi người cùng tham gia.',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
