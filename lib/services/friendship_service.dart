import 'package:pocketbase/pocketbase.dart';

import '../models/friend_search_result.dart';
import '../models/user.dart';
import '../services/pocketbase_client.dart';
import '../services/user_service.dart';

class FriendshipService {
  FriendshipService() : _userDetailsService = UserDetailsService();

  final UserDetailsService _userDetailsService;

  Future<List<FriendSearchResult>> fetchFriends() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final friendships = await pb.collection('friendships').getFullList(
          filter: "user_a = '$currentUserId' || user_b = '$currentUserId'",
          sort: '-created',
          expand: 'user_a,user_b',
        );

    final results = <FriendSearchResult>[];

    for (final friendship in friendships) {
      final userAId = friendship.getStringValue('user_a');
      final userBId = friendship.getStringValue('user_b');
      final otherUserId = userAId == currentUserId ? userBId : userAId;

      User? otherUser;

      final userAExpanded = friendship.expand['user_a'] as List<dynamic>?;
      final userBExpanded = friendship.expand['user_b'] as List<dynamic>?;

      if (userAExpanded != null && userAExpanded.isNotEmpty) {
        final expandedUser = userAExpanded.first;
        if (expandedUser is RecordModel && expandedUser.id == otherUserId) {
          otherUser = User.fromJson(expandedUser.toJson());
        }
      }

      if (otherUser == null && userBExpanded != null && userBExpanded.isNotEmpty) {
        final expandedUser = userBExpanded.first;
        if (expandedUser is RecordModel && expandedUser.id == otherUserId) {
          otherUser = User.fromJson(expandedUser.toJson());
        }
      }

      otherUser ??= User(id: otherUserId, username: '', email: '', phone: '');

      final details = await _userDetailsService.getByUserIdWithClient(
        pb,
        otherUserId,
      );

      results.add(FriendSearchResult(user: otherUser, details: details));
    }

    return results;
  }
}
