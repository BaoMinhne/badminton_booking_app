import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/models/user.dart';
import 'package:badminton_booking_app/models/user_details.dart';
import 'package:pocketbase/pocketbase.dart';

import 'pocketbase_client.dart';
import 'user_service.dart';

enum FriendRelationStatus { none, requestSent, incomingRequest, friends }

class FriendRelation {
  const FriendRelation(this.status, {this.requestId});

  final FriendRelationStatus status;
  final String? requestId;
}

class FriendService {
  FriendService() : _userDetailsService = UserDetailsService();

  final UserDetailsService _userDetailsService;

  Future<String> _currentUserId(PocketBase pb) async {
    final id = pb.authStore.record?.id;
    if (id == null || id.isEmpty) {
      throw Exception('Bạn chưa đăng nhập.');
    }
    return id;
  }

  Future<FriendRelation> getRelationWith(String otherUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = await _currentUserId(pb);

    // Check existing friendship
    final friendshipFilter = """
      (user_a = '$currentUserId' && user_b = '$otherUserId')
      || (user_a = '$otherUserId' && user_b = '$currentUserId')
    """;

    try {
      await pb.collection('friendships').getFirstListItem(friendshipFilter);
      return const FriendRelation(FriendRelationStatus.friends);
    } catch (_) {
      // ignore not found
    }

    // Check outgoing pending request
    try {
      final req = await pb.collection('friend_requests').getFirstListItem(
            "from_user = '$currentUserId' && to_user = '$otherUserId' && status = 'pending'",
          );
      return FriendRelation(
        FriendRelationStatus.requestSent,
        requestId: req.id,
      );
    } catch (_) {
      // ignore
    }

    // Check incoming pending request
    try {
      final req = await pb.collection('friend_requests').getFirstListItem(
            "from_user = '$otherUserId' && to_user = '$currentUserId' && status = 'pending'",
          );
      return FriendRelation(
        FriendRelationStatus.incomingRequest,
        requestId: req.id,
      );
    } catch (_) {
      // ignore
    }

    return const FriendRelation(FriendRelationStatus.none);
  }

  Future<void> sendFriendRequest(String toUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = await _currentUserId(pb);

    await pb.collection('friend_requests').create(body: {
      'from_user': currentUserId,
      'to_user': toUserId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requestId, String otherUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = await _currentUserId(pb);

    await pb.collection('friend_requests').update(
      requestId,
      body: {'status': 'accepted'},
    );

    await _createFriendship(pb, currentUserId, otherUserId);
  }

  Future<List<ChatContact>> loadFriends() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = await _currentUserId(pb);

    final records = await pb.collection('friendships').getFullList(
          filter: "user_a='$currentUserId' || user_b='$currentUserId'",
          expand: 'user_a,user_b',
        );

    final contacts = <ChatContact>[];

    for (final record in records) {
      final userAList = record.expand['user_a'] ?? <RecordModel>[];
      final userBList = record.expand['user_b'] ?? <RecordModel>[];
      final userA = userAList.isNotEmpty ? userAList.first : null;
      final userB = userBList.isNotEmpty ? userBList.first : null;
      if (userA == null || userB == null) continue;

      final other = userA.id == currentUserId ? userB : userA;
      final user = User.fromJson(other.toJson());

      UserDetails? details;
      try {
        details = await _userDetailsService.getByUserIdWithClient(pb, user.id);
      } catch (_) {
        // ignore
      }

      final result = FriendSearchResult(user: user, details: details);
      contacts.add(
        ChatContact(
          id: user.id,
          name: result.displayName,
          avatarText: result.initials,
          statusMessage: result.subtitle.isEmpty ? null : result.subtitle,
        ),
      );
    }

    return contacts;
  }

  Future<void> _createFriendship(
    PocketBase pb,
    String userA,
    String userB,
  ) async {
    // Sort ids to avoid duplicate pair ordering
    final ordered = [userA, userB]..sort();
    final a = ordered.first;
    final b = ordered.last;

    // check existing
    try {
      await pb.collection('friendships').getFirstListItem(
            "user_a='$a' && user_b='$b'",
          );
      return;
    } catch (_) {
      // not found
    }

    await pb.collection('friendships').create(body: {
      'user_a': a,
      'user_b': b,
    });
  }
}
