import 'package:flutter/material.dart';

class PlayStyleOption {
  final String value;
  final String label;

  const PlayStyleOption({
    required this.value,
    required this.label,
  });
}

class PlayStyleSelector extends StatelessWidget {
  final List<PlayStyleOption> playStyles;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const PlayStyleSelector({
    super.key,
    required this.playStyles,
    required this.selectedValue,
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
            final isSelected = selectedValue == style.value;
            return ChoiceChip(
              label: Text(style.label),
              selected: isSelected,
              onSelected: (_) => onChanged(style.value),
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
