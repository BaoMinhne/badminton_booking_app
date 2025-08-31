import 'package:flutter/material.dart';

class Rules extends StatelessWidget {
  final String title;
  final List<String> items;
  const Rules({
    super.key,
    this.title = "Điều khoản & Quy định",
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),

        // Khung gọn gàng
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            children: [
              for (final t in items) _bulletTile(context, t),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _bulletTile(BuildContext context, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // bullet tròn nhỏ
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration:
                BoxDecoration(color: cs.primary, shape: BoxShape.rectangle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.35)),
          ),
        ],
      ),
    );
  }
}
