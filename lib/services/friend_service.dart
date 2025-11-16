import 'package:pocketbase/pocketbase.dart';

import '../models/friend_request.dart';
import '../models/friendship.dart';
import 'pocketbase_client.dart';

class FriendServiceException implements Exception {
  FriendServiceException(this.message);
  final String message;
  @override
  String toString() => message;
}

class FriendService {
  static const _friendRequests = 'friend_requests';
  static const _friendships = 'friendships';

  Future<String> _currentUserId(PocketBase pocketBase) async {
    final userId = pocketBase.authStore.record?.id;
    if (userId == null) {
      throw FriendServiceException('Bạn cần đăng nhập để sử dụng tính năng này.');
    }
    return userId;
  }

  Future<List<Friendship>> fetchFriends({int page = 1, int perPage = 30}) async {
    final pb = await getPocketbaseInstance();
    final userId = await _currentUserId(pb);
    final result = await pb.collection(_friendships).getList(
          page: page,
          perPage: perPage,
          filter: 'user_a = "$userId" || user_b = "$userId"',
          expand: 'user_a,user_b',
          sort: '-created',
        );
    return result.items
        .map((record) => Friendship.fromRecord(record, pb))
        .toList(growable: false);
  }

  Future<List<FriendRequest>> fetchIncomingRequests({
    int page = 1,
    int perPage = 30,
  }) async {
    final pb = await getPocketbaseInstance();
    final userId = await _currentUserId(pb);
    final result = await pb.collection(_friendRequests).getList(
          page: page,
          perPage: perPage,
          filter: 'to_user = "$userId" && status = "pending"',
          expand: 'from_user,to_user',
          sort: '-created',
        );
    return result.items
        .map((record) => FriendRequest.fromRecord(record, pb))
        .toList(growable: false);
  }

  Future<List<FriendRequest>> fetchOutgoingRequests({
    int page = 1,
    int perPage = 30,
  }) async {
    final pb = await getPocketbaseInstance();
    final userId = await _currentUserId(pb);
    final result = await pb.collection(_friendRequests).getList(
          page: page,
          perPage: perPage,
          filter: 'from_user = "$userId" && status = "pending"',
          expand: 'from_user,to_user',
          sort: '-created',
        );
    return result.items
        .map((record) => FriendRequest.fromRecord(record, pb))
        .toList(growable: false);
  }

  Future<FriendRequest> sendFriendRequest(String targetUserId) async {
    final pb = await getPocketbaseInstance();
    final currentUserId = await _currentUserId(pb);
    if (currentUserId == targetUserId) {
      throw FriendServiceException('Bạn không thể tự gửi lời mời cho chính mình.');
    }

    await _ensureNotFriends(pb, currentUserId, targetUserId);
    await _ensureNoPendingRequest(pb, currentUserId, targetUserId);

    final record = await pb.collection(_friendRequests).create(body: {
      'from_user': currentUserId,
      'to_user': targetUserId,
      'status': 'pending',
    });

    return FriendRequest.fromRecord(await _expandRequest(pb, record), pb);
  }

  Future<void> cancelFriendRequest(String requestId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection(_friendRequests).update(requestId, body: {
      'status': 'cancelled',
    });
  }

  Future<void> rejectFriendRequest(String requestId) async {
    final pb = await getPocketbaseInstance();
    await pb.collection(_friendRequests).update(requestId, body: {
      'status': 'rejected',
    });
  }

  Future<Friendship> acceptFriendRequest(String requestId) async {
    final pb = await getPocketbaseInstance();
    final request = await pb.collection(_friendRequests).update(
      requestId,
      body: {
        'status': 'accepted',
      },
    );

    final fromUserId = request.getStringValue('from_user');
    final toUserId = request.getStringValue('to_user');
    final pair = _sortedPair(fromUserId, toUserId);

    try {
      final existing = await pb.collection(_friendships).getFirstListItem(
            'user_a = "${pair.$1}" && user_b = "${pair.$2}"',
          );
      return Friendship.fromRecord(existing, pb);
    } catch (_) {
      final friendship = await pb.collection(_friendships).create(body: {
        'user_a': pair.$1,
        'user_b': pair.$2,
      });
      final expanded = await _expandFriendship(pb, friendship);
      return Friendship.fromRecord(expanded, pb);
    }
  }

  Future<void> unfriend(String friendUserId) async {
    final pb = await getPocketbaseInstance();
    final me = await _currentUserId(pb);
    final pair = _sortedPair(me, friendUserId);
    try {
      final friendship = await pb.collection(_friendships).getFirstListItem(
            'user_a = "${pair.$1}" && user_b = "${pair.$2}"',
          );
      await pb.collection(_friendships).delete(friendship.id);
    } on ClientException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }
    }
  }

  Future<void> _ensureNotFriends(
    PocketBase pocketBase,
    String me,
    String target,
  ) async {
    final pair = _sortedPair(me, target);
    try {
      await pocketBase.collection(_friendships).getFirstListItem(
            'user_a = "${pair.$1}" && user_b = "${pair.$2}"',
          );
      throw FriendServiceException('Hai bạn đã là bạn bè.');
    } on ClientException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }
    }
  }

  Future<void> _ensureNoPendingRequest(
    PocketBase pocketBase,
    String me,
    String target,
  ) async {
    final filter =
        '((from_user = "$me" && to_user = "$target") || (from_user = "$target" && to_user = "$me")) && status = "pending"';
    try {
      await pocketBase.collection(_friendRequests).getFirstListItem(filter);
      throw FriendServiceException('Đang có lời mời kết bạn chờ xử lý.');
    } on ClientException catch (error) {
      if (error.statusCode != 404) {
        rethrow;
      }
    }
  }

  Future<RecordModel> _expandRequest(
    PocketBase pocketBase,
    RecordModel record,
  ) async {
    return pocketBase.collection(_friendRequests).getOne(
          record.id,
          expand: 'from_user,to_user',
        );
  }

  Future<RecordModel> _expandFriendship(
    PocketBase pocketBase,
    RecordModel record,
  ) async {
    return pocketBase.collection(_friendships).getOne(
          record.id,
          expand: 'user_a,user_b',
        );
  }

  (String, String) _sortedPair(String a, String b) {
    final list = [a, b]..sort();
    return (list[0], list[1]);
  }
}
