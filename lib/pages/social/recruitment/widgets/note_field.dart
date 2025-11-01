import 'package:flutter/material.dart';

class NoteField extends StatelessWidget {
  final TextEditingController controller;
  const NoteField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ghi chú cho thành viên', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'Ví dụ: Mang theo vợt cá nhân, đến sớm 10 phút để khởi động...',
            filled: true,
            fillColor: cs.surfaceVariant.withOpacity(0.6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
