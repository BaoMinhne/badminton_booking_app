import 'package:flutter/material.dart';

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final VoidCallback onSubmit;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FilledButton.icon(
      onPressed: isLoading ? null : onSubmit,
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : const Icon(Icons.send_rounded),
      label: Text(isLoading ? 'Đang đăng...' : 'Đăng bài tuyển thành viên'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
