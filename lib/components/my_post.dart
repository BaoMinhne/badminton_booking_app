import 'package:flutter/material.dart';

class MyPost extends StatefulWidget {
  const MyPost({
    super.key,
    required this.content,
    required this.userName,
    required this.time,
    this.imageUrls = const [],
    this.onLikePressed,
    this.onCommentPressed,
    this.onSharePressed,
    this.onSavePressed,
    this.isLiked = false,
    this.likesCount,
  });

  final String content;
  final String userName;
  final DateTime time;
  final List<String> imageUrls;

  // Actions
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onSavePressed;

  // UI state (optional)
  final bool isLiked;
  final int? likesCount;

  @override
  State<MyPost> createState() => _MyPostState();
}

class _MyPostState extends State<MyPost> {
  late final PageController _pageController;
  int _currentIndex = 0;
  late bool _liked;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _liked = widget.isLiked;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImages = widget.imageUrls.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary,
                child: Text(
                  widget.userName.isNotEmpty
                      ? widget.userName[0].toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.userName,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () {},
                icon: const Icon(Icons.more_horiz_rounded),
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),

        // Image (square, pageable)
        if (hasImages)
          _SquareMedia(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.imageUrls.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (_, i) => Ink.image(
                    image: NetworkImage(widget.imageUrls[i]),
                    fit: BoxFit.cover,
                  ),
                ),
                if (widget.imageUrls.length > 1)
                  Positioned(
                    bottom: 10,
                    child: _Dots(
                      length: widget.imageUrls.length,
                      index: _currentIndex,
                    ),
                  ),
              ],
            ),
          ),

        // Action row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _liked = !_liked);
                  widget.onLikePressed?.call();
                },
                icon: Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  size: 30,
                ),
                color: _liked ? Colors.red : cs.onSurface,
              ),
              IconButton(
                onPressed: widget.onCommentPressed,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 25,
                ),
              ),
              IconButton(
                onPressed: widget.onSharePressed,
                icon: const Icon(
                  Icons.send_outlined,
                  size: 25,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onSavePressed,
                icon: const Icon(
                  Icons.bookmark_border,
                  size: 30,
                ),
              ),
            ],
          ),
        ),

        // Likes (optional)
        if ((widget.likesCount ?? 0) > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${widget.likesCount} lượt thích',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),

        // Caption: Username + content (like Instagram)
        if (widget.content.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.userName} ',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  TextSpan(
                    text: widget.content,
                    style: const TextStyle(fontSize: 15),
                  ),
                ],
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],

        // Time ago
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Text(
            _timeAgo(widget.time).toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  letterSpacing: 0.2,
                ),
          ),
        ),

        // Thin divider between posts
        Divider(height: 1, color: cs.outlineVariant.withOpacity(0.6)),
      ],
    );
  }

  // -------- Helpers --------

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'VỪA XONG';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
    if (diff.inHours < 24) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '$weeks tuần';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '$months tháng';
    final years = (diff.inDays / 365).floor();
    return '$years năm';
  }
}

/// Keeps media square like Instagram feed
class _SquareMedia extends StatelessWidget {
  const _SquareMedia({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(aspectRatio: 1, child: child);
  }
}

/// Minimal dot indicator
class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.index});
  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(length, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 10 : 6,
            height: 6,
            decoration: BoxDecoration(
              color:
                  active ? cs.primary : cs.onSurfaceVariant.withOpacity(0.35),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}
