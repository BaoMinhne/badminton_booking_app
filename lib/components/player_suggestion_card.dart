import 'package:flutter/material.dart';

class PlayerSuggestionCard extends StatelessWidget {
  const PlayerSuggestionCard({
    super.key,
    required this.name,
    required this.level,
    required this.matchScore,
    required this.playTags,
    required this.intensityLabel,
    required this.onProfileTap,
    required this.onInviteTap,
    this.avatarColor,
    this.avatarInitial,
  });

  final String name;
  final String level;
  final int matchScore;
  final List<String> playTags;
  final String intensityLabel;
  final Color? avatarColor;
  final String? avatarInitial;
  final VoidCallback onProfileTap;
  final VoidCallback onInviteTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: avatarColor ?? cs.primary.withOpacity(0.15),
                child: Text(
                  (avatarInitial ?? name[0]).toUpperCase(),
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Match: $matchScore%',
                            style: tt.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star_rate_rounded,
                            size: 18, color: cs.secondary),
                        const SizedBox(width: 6),
                        Text(
                          level,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...playTags.map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: cs.secondaryContainer,
                            side: BorderSide(
                              color: cs.secondaryContainer.withOpacity(0.4),
                            ),
                            labelStyle: tt.labelMedium?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Chip(
                          avatar: Icon(Icons.local_fire_department_rounded,
                              color: cs.onTertiary, size: 18),
                          label: Text('Intensity: $intensityLabel'),
                          backgroundColor: cs.tertiaryContainer,
                          labelStyle: tt.labelMedium?.copyWith(
                            color: cs.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onProfileTap,
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Xem hồ sơ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onInviteTap,
                  icon: const Icon(Icons.handshake_rounded, size: 18),
                  label: const Text('Gửi lời mời'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
