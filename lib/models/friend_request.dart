import 'package:badminton_booking_app/models/friend_search_result.dart';

class FriendRequestItem {
  FriendRequestItem({
    required this.id,
    required this.from,
    required this.createdAt,
    required this.timeLabel,
  });

  final String id;
  final FriendSearchResult from;
  final DateTime createdAt;
  final String timeLabel;
}
