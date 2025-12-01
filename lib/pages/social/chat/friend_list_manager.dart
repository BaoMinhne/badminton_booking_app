import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../models/friend_search_result.dart';
import '../../../services/friendship_service.dart';
import '../../../services/pocketbase_client.dart';

class FriendListManager extends ChangeNotifier {
  FriendListManager() : _service = FriendshipService();

  final FriendshipService _service;

  List<FriendSearchResult> _friends = const <FriendSearchResult>[];
  bool _isLoading = false;
  String? _error;
  UnsubscribeFunc? _unsubscribe;
  String? _currentUserId;

  List<FriendSearchResult> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    await loadFriends();
    await _setupRealtime();
  }

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _service.fetchFriends();
      final pb = await getPocketbaseInstance();
      _currentUserId = pb.authStore.record?.id;
    } catch (_) {
      _error = 'Không thể tải danh sách bạn bè. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _setupRealtime() async {
    final pb = await getPocketbaseInstance();
    _currentUserId = pb.authStore.record?.id;
    final userId = _currentUserId;

    if (userId == null) return;

    final oldUnsub = _unsubscribe;
    _unsubscribe = null;
    if (oldUnsub != null) {
      await oldUnsub();
    }

    try {
      _unsubscribe = await pb
          .collection('friendships')
          .subscribe('*', _handleRealtimeEvent);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe friendships: $error');
      }
    }
  }

  Future<void> _handleRealtimeEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    final userId = _currentUserId;
    if (record == null || userId == null) return;

    final userA = record.getStringValue('user_a');
    final userB = record.getStringValue('user_b');

    if (userA != userId && userB != userId) return;

    final otherUserId = userA == userId ? userB : userA;

    switch (event.action) {
      case 'delete':
        _friends =
            _friends.where((friend) => friend.user.id != otherUserId).toList();
        break;
      case 'create':
      case 'update':
        final pb = await getPocketbaseInstance();
        final friend =
            await _service.buildFriendFromRecord(pb, record, userId);
        if (friend == null) break;

        final index =
            _friends.indexWhere((element) => element.user.id == otherUserId);
        if (index == -1) {
          _friends = <FriendSearchResult>[friend, ..._friends];
        } else {
          final mutable = [..._friends];
          mutable[index] = friend;
          _friends = mutable;
        }
        break;
      default:
        break;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_unsubscribe?.call());
    super.dispose();
  }
}
