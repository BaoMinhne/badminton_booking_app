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
  final String? currentUserStatus;
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
    this.currentUserStatus,
    this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalSlots = requiredPlayers <= 0 ? joinedPlayers : requiredPlayers;
    final progress =
        totalSlots == 0 ? 0.0 : (joinedPlayers / totalSlots).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(28),
        color: cs.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, textTheme),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              // Player count with modern styling
              Row(
                children: [
                  Icon(Icons.group_rounded, color: cs.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Joined $joinedPlayers / $requiredPlayers members',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar with capsule shape
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                ),
              ),
              const SizedBox(height: 20),
              // Chips section
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (skillLevel != null && skillLevel!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.stars_rounded,
                      label: 'Skill level: $skillLevel',
                      color: cs.primaryContainer.withOpacity(0.8),
                      iconColor: cs.primary,
                    ),
                  if (playStyle != null && playStyle!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.sports_tennis_rounded,
                      label: 'Play style: $playStyle',
                      color: cs.secondaryContainer.withOpacity(0.8),
                      iconColor: cs.secondary,
                    ),
                  if (courtName != null && courtName!.isNotEmpty)
                    _InfoChip(
                      icon: Icons.location_on_rounded,
                      label: 'Court: $courtName',
                      color: cs.tertiaryContainer.withOpacity(0.8),
                      iconColor: cs.tertiary,
                    ),
                  if (playTime != null)
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label:
                          'Play time: ${DateFormat('HH:mm - dd/MM').format(playTime!)}',
                      color: cs.surfaceVariant.withOpacity(0.8),
                      iconColor: cs.primary,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              // Professional button layout: Full-width for main action, secondary aligned right
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActionButton(context),
                  if (isOwner && onManage != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: onManage,
                        icon: Icon(Icons.assignment_ind_rounded, size: 20),
                        label: const Text('Manage requests'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  fontSize: 18,
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
        Container(
          decoration: BoxDecoration(
            color: isActive
                ? cs.primaryContainer.withOpacity(0.9)
                : cs.surfaceVariant.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isActive
                    ? cs.primary.withOpacity(0.3)
                    : cs.outline.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.bolt_rounded : Icons.lock_rounded,
                color: isActive ? cs.primary : cs.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                isActive ? 'Open' : 'Closed',
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

  Widget _buildActionButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bool hasApplication =
        currentUserStatus != null && currentUserStatus != 'cancelled';

    final bool isDisabled =
        !isActive || isOwner || isJoinLoading || hasApplication;

    return FilledButton.icon(
      onPressed: isDisabled ? null : onJoin,
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: isDisabled ? 0 : 2,
        backgroundColor: isDisabled ? cs.surfaceVariant : cs.primary,
        foregroundColor: isDisabled ? cs.onSurfaceVariant : cs.onPrimary,
      ),
      icon: isJoinLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: cs.onPrimary,
              ),
            )
          : Icon(
              !isActive
                  ? Icons.lock_rounded
                  : currentUserStatus == 'accepted' || isJoined
                      ? Icons.check_circle_rounded
                      : currentUserStatus == 'rejected'
                          ? Icons.cancel_rounded
                          : currentUserStatus == 'pending'
                              ? Icons.hourglass_top_rounded
                              : Icons.add_circle_rounded,
              size: 22,
            ),
      label: Text(
        isOwner
            ? 'Your post'
            : !isActive
                ? 'Closed'
                : currentUserStatus == 'pending'
                    ? 'Pending'
                    : currentUserStatus == 'accepted' || isJoined
                        ? 'Joined'
                        : currentUserStatus == 'rejected'
                            ? 'Declined'
                            : 'Join',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outline.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
