import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class CarouselSlide {
  final String image;
  final String title;
  final String? description;
  final String? ctaLabel;
  final VoidCallback? onTap;

  const CarouselSlide({
    required this.image,
    required this.title,
    this.description,
    this.ctaLabel,
    this.onTap,
  });
}

class MyCarousel extends StatefulWidget {
  final List<CarouselSlide> slides;
  final ValueChanged<int>? onIndexChanged;
  final Duration interval; // thời gian chờ giữa các lần chuyển
  final Duration duration; // thời gian chạy animation
  final Curve curve;

  const MyCarousel({
    super.key,
    required this.slides,
    this.onIndexChanged,
    this.interval = const Duration(seconds: 4),
    this.duration = const Duration(milliseconds: 450),
    this.curve = Curves.easeOut,
  });

  @override
  State<MyCarousel> createState() => _MyCarouselState();
}

class _MyCarouselState extends State<MyCarousel> {
  late final PageController _pc;
  int _idx = 0;
  Timer? _timer;
  bool _isUserDragging = false;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 1);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.slides.isEmpty) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _isUserDragging) return;
      final next = (_idx + 1) % widget.slides.length;
      _pc.animateToPage(next, duration: widget.duration, curve: widget.curve);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: NotificationListener<UserScrollNotification>(
              onNotification: (n) {
                // tạm dừng khi người dùng kéo, tiếp tục khi thả
                if (n.direction == ScrollDirection.idle) {
                  _isUserDragging = false;
                } else {
                  _isUserDragging = true;
                }
                return false;
              },
              child: PageView.builder(
                controller: _pc,
                itemCount: widget.slides.length,
                onPageChanged: (i) {
                  setState(() => _idx = i);
                  widget.onIndexChanged?.call(i);
                },
                itemBuilder: (_, i) {
                  final slide = widget.slides[i];
                  final src = slide.image;
                  final isAsset = !src.startsWith('http');
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isAsset
                            ? Image.asset(src, fit: BoxFit.cover)
                            : Image.network(src, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.55),
                                Colors.black.withOpacity(0.15),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slide.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                if (slide.description != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    slide.description!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                                if (slide.ctaLabel != null &&
                                    slide.onTap != null) ...[
                                  const SizedBox(height: 10),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                      backgroundColor:
                                          Colors.white.withOpacity(0.95),
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: slide.onTap,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          slide.ctaLabel!,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              final active = i == _idx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 16 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
