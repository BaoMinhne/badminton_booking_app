import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecruitmentPostCard extends StatelessWidget {
  final String hostName;
  final DateTime createdTime;
  final String? skillLevel;
  final int requiredPlayers;
  final int joinedPlayers;
  final String? description;
  final String? courtName;
  final DateTime? playTime;
  final String? locationNote;
  final VoidCallback? onJoin;
  final String? playStyle;
  final bool isJoined;
  final bool isOwner;
  final bool isJoinLoading;

  const RecruitmentPostCard({
    super.key,
    required this.hostName,
    required this.createdTime,
    required this.requiredPlayers,
    required this.joinedPlayers,
    this.skillLevel,
    this.description,
    this.courtName,
    this.playTime,
    this.locationNote,
    this.onJoin,
    this.playStyle,
    this.isJoined = false,
    this.isOwner = false,
    this.isJoinLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalSlots = requiredPlayers <= 0 ? joinedPlayers : requiredPlayers;
    final progress = totalSlots == 0
        ? 0.0
        : (joinedPlayers / totalSlots).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, textTheme),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.group_outlined, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã có $joinedPlayers / $requiredPlayers thành viên',
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: (isJoined || isOwner || isJoinLoading)
                        ? null
                        : onJoin,
                    icon: isJoinLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(isJoined ? Icons.check_circle : Icons.add_circle_outline),
                    label: Text(
                      isOwner
                          ? 'Bài của bạn'
                          : isJoined
                              ? 'Đã tham gia'
                              : 'Tham gia',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: cs.surfaceVariant,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (skillLevel != null && skillLevel!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.stars_rounded,
                      label: 'Trình độ: $skillLevel',
                      color: cs.primaryContainer,
                      iconColor: cs.primary,
                    ),
                  if (playStyle != null && playStyle!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.sports_tennis,
                      label: 'Lối chơi: $playStyle',
                      color: cs.secondaryContainer,
                      iconColor: cs.secondary,
                    ),
                  if (courtName != null && courtName!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.location_on_outlined,
                      label: 'Sân: $courtName',
                      color: cs.tertiaryContainer,
                      iconColor: cs.tertiary,
                    ),
                  if ((locationNote ?? '').trim().isNotEmpty)
                    _InfoChip(
                      icon: Icons.map_outlined,
                      label: 'Địa điểm: ${locationNote!.trim()}',
                      color: cs.surfaceVariant,
                      iconColor: cs.primary,
                    ),
                  if (playTime != null)
                    _InfoChip(
                      icon: Icons.access_time,
                      label:
                          'Giờ đánh: ${DateFormat('HH:mm dd/MM').format(playTime!)}',
                      color: cs.surfaceVariant,
                      iconColor: cs.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: cs.primary,
          child: Text(
            (hostName.isNotEmpty ? hostName[0] : '?').toUpperCase(),
            style: textTheme.titleMedium?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hostName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(createdTime),
                style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, color: cs.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Tuyển gấp',
                style: textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
