import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RecruitmentPostCard extends StatelessWidget {
  final String hostName;
  final DateTime createdTime;
  final String? skillLevel;
  final String? hostAvatarUrl;
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
  final bool isActive;
  final VoidCallback? onManage;

  const RecruitmentPostCard({
    super.key,
    required this.hostName,
    required this.createdTime,
    required this.requiredPlayers,
    required this.joinedPlayers,
    this.skillLevel,
    this.hostAvatarUrl,
    this.description,
    this.courtName,
    this.playTime,
    this.locationNote,
    this.onJoin,
    this.playStyle,
    this.isJoined = false,
    this.isOwner = false,
    this.isJoinLoading = false,
    this.isActive = true,
    this.onManage,
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
                    onPressed: (!isActive || isJoined || isOwner || isJoinLoading)
                        ? null
                        : onJoin,
                    icon: isJoinLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isActive
                                ? (isJoined
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline)
                                : Icons.lock_outline,
                          ),
                    label: Text(
                      isOwner
                          ? 'Bài của bạn'
                          : !isActive
                              ? 'Đã đóng'
                              : isJoined
                                  ? 'Đã tham gia'
                                  : 'Tham gia',
                    ),
                  ),
                ],
              ),
              if (isOwner && onManage != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onManage,
                    icon: const Icon(Icons.assignment_ind_outlined),
                    label: const Text('Quản lý yêu cầu'),
                  ),
                ),
              ],
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
                  if (playTime != null)
                    _InfoChip(
                      icon: Icons.access_time,
                      label:
                          'Giờ đánh: ${DateFormat('HH:mm - dd/MM').format(playTime!)}',
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
          backgroundColor:
              hostAvatarUrl == null ? cs.primary : Colors.transparent,
          backgroundImage:
              hostAvatarUrl != null ? NetworkImage(hostAvatarUrl!) : null,
          child: hostAvatarUrl == null
              ? Text(
                  (hostName.isNotEmpty ? hostName[0] : '?').toUpperCase(),
                  style: textTheme.titleMedium?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
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
                style:
                    textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: isActive ? cs.primaryContainer : cs.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.bolt : Icons.lock,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'Đang tuyển' : 'Đã đóng',
                style: textTheme.labelMedium?.copyWith(
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
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
