import 'package:flutter/material.dart';

class MemberInputSection extends StatelessWidget {
  final int memberCount;
  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  const MemberInputSection({
    super.key,
    required this.memberCount,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (memberCount > 1) {
                  onChanged(memberCount - 1);
                }
              },
              icon: const Icon(Icons.remove_circle_outline),
            ),
            SizedBox(
              width: 90,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceVariant.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  onChanged((parsed == null || parsed <= 0) ? 1 : parsed);
                },
              ),
            ),
            IconButton(
              onPressed: () {
                onChanged(memberCount + 1);
              },
              icon: const Icon(Icons.add_circle_outline),
            ),
            const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Enter the number of members you want to recruit.',
                  style:
                      textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: cs.primary,
                child: Icon(Icons.people_alt_rounded, color: cs.onPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Need $memberCount more member${memberCount > 1 ? 's' : ''}',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
