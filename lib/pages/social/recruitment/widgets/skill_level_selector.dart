import 'package:flutter/material.dart';

class SkillLevelOption {
  final String value;
  final String label;

  const SkillLevelOption({
    required this.value,
    required this.label,
  });
}

class SkillLevelSelector extends StatelessWidget {
  final List<SkillLevelOption> skillLevels;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const SkillLevelSelector({
    super.key,
    required this.skillLevels,
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
        Text('Trình độ mong muốn', style: textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: skillLevels.map((level) {
            final isSelected = selectedValue == level.value;
            return ChoiceChip(
              label: Text(level.label),
              selected: isSelected,
              onSelected: (_) => onChanged(level.value),
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
