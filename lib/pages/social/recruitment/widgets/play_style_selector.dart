import 'package:flutter/material.dart';

class PlayStyleSelector extends StatelessWidget {
  final List<String> playStyles;
  final String selectedStyle;
  final ValueChanged<String> onChanged;

  const PlayStyleSelector({
    super.key,
    required this.playStyles,
    required this.selectedStyle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lối chơi muốn tuyển', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: playStyles.map((style) {
            final isSelected = selectedStyle == style;
            return ChoiceChip(
              label: Text(style),
              selected: isSelected,
              onSelected: (_) => onChanged(style),
              selectedColor: cs.primaryContainer,
              labelStyle: textTheme.bodyMedium?.copyWith(
                color: isSelected ? cs.primary : cs.onSurface,
                fontWeight: isSelected ? FontWeight.bold : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
