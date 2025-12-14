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
    required this.onDismiss,
    this.onTap,
    this.avatarColor,
    this.avatarInitial,

    // NEW: kiểm soát khoảng cách ngoài (để card không dính nhau)
    this.outerPadding = const EdgeInsets.only(bottom: 20),
  });

  final String name;
  final String level;
  final int matchScore;
  final List<String> playTags;
  final String intensityLabel;

  final Color? avatarColor;
  final String? avatarInitial;

  final VoidCallback? onTap;
  final VoidCallback onProfileTap;
  final VoidCallback onInviteTap;
  final VoidCallback onDismiss;

  /// Khoảng cách bên ngoài card (giữa các thẻ gợi ý).
  /// Mặc định: bottom 14px.
  final EdgeInsets outerPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final score = matchScore.clamp(0, 100);
    final tone = _scoreTone(score, cs);
    final surface = _surfaceColor(theme);

    // FIX: đảm bảo thẻ gợi ý tách nhau ra dù list builder/column không có separator
    return Padding(
      padding: outerPadding,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(
                    theme.brightness == Brightness.dark ? 0.18 : 0.08,
                  ),
                ),
              ],
            ),
            child: ClipRRect(
              // giúp ripple/ink nằm gọn trong bo góc
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Header =====
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Avatar(
                          initial: (avatarInitial ?? name.characters.first)
                              .toUpperCase(),
                          color: avatarColor ?? cs.primaryContainer,
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
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  _MatchBadge(score: score, tone: tone),
                                  const SizedBox(width: 8),
                                  _DismissButton(onPressed: onDismiss),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 18, color: cs.secondary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      level,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tt.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurfaceVariant,
                                      ),
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

                    // ===== Tags (chips bên trong card) =====
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...playTags.map(
                          (t) => _PillChip(
                            label: t,
                            background: cs.secondaryContainer.withOpacity(0.65),
                            foreground: cs.onSecondaryContainer,
                          ),
                        ),
                        _PillChip(
                          icon: Icons.local_fire_department_rounded,
                          label: 'Intensity: $intensityLabel',
                          background: cs.tertiaryContainer.withOpacity(0.75),
                          foreground: cs.onTertiaryContainer,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ===== Actions =====
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onProfileTap,
                            icon: const Icon(Icons.remove_red_eye_outlined,
                                size: 18),
                            label: const Text('Xem hồ sơ'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
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
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _surfaceColor(ThemeData theme) {
    final cs = theme.colorScheme;
    return theme.brightness == Brightness.dark
        ? cs.surfaceContainerLow
        : cs.surfaceContainer;
  }

  _ScoreTone _scoreTone(int score, ColorScheme cs) {
    if (score >= 80) {
      return _ScoreTone(
        bg: cs.primaryContainer,
        fg: cs.onPrimaryContainer,
        dot: cs.primary,
      );
    }
    if (score >= 50) {
      return _ScoreTone(
        bg: cs.secondaryContainer,
        fg: cs.onSecondaryContainer,
        dot: cs.secondary,
      );
    }
    return _ScoreTone(
      bg: cs.errorContainer,
      fg: cs.onErrorContainer,
      dot: cs.error,
    );
  }
}

class _ScoreTone {
  const _ScoreTone({required this.bg, required this.fg, required this.dot});
  final Color bg;
  final Color fg;
  final Color dot;
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.score, required this.tone});
  final int score;
  final _ScoreTone tone;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.bg.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.dot.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: tone.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Match $score%',
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone.fg,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: 'Ẩn gợi ý',
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.color});
  final String initial;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.55)),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: tt.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
          color: cs.primary,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foreground.withOpacity(0.9)),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: foreground,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
