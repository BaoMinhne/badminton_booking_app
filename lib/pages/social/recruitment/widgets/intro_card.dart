import 'package:flutter/material.dart';

class IntroCard extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme textTheme;

  const IntroCard({
    super.key,
    required this.cs,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.groups_2_rounded, color: cs.onPrimary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Tạo bài đăng để tuyển thành viên phù hợp.',
              style:
                  textTheme.bodyMedium?.copyWith(color: cs.onPrimaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
