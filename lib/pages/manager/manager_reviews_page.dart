import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/manager_reviews_service.dart';

class ManagerReviewsPage extends StatefulWidget {
  const ManagerReviewsPage({super.key});

  @override
  State<ManagerReviewsPage> createState() => _ManagerReviewsPageState();
}

class _ManagerReviewsPageState extends State<ManagerReviewsPage> {
  final _service = ManagerReviewsService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  ManagerReviewsData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews({String? courtId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchReviews(courtId: courtId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _confirmDelete(ManagerReviewEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete review'),
          content: const Text('Are you sure you want to delete this review?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
    await _service.deleteReview(entry.review.id);
      if (!mounted) return;
      setState(() {
        _data = _data == null
            ? null
            : ManagerReviewsData(
                courts: _data!.courts,
                reviews: _data!.reviews
                    .where((review) => review.review.id != entry.review.id)
                    .toList(),
              );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete review: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadReviews,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final data = _data ?? const ManagerReviewsData(courts: [], reviews: []);
    if (!data.hasCourts) {
      return const Center(child: Text('You do not have any courts to view reviews.'));
    }

    final reviews = data.reviews;

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (reviews.isEmpty)
            const Center(child: Text('No reviews yet.'))
          else
            ...reviews.map((entry) => _ReviewCard(
                  entry: entry,
                  dateLabel: _dateFormat.format(entry.review.createdAt.toLocal()),
                  onDelete: () => _confirmDelete(entry),
                )),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.entry,
    required this.dateLabel,
    required this.onDelete,
  });

  final ManagerReviewEntry entry;
  final String dateLabel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final review = entry.review;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.userName.isEmpty ? 'Customer' : review.userName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete review',
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _StarRow(rating: review.stars),
                Chip(
                  label: Text(entry.courtLabel),
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final fullStars = rating.floor().clamp(0, 5);
    final hasHalf = rating - fullStars >= 0.5;
    final stars = <Widget>[
      for (var i = 0; i < fullStars; i++)
        const Icon(Icons.star, size: 16, color: Colors.amber),
      if (hasHalf)
        const Icon(Icons.star_half, size: 16, color: Colors.amber),
      for (var i = fullStars + (hasHalf ? 1 : 0); i < 5; i++)
        const Icon(Icons.star_border, size: 16, color: Colors.amber),
    ];
    return Row(mainAxisSize: MainAxisSize.min, children: stars);
  }
}
