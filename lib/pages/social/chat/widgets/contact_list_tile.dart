import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:flutter/material.dart';

enum _ContactTileType { chat, friend, suggestion }

class ContactListTile extends StatelessWidget {
  const ContactListTile._({
    super.key,
    required this.contact,
    required this.type,
    this.onTap,
    this.onChatPressed,
    this.actionLabel,
    this.isProcessing = false,
    this.isPending = false,
    this.trailing,
  });

  factory ContactListTile.chat({
    Key? key,
    required ChatContact contact,
    VoidCallback? onTap,
  }) {
    return ContactListTile._(
      key: key,
      contact: contact,
      type: _ContactTileType.chat,
      onTap: onTap,
    );
  }

  factory ContactListTile.friend({
    Key? key,
    required ChatContact contact,
    VoidCallback? onTap,
    VoidCallback? onChatPressed,
  }) {
    return ContactListTile._(
      key: key,
      contact: contact,
      type: _ContactTileType.friend,
      onTap: onTap,
      onChatPressed: onChatPressed,
    );
  }

  factory ContactListTile.suggestion({
    Key? key,
    required ChatContact contact,
    VoidCallback? onTap,
    VoidCallback? onChatPressed,
    String? actionLabel,
    bool isProcessing = false,
    bool isPending = false,
    Widget? trailing,
  }) {
    return ContactListTile._(
      key: key,
      contact: contact,
      type: _ContactTileType.suggestion,
      onTap: onTap,
      onChatPressed: onChatPressed,
      actionLabel: actionLabel,
      isProcessing: isProcessing,
      isPending: isPending,
      trailing: trailing,
    );
  }

  final ChatContact contact;
  final _ContactTileType type;
  final VoidCallback? onTap;
  final VoidCallback? onChatPressed;
  final String? actionLabel;
  final bool isProcessing;
  final bool isPending;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                _buildAvatar(cs),
                const SizedBox(width: 14),
                Expanded(child: _buildContent(context)),
                const SizedBox(width: 12),
                _buildTrailing(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ColorScheme cs) {
    final avatar = CircleAvatar(
      radius: 26,
      backgroundColor: cs.primaryContainer,
      child: Text(
        contact.avatarText,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );

    if (!contact.isOnline) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.72),
    );

    final subtitle = switch (type) {
      _ContactTileType.chat => contact.lastMessage,
      _ContactTileType.friend => contact.statusMessage,
      _ContactTileType.suggestion => contact.statusMessage,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(contact.name, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: bodyStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    if (trailing != null) return trailing!;

    switch (type) {
      case _ContactTileType.chat:
        return _ChatTrailing(contact: contact);
      case _ContactTileType.friend:
        return FilledButton.tonalIcon(
          onPressed: onChatPressed,
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Chat'),
        );
      case _ContactTileType.suggestion:
        final label = actionLabel ?? 'Kết bạn';
        if (isProcessing) {
          return const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          );
        }

        return FilledButton(
          style: isPending
              ? FilledButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onSecondaryContainer,
                )
              : null,
          onPressed: onChatPressed,
          child: Text(label),
        );
    }
  }
}

class _ChatTrailing extends StatelessWidget {
  const _ChatTrailing({
    required this.contact,
  });

  final ChatContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeText = contact.lastMessageTimeLabel;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (timeText != null)
          Text(
            timeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
            ),
          ),
        if (contact.hasUnreadMessages) ...[
          const SizedBox(height: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              contact.unreadCount.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
