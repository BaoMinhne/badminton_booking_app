import 'dart:async';

import 'package:badminton_booking_app/models/friend_relation.dart';
import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/services/friend_request_service.dart';
import 'package:badminton_booking_app/services/pocketbase_client.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

class FriendManager extends ChangeNotifier {
  FriendManager()
      : _userDetailsService = UserDetailsService(),
        _friendRequestService = FriendRequestService();

  Timer? _searchDebounce;

  final UserDetailsService _userDetailsService;
  final FriendRequestService _friendRequestService;

  List<FriendSearchResult> _searchResults = const <FriendSearchResult>[];
  bool _isSearching = false;
  String _currentQuery = '';
  String? _error;

  final Map<String, FriendRelationStatus> _relations = {};
  final Map<String, bool> _actionLoading = {};
  UnsubscribeFunc? _requestUnsubscribe;
  UnsubscribeFunc? _friendshipUnsubscribe;
  String? _currentUserId;

  List<FriendSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  String? get error => _error;

  bool isRequestPending(String userId) =>
      _relations[userId]?.isPending == true;
  bool hasIncomingRequest(String userId) =>
      _relations[userId]?.type == FriendRelationType.incomingRequest;
  bool isFriend(String userId) =>
      _relations[userId]?.type == FriendRelationType.friends;
  bool isActionInProgress(String userId) => _actionLoading[userId] == true;

  FriendRelationStatus relationFor(String userId) =>
      _relations[userId] ?? const FriendRelationStatus.none();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    unawaited(_requestUnsubscribe?.call());
    unawaited(_friendshipUnsubscribe?.call());
    super.dispose();
  }

  Future<void> initialize() async {
    final pb = await getPocketbaseInstance();
    _currentUserId = pb.authStore.record?.id;
    await _setupRealtime(pb);
  }

  Future<void> _setupRealtime(PocketBase pocketBase) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final oldReqUnsub = _requestUnsubscribe;
    _requestUnsubscribe = null;
    if (oldReqUnsub != null) {
      await oldReqUnsub();
    }

    final oldFriendshipUnsub = _friendshipUnsubscribe;
    _friendshipUnsubscribe = null;
    if (oldFriendshipUnsub != null) {
      await oldFriendshipUnsub();
    }

    try {
      _requestUnsubscribe = await pocketBase
          .collection('friend_requests')
          .subscribe('*', _handleRequestEvent);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe friend requests: $error');
      }
    }

    try {
      _friendshipUnsubscribe = await pocketBase
          .collection('friendships')
          .subscribe('*', _handleFriendshipEvent);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe friendships: $error');
      }
    }
  }

  Future<void> _handleRequestEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    final userId = _currentUserId;
    if (record == null || userId == null) return;

    final fromUser = record.getStringValue('from_user');
    final toUser = record.getStringValue('to_user');

    if (fromUser != userId && toUser != userId) return;

    final otherUserId = fromUser == userId ? toUser : fromUser;
    final status = record.getStringValue('status');

    switch (event.action) {
      case 'delete':
        _relations[otherUserId] = const FriendRelationStatus.none();
        break;
      case 'create':
      case 'update':
        if (status == 'pending') {
          final type = toUser == userId
              ? FriendRelationType.incomingRequest
              : FriendRelationType.outgoingRequest;
          _relations[otherUserId] = FriendRelationStatus(
            type: type,
            requestId: record.id,
          );
        } else if (status == 'accepted') {
          _relations[otherUserId] =
              const FriendRelationStatus(type: FriendRelationType.friends);
        } else {
          _relations[otherUserId] = const FriendRelationStatus.none();
        }
        break;
      default:
        break;
    }

    notifyListeners();
  }

  Future<void> _handleFriendshipEvent(RecordSubscriptionEvent event) async {
    final record = event.record;
    final userId = _currentUserId;
    if (record == null || userId == null) return;

    final userA = record.getStringValue('user_a');
    final userB = record.getStringValue('user_b');

    if (userA != userId && userB != userId) return;

    final otherUserId = userA == userId ? userB : userA;

    switch (event.action) {
      case 'delete':
        _relations[otherUserId] = const FriendRelationStatus.none();
        break;
      case 'create':
      case 'update':
        _relations[otherUserId] =
            const FriendRelationStatus(type: FriendRelationType.friends);
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void searchDebounced(String keyword) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      search(keyword);
    });
  }

  Future<void> search(String keyword) async {
    _currentQuery = keyword;
    final term = keyword.trim();

    if (term.isEmpty) {
      _searchResults = const <FriendSearchResult>[];
      _relations.clear();
      _error = null;
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _userDetailsService.searchUsers(term);
      if (_currentQuery.trim() != term) {
        // đã có query mới, bỏ qua kết quả cũ
        return;
      }
      _searchResults = results;
      _loadRelationsForResults(results, term);
    } catch (_) {
      if (_currentQuery.trim() != term) return;
      _error = 'Không thể tìm kiếm. Vui lòng thử lại.';
    } finally {
      if (_currentQuery.trim() == term) {
        _isSearching = false;
        notifyListeners();
      }
    }
  }

  void _loadRelationsForResults(
    List<FriendSearchResult> results,
    String term,
  ) {
    unawaited(() async {
      try {
        final entries = await Future.wait(
          results.map((result) async {
            final relation =
                await _friendRequestService.getRelationStatus(result.user.id);
            return MapEntry(result.user.id, relation);
          }),
        );

        if (_currentQuery.trim() != term.trim()) return;

        _relations
          ..clear()
          ..addEntries(entries);
        notifyListeners();
      } catch (_) {
        // ignore background errors
      }
    }());
  }

  Future<void> sendFriendRequest(FriendSearchResult target) async {
    final userId = target.user.id;
    _setActionLoading(userId, true);
    try {
      final requestId = await _friendRequestService.sendFriendRequest(userId);
      _relations[userId] = FriendRelationStatus(
        type: FriendRelationType.outgoingRequest,
        requestId: requestId,
      );
    } finally {
      _setActionLoading(userId, false);
    }
  }

  Future<void> cancelPendingRequest(
    String userId, {
    bool deleteRecord = true,
  }) async {
    final requestId = _relations[userId]?.requestId;
    if (requestId == null) return;

    _setActionLoading(userId, true);
    try {
      await _friendRequestService.cancelFriendRequest(
        requestId,
        deleteRecord: deleteRecord,
      );
      _relations[userId] = const FriendRelationStatus.none();
    } finally {
      _setActionLoading(userId, false);
    }
  }

  Future<void> acceptIncomingRequest(FriendSearchResult target) async {
    final userId = target.user.id;
    final relation = _relations[userId];
    final requestId = relation?.requestId;
    if (relation?.type != FriendRelationType.incomingRequest || requestId == null) {
      return;
    }

    _setActionLoading(userId, true);
    try {
      await _friendRequestService.acceptFriendRequestById(requestId, userId);
      _relations[userId] = const FriendRelationStatus(
        type: FriendRelationType.friends,
      );
    } finally {
      _setActionLoading(userId, false);
    }
  }

  Future<void> rejectIncomingRequest(FriendSearchResult target) async {
    final userId = target.user.id;
    final relation = _relations[userId];
    final requestId = relation?.requestId;
    if (relation?.type != FriendRelationType.incomingRequest || requestId == null) {
      return;
    }

    _setActionLoading(userId, true);
    try {
      await _friendRequestService.rejectFriendRequestById(requestId);
      _relations[userId] = const FriendRelationStatus.none();
    } finally {
      _setActionLoading(userId, false);
    }
  }

  void _setActionLoading(String userId, bool value) {
    _actionLoading[userId] = value;
    notifyListeners();
  }
}
