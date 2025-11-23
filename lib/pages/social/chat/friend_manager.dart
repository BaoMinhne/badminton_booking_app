import 'package:badminton_booking_app/models/friend_search_result.dart';
import 'package:badminton_booking_app/services/user_service.dart';
import 'package:flutter/foundation.dart';

import 'dart:async';

class FriendManager extends ChangeNotifier {
  FriendManager() : _userDetailsService = UserDetailsService();

  Timer? _searchDebounce;

  final UserDetailsService _userDetailsService;

  List<FriendSearchResult> _searchResults = const <FriendSearchResult>[];
  bool _isSearching = false;
  String _currentQuery = '';
  String? _error;

  List<FriendSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;
  String? get error => _error;

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
}
