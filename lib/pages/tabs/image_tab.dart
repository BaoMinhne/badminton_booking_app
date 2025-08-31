import 'package:flutter/material.dart';

class CourtImageGallery extends StatelessWidget {
  final List<String> images;
  final double spacing;
  final int crossAxisCount;

  const CourtImageGallery({
    super.key,
    required this.images,
    this.spacing = 8,
    this.crossAxisCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (images.isEmpty) {
      return Center(
        child: Text('Chưa có hình ảnh', style: TextStyle(color: cs.primary)),
      );
    }

    return Padding(
      padding: EdgeInsets.all(spacing),
      child: GridView.builder(
        itemCount: images.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
        ),
        itemBuilder: (context, index) {
          final src = images[index];
          return _Thumb(
            tag: 'court-photo-$index',
            src: src,
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: true,
                  barrierDismissible: false,
                  pageBuilder: (_, __, ___) => _FullscreenGallery(
                    images: images,
                    initialIndex: index,
                  ),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String src;
  final String tag;
  final VoidCallback onTap;
  const _Thumb({required this.src, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: _buildImage(src, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  const _FullscreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.3),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${_index + 1}/${widget.images.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        onPageChanged: _onPageChanged,
        itemCount: widget.images.length,
        itemBuilder: (context, i) {
          final src = widget.images[i];
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Hero(
                  tag: 'court-photo-$i',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: _buildImage(src, fit: BoxFit.contain),
                  ),
                ),
              ),
              // Chú thích/ghi chú nếu muốn (ẩn mặc định)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: 0.0, // đổi thành 1.0 nếu muốn hiện caption
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        'Ảnh sân #${i + 1}',
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      // Thanh điều hướng nhanh
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            border: const Border(top: BorderSide(color: Colors.white24)),
          ),
          child: SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, i) {
                final active = i == _index;
                return GestureDetector(
                  onTap: () => _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  ),
                  child: Opacity(
                    opacity: active ? 1 : 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: active ? Border.all(color: Colors.white) : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.6, // thumbnail widescreen
                          child:
                              _buildImage(widget.images[i], fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: widget.images.length,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper: hiển thị được cả asset và network, có loader
Widget _buildImage(String src, {BoxFit fit = BoxFit.cover}) {
  if (src.startsWith('http')) {
    return Image.network(
      src,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final v =
            progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1);
        return Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(value: v.isFinite ? v : null),
          ),
        );
      },
      errorBuilder: (_, __, ___) => const _ImgError(),
    );
  } else {
    return Image.asset(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => const _ImgError(),
    );
  }
}

class _ImgError extends StatelessWidget {
  const _ImgError();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black12,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, size: 32),
    );
  }
}
