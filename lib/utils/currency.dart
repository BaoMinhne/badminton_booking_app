String formatVND(num value) {
  final s = value.toStringAsFixed(0);
  final rev = s.split('').reversed.toList();
  final out = <String>[];
  for (int i = 0; i < rev.length; i++) {
    out.add(rev[i]);
    if ((i + 1) % 3 == 0 && i + 1 != rev.length) out.add('.');
  }
  return out.reversed.join() + 'đ';
}
