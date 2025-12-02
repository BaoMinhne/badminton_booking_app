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

    // Gradient cho match score dựa trên giá trị (hiện đại hóa visual feedback)
    Color matchColor = matchScore >= 80
        ? cs.primary
        : (matchScore >= 50 ? cs.secondary : cs.error);
    Color matchTextColor = matchScore >= 80
        ? cs.onPrimary
        : (matchScore >= 50 ? cs.onSecondary : cs.onError);

    return Card(
      elevation: 2, // Elevation nhẹ cho shadow hiện đại
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
            color: cs.outline.withOpacity(0.4),
            width: 1), // Thêm border cho card
      ),
      margin: const EdgeInsets.symmetric(
          vertical: 8, horizontal: 4), // Tăng vertical margin cho spacing
      child: Padding(
        padding: const EdgeInsets.all(16), // Tăng padding cho thoáng hơn
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28, // Tăng kích thước avatar cho nổi bật
                  backgroundColor: avatarColor ?? cs.primary.withOpacity(0.15),
                  child: Text(
                    (avatarInitial ?? name[0]).toUpperCase(),
                    style: tt.titleLarge?.copyWith(
                      // Tăng font size
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontWeight: FontWeight.bold,
                                fontSize: 18, // Tăng size cho hiện đại
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                // Tăng độ tương phản cho badge match score
                                colors: [
                                  matchColor.withOpacity(0.28),
                                  matchColor.withOpacity(0.14)
                                ],
                              ),
                              border: Border.all(
                                color: matchColor.withOpacity(0.55),
                                width: 0.9,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Match: $matchScore%',
                              style: tt.labelMedium?.copyWith(
                                color: matchTextColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rate_rounded,
                            size: 18,
                            color: cs.secondary
                                .withOpacity(0.8), // Giảm opacity để hài hòa
                          ),
                          const SizedBox(width: 6),
                          Text(
                            level,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant
                                  .withOpacity(0.9), // Màu tinh tế hơn
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment:
                            WrapAlignment.start, // Lệch về bên trái (align left)
                        children: [
                          ...playTags.map(
                            (tag) => Chip(
                              label: Text(tag),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4), // Tăng padding để tag lớn hơn
                              backgroundColor:
                                  cs.secondaryContainer, // Tô đậm màu thẻ
                              side: BorderSide(
                                color: cs.secondary.withOpacity(0.4),
                                width: 1,
                              ),
                              labelStyle: tt.labelMedium?.copyWith(
                                // Tăng từ labelSmall lên labelMedium để chữ lớn hơn
                                color: cs.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    16), // Radius lớn hơn cho chip
                              ),
                            ),
                          ),
                          Chip(
                            avatar: Icon(
                              Icons.local_fire_department_rounded,
                              color: cs.onTertiary, // Giữ màu rõ ràng
                              size: 18,
                            ),
                            label: Text('Intensity: $intensityLabel'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4), // Tăng padding tương tự
                            backgroundColor:
                                cs.tertiaryContainer, // Đầy màu hơn cho tag chính
                            side: BorderSide(
                              color: cs.tertiary.withOpacity(0.45),
                              width: 1,
                            ),
                            labelStyle: tt.labelMedium?.copyWith(
                              // Tăng size chữ
                              color: cs.onTertiaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    // Chuyển sang FilledButton để nổi bật hơn (thay vì OutlinedButton)
                    onPressed: onProfileTap,
                    icon: const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    label: const Text('Xem hồ sơ'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      backgroundColor: cs.primaryContainer
                          .withOpacity(0.8), // Giảm opacity nhẹ để hài hòa
                      foregroundColor: cs.onPrimaryContainer,
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
                          vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
