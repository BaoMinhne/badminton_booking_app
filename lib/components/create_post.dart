// lib/widgets/create_post_bar.dart
import 'package:flutter/material.dart';

class CreatePostBar extends StatelessWidget {
  const CreatePostBar({
    super.key,
    required this.onCreatePost,
    this.onPickPhoto,
    this.onInviteFriends,
    this.avatarImageProvider,
    this.hintText = 'Bạn đang nghĩ gì thế?',
    this.backgroundColor,
    this.primaryColor,
    this.elevation = 1.0,
    this.compact = false,
  });

  /// Tap vào “ô nhập” để mở trang tạo bài viết
  final VoidCallback onCreatePost;

  /// Các action bên dưới (tùy chọn)
  final VoidCallback? onPickPhoto;
  final VoidCallback? onInviteFriends;

  /// Ảnh đại diện (NetworkImage/FileImage/AssetImage…)
  final ImageProvider? avatarImageProvider;

  /// Placeholder trong ô nhập
  final String hintText;

  /// Màu nền khối
  final Color? backgroundColor;

  /// Màu chủ đạo (icon/nhấn)
  final Color? primaryColor;

  /// Độ nổi khối thẻ (0 = phẳng)
  final double elevation;

  /// Chế độ gọn hơn (ẩn hàng action)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final basePrimary = primaryColor ?? colorScheme.primary;

    return Material(
      elevation: elevation,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colorScheme.outline.withOpacity(0.8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hàng avatar + “ô nhập”
            Row(
              children: [
                _Avatar(imageProvider: avatarImageProvider),
                const SizedBox(width: 12),
                Expanded(
                  child: _FakeInput(
                    hintText: hintText,
                    onTap: onCreatePost,
                  ),
                ),
              ],
            ),
            if (!compact) const SizedBox(height: 12),
            if (!compact)
              Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withOpacity(0.4),
              ),
            if (!compact) const SizedBox(height: 12),
            if (!compact)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _Action(
                      icon: Icons.photo_library_outlined,
                      label: 'Ảnh',
                      onTap: onPickPhoto,
                      activeColor: basePrimary,
                    ),
                  ),
                  const SizedBox(width: 16), // Thêm khoảng cách giữa hai nút
                  Expanded(
                    child: _Action(
                      icon: Icons.person_add_alt_1_outlined,
                      label: 'Mời bạn bè',
                      onTap: onInviteFriends,
                      activeColor: basePrimary,
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageProvider});

  final ImageProvider? imageProvider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(Icons.person_rounded,
                color: theme.colorScheme.primary, size: 28)
            : null,
      ),
    );
  }
}

class _FakeInput extends StatelessWidget {
  const _FakeInput({
    required this.hintText,
    required this.onTap,
  });

  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: theme.hintColor.withOpacity(0.8),
                ),
              ),
            ),
            Icon(Icons.edit_rounded,
                size: 20, color: cs.primary.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isEnabled
              ? activeColor.withOpacity(0.1)
              : theme.disabledColor.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isEnabled ? activeColor : theme.disabledColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isEnabled ? activeColor : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
