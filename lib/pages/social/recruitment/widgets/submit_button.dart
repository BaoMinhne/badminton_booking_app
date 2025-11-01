import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  final VoidCallback onSubmit;

  const SubmitButton({
    super.key,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FilledButton.icon(
      onPressed: onSubmit,
      icon: const Icon(Icons.send_rounded),
      label: const Text('Đăng bài tuyển thành viên'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
