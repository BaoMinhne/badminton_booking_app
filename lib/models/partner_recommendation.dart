import 'package:badminton_booking_app/models/friend_search_result.dart';

class PartnerRecommendation {
  const PartnerRecommendation({
    required this.friend,
    required this.matchScore,
  });

  final FriendSearchResult friend;
  final double matchScore;
}
