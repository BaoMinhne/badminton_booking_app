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
      titleSpacing: 0,
      elevation: 0,
      backgroundColor: cs.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.onPrimary.withOpacity(.2),
            child: Text(
              avatarText,
              style: TextStyle(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(
                isOnline ? 'Đang hoạt động' : 'Ngoại tuyến',
                style: TextStyle(
                    fontSize: 12, color: cs.onPrimary.withOpacity(.7)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onCall,
          icon: const Icon(Icons.call_rounded),
        ),
        IconButton(
          onPressed: onVideoCall,
          icon: const Icon(Icons.videocam_rounded),
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}
