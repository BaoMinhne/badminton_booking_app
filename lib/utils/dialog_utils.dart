import 'package:flutter/material.dart';

/// Hiển thị dialog xác nhận Yes/No.
/// Trả về true nếu chọn Yes, ngược lại false.
Future<bool> showConfirmDialog(BuildContext context, String message,
    {String title = 'Xác nhận'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(Icons.help_outline,
          size: 40, color: Theme.of(context).colorScheme.primary),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
      content: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Đồng ý'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Hiển thị dialog báo lỗi.
Future<void> showErrorDialog(BuildContext context, String message,
    {String title = 'Đã xảy ra lỗi'}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.error, size: 40, color: Colors.redAccent),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent)),
      content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

/// Hiển thị dialog thông báo thành công.
Future<void> showSuccessDialog(BuildContext context, String message,
    {String title = 'Thành công'}) {
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.check_circle, size: 40, color: Colors.green),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
      content: Text(message, style: Theme.of(context).textTheme.bodyLarge),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
