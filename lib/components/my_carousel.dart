import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MyCarousel extends StatefulWidget {
  final List<String> images;
  final ValueChanged<int>? onIndexChanged;
  final Duration interval; // thời gian chờ giữa các lần chuyển
  final Duration duration; // thời gian chạy animation
  final Curve curve;

  const MyCarousel({
    super.key,
    required this.images,
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
    if (widget.images.isEmpty) return;
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || _isUserDragging) return;
      final next = (_idx + 1) % widget.images.length;
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
                itemCount: widget.images.length,
                onPageChanged: (i) {
                  setState(() => _idx = i);
                  widget.onIndexChanged?.call(i);
                },
                itemBuilder: (_, i) {
                  final src = widget.images[i];
                  final isAsset = !src.startsWith('http');
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isAsset
                            ? Image.asset(src, fit: BoxFit.cover)
                            : Image.network(src, fit: BoxFit.cover),
                        Container(color: Colors.black.withOpacity(0.2)),
                        const Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Ưu đãi thành viên • tuần này',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
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
            children: List.generate(widget.images.length, (i) {
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
