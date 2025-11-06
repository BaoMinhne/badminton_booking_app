import 'package:flutter/material.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final bool isOnline;
  final String avatarText;
  final VoidCallback? onCall;
  final VoidCallback? onVideoCall;

  const ChatAppBar({
    super.key,
    required this.name,
    required this.isOnline,
    required this.avatarText,
    this.onCall,
    this.onVideoCall,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        color: cs.onPrimary,
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actionsIconTheme: IconThemeData(color: cs.onPrimary),
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: cs.onPrimary.withOpacity(.2),
            child: Text(
              avatarText,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ⬇️ Phần chữ được co giãn và cắt "..." khi hết chỗ
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min, // giữ chiều cao gọn
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis, // cắt "..."
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cs.onPrimary.withOpacity(.72),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(onPressed: onCall, icon: const Icon(Icons.call_rounded)),
        IconButton(
            onPressed: onVideoCall, icon: const Icon(Icons.videocam_rounded)),
        const SizedBox(width: 6),
      ],
    );
  }
}
