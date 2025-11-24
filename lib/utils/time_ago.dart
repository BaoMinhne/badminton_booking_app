String formatRelativeTime(DateTime time) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inDays >= 365) {
    final years = (diff.inDays / 365).floor();
    return '$years năm';
  }

  if (diff.inDays >= 30) {
    final months = (diff.inDays / 30).floor();
    return '$months tháng';
  }

  if (diff.inDays >= 7) {
    final weeks = (diff.inDays / 7).floor();
    return '$weeks tuần';
  }

  if (diff.inDays >= 1) {
    return '${diff.inDays} ngày';
  }

  if (diff.inHours >= 1) {
    return '${diff.inHours} giờ';
  }

  if (diff.inMinutes >= 1) {
    return '${diff.inMinutes} phút';
  }

  return 'Vừa xong';
}
