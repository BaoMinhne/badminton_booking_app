import 'package:flutter/material.dart';

class Review {
  final String id;
  final String userName;
  final double stars; // 1..5
  final String comment;
  final DateTime createdAt;
  int likes;
  bool likedByMe;

  Review({
    required this.id,
    required this.userName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
  });
}

final List<Review> kSampleReviews = [
  Review(
    id: 'r1',
    userName: 'Hữu Minh',
    stars: 5,
    comment:
        'Sân sạch, đèn sáng, vạch rõ. Chủ sân hỗ trợ nhiệt tình. Giờ cao điểm hơi đông nhưng đặt trước là ổn.',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    likes: 2,
  ),
  Review(
    id: 'r2',
    userName: 'Ngọc Anh',
    stars: 4,
    comment:
        'Giá hợp lý. Nếu có thêm quạt ở sân số 3 thì tuyệt. Nói chung đáng quay lại.',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Review(
    id: 'r3',
    userName: 'Quốc Việt',
    stars: 3,
    comment:
        'Hôm mưa sàn hơi trơn, hy vọng sân cải thiện thoát nước. Nhân viên ok.',
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
    likes: 1,
  ),
];

class ReviewTab extends StatefulWidget {
  final List<Review> initialReviews;
  const ReviewTab({super.key, this.initialReviews = const []});

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

enum _SortBy { newest, highest, lowest, mostLiked }

class _ReviewTabState extends State<ReviewTab> {
  late List<Review> _reviews;
  _SortBy _sortBy = _SortBy.newest;
  int _filterStars = 0; // 0: all, 1..5: filter by stars

  @override
  void initState() {
    super.initState();
    _reviews = [...widget.initialReviews];
  }

  void _addReview(Review r) {
    setState(() => _reviews.insert(0, r));
  }

  void _toggleLike(String id) {
    final i = _reviews.indexWhere((e) => e.id == id);
    if (i == -1) return;
    setState(() {
      final cur = _reviews[i];
      if (cur.likedByMe) {
        cur.likes = (cur.likes - 1).clamp(0, 1 << 30);
      } else {
        cur.likes += 1;
      }
      cur.likedByMe = !cur.likedByMe;
    });
  }

  double get _avg {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((e) => e.stars).reduce((a, b) => a + b) /
        _reviews.length;
  }

  List<int> get _dist {
    final d = List<int>.filled(6, 0); // index 1..5
    for (final r in _reviews) {
      d[r.stars.round().clamp(1, 5)]++;
    }
    return d;
  }

  List<Review> get _visible {
    List<Review> out = [..._reviews];
    if (_filterStars != 0) {
      out = out.where((e) => e.stars.round() == _filterStars).toList();
    }
    switch (_sortBy) {
      case _SortBy.newest:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortBy.highest:
        out.sort((a, b) => b.stars.compareTo(a.stars));
        break;
      case _SortBy.lowest:
        out.sort((a, b) => a.stars.compareTo(b.stars));
        break;
      case _SortBy.mostLiked:
        out.sort((a, b) => b.likes.compareTo(a.likes));
        break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        // ===== Header: Tổng quan điểm & phân bố sao =====
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outline.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              // Tổng điểm
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_avg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    StarRow(rating: _avg, size: 20),
                    const SizedBox(height: 4),
                    Text('${_reviews.length} đánh giá',
                        style: TextStyle(
                          color: cs.onSurface.withOpacity(0.7),
                        )),
                  ],
                ),
              ),
              // Phân bố sao
              Expanded(
                flex: 6,
                child: Column(
                  children: List.generate(5, (i) {
                    final star = 5 - i;
                    final total = _reviews.isEmpty ? 1 : _reviews.length;
                    final count = _dist[star];
                    final ratio = count / total;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          SizedBox(
                              width: 42,
                              child: Text('$star sao',
                                  style: const TextStyle(fontSize: 12))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                              width: 28,
                              child: Text('$count',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),

        // ===== Bộ lọc & sắp xếp + nút viết đánh giá =====
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Filter theo sao
              PopupMenuButton<int>(
                tooltip: 'Lọc theo số sao',
                position: PopupMenuPosition.under,
                onSelected: (v) => setState(() => _filterStars = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 0, child: Text('Tất cả')),
                  for (int s = 5; s >= 1; s--)
                    PopupMenuItem(value: s, child: Text('$s sao')),
                ],
                child: _FilterChipLike(
                  label: _filterStars == 0 ? 'Tất cả' : '${_filterStars} sao',
                ),
              ),
              const SizedBox(width: 8),
              // Sort
              DropdownButton<_SortBy>(
                value: _sortBy,
                onChanged: (v) => setState(() => _sortBy = v ?? _SortBy.newest),
                items: const [
                  DropdownMenuItem(
                    value: _SortBy.newest,
                    child: Text('Mới nhất'),
                  ),
                  DropdownMenuItem(
                    value: _SortBy.highest,
                    child: Text('Sao cao nhất'),
                  ),
                  DropdownMenuItem(
                    value: _SortBy.lowest,
                    child: Text('Sao thấp nhất'),
                  ),
                  DropdownMenuItem(
                    value: _SortBy.mostLiked,
                    child: Text('Được thích nhiều'),
                  ),
                ],
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openWriteReview(context),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Viết đánh giá'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ===== Danh sách đánh giá =====
        Expanded(
          child: _visible.isEmpty
              ? _EmptyState(
                  message: _reviews.isEmpty
                      ? 'Chưa có đánh giá. Hãy là người đầu tiên!'
                      : 'Không có mục nào khớp bộ lọc.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemBuilder: (_, i) => ReviewCard(
                    review: _visible[i],
                    onLike: () => _toggleLike(_visible[i].id),
                    onReport: () => _report(_visible[i]),
                  ),
                  separatorBuilder: (_, __) => Divider(
                    height: 16,
                    color: cs.outline.withOpacity(0.2),
                  ),
                  itemCount: _visible.length,
                ),
        ),
      ],
    );
  }

  void _openWriteReview(BuildContext context) async {
    final r = await showModalBottomSheet<Review>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _WriteReviewSheet(),
      ),
    );

    if (r != null) _addReview(r);
  }

  void _report(Review r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Báo cáo đánh giá'),
        content: Text(
            'Bạn muốn báo cáo đánh giá của "${r.userName}"? Chúng tôi sẽ xem xét.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huỷ')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã gửi báo cáo.')),
              );
            },
            child: const Text('Gửi'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 48, color: cs.primary.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: cs.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== STAR ROW (đọc/ghi) =====================
class StarRow extends StatelessWidget {
  final double rating; // 0..5 (đọc)
  final double size;
  final int maxStars;
  const StarRow(
      {super.key, required this.rating, this.size = 18, this.maxStars = 5});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = (rating - full) >= 0.5;
    return Row(
      children: List.generate(maxStars, (i) {
        IconData icon;
        if (i < full) {
          icon = Icons.star;
        } else if (i == full && hasHalf) {
          icon = Icons.star_half;
        } else {
          icon = Icons.star_border;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(icon, size: size),
        );
      }),
    );
  }
}

class StarPicker extends StatefulWidget {
  final int initial; // 1..5
  final void Function(int) onChanged;
  const StarPicker({super.key, this.initial = 5, required this.onChanged});

  @override
  State<StarPicker> createState() => _StarPickerState();
}

class _StarPickerState extends State<StarPicker> {
  late int _v;
  @override
  void initState() {
    super.initState();
    _v = widget.initial.clamp(1, 5);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final filled = idx <= _v;
        return IconButton(
          onPressed: () {
            setState(() => _v = idx);
            widget.onChanged(_v);
          },
          icon: Icon(filled ? Icons.star : Icons.star_outline),
        );
      }),
    );
  }
}

// ===================== REVIEW CARD =====================
class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onLike;
  final VoidCallback onReport;
  const ReviewCard({
    super.key,
    required this.review,
    required this.onLike,
    required this.onReport,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = widget.review;

    final text = r.comment.trim();
    final isLong = text.length > 160;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          child:
              Text(r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tên + sao + thời gian
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(timeAgo(r.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withOpacity(0.6),
                      )),
                ],
              ),
              const SizedBox(height: 2),
              StarRow(rating: r.stars, size: 16),
              const SizedBox(height: 6),

              // comment (gập/mở)
              AnimatedCrossFade(
                firstChild: Text(
                  isLong ? text.substring(0, 160) + '…' : text,
                ),
                secondChild: Text(text),
                crossFadeState: _expanded || !isLong
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              if (isLong)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'Thu gọn' : 'Xem thêm'),
                ),

              // hành động
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onLike,
                    icon: Icon(
                      r.likedByMe ? Icons.favorite : Icons.favorite_border,
                      color: r.likedByMe ? cs.primary : null,
                    ),
                  ),
                  Text('${r.likes}'),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: widget.onReport,
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: const Text('Báo cáo'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===================== WRITE REVIEW SHEET =====================
class _WriteReviewSheet extends StatefulWidget {
  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _stars = 5;
  final _name = TextEditingController();
  final _comment = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Viết đánh giá',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          Align(
              alignment: Alignment.centerLeft,
              child: Text('Chấm sao', style: TextStyle(color: cs.onSurface))),
          StarPicker(
            initial: 5,
            onChanged: (v) => _stars = v,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              hintText: 'VD: Minh Nguyễn',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comment,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Nội dung đánh giá',
              hintText: 'Chia sẻ trải nghiệm của bạn…',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Huỷ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    final name = _name.text.trim().isEmpty
                        ? 'Người dùng'
                        : _name.text.trim();
                    final cmt = _comment.text.trim();
                    if (cmt.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng nhập nội dung đánh giá.')),
                      );
                      return;
                    }
                    final r = Review(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      userName: name,
                      stars: _stars.toDouble(),
                      comment: cmt,
                      createdAt: DateTime.now(),
                    );
                    Navigator.pop(context, r);
                  },
                  child: const Text('Gửi đánh giá'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ===================== SMALL UTILS =====================
class _FilterChipLike extends StatelessWidget {
  final String label;
  const _FilterChipLike({required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_outlined, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '$weeks tuần trước';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
