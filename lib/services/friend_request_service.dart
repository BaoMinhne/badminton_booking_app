import 'package:pocketbase/pocketbase.dart';

import '../models/friend_request.dart';
import '../models/friend_search_result.dart';
import '../models/user.dart';
import '../services/pocketbase_client.dart';
import '../services/user_service.dart';
import '../utils/time_ago.dart';

class FriendRequestService {
  FriendRequestService() : _userDetailsService = UserDetailsService();

  final UserDetailsService _userDetailsService;

  Future<List<FriendRequestItem>> fetchIncomingRequests() async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    final requests = await pb.collection('friend_requests').getFullList(
          filter: "to_user = '$currentUserId' && status = 'pending'",
          sort: '-created',
          expand: 'from_user',
        );

    final List<FriendRequestItem> result = [];

    for (final request in requests) {
      final fromUserId = request.getStringValue('from_user');
      User? fromUser;

      final expanded = request.expand['from_user'] as List<dynamic>?;
      if (expanded != null && expanded.isNotEmpty) {
        final expandedUser = expanded.first;
        if (expandedUser is RecordModel) {
          fromUser = User.fromJson(expandedUser.toJson());
        }
      }

      fromUser ??= User(id: fromUserId, username: '', email: '', phone: '');

      final details = await _userDetailsService.getByUserIdWithClient(
        pb,
        fromUserId,
      );

      final createdAt = DateTime.tryParse(request.getStringValue('created')) ??
          DateTime.now();

      result.add(
        FriendRequestItem(
          id: request.id,
          from: FriendSearchResult(user: fromUser, details: details),
          createdAt: createdAt,
          timeLabel: formatRelativeTime(createdAt),
        ),
      );
    }

    return result;
  }

  Future<String?> getPendingRequestIdTo(String toUserId) async {
    try {
      final pb = await getPocketbaseInstance();
      final currentUserId = pb.authStore.record?.id;
      if (currentUserId == null) return null;

      final rec = await pb.collection('friend_requests').getFirstListItem(
            filter:
                "from_user = '$currentUserId' && to_user = '$toUserId' && status = 'pending'",
          );
      return rec.id;
    } on ClientException catch (err) {
      if (err.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<String> sendFriendRequest(String toUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;

    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    if (currentUserId == toUserId) {
      throw Exception('Không thể tự gửi lời mời kết bạn.');
    }

    try {
      final rec = await pb.collection('friend_requests').create(body: {
        'from_user': currentUserId,
        'to_user': toUserId,
        'status': 'pending',
      });
      return rec.id;
    } on ClientException catch (err) {
      final msg = err.response['message'] ?? 'Không thể gửi lời mời kết bạn.';
      throw Exception(msg);
    }
  }

  Future<void> cancelFriendRequest(
    String requestId, {
    bool deleteRecord = false,
  }) async {
    final pb = await getPocketbaseInstance();

    if (deleteRecord) {
      await pb.collection('friend_requests').delete(requestId);
      return;
    }

    await pb.collection('friend_requests').update(
      requestId,
      body: {'status': 'cancelled'},
    );
  }

  Future<void> acceptFriendRequest(FriendRequestItem request) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = pb.authStore.record?.id;
    if (currentUserId == null) {
      throw Exception('Bạn chưa đăng nhập.');
    }

    await pb.collection('friend_requests').update(
      request.id,
      body: {'status': 'accepted'},
    );

    await _createFriendship(pb, request.from.user.id, currentUserId);
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection('friend_requests').update(
      requestId,
      body: {'status': 'rejected'},
    );
  }

  Future<void> _createFriendship(
    PocketBase pb,
    String userA,
    String userB,
  ) async {
    final first = userA.compareTo(userB) <= 0 ? userA : userB;
    final second = first == userA ? userB : userA;

    try {
      await pb.collection('friendships').create(
        body: {'user_a': first, 'user_b': second},
      );
    } on ClientException catch (err) {
      final msg = err.response['message'] ?? '';
      if (msg.contains('idx_friendships_pair')) return;
      rethrow;
    }
  }
}
