import 'package:pocketbase/pocketbase.dart';

import '../utils/pocketbase_utils.dart';

class CourtReview {
  CourtReview({
    required this.id,
    required this.courtId,
    required this.userId,
    required this.userName,
    required this.stars,
    required this.comment,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
  });

  factory CourtReview.fromRecord(RecordModel record, PocketBase pocketBase) {
    final data = record.data;
    final userRecord = resolveExpandedRecord(record.expand?['user_id']);
    final userData = userRecord?.data;

    return CourtReview(
      id: record.id,
      courtId: _resolveRelationId(data['court_id']),
      userId: _resolveRelationId(data['user_id'], fallback: userRecord?.id),
      userName: sanitizeDisplayName(
        (data['display_name'] as String?) ??
            (userData?['username'] as String?) ??
            (userData?['email'] as String?),
      ),
      stars: (data['rating'] as num?)?.toDouble() ?? 0,
      comment: (data['comment'] as String?)?.trim() ?? '',
      createdAt: DateTime.parse(data['created'] as String),
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      likedByMe: (data['liked_by_me'] as bool?) ?? false,
    );
  }

  final String id;
  final String courtId;
  final String userId;
  final String userName;
  final double stars;
  final String comment;
  final DateTime createdAt;
  int likes;
  bool likedByMe;

  static String _resolveRelationId(dynamic value, {String? fallback}) {
    if (value is String) {
      return value;
    }
    if (value is List && value.isNotEmpty && value.first is String) {
      return value.first as String;
    }
    return fallback ?? '';
  }
}
