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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Hàng avatar + “ô nhập”
            Row(
              children: [
                _Avatar(imageProvider: avatarImageProvider),
                const SizedBox(width: 10),
                Expanded(
                  child: _FakeInput(
                    hintText: hintText,
                    onTap: onCreatePost,
                  ),
                ),
              ],
            ),
            if (!compact) const SizedBox(height: 8),
            if (!compact)
              Divider(
                height: 16,
                thickness: 0.8,
                color: theme.dividerColor.withOpacity(0.6),
              ),
            if (!compact) const SizedBox(height: 2),
            if (!compact)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Action(
                    icon: Icons.photo_library_outlined,
                    label: 'Ảnh',
                    onTap: onPickPhoto,
                    activeColor: basePrimary,
                  ),
                  _Action(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Mời bạn bè',
                    onTap: onInviteFriends,
                    activeColor: basePrimary,
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
    return CircleAvatar(
      radius: 30,
      backgroundColor: theme.colorScheme.surfaceVariant,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant)
          : null,
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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outline),
        ),
        child: Text(
          hintText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 16, // ✅ thêm dòng này để tăng font size
            color: theme.hintColor,
          ),
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

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isEnabled ? activeColor : theme.disabledColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? theme.textTheme.bodyMedium?.color
                      : theme.disabledColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
