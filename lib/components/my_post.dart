import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyPost extends StatefulWidget {
  const MyPost({
    super.key,
    required this.content,
    required this.userName,
    required this.time,
    this.imageUrls = const [],
    this.onLikePressed,
  });

  final String content;
  final String userName;
  final DateTime time;
  final List<String> imageUrls;
  final VoidCallback? onLikePressed;

  @override
  State<MyPost> createState() => _MyPostState();
}

class _MyPostState extends State<MyPost> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasImages = widget.imageUrls.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(24),
        color: cs.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            if (hasImages) _buildImageCarousel(context),
            if (widget.content.trim().isNotEmpty) _buildMessage(context),
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: cs.primary,
            child: Text(
              widget.userName.isNotEmpty
                  ? widget.userName[0].toUpperCase()
                  : 'U',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(widget.time),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded),
            color: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            AspectRatio(
              aspectRatio: 4 / 5,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  return Ink.image(
                    image: NetworkImage(widget.imageUrls[index]),
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.surface.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.imageUrls.length, (index) {
                      final isActive = _currentIndex == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 10 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? cs.primary
                              : cs.onSurfaceVariant.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(
        widget.content,
        style: Theme.of(context)
            .textTheme
            .bodyLarge
            ?.copyWith(height: 1.4, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: widget.onLikePressed,
            icon: Icon(Icons.favorite_border, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Text(
            'Thích',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 20),
          Icon(Icons.chat_bubble_outline_rounded,
              color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Bình luận',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const Spacer(),
          Icon(Icons.bookmark_border, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
