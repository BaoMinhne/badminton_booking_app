import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:badminton_booking_app/models/friend_candidate.dart';
import 'package:badminton_booking_app/services/user_service.dart';

class FriendManager with ChangeNotifier {
  FriendManager({UserDetailsService? userService})
      : _userService = userService ?? UserDetailsService();

  final UserDetailsService _userService;

  final List<FriendCandidate> _searchResults = <FriendCandidate>[];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _searchError;
  int _searchToken = 0;

  UnmodifiableListView<FriendCandidate> get searchResults =>
      UnmodifiableListView(_searchResults);
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get searchError => _searchError;
  bool get hasQuery => _searchQuery.trim().isNotEmpty;

  Future<void> searchFriends(String query) async {
    _searchQuery = query;
    final trimmedQuery = query.trim();
    _searchToken++;
    final currentToken = _searchToken;

    if (trimmedQuery.isEmpty) {
      _resetState(notify: true);
      return;
    }

    _isSearching = true;
    _searchError = null;
    notifyListeners();

    try {
      final results =
          await _userService.searchFriendCandidates(trimmedQuery, perPage: 30);
      if (currentToken != _searchToken) {
        return;
      }
      _searchResults
        ..clear()
        ..addAll(results);
      _searchError = null;
    } catch (error) {
      if (currentToken != _searchToken) {
        return;
      }
      _searchResults.clear();
      _searchError = 'Không thể tìm kiếm bạn bè. Vui lòng thử lại sau.';
      debugPrint('FriendManager search error: $error');
    } finally {
      if (currentToken != _searchToken) {
        return;
      }
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    if (!hasQuery && _searchResults.isEmpty) {
      return;
    }
    _resetState(notify: true);
  }

  void _resetState({bool notify = false}) {
    _searchQuery = '';
    _searchResults.clear();
    _isSearching = false;
    _searchError = null;
    if (notify) {
      notifyListeners();
    }
  }
}
