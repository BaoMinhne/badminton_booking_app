import 'package:pocketbase/pocketbase.dart';

import '../models/court_review.dart';
import 'pocketbase_client.dart';

class ManagerReviewsData {
  const ManagerReviewsData({
    required this.courts,
    required this.reviews,
  });

  final List<ReviewCourtOption> courts;
  final List<ManagerReviewEntry> reviews;

  bool get hasCourts => courts.isNotEmpty;
}

class ReviewCourtOption {
  const ReviewCourtOption({required this.id, required this.label});

  final String id;
  final String label;
}

class ManagerReviewEntry {
  const ManagerReviewEntry({
    required this.review,
    required this.courtLabel,
  });

  final CourtReview review;
  final String courtLabel;
}

class ManagerReviewsService {
  static const String _reviewCollection = 'court_ratings';

  Future<ManagerReviewsData> fetchReviews({String? courtId}) async {
    final pb = await getPocketbaseInstance();
    final authRecord = pb.authStore.record;

    if (authRecord == null) {
      throw ClientException(
        statusCode: 401,
        response: {'message': 'Bạn cần đăng nhập để xem đánh giá.'},
      );
    }

    final ownerId = _escape(authRecord.id);
    final courtsResult = await pb.collection('courts').getList(
          perPage: 200,
          filter: "owner='$ownerId'",
        );

    if (courtsResult.items.isEmpty) {
      return const ManagerReviewsData(courts: [], reviews: []);
    }

    final courtIds = courtsResult.items.map((record) => record.id).toList();
    final courts = courtsResult.items
        .map(
          (record) => ReviewCourtOption(
            id: record.id,
            label: (record.data['name'] as String?)?.trim().isNotEmpty == true
                ? record.data['name'] as String
                : 'Sân',
          ),
        )
        .toList();

    final selectedCourtId = courtId?.trim();
    final filter = selectedCourtId != null && selectedCourtId.isNotEmpty
        ? "court_id='${_escape(selectedCourtId)}'"
        : _buildOrFilter('court_id', courtIds);

    final reviewsResult = await pb.collection(_reviewCollection).getList(
          perPage: 200,
          sort: '-created',
          filter: filter,
          expand: 'user_id',
        );

    final courtLabelById = {for (final court in courts) court.id: court.label};

    final reviews = reviewsResult.items.map((record) {
      final review = CourtReview.fromRecord(record, pb);
      final courtLabel = courtLabelById[review.courtId] ?? 'Sân';
      return ManagerReviewEntry(review: review, courtLabel: courtLabel);
    }).toList();

    return ManagerReviewsData(courts: courts, reviews: reviews);
  }

  Future<void> deleteReview(String reviewId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection(_reviewCollection).delete(reviewId);
  }

  String _buildOrFilter(String field, List<String> values) {
    final escaped = values.map(_escape).map((value) => "${field}='$value'");
    return escaped.join(' || ');
  }

  String _escape(String value) => value.replaceAll("'", "\\'");
}
