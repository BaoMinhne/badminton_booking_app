import 'package:pocketbase/pocketbase.dart';

import '../models/court_review.dart';
import 'pocketbase_client.dart';

class ReviewService {
  static const String collection = 'court_ratings';

  Future<List<CourtReview>> fetchReviews(String courtId) async {
    final pb = await getPocketbaseInstance();
    final result = await pb.collection(collection).getList(
          page: 1,
          perPage: 200,
          filter: "court_id='$courtId'",
          sort: '-created',
          expand: 'user_id',
        );
    return result.items
        .map((record) => CourtReview.fromRecord(record, pb))
        .toList();
  }

  Future<CourtReview> submitReview({
    required String courtId,
    required int stars,
    required String comment,
    required String displayName,
  }) async {
    final pb = await getPocketbaseInstance();
    final userId = pb.authStore.record?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Bạn cần đăng nhập để đánh giá sân.');
    }
    final record = await pb.collection(collection).create(body: {
      'court_id': courtId,
      'user_id': userId,
      'rating': stars,
      'comment': comment,
      'display_name': displayName,
    });
    return CourtReview.fromRecord(record, pb);
  }
}
