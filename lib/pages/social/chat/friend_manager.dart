import 'dart:async';

import 'package:badminton_booking_app/models/chat_contact.dart';
import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/services/friend_service.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/foundation.dart';

class FriendManager extends ChangeNotifier {
  FriendManager()
      : _userDetailsService = UserDetailsService(),
        _friendService = FriendService();

  Timer? _searchDebounce;

  final UserDetailsService _userDetailsService;
  final FriendService _friendService;

  List<FriendSearchResult> _searchResults = const <FriendSearchResult>[];
  List<ChatContact> _friends = const <ChatContact>[];
  final Map<String, FriendRelation> _relations = {};
  final Set<String> _pendingActions = {};
  bool _isSearching = false;
  bool _isLoadingFriends = false;
  String _currentQuery = '';
  String? _error;
  String? _friendError;

  List<FriendSearchResult> get searchResults => _searchResults;
  List<ChatContact> get friends => _friends;
  FriendRelation relationFor(String userId) =>
      _relations[userId] ?? const FriendRelation(FriendRelationStatus.none);
  bool isPendingAction(String userId) => _pendingActions.contains(userId);
  bool get isSearching => _isSearching;
  bool get isLoadingFriends => _isLoadingFriends;
  String get currentQuery => _currentQuery;
  String? get error => _error;
  String? get friendError => _friendError;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
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
      await _loadRelations(results);
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

  Future<void> sendFriendRequest(String userId) async {
    _pendingActions.add(userId);
    notifyListeners();

    try {
      await _friendService.sendFriendRequest(userId);
      _relations[userId] = const FriendRelation(FriendRelationStatus.requestSent);
    } catch (e) {
      _error = e.toString();
    } finally {
      _pendingActions.remove(userId);
      notifyListeners();
    }
  }

  Future<void> acceptRequest(String userId) async {
    final relation = _relations[userId];
    if (relation == null || relation.requestId == null) return;

    _pendingActions.add(userId);
    notifyListeners();

    try {
      await _friendService.acceptFriendRequest(relation.requestId!, userId);
      _relations[userId] = const FriendRelation(FriendRelationStatus.friends);
      await loadFriends();
    } catch (e) {
      _error = e.toString();
    } finally {
      _pendingActions.remove(userId);
      notifyListeners();
    }
  }

  Future<void> loadFriends() async {
    _isLoadingFriends = true;
    _friendError = null;
    notifyListeners();

    try {
      _friends = await _friendService.loadFriends();
    } catch (e) {
      _friendError = 'Không thể tải danh sách bạn bè: $e';
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> _loadRelations(List<FriendSearchResult> results) async {
    for (final result in results) {
      final relation = await _friendService.getRelationWith(result.user.id);
      _relations[result.user.id] = relation;
    }
    notifyListeners();
  }
}
