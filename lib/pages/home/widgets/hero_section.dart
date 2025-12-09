import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onCtaPressed;

  const HeroSection({super.key, required this.onCtaPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primaryContainer.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flash_on_rounded, color: cs.onPrimary, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Đặt sân cầu lông siêu tốc',
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Ưu đãi giữ sân tức thì, xác nhận nhanh trong 1 phút cho mọi khung giờ bận rộn.',
              style: textTheme.bodyMedium?.copyWith(
                color: cs.onPrimary.withOpacity(0.9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onCtaPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.onPrimary,
                  foregroundColor: cs.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.sports_tennis_rounded),
                label: const Text(
                  'Đặt sân ngay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoPill(
                  icon: Icons.access_time_rounded,
                  label: 'Giờ mở cửa',
                  value: '06:00 - 23:30 hằng ngày',
                  foreground: cs.onPrimary,
                  background: cs.onPrimary.withOpacity(0.12),
                ),
                const SizedBox(width: 12),
                _InfoPill(
                  icon: Icons.call_rounded,
                  label: 'Hotline',
                  value: '1900 636 979',
                  foreground: cs.onPrimary,
                  background: cs.onPrimary.withOpacity(0.12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color foreground;
  final Color background;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: foreground.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground.withOpacity(0.8),
                          letterSpacing: 0.1,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
