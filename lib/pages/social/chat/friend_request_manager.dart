import 'package:flutter/foundation.dart';

import '../../../models/friend_request.dart';
import '../../../services/friend_request_service.dart';

class FriendRequestManager extends ChangeNotifier {
  FriendRequestManager() : _service = FriendRequestService();

  final FriendRequestService _service;

  List<FriendRequestItem> _incoming = const <FriendRequestItem>[];
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _actionLoading = {};

  List<FriendRequestItem> get incoming => _incoming;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool isProcessing(String requestId) => _actionLoading[requestId] == true;

  Future<void> loadIncomingRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _incoming = await _service.fetchIncomingRequests();
    } catch (err) {
      _error = 'Không thể tải lời mời kết bạn. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> accept(String requestId) async {
    _setProcessing(requestId, true);
    _error = null;
    try {
      final request = _incoming.firstWhere((element) => element.id == requestId);
      await _service.acceptFriendRequest(request);
      _incoming = _incoming.where((e) => e.id != requestId).toList();
    } catch (err) {
      _error = 'Không thể chấp nhận lời mời. Vui lòng thử lại.';
      rethrow;
    } finally {
      _setProcessing(requestId, false);
    }
  }

  Future<void> reject(String requestId) async {
    _setProcessing(requestId, true);
    _error = null;
    try {
      await _service.rejectFriendRequest(requestId);
      _incoming = _incoming.where((e) => e.id != requestId).toList();
    } catch (err) {
      _error = 'Không thể từ chối lời mời. Vui lòng thử lại.';
      rethrow;
    } finally {
      _setProcessing(requestId, false);
    }
  }

  void _setProcessing(String requestId, bool value) {
    _actionLoading[requestId] = value;
    notifyListeners();
  }
}
