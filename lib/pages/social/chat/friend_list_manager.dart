import 'package:flutter/foundation.dart';

import '../../../models/friend_search_result.dart';
import '../../../services/friendship_service.dart';

class FriendListManager extends ChangeNotifier {
  FriendListManager() : _service = FriendshipService();

  final FriendshipService _service;

  List<FriendSearchResult> _friends = const <FriendSearchResult>[];
  bool _isLoading = false;
  String? _error;

  List<FriendSearchResult> get friends => _friends;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFriends() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _friends = await _service.fetchFriends();
    } catch (_) {
      _error = 'Không thể tải danh sách bạn bè. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
