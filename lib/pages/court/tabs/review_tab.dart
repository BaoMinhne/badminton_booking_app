import 'package:flutter/material.dart';

import '../../../models/court_review.dart';
import '../../../services/review_service.dart';

class ReviewTab extends StatefulWidget {
  final String courtId;
  final List<CourtReview> initialReviews;
  final ReviewService? reviewService;
  const ReviewTab({
    super.key,
    required this.courtId,
    this.initialReviews = const [],
    this.reviewService,
  });

  @override
  State<ReviewTab> createState() => _ReviewTabState();
}

enum _SortBy { newest, highest, lowest, mostLiked }

class _ReviewTabState extends State<ReviewTab> {
  late List<CourtReview> _reviews;
  late final ReviewService _reviewService;
  bool _isLoading = false;
  String? _errorMessage;
  _SortBy _sortBy = _SortBy.newest;
  int _filterStars = 0; // 0: all, 1..5: filter by stars

  @override
  void initState() {
    super.initState();
    _reviews = [...widget.initialReviews];
    _reviewService = widget.reviewService ?? ReviewService();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reviews = await _reviewService.fetchReviews(widget.courtId);
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  void _addReview(CourtReview r) {
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

  List<CourtReview> get _visible {
    List<CourtReview> out = [..._reviews];
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
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final header = Container(
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
                Text('${_reviews.length} reviews',
                    style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
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
                      const SizedBox(
                          width: 42, child: Text('')), // giữ layout gọn
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                              value: ratio, minHeight: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                          width: 28,
                          child: Text('$count', textAlign: TextAlign.right)),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    final filters = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          PopupMenuButton<int>(
            tooltip: 'Filter by star rating',
            position: PopupMenuPosition.under,
            onSelected: (v) => setState(() => _filterStars = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 0, child: Text('All')),
              for (int s = 5; s >= 1; s--)
                PopupMenuItem(value: s, child: Text('$s stars')),
            ],
            child: _FilterChipLike(
                label: _filterStars == 0 ? 'All' : '${_filterStars} stars'),
          ),
          const SizedBox(width: 8),
          DropdownButton<_SortBy>(
            value: _sortBy,
            onChanged: (v) => setState(() => _sortBy = v ?? _SortBy.newest),
            items: const [
              DropdownMenuItem(value: _SortBy.newest, child: Text('Newest')),
              DropdownMenuItem(
                  value: _SortBy.highest, child: Text('Highest rating')),
              DropdownMenuItem(
                  value: _SortBy.lowest, child: Text('Lowest rating')),
              DropdownMenuItem(
                  value: _SortBy.mostLiked, child: Text('Most liked')),
            ],
          ),
          const Spacer(),
          TextButton.icon(
            onPressed:
                _isLoading ? null : () => _openWriteReview(context, cs),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Write a review'),
          ),
        ],
      ),
    );

    final visible = _visible;

    return CustomScrollView(
      // để NestedScrollView điều phối cuộn mượt
      slivers: [
        SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        SliverToBoxAdapter(child: filters),
        SliverToBoxAdapter(child: const SizedBox(height: 8)),
        if (visible.isEmpty)
          // Lấp phần còn lại, không cuộn thêm → không overflow
          SliverFillRemaining(
            hasScrollBody: false,
            child: _EmptyState(
              message: _isLoading
                  ? 'Loading reviews...'
                  : _errorMessage != null
                      ? 'Unable to load reviews. Please try again.'
                      : _reviews.isEmpty
                          ? 'No reviews yet. Be the first!'
                          : 'No items match the filter.',
            ),
          )
        else
          // Danh sách đánh giá (có ngăn cách)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) {
                  return Divider(
                      height: 16, color: cs.outline.withOpacity(0.2));
                }
                final i = index ~/ 2;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: ReviewCard(
                    review: visible[i],
                    onLike: () => _toggleLike(visible[i].id),
                    onReport: () => _report(visible[i]),
                  ),
                );
              },
              childCount: visible.length * 2 - 1,
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  void _openWriteReview(BuildContext context, ColorScheme cs) async {
    final draft = await Navigator.of(context).push<_ReviewDraft>(
      MaterialPageRoute(
        builder: (_) => const _WriteReviewPage(),
        fullscreenDialog: true,
      ),
    );

    if (draft == null) return;
    try {
      final review = await _reviewService.submitReview(
        courtId: widget.courtId,
        stars: draft.stars,
        comment: draft.comment,
        displayName: draft.displayName,
      );
      if (!mounted) return;
      _addReview(review);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _report(CourtReview r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report review'),
        content: Text(
            'Do you want to report the review from "${r.userName}"? We will review it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report submitted.')),
              );
            },
            child: const Text('Submit'),
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
  final Color filledColor;
  final Color emptyColor;
  const StarRow(
      {super.key,
      required this.rating,
      this.size = 18,
      this.maxStars = 5,
      this.filledColor = Colors.amber,
      this.emptyColor = const Color(0xFFFFD54F)});

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
          child: Icon(
            icon,
            size: size,
            color:
                i < full || (i == full && hasHalf) ? filledColor : emptyColor,
          ),
        );
      }),
    );
  }
}

class StarPicker extends StatefulWidget {
  final int initial; // 1..5
  final void Function(int) onChanged;
  final Color filledColor;
  final Color emptyColor;
  const StarPicker({
    super.key,
    this.initial = 5,
    required this.onChanged,
    this.filledColor = Colors.amber,
    this.emptyColor = const Color(0xFFFFD54F),
  });

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
          icon: Icon(
            filled ? Icons.star : Icons.star_outline,
            color: filled ? widget.filledColor : widget.emptyColor,
          ),
        );
      }),
    );
  }
}

// ===================== REVIEW CARD =====================
class ReviewCard extends StatefulWidget {
  final CourtReview review;
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
                  child: Text(_expanded ? 'Collapse' : 'See more'),
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
                    label: const Text('Report'),
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
class _WriteReviewPage extends StatefulWidget {
  const _WriteReviewPage();

  @override
  State<_WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<_WriteReviewPage> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a review'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate', style: TextStyle(color: cs.onSurface)),
              StarPicker(
                initial: 5,
                onChanged: (v) => _stars = v,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'e.g., Minh Nguyen',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _comment,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Review content',
                  hintText: 'Share your experience…',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final name = _name.text.trim().isEmpty
                            ? 'User'
                            : _name.text.trim();
                        final cmt = _comment.text.trim();
                        if (cmt.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Please enter your review content.'),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(
                          context,
                          _ReviewDraft(
                            displayName: name,
                            stars: _stars,
                            comment: cmt,
                          ),
                        );
                      },
                      child: const Text('Submit review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

class _ReviewDraft {
  final String displayName;
  final int stars;
  final String comment;

  const _ReviewDraft({
    required this.displayName,
    required this.stars,
    required this.comment,
  });
}

String timeAgo(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
  if (diff.inHours < 24) return '${diff.inHours} hours ago';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  final weeks = (diff.inDays / 7).floor();
  if (weeks < 5) return '$weeks weeks ago';
  return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
}
