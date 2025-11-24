import 'dart:async';

import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/services/friend_request_service.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/foundation.dart';

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

  final Map<String, String?> _pendingRequestIds = {};
  final Map<String, bool> _actionLoading = {};

  List<FriendSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  String? get error => _error;

  bool isRequestPending(String userId) => _pendingRequestIds[userId] != null;
  bool isActionInProgress(String userId) => _actionLoading[userId] == true;

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
      _pendingRequestIds.clear();
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
      _loadPendingRequestsForResults(results, term);
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

  void _loadPendingRequestsForResults(
    List<FriendSearchResult> results,
    String term,
  ) {
    unawaited(() async {
      try {
        final entries = <MapEntry<String, String?>>[];

        for (final result in results) {
          final pendingId =
              await _friendRequestService.getPendingRequestIdTo(result.user.id);
          entries.add(MapEntry(result.user.id, pendingId));
        }

        if (_currentQuery.trim() != term.trim()) return;

        _pendingRequestIds
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
      _pendingRequestIds[userId] = requestId;
    } finally {
      _setActionLoading(userId, false);
    }
  }

  Future<void> cancelPendingRequest(
    String userId, {
    bool deleteRecord = true,
  }) async {
    final requestId = _pendingRequestIds[userId];
    if (requestId == null) return;

    _setActionLoading(userId, true);
    try {
      await _friendRequestService.cancelFriendRequest(
        requestId,
        deleteRecord: deleteRecord,
      );
      _pendingRequestIds.remove(userId);
    } finally {
      _setActionLoading(userId, false);
    }
  }

  void _setActionLoading(String userId, bool value) {
    _actionLoading[userId] = value;
    notifyListeners();
  }
}
