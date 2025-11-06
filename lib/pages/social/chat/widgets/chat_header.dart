import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const ChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.onAddFriend,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onAddFriend;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.light, // status bar icon sáng
      backgroundColor: cs.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leadingWidth: 56, // tap-target ≥ 48dp
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        iconSize: 26, // icon lớn hơn mặc định
        icon: const Icon(Icons.arrow_back_rounded),
        color: cs.onPrimary,
        tooltip: 'Quay lại',
      ),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tt.titleLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: tt.labelSmall?.copyWith(
                color: cs.onPrimary.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
      actionsIconTheme: IconThemeData(color: cs.onPrimary, size: 24),
      actions: [
        // Nút thêm bạn (tonal theo M3)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton.filledTonal(
            onPressed: onAddFriend,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
              padding: const WidgetStatePropertyAll(EdgeInsets.zero),
              backgroundColor: WidgetStatePropertyAll(
                cs.onPrimary.withOpacity(0.12),
              ),
              foregroundColor: WidgetStatePropertyAll(cs.onPrimary),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            tooltip: 'Thêm bạn',
          ),
        ),
      ],
      bottom: bottom, // gắn TabBar vào đây
    );
  }
}
